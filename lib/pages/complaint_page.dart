import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/app_attachment.dart';
import '../models/complaint_model.dart';
import '../services/supabase_service.dart';
import '../widgets/attachment_picker_panel.dart';
import '../widgets/input_field.dart';
import 'complaint_detail_page.dart';

class ComplaintPage extends StatelessWidget {
  const ComplaintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (ctx) => Column(
          children: [
            Container(
              color: const Color(0xFF1E8449),
              child: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(icon: Icon(Icons.edit_note), text: 'Submit'),
                  Tab(icon: Icon(Icons.list_alt), text: 'My Complaints'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SubmitTab(onSubmitted: () => DefaultTabController.of(ctx).animateTo(1)),
                  const _MyComplaintsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitTab extends StatefulWidget {
  final VoidCallback onSubmitted;
  const _SubmitTab({required this.onSubmitted});

  @override
  State<_SubmitTab> createState() => _SubmitTabState();
}

class _SubmitTabState extends State<_SubmitTab> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final List<PickedAttachment> _files = [];
  final List<NoticeLink> _links = [];

  String _category = 'Academic Issue';
  String _priority = 'Normal';
  bool _submitting = false;

  final List<String> _categories = const [
    'Academic Issue',
    'Transport Complaint',
    'Fee / Finance',
    'Harassment',
    'Facility Issue',
    'General Inquiry',
  ];

  final List<String> _priorities = const ['Normal', 'High', 'Urgent'];

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await SupabaseService.submitComplaint(
        category: _category,
        subject: _subjectController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        files: _files,
        links: _links,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully!'), backgroundColor: Color(0xFF2ECC71)),
      );

      _subjectController.clear();
      _descController.clear();
      setState(() {
        _category = 'Academic Issue';
        _priority = 'Normal';
        _files.clear();
        _links.clear();
      });

      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'Urgent':
        return Colors.redAccent;
      case 'High':
        return Colors.orange;
      default:
        return const Color(0xFF2ECC71);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E8449).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E8449).withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1E8449), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add your complaint',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Category', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Select Category',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _category = v!),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Priority', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            Row(
              children: _priorities.map((p) {
                final selected = _priority == p;
                final color = _priorityColor(p);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      margin: EdgeInsets.only(right: p != _priorities.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color, width: selected ? 0 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p[0].toUpperCase() + p.substring(1),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : color),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Subject', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            InputField(
              controller: _subjectController,
              keyboardType: TextInputType.text,
              label: 'Brief subject',
              hint: 'e.g. Result not updated on portal',
              icon: Icons.subject,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Subject is required';
                if (v.trim().length < 5) return 'Too short';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Description', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            InputField(
              controller: _descController,
              keyboardType: TextInputType.multiline,
              label: 'Describe your issue',
              hint: 'Provide details',
              icon: Icons.description_outlined,
              maxLines: 5,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Description is required';
                if (v.trim().length < 20) return 'Please provide more detail (min 20 characters)';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AttachmentPickerPanel(
              title: 'Complaint proof: images, files and links',
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _submitting
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send),
                      label: Text('Submit Complaint', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _MyComplaintsTab extends StatefulWidget {
  const _MyComplaintsTab();

  @override
  State<_MyComplaintsTab> createState() => _MyComplaintsTabState();
}

class _MyComplaintsTabState extends State<_MyComplaintsTab> {
  List<ComplaintModel> _complaints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getMyComplaints();
    if (mounted) {
      setState(() {
        _complaints = data;
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF2ECC71);
      case 'in_review':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_review':
        return 'In Review';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Pending';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.check_circle_outline;
      case 'in_review':
        return Icons.hourglass_top;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));

    if (_complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No complaints yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text('Submit a complaint to raise an issue.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2ECC71),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _complaints.length,
        itemBuilder: (context, i) {
          final c = _complaints[i];
          final color = _statusColor(c.status);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailPage(complaint: c)));
                await _load();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_statusIcon(c.status), color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(c.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF2C3E50))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(_statusLabel(c.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category_outlined, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(c.category, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        if (c.attachments.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.attach_file, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text('${c.attachments.length}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                        const Spacer(),
                        Text(DateFormat('dd MMM, hh:mm a').format(c.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
