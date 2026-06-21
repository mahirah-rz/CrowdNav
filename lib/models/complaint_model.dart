import 'app_attachment.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final String userDepartment;
  final String category;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AppAttachment> attachments;

  const ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userDepartment,
    required this.category,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  int get imageCount => attachments.where((a) => a.isImage).length;
  int get fileCount => attachments.where((a) => a.isFile).length;
  int get linkCount => attachments.where((a) => a.isLink).length;

  factory ComplaintModel.fromMap(
    Map<String, dynamic> map, {
    List<AppAttachment> attachments = const [],
  }) {
    return ComplaintModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      userName: (map['user_name'] ?? 'Unknown').toString(),
      userDepartment: (map['user_department'] ?? '').toString(),
      category: (map['category'] ?? 'general').toString(),
      subject: (map['subject'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      priority: (map['priority'] ?? 'normal').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()) ?? DateTime.now(),
      attachments: attachments,
    );
  }
}

class ComplaintReply {
  final String id;
  final String complaintId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;
  final List<AppAttachment> attachments;

  const ComplaintReply({
    required this.id,
    required this.complaintId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.attachments = const [],
  });

  int get imageCount => attachments.where((a) => a.isImage).length;
  int get fileCount => attachments.where((a) => a.isFile).length;
  int get linkCount => attachments.where((a) => a.isLink).length;

  factory ComplaintReply.fromMap(
    Map<String, dynamic> map, {
    List<AppAttachment> attachments = const [],
  }) {
    return ComplaintReply(
      id: (map['id'] ?? '').toString(),
      complaintId: (map['complaint_id'] ?? '').toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      senderName: (map['sender_name'] ?? 'Unknown').toString(),
      senderRole: (map['sender_role'] ?? 'student').toString(),
      message: (map['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      attachments: attachments,
    );
  }
}
