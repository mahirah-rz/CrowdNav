import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../services/supabase_service.dart';
import '../widgets/input_field.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfilePage({super.key, this.onProfileUpdated});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();

  String _selectedDept = 'CSE';
  String _selectedProgram = 'BSc';
  String _selectedBlood = 'A+';
  String _assignedRoute = 'Route 1 – Tilagor';

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

  bool get _isLoggedIn => Supabase.instance.client.auth.currentSession != null;
  String get _role => (_profile?['role'] ?? 'student').toString();
  bool get _needsDepartment => _role == 'student' || _role == 'faculty' || _role == 'office_staff' || _role == 'office staff';
  bool get _needsProgram => _role == 'student';
  bool get _needsRoute => _role == 'driver';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    if (!_isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loading = false;
        _editing = false;
      });
      return;
    }

    try {
      final data = await SupabaseService.getProfileMap();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
      });
      if (data != null) _populateControllers(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile load failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    _nameController.text = (data['name'] ?? '').toString();
    _phoneController.text = (data['phone'] ?? '').toString();
    _idController.text = (data['student_id'] ?? '').toString();
    _selectedDept = _departments.contains(data['department']) ? data['department'] : _departments.first;
    _selectedProgram = _programs.contains(data['program']) ? data['program'] : _programs.first;
    _selectedBlood = _bloodGroups.contains(data['blood_group']) ? data['blood_group'] : _bloodGroups.first;
    _assignedRoute = _routes.contains(data['assigned_route']) ? data['assigned_route'] : _routes.first;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'driver':
        return 'Bus Driver';
      case 'admin':
        return 'Administrator';
      case 'faculty':
        return 'Faculty';
      case 'office_staff':
      case 'office staff':
        return 'Office Staff';
      default:
        return 'Student';
    }
  }

  String get _idLabel {
    switch (_role) {
      case 'driver':
        return 'Driver ID';
      case 'faculty':
        return 'Faculty ID';
      case 'office_staff':
      case 'office staff':
        return 'Staff ID';
      default:
        return 'Student ID';
    }
  }

  void _enterEditMode() {
    if (_profile != null) _populateControllers(_profile!);
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    if (_profile != null) _populateControllers(_profile!);
    setState(() => _editing = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    if (!_isLoggedIn) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
      );

      if (picked == null) return;
      setState(() => _uploadingAvatar = true);

      final bytes = await picked.readAsBytes();
      final url = await SupabaseService.uploadAvatarBytes(bytes, picked.name);
      final fresh = await SupabaseService.getProfileMap();

      if (!mounted) return;
      setState(() {
        _profile = fresh ?? {...(_profile ?? <String, dynamic>{}), 'avatar_url': url};
        _uploadingAvatar = false;
      });
      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated.'), backgroundColor: Color(0xFF2ECC71)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture upload failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'student_id': _idController.text.trim(),
        'department': _needsDepartment ? _selectedDept : '',
        'program': _needsProgram ? _selectedProgram : '',
        'blood_group': _selectedBlood,
        'assigned_route': _needsRoute ? _assignedRoute : '',
      };

      await SupabaseService.updateProfile(updates);
      final fresh = await SupabaseService.getProfileMap();

      if (!mounted) return;
      setState(() {
        _profile = fresh ?? {...?_profile, ...updates};
        _editing = false;
        _saving = false;
      });
      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.'), backgroundColor: Color(0xFF2ECC71)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _logout() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    setState(() {
      _profile = null;
      _editing = false;
    });
    widget.onProfileUpdated?.call();
  }

  Future<void> _openLogin() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    await _loadProfile();
    widget.onProfileUpdated?.call();
  }

  Future<void> _openRegister() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
    await _loadProfile();
    widget.onProfileUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
    }

    if (!_isLoggedIn) {
      return _buildGuestProfile();
    }

    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No profile record found.', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Please complete registration again or ask admin to verify your account.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _logout, child: const Text('Back to Home')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _editing ? _buildEditForm() : _buildViewCards(),
        const SizedBox(height: 16),
        if (!_editing)
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGuestProfile() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF123D35), Color(0xFF1E6B5C)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_outline, size: 46, color: Color(0xFF123D35)),
              ),
              const SizedBox(height: 14),
              Text('Guest Mode', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              const Text(
                'Login/Register to access more features!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openLogin,
                    icon: const Icon(Icons.login),
                    label: Text('Login', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _openRegister,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text('Create New Account', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E8449),
                      side: const BorderSide(color: Color(0xFF1E8449)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final name = (_profile?['name'] ?? 'User').toString();
    final role = _roleLabel(_role);
    final avatarUrl = (_profile?['avatar_url'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF123D35), Color(0xFF1E6B5C)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 42, color: Color(0xFF123D35)) : null,
              ),
              GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle),
                  child: _uploadingAvatar
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(30)),
            child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          if (!_editing) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _enterEditMode,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewCards() {
    final email = (_profile?['email'] ?? '').toString();
    final phone = (_profile?['phone'] ?? '').toString();
    final id = (_profile?['student_id'] ?? '').toString();
    final dept = (_profile?['department'] ?? '').toString();
    final program = (_profile?['program'] ?? '').toString();
    final blood = (_profile?['blood_group'] ?? '').toString();
    final route = (_profile?['assigned_route'] ?? '').toString();

    return Column(
      children: [
        _buildCard('Personal Information', [
          _item(Icons.email_outlined, 'Email', email, locked: true),
          _item(Icons.phone_outlined, 'Phone', phone),
          _item(Icons.badge_outlined, _idLabel, id),
        ]),
        if (_needsDepartment || _needsProgram)
          _buildCard('University Information', [
            if (_needsDepartment) _item(Icons.school_outlined, 'Department / Office', dept),
            if (_needsProgram) _item(Icons.menu_book_outlined, 'Program', program),
          ]),
        if (_needsRoute)
          _buildCard('Driver Information', [
            _item(Icons.route_outlined, 'Assigned Route', route),
          ]),
        _buildCard('Emergency Information', [
          _item(Icons.bloodtype_outlined, 'Blood Group', blood, highlight: true),
        ]),
      ],
    );
  }

  Widget _buildEditForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF123D35))),
                  const Spacer(),
                  TextButton(onPressed: _cancelEdit, child: const Text('Cancel')),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              InputField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 3) return 'Too short';
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
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(v.trim())) return 'Enter a valid BD phone number';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              InputField(
                controller: _idController,
                keyboardType: TextInputType.text,
                label: _idLabel,
                hint: 'Enter your university ID',
                icon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? '$_idLabel is required' : null,
              ),
              const SizedBox(height: 16),
              if (_needsDepartment) ...[
                _buildDropdown(label: 'Department / Office', value: _selectedDept, items: _departments, icon: Icons.school_outlined, onChanged: (v) => setState(() => _selectedDept = v!)),
                const SizedBox(height: 10),
              ],
              if (_needsProgram) ...[
                _buildDropdown(label: 'Program', value: _selectedProgram, items: _programs, icon: Icons.menu_book_outlined, onChanged: (v) => setState(() => _selectedProgram = v!)),
                const SizedBox(height: 10),
              ],
              if (_needsRoute) ...[
                _buildDropdown(label: 'Assigned Route', value: _assignedRoute, items: _routes, icon: Icons.route_outlined, onChanged: (v) => setState(() => _assignedRoute = v!)),
                const SizedBox(height: 10),
              ],
              _buildDropdown(label: 'Blood Group', value: _selectedBlood, items: _bloodGroups, icon: Icons.bloodtype_outlined, onChanged: (v) => setState(() => _selectedBlood = v!)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: _saving
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                    : ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF123D35)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => (v == null || v.isEmpty) ? 'Please select $label' : null,
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF123D35))),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, String text, {bool locked = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 19, color: highlight ? Colors.redAccent : const Color(0xFF123D35)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                Text(
                  text.isNotEmpty ? text : '—',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                    color: highlight ? Colors.redAccent : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          if (locked) const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
