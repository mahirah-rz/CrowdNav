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
    'Bangla',
    'Tourism & Hospitality Management',
    'Public Health',
    'Islamic History & Culture',
    'Civil Engineering',
    
  ];

  final List<String> _programs = const [
    'All',
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

  final List<String> _priorities = const ['Normal', 'High', 'Emergency'];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _posting = true);

    try {
      final isAdmin = await SupabaseService.isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admin users can post announcements.');
      }

      await SupabaseService.postAnnouncement(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        targetDepartment: _targetDept,
        targetProgram: _targetProgram,
        priority: _priority,
        files: _files,
        links: _links,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement posted successfully.'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Emergency':
        return Colors.redAccent;
      case 'High':
        return Colors.orange;
      default:
        return const Color(0xFF2ECC71);
    }
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final safeItems = items.toSet().toList();
    final safeValue = safeItems.contains(value) ? value : safeItems.first;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: safeItems.map((e) {
        final labelText = e == 'All' ? 'All' : e;
        return DropdownMenuItem<String>(
          value: e,
          child: Text(
            labelText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTargetSelectors() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 430;

        final dept = _dropdown(
          'Department',
          _targetDept,
          _departments,
          (v) => setState(() => _targetDept = v ?? 'All'),
        );

        final program = _dropdown(
          'Program',
          _targetProgram,
          _programs,
          (v) => setState(() => _targetProgram = v ?? 'All'),
        );

        if (useVerticalLayout) {
          return Column(
            children: [
              dept,
              const SizedBox(height: 12),
              program,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: dept),
            const SizedBox(width: 10),
            Expanded(child: program),
          ],
        );
      },
    );
  }

  Widget _buildPrioritySelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 360;

        final buttons = _priorities.map((p) {
          final selected = _priority == p;
          final color = _priorityColor(p);
          return _PriorityButton(
            label: p.toUpperCase(),
            selected: selected,
            color: color,
            onTap: () => setState(() => _priority = p),
          );
        }).toList();

        if (useVerticalLayout) {
          return Column(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                SizedBox(width: double.infinity, child: buttons[i]),
                if (i != buttons.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              Expanded(child: buttons[i]),
              if (i != buttons.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        title: const Text('Create Announcement'),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  InputField(
                    controller: _titleController,
                    keyboardType: TextInputType.text,
                    label: 'Notice title',
                    hint: 'e.g. 9–5PM CSE Routine Fall_26',
                    icon: Icons.title,
                    validator: (v) =>
                        (v == null || v.trim().length < 3) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),
                  InputField(
                    controller: _bodyController,
                    keyboardType: TextInputType.multiline,
                    label: 'Notice body',
                    hint: 'Add notice with Media',
                    icon: Icons.notes_outlined,
                    maxLines: 7,
                    validator: (v) =>
                        (v == null || v.trim().length < 10) ? 'Notice body is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTargetSelectors(),
                  const SizedBox(height: 14),
                  Text(
                    'Priority',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPrioritySelector(),
                  const SizedBox(height: 14),
                  AttachmentPickerPanel(
                    title: 'images/documents/links',
                    files: _files,
                    links: _links,
                    onFilesChanged: (v) => setState(() {
                      _files
                        ..clear()
                        ..addAll(v);
                    }),
                    onLinksChanged: (v) => setState(() {
                      _links
                        ..clear()
                        ..addAll(v);
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _posting
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                          )
                        : ElevatedButton.icon(
                            onPressed: _post,
                            icon: const Icon(Icons.campaign),
                            label: Text(
                              'Publish Announcement',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
