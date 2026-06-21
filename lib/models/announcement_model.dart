import 'app_attachment.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String targetDepartment;
  final String targetProgram;
  final String priority;
  final DateTime createdAt;
  final List<AppAttachment> attachments;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.targetDepartment,
    required this.targetProgram,
    required this.priority,
    required this.createdAt,
    this.attachments = const [],
  });

  factory Announcement.fromMap(Map map, {List<AppAttachment> attachments = const []}) {
    return Announcement(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      targetDepartment: (map['target_department'] ?? 'all').toString(),
      targetProgram: (map['target_program'] ?? 'all').toString(),
      priority: (map['priority'] ?? 'normal').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      attachments: attachments,
    );
  }

  int get imageCount => attachments.where((e) => e.isImage).length;
  int get fileCount => attachments.where((e) => e.isFile).length;
  int get linkCount => attachments.where((e) => e.isLink).length;
}
