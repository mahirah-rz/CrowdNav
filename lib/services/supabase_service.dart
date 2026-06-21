import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement_model.dart';
import '../models/app_attachment.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String attachmentsBucket = 'app_attachments';

  static String? get currentUserId => _client.auth.currentUser?.id;
  static String get currentUserEmail => _client.auth.currentUser?.email ?? '';
  static bool get isLoggedIn => _client.auth.currentSession != null;

  static Future<Map<String, dynamic>?> getProfileMap() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  static Future<UserModel?> getProfile() async {
    final data = await getProfileMap();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  static Future<bool> isCurrentUserAdmin() async {
    final profile = await getProfileMap();
    return (profile?['role'] ?? '').toString() == 'admin';
  }

  static Future<void> upsertProfile(Map<String, dynamic> profile) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').upsert({
      ...profile,
      'id': userId,
      'email': profile['email'] ?? currentUserEmail,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  static Future<String> uploadAvatarBytes(Uint8List bytes, String originalName) async {
    final userId = currentUserId;
    if (userId == null) throw const AuthException('You must be logged in to upload a profile picture.');

    final ext = _extension(originalName, fallback: 'jpg');
    final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
    final contentType = _mimeType('avatar.$safeExt');
    final storagePath = '$userId/avatars/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _client.storage.from('avatars').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(cacheControl: '3600', upsert: true, contentType: contentType),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    await updateProfile({'avatar_url': publicUrl});
    return publicUrl;
  }

  static Future<void> saveDeviceToken({required String fcmToken, String platform = 'android'}) async {
    final userId = currentUserId;
    if (userId == null || fcmToken.trim().isEmpty) return;
    final profile = await getProfileMap();

    await _client.from('device_tokens').upsert({
      'user_id': userId,
      'fcm_token': fcmToken,
      'platform': platform,
      'role': profile?['role'] ?? 'student',
      'department': profile?['department'],
      'program': profile?['program'],
      'office_section': profile?['office_section'],
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'fcm_token');
  }

  static Future<void> deactivateCurrentDeviceToken(String fcmToken) async {
    if (fcmToken.trim().isEmpty) return;
    await _client.from('device_tokens').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('fcm_token', fcmToken);
  }

  // ---------------- Bus ----------------
  static Future<void> updateBusLocation({
    required String busId,
    required double lat,
    required double lng,
    String routeName = '',
    String driverName = '',
    String driverPhone = '',
    double? speedKmph,
    double? heading,
  }) async {
    await _client.from('bus_locations').upsert({
      'bus_id': busId,
      'latitude': lat,
      'longitude': lng,
      'route_name': routeName,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'speed_kmph': speedKmph,
      'heading': heading,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'bus_id');
  }

  static Future<void> clearBusLocation(String busId) async {
    await _client.from('bus_locations').delete().eq('bus_id', busId);
  }

  static Future<List<Map<String, dynamic>>> getBusLocations() async {
    try {
      final data = await _client.from('bus_locations').select().order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  static RealtimeChannel busLocationStream(void Function() onChange) {
    return _client
        .channel('public:bus_locations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bus_locations',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  // ---------------- Announcements ----------------
  static Future<List<Announcement>> getAnnouncements({
    String role = 'all',
    String department = 'all',
    String program = 'all',
  }) async {
    try {
      final data = await _client.from('announcements').select().order('created_at', ascending: false);
      final list = <Announcement>[];

      for (final raw in data as List) {
        final map = Map<String, dynamic>.from(raw);
        final targetRole = (map['target_role'] ?? 'all').toString();
        final targetDepartment = (map['target_department'] ?? 'all').toString();
        final targetProgram = (map['target_program'] ?? 'all').toString();

        final roleOk = targetRole == 'all' || role == 'all' || targetRole == role;
        final deptOk = targetDepartment == 'all' || department == 'all' || targetDepartment == department;
        final programOk = targetProgram == 'all' || program == 'all' || targetProgram == program;
        if (!roleOk || !deptOk || !programOk) continue;

        final attachments = await getAnnouncementAttachments(map['id'].toString());
        list.add(Announcement.fromMap(map, attachments: attachments));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<String> postAnnouncement({
    required String title,
    required String body,
    String targetRole = 'all',
    String targetDepartment = 'all',
    String targetProgram = 'all',
    String priority = 'normal',
    List<PickedAttachment> files = const [],
    List<NoticeLink> links = const [],
  }) async {
    final inserted = await _client
        .from('announcements')
        .insert({
          'title': title,
          'body': body,
          'target_role': targetRole,
          'target_department': targetDepartment,
          'target_program': targetProgram,
          'priority': priority,
          'sent_push': false,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final announcementId = inserted['id'].toString();
    await _saveAnnouncementAttachments(announcementId: announcementId, files: files, links: links);
    return announcementId;
  }

  static Future<void> _saveAnnouncementAttachments({
    required String announcementId,
    required List<PickedAttachment> files,
    required List<NoticeLink> links,
  }) async {
    for (final file in files) {
      final uploaded = await _uploadPickedFile(file, folder: 'announcements/$announcementId');
      await _client.from('announcement_attachments').insert({
        'announcement_id': announcementId,
        'kind': uploaded.kind,
        'file_name': uploaded.fileName,
        'file_url': uploaded.fileUrl,
        'mime_type': uploaded.mimeType,
        'file_size': uploaded.fileSize,
        'storage_path': uploaded.storagePath,
      });
    }

    for (final link in links) {
      await _client.from('announcement_attachments').insert({
        'announcement_id': announcementId,
        'kind': 'link',
        'file_name': link.title,
        'file_url': link.url,
        'mime_type': 'text/uri-list',
        'file_size': 0,
        'storage_path': '',
      });
    }
  }

  static Future<List<AppAttachment>> getAnnouncementAttachments(String announcementId) async {
    try {
      final data = await _client
          .from('announcement_attachments')
          .select()
          .eq('announcement_id', announcementId)
          .order('created_at', ascending: true);
      return (data as List).map((e) => AppAttachment.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static RealtimeChannel announcementStream(void Function() onChange) {
    return _client
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  // ---------------- Complaints ----------------
  static Future<String> submitComplaint({
    required String category,
    required String subject,
    required String description,
    String priority = 'normal',
    List<PickedAttachment> files = const [],
    List<NoticeLink> links = const [],
  }) async {
    final userId = currentUserId;
    if (userId == null) throw const AuthException('Please login to submit a complaint.');
    final profile = await getProfile();

    final inserted = await _client
        .from('complaints')
        .insert({
          'user_id': userId,
          'user_name': profile?.name ?? 'Unknown',
          'user_department': profile?.department ?? '',
          'category': category,
          'subject': subject,
          'description': description,
          'priority': priority,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final complaintId = inserted['id'].toString();
    await _saveComplaintAttachments(complaintId: complaintId, files: files, links: links);
    return complaintId;
  }

  static Future<List<ComplaintModel>> getMyComplaints() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final data = await _client.from('complaints').select().eq('user_id', userId).order('created_at', ascending: false);
    final list = <ComplaintModel>[];
    for (final raw in data as List) {
      final map = Map<String, dynamic>.from(raw);
      final attachments = (await getComplaintAttachments(map['id'].toString())).where((a) => a.replyId == null).toList();
      list.add(ComplaintModel.fromMap(map, attachments: attachments));
    }
    return list;
  }

  static Future<List<ComplaintModel>> getAllComplaints() async {
    final data = await _client.from('complaints').select().order('created_at', ascending: false);
    final list = <ComplaintModel>[];
    for (final raw in data as List) {
      final map = Map<String, dynamic>.from(raw);
      final attachments = (await getComplaintAttachments(map['id'].toString())).where((a) => a.replyId == null).toList();
      list.add(ComplaintModel.fromMap(map, attachments: attachments));
    }
    return list;
  }

  static Future<List<AppAttachment>> getComplaintAttachments(String complaintId) async {
    try {
      final data = await _client
          .from('complaint_attachments')
          .select()
          .eq('complaint_id', complaintId)
          .order('created_at', ascending: true);
      return (data as List).map((e) => AppAttachment.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveComplaintAttachments({
    required String complaintId,
    String? replyId,
    required List<PickedAttachment> files,
    required List<NoticeLink> links,
  }) async {
    final userId = currentUserId;

    for (final file in files) {
      final uploaded = await _uploadPickedFile(file, folder: 'complaints/$complaintId${replyId == null ? '' : '/replies/$replyId'}');
      await _client.from('complaint_attachments').insert({
        'complaint_id': complaintId,
        'reply_id': replyId,
        'sender_id': userId,
        'kind': uploaded.kind,
        'file_name': uploaded.fileName,
        'file_url': uploaded.fileUrl,
        'mime_type': uploaded.mimeType,
        'file_size': uploaded.fileSize,
        'storage_path': uploaded.storagePath,
      });
    }

    for (final link in links) {
      await _client.from('complaint_attachments').insert({
        'complaint_id': complaintId,
        'reply_id': replyId,
        'sender_id': userId,
        'kind': 'link',
        'file_name': link.title,
        'file_url': link.url,
        'mime_type': 'text/uri-list',
        'file_size': 0,
        'storage_path': '',
      });
    }
  }

  static Future<List<ComplaintReply>> getComplaintReplies(String complaintId) async {
    final repliesData = await _client
        .from('complaint_replies')
        .select()
        .eq('complaint_id', complaintId)
        .order('created_at', ascending: true);

    final allAttachments = await getComplaintAttachments(complaintId);
    final replies = <ComplaintReply>[];
    for (final raw in repliesData as List) {
      final map = Map<String, dynamic>.from(raw);
      final replyId = map['id'].toString();
      final replyAttachments = allAttachments.where((a) => a.replyId == replyId).toList();
      replies.add(ComplaintReply.fromMap(map, attachments: replyAttachments));
    }
    return replies;
  }

  static Future<String> postComplaintReply({
    required String complaintId,
    required String message,
    List<PickedAttachment> files = const [],
    List<NoticeLink> links = const [],
  }) async {
    final userId = currentUserId;
    if (userId == null) throw const AuthException('Please login to reply.');
    final profile = await getProfile();

    final inserted = await _client
        .from('complaint_replies')
        .insert({
          'complaint_id': complaintId,
          'sender_id': userId,
          'sender_name': profile?.name ?? 'Unknown',
          'sender_role': profile?.role ?? 'student',
          'message': message,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final replyId = inserted['id'].toString();
    await _saveComplaintAttachments(complaintId: complaintId, replyId: replyId, files: files, links: links);
    return replyId;
  }

  static Future<void> updateComplaintStatus({required String complaintId, required String status}) async {
    await _client.from('complaints').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);
  }

  
  static Future<AppAttachment> _uploadPickedFile(PickedAttachment file, {required String folder}) async {
    final userId = currentUserId;
    if (userId == null) throw const AuthException('Please login to upload files.');

    final safeName = _safeFileName(file.name);
    final path = '$userId/$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final mime = _mimeType(file.name);
    final kind = mime.startsWith('image/') ? 'image' : 'file';

    await _client.storage.from(attachmentsBucket).uploadBinary(
          path,
          file.bytes,
          fileOptions: FileOptions(cacheControl: '3600', upsert: true, contentType: mime),
        );

    final url = _client.storage.from(attachmentsBucket).getPublicUrl(path);
    return AppAttachment(
      id: '',
      ownerId: '',
      kind: kind,
      fileName: file.name,
      fileUrl: url,
      mimeType: mime,
      fileSize: file.size,
      storagePath: path,
      createdAt: DateTime.now(),
    );
  }

  static String _safeFileName(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return cleaned.isEmpty ? 'file' : cleaned;
  }

  static String _extension(String name, {String fallback = 'bin'}) {
    final clean = name.toLowerCase().split('?').first;
    if (!clean.contains('.')) return fallback;
    final ext = clean.split('.').last.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return ext.isEmpty ? fallback : ext;
  }

  static String _mimeType(String name) {
    switch (_extension(name)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
