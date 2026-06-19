import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../models/complaint_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String? get currentUserId => _client.auth.currentUser?.id;
  static String get currentUserEmail => _client.auth.currentUser?.email ?? '';

  static Future<Map<String, dynamic>?> getProfileMap() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }

  static Future<UserModel?> getProfile() async {
    final data = await getProfileMap();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  static Future<void> upsertProfile(Map<String, dynamic> profile) async {
    final userId = currentUserId;
    if (userId == null) return;

    final payload = {
      ...profile,
      'id': userId,
      'email': profile['email'] ?? currentUserEmail,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('profiles').upsert(payload, onConflict: 'id');
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.from('profiles').update({
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }



  static Future<String> uploadAvatar(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('You must be logged in to upload a profile picture.');
    }

    final ext = imageFile.path.split('.').last.toLowerCase();
    final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
    final storagePath = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _client.storage.from('avatars').upload(
          storagePath,
          imageFile,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: safeExt == 'png'
                ? 'image/png'
                : safeExt == 'webp'
                    ? 'image/webp'
                    : 'image/jpeg',
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    await updateProfile({'avatar_url': publicUrl});
    return publicUrl;
  }

  static Future<void> saveDeviceToken({
    required String fcmToken,
    String platform = 'android',
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

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
    await _client
        .from('device_tokens')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('fcm_token', fcmToken);
  }

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
    final data = await _client
        .from('bus_locations')
        .select()
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
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

  static Future<List<Announcement>> getAnnouncements({
    String role = 'all',
    String department = 'all',
    String program = 'all',
  }) async {
    final data = await _client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Announcement.fromMap(Map<String, dynamic>.from(e)))
        .where((a) =>
            (a.targetDepartment == 'all' || a.targetDepartment == department) &&
            (a.targetProgram == 'all' || a.targetProgram == program))
        .toList();
  }

  static Future<void> postAnnouncement({
    required String title,
    required String body,
    String targetRole = 'all',
    String targetDepartment = 'all',
    String targetProgram = 'all',
    String priority = 'normal',
  }) async {
    await _client.from('announcements').insert({
      'title': title,
      'body': body,
      'target_role': targetRole,
      'target_department': targetDepartment,
      'target_program': targetProgram,
      'priority': priority,
      'sent_push': false,
      'created_at': DateTime.now().toIso8601String(),
    });
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

  static Future<void> submitComplaint({
    required String category,
    required String subject,
    required String description,
    String priority = 'normal',
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final profile = await getProfile();

    await _client.from('complaints').insert({
      'user_id': userId,
      'user_name': profile?.name ?? 'Unknown',
      'user_department': profile?.department ?? '',
      'category': category,
      'subject': subject,
      'description': description,
      'priority': priority,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<ComplaintModel>> getMyComplaints() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final data = await _client
        .from('complaints')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => ComplaintModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<ComplaintModel>> getAllComplaints() async {
    final data = await _client
        .from('complaints')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => ComplaintModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<ComplaintReply>> getComplaintReplies(
    String complaintId,
  ) async {
    final data = await _client
        .from('complaint_replies')
        .select()
        .eq('complaint_id', complaintId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => ComplaintReply.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> postComplaintReply({
    required String complaintId,
    required String message,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final profile = await getProfile();

    await _client.from('complaint_replies').insert({
      'complaint_id': complaintId,
      'sender_id': userId,
      'sender_name': profile?.name ?? 'Unknown',
      'sender_role': profile?.role ?? 'student',
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
  }) async {
    await _client.from('complaints').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}