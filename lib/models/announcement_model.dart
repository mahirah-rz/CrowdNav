class Announcement {
  final String id;
  final String title;
  final String body;
  final String targetDepartment; 
  final String targetProgram;    
  final String priority;         
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.targetDepartment,
    required this.targetProgram,
    required this.priority,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      targetDepartment: map['target_department'] ?? 'all',
      targetProgram: map['target_program'] ?? 'all',
      priority: map['priority'] ?? 'normal',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}