import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_attachment.dart';
import '../services/supabase_service.dart';
import '../widgets/attachment_picker_panel.dart';
import '../widgets/input_field.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final List<PickedAttachment> _files = [];
  final List<NoticeLink> _links = [];

  String _targetDept = 'All';
  String _targetProgram = 'All';
  String _priority = 'Normal';
  bool _posting = false;

  final List<String> _departments = const [
    'All',
    'CSE',
    'EEE',
    'Architecture',
    'Business Administration',
    'English',
    'Law',
    'Civil Engineering',
    'Islamic Studies',
    'Public Health',
  ];

  final List<String> _programs = const [
    'All',
    'BSc',
    'MSc',
    'BBA',
    'MBA',
    'BA',
    'MA',
    'LLB',
    'LLM',
  ];

  final List<String> _priorities = const ['Normal', 'High', 'Emergency'];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _posting = true);
    try {
      await SupabaseService.postAnnouncement(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        targetRole: 'all',
        targetDepartment: _targetDept,
        targetProgram: _targetProgram,
        priority: _priority,
        files: _files,
        links: _links,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice posted successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $error')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  String _label(String value) {
    if (value == 'All') return 'All';
    if (value == 'Normal') return 'NORMAL';
    if (value == 'High') return 'HIGH';
    if (value == 'Emergency') return 'EMERGENCY';
    return value;
  }

  Color _priorityColor(String value) {
    switch (value) {
      case 'High':
        return Colors.orange;
      case 'Emergency':
        return Colors.redAccent;
      case 'Normal':
      default:
        return const Color(0xFF31C96F);
    }
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black54, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E8E4E), width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(_label(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E8E4E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create Announcement',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              InputField(
                controller: _titleController,
                keyboardType: TextInputType.text,
                label: 'Notice title',
                hint: 'Enter notice title',
                icon: Icons.campaign_outlined,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter notice title' : null,
              ),
              const SizedBox(height: 16),
              InputField(
                controller: _bodyController,
                keyboardType: TextInputType.multiline,
                label: 'Notice body',
                hint: 'Write notice details',
                icon: Icons.notes,
                maxLines: 5,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter notice body' : null,
              ),
              const SizedBox(height: 18),
              _dropdown(
                label: 'Department',
                value: _targetDept,
                items: _departments,
                onChanged: (value) => setState(() => _targetDept = value ?? 'All'),
              ),
              const SizedBox(height: 12),
              _dropdown(
                label: 'Program',
                value: _targetProgram,
                items: _programs,
                onChanged: (value) => setState(() => _targetProgram = value ?? 'All'),
              ),
              const SizedBox(height: 18),
              Text(
                'Priority',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF425466),
                ),
              ),
              const SizedBox(height: 8),
              for (final item in _priorities) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _priority = item),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _priority == item
                          ? _priorityColor(item)
                          : Colors.white,
                      foregroundColor: _priority == item
                          ? Colors.white
                          : _priorityColor(item),
                      side: BorderSide(color: _priorityColor(item)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _label(item),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
              AttachmentPickerPanel(
                title: 'images/documents/links',
                files: _files,
                links: _links,
                onFilesChanged: (value) => setState(() {
                  _files
                    ..clear()
                    ..addAll(value);
                }),
                onLinksChanged: (value) => setState(() {
                  _links
                    ..clear()
                    ..addAll(value);
                }),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _posting ? null : _submit,
                  icon: _posting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_posting ? 'Posting...' : 'Post Notice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E8E4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
