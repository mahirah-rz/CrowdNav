class UserModel {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final String phone;
  final String department;
  final String program;
  final String bloodGroup;
  final String role;
  final String? avatarUrl;
  final String? assignedRoute;
  final String? officeSection;

  const UserModel({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.department,
    required this.program,
    required this.bloodGroup,
    required this.role,
    this.avatarUrl,
    this.assignedRoute,
    this.officeSection,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      studentId: map['student_id'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      program: map['program'] ?? '',
      bloodGroup: map['blood_group'] ?? '',
      role: map['role'] ?? 'student',
      avatarUrl: map['avatar_url'] as String?,
      assignedRoute: map['assigned_route'] as String?,
      officeSection: map['office_section'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'student_id': studentId,
        'email': email,
        'phone': phone,
        'department': department,
        'program': program,
        'blood_group': bloodGroup,
        'role': role,
        'avatar_url': avatarUrl,
        'assigned_route': assignedRoute,
        'office_section': officeSection,
      };
}
