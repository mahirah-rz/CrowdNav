import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'auth_gate.dart';
import '../widgets/input_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _selectedRole = 'student';
  String _selectedDepartment = 'CSE';
  String _selectedProgram = 'BSc';
  String _selectedBloodGroup = 'A+';
  String _assignedRoute = 'Route 1 – Tilagor';
  String _selectedOfficeSection = 'Admission Office';

  bool _isLoading = false;

  final List<String> _roles = const [
    'student',
    'driver',
    'faculty',
    'office_staff',
  ];

  final List<String> _departments = const [
    'CSE',
    'EEE',
    'Architecture',
    'Business Administration',
    'English',
    'Law',
    'Bangla',
    'Tourism & Hospitality Management',
    'Public Health',
    'Islamic History & Culture',
    'Civil Engineering',
    
  ];

  final List<String> _programs = const [
    'BSc',
    'MSc',
    'BBA',
    'MBA',
    'LLB',
    'LLM',
    'BA',
    'MA',
    'B.Arch',
    'M.Arch',
  ];

  final List<String> _bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _routes = const [
    'Route 1 – Tilagor',
    'Route 2 – Surma Tower',
    'Route 3 – Lakkatura',
    'Route 4 – Tilagor (via Bypass)',
  ];

  final List<String> _officeSections = const [
    'Admission Office',
    'Accounts Office',
    'Exam Controller Office',
    'Registrar Office',
    'Library Office',
    'Transport Office',
    'IT Office',
    'Student Affairs Office',
  ];

  bool get _needsStudentId => _selectedRole == 'student';
  bool get _needsDepartment =>
      _selectedRole == 'student' || _selectedRole == 'faculty';
  bool get _needsProgram => _selectedRole == 'student';
  bool get _needsRoute => _selectedRole == 'driver';
  bool get _needsOfficeSection => _selectedRole == 'office_staff';

  String _roleLabel(String role) {
    switch (role) {
      case 'driver':
        return 'Bus Driver';
      case 'faculty':
        return 'Faculty';
      case 'office_staff':
        return 'Office Staff';
      default:
        return 'Student';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authResponse.user;

      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
          'student_id':
              _needsStudentId ? _studentIdController.text.trim() : null,
          'department': _needsDepartment ? _selectedDepartment : null,
          'program': _needsProgram ? _selectedProgram : null,
          'office_section':
              _needsOfficeSection ? _selectedOfficeSection : null,
          'assigned_route': _needsRoute ? _assignedRoute : null,
          'blood_group': _selectedBloodGroup,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      }

      if (!mounted) return;

      if (authResponse.session != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created. Please confirm your email.'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
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
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(display == null ? e : display(e)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Please select $label' : null,
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF123D35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF123D35),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF123D35),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _sectionLabel('ROLE'),
                    const SizedBox(height: 8),
                    _dropdown(
                      label: 'Role',
                      value: _selectedRole,
                      items: _roles,
                      display: _roleLabel,
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('PERSONAL INFORMATION'),
                    const SizedBox(height: 8),

                    InputField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    if (_needsStudentId) ...[
                      InputField(
                        controller: _studentIdController,
                        keyboardType: TextInputType.text,
                        label: 'Student ID',
                        hint: 'Enter your student ID',
                        icon: Icons.badge_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Student ID is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                    ],

                    InputField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      label: 'Email',
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    InputField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      label: 'Phone',
                      hint: '01XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone is required';
                        }
                        if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(v.trim())) {
                          return 'Enter valid BD phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    if (_needsDepartment ||
                        _needsProgram ||
                        _needsRoute ||
                        _needsOfficeSection) ...[
                      _sectionLabel(
                        _needsRoute
                            ? 'TRANSPORT INFORMATION'
                            : _needsOfficeSection
                                ? 'OFFICE INFORMATION'
                                : 'UNIVERSITY INFORMATION',
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (_needsDepartment) ...[
                      _dropdown(
                        label: 'Department',
                        value: _selectedDepartment,
                        items: _departments,
                        onChanged: (v) =>
                            setState(() => _selectedDepartment = v!),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (_needsProgram) ...[
                      _dropdown(
                        label: 'Program',
                        value: _selectedProgram,
                        items: _programs,
                        onChanged: (v) =>
                            setState(() => _selectedProgram = v!),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (_needsOfficeSection) ...[
                      _dropdown(
                        label: 'Office Section',
                        value: _selectedOfficeSection,
                        items: _officeSections,
                        onChanged: (v) =>
                            setState(() => _selectedOfficeSection = v!),
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

                    _sectionLabel('EMERGENCY INFORMATION'),
                    const SizedBox(height: 8),
                    _dropdown(
                      label: 'Blood Group',
                      value: _selectedBloodGroup,
                      items: _bloodGroups,
                      onChanged: (v) =>
                          setState(() => _selectedBloodGroup = v!),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('SECURITY'),
                    const SizedBox(height: 8),

                    InputField(
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      label: 'Password',
                      hint: 'Min 8 characters',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    InputField(
                      controller: _confirmController,
                      keyboardType: TextInputType.visiblePassword,
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2ECC71),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _register,
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}