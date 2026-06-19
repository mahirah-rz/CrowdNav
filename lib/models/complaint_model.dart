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
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? 'Unknown',
      userDepartment: map['user_department'] ?? '',
      category: map['category'] ?? 'general',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'normal',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
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

  const ComplaintReply({
    required this.id,
    required this.complaintId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory ComplaintReply.fromMap(Map<String, dynamic> map) {
    return ComplaintReply(
      id: map['id'] ?? '',
      complaintId: map['complaint_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? 'Unknown',
      senderRole: map['sender_role'] ?? 'student',
      message: map['message'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}