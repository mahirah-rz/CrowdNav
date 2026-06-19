import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_gate.dart';
import '../services/supabase_service.dart';
import '../widgets/input_field.dart';

class CompleteProfilePage extends StatefulWidget {
  final String email;
  final String name;

  const CompleteProfilePage({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'student';
  String _selectedDepartment = 'CSE';
  String _selectedProgram = 'BSc';
  String _selectedBloodGroup = 'A+';
  String _assignedRoute = 'Route 1 – Tilagor';
  bool _isLoading = false;

  final List<String> _roles = ['student', 'driver', 'faculty', 'office_staff'];
  final List<String> _departments = const [
    'CSE', 'EEE', 'Architecture', 'Business Administration', 'English',
    'Law', 'Bangla', 'Tourism & Hospitality Management', 'Public Health',
    'Islamic History & Culture', 'Civil Engineering', 'Electrical & Electronic Engineering',
  ];
  final List<String> _programs = const [
    'BSc', 'MSc', 'BBA', 'MBA', 'LLB', 'LLM', 'BA', 'MA', 'B.Arch', 'M.Arch',
  ];
  final List<String> _bloodGroups = const [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
  final List<String> _routes = const [
    'Route 1 – Tilagor',
    'Route 2 – Surma Tower',
    'Route 3 – Lakkatura',
    'Route 4 – Tilagor (via Bypass)',
  ];

  bool get _needsDepartment => _selectedRole == 'student' || _selectedRole == 'faculty' || _selectedRole == 'office_staff';
  bool get _needsProgram => _selectedRole == 'student';
  bool get _needsRoute => _selectedRole == 'driver';
  bool get _needsId => _selectedRole == 'student';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'driver':
        return 'Bus Driver';
      case 'faculty':
        return 'Faculty';
      case 'office_staff':
      case 'office staff':
        return 'Office Staff';
      default:
        return 'Student';
    }
  }

  String get _idLabel => 'Student ID';

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await SupabaseService.upsertProfile({
        'name': _nameController.text.trim(),
        'student_id': _needsId ? _idController.text.trim() : '',
        'email': widget.email,
        'phone': _phoneController.text.trim(),
        'department': _needsDepartment ? _selectedDepartment : '',
        'program': _needsProgram ? _selectedProgram : '',
        'blood_group': _selectedBloodGroup,
        'role': _selectedRole,
        'assigned_route': _needsRoute ? _assignedRoute : '',
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String Function(String)? display,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  display == null ? e : display(e),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text('Complete Your Profile', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF123D35),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.school_outlined, size: 64, color: Color(0xFF123D35)),
                const SizedBox(height: 12),
                Text(
                  'Almost there!',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF123D35)),
                ),
                const SizedBox(height: 4),
                const Text('Fill in your university details to continue.', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                _dropdown(
                  label: 'Role',
                  value: _selectedRole,
                  items: _roles,
                  display: _roleLabel,
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(height: 10),
                InputField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  label: 'Full Name',
                  hint: 'Your name',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 10),
                if (_needsId) ...[
                  InputField(
                    controller: _idController,
                    keyboardType: TextInputType.text,
                    label: _idLabel,
                    hint: 'Enter your student ID',
                    icon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? '$_idLabel is required' : null,
                  ),
                  const SizedBox(height: 10),
                ],
                InputField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  label: 'Phone',
                  hint: '01XXXXXXXXX',
                  icon: Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone is required';
                    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(v.trim())) return 'Enter valid BD number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (_needsDepartment) ...[
                  _dropdown(
                    label: 'Department / Office',
                    value: _selectedDepartment,
                    items: _departments,
                    onChanged: (v) => setState(() => _selectedDepartment = v!),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_needsProgram) ...[
                  _dropdown(
                    label: 'Program',
                    value: _selectedProgram,
                    items: _programs,
                    onChanged: (v) => setState(() => _selectedProgram = v!),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_needsRoute) ...[
                  _dropdown(
                    label: 'Assigned Bus Route',
                    value: _assignedRoute,
                    items: _routes,
                    onChanged: (v) => setState(() => _assignedRoute = v!),
                  ),
                  const SizedBox(height: 10),
                ],
                _dropdown(
                  label: 'Blood Group',
                  value: _selectedBloodGroup,
                  items: _bloodGroups,
                  onChanged: (v) => setState(() => _selectedBloodGroup = v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Save & Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
