import json
import os
from pathlib import Path
from typing import Any

import firebase_admin
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import credentials, messaging
from pydantic import BaseModel, Field
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
FIREBASE_SERVICE_ACCOUNT_JSON = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
BACKEND_ADMIN_TOKEN = os.getenv("CROWDNAV_BACKEND_ADMIN_TOKEN")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def _init_firebase() -> None:
    if firebase_admin._apps:
        return

    if not FIREBASE_SERVICE_ACCOUNT_JSON:
        raise RuntimeError("Missing FIREBASE_SERVICE_ACCOUNT_JSON")

    raw_value = FIREBASE_SERVICE_ACCOUNT_JSON.strip()

    if raw_value.startswith("{"):
        info: dict[str, Any] = json.loads(raw_value)
        cred = credentials.Certificate(info)
    else:
        key_path = Path(raw_value)
        if not key_path.exists():
            raise RuntimeError(f"Firebase service account file not found: {key_path}")
        cred = credentials.Certificate(str(key_path))

    firebase_admin.initialize_app(cred)


_init_firebase()

app = FastAPI(title="CrowdNav Notification Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class AnnouncementRequest(BaseModel):
    title: str = Field(min_length=1, max_length=160)
    body: str = Field(min_length=1, max_length=2000)
    target_role: str = "all"
    target_department: str = "all"
    target_program: str = "all"
    priority: str = "normal"


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "crowdnav-notification-backend"}


def _extract_bearer_token(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.split(" ", 1)
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1].strip()
    return authorization.strip()


def _validate_admin(authorization: str | None, x_admin_token: str | None) -> dict[str, Any]:
    if BACKEND_ADMIN_TOKEN and x_admin_token == BACKEND_ADMIN_TOKEN:
        return {"id": None, "role": "admin"}

    token = _extract_bearer_token(authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization bearer token.",
        )

    try:
        auth_response = supabase.auth.get_user(token)
        user = auth_response.user
        user_id = user.id
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Supabase user token: {exc}",
        ) from exc

    profile_response = (
        supabase.table("profiles")
        .select("id, role, name, email")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    profile = profile_response.data
    if not profile or profile.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admin users can send announcements.",
        )
    return profile


def _target_matches(value: str | None, target: str | None) -> bool:
    target = (target or "all").strip()
    value = (value or "").strip()
    return target == "all" or value == target


def _select_tokens(req: AnnouncementRequest) -> list[str]:
    response = (
        supabase.table("device_tokens")
        .select("fcm_token, role, department, program, is_active")
        .eq("is_active", True)
        .execute()
    )

    tokens: list[str] = []
    seen: set[str] = set()
    for row in response.data or []:
        token = row.get("fcm_token")
        if not token or token in seen:
            continue
        if not _target_matches(row.get("role"), req.target_role):
            continue
        if not _target_matches(row.get("department"), req.target_department):
            continue
        if not _target_matches(row.get("program"), req.target_program):
            continue
        tokens.append(token)
        seen.add(token)

    return tokens


def _send_multicast(tokens: list[str], req: AnnouncementRequest, announcement_id: str) -> tuple[int, int]:
    if not tokens:
        return 0, 0

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=req.title, body=req.body),
        data={
            "type": "announcement",
            "announcement_id": str(announcement_id),
            "priority": req.priority,
            "target_role": req.target_role,
            "target_department": req.target_department,
            "target_program": req.target_program,
        },
        tokens=tokens,
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="crowdnav_emergency"
                if req.priority == "emergency"
                else "crowdnav_normal",
                sound="default",
            ),
        ),
    )

    success = 0
    failure = 0
    for start in range(0, len(tokens), 500):
        chunk = tokens[start : start + 500]
        chunk_message = messaging.MulticastMessage(
            notification=message.notification,
            data=message.data,
            tokens=chunk,
            android=message.android,
        )
        batch_response = messaging.send_each_for_multicast(chunk_message)
        success += batch_response.success_count
        failure += batch_response.failure_count

    return success, failure


@app.post("/announcements/send")
def create_and_send_announcement(
    req: AnnouncementRequest,
    authorization: str | None = Header(default=None),
    x_admin_token: str | None = Header(default=None),
) -> dict[str, Any]:
    admin_profile = _validate_admin(authorization, x_admin_token)

    insert_response = (
        supabase.table("announcements")
        .insert(
            {
                "title": req.title.strip(),
                "body": req.body.strip(),
                "target_role": req.target_role,
                "target_department": req.target_department,
                "target_program": req.target_program,
                "priority": req.priority,
                "sent_push": False,
                "created_by": admin_profile.get("id"),
            }
        )
        .execute()
    )

    if not insert_response.data:
        raise HTTPException(status_code=500, detail="Failed to create announcement.")

    announcement = insert_response.data[0]
    announcement_id = announcement["id"]
    tokens = _select_tokens(req)

    success_count = 0
    failure_count = 0
    error_message = None

    try:
        success_count, failure_count = _send_multicast(tokens, req, announcement_id)
    except Exception as exc:
        error_message = str(exc)

    update_payload = {
        "sent_push": error_message is None,
        "push_success_count": success_count,
        "push_failure_count": failure_count,
        "push_error": error_message,
    }

    supabase.table("announcements").update(update_payload).eq("id", announcement_id).execute()

    if error_message:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Announcement saved, but FCM sending failed.",
                "announcement_id": announcement_id,
                "error": error_message,
            },
        )

    return {
        "ok": True,
        "announcement_id": announcement_id,
        "targeted_tokens": len(tokens),
        "success_count": success_count,
        "failure_count": failure_count,
    }
