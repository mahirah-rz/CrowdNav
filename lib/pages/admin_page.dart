import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../models/app_attachment.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../auth/login_page.dart';
import '../widgets/input_field.dart';
import '../widgets/attachment_picker_panel.dart';
import '../widgets/attachment_viewer.dart';
import 'complaint_detail_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _admin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmin() async {
    final user = await SupabaseService.getProfile();
    if (mounted) setState(() => _admin = user);
  }

  Future<void> _confirmSignOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Do you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8449),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E8449),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_admin != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  _admin!.name.split(' ').first,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _confirmSignOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.campaign, size: 18), text: 'Announce'),
            Tab(icon: Icon(Icons.gavel, size: 18), text: 'Complaints'),
            Tab(icon: Icon(Icons.directions_bus, size: 18), text: 'Buses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AnnouncementsTab(),
          _ComplaintsTab(),
          _BusesTab(),
        ],
      ),
    );
  }
}


class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final List<PickedAttachment> _files = [];
  final List<NoticeLink> _links = [];

  String _targetDept = 'All';
  String _targetProgram = 'All';
  String _priority = 'Normal';
  bool _posting = false;

  List<Announcement> _announcements = [];
  bool _loadingList = true;

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
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _loadingList = true);
    final data = await SupabaseService.getAnnouncements();
    if (!mounted) return;
    setState(() {
      _announcements = data;
      _loadingList = false;
    });
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _posting = true);

    try {
      await SupabaseService.postAnnouncement(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        targetRole: 'All',
        targetDepartment: _targetDept,
        targetProgram: _targetProgram,
        priority: _priority,
        files: _files,
        links: _links,
      );

      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _targetDept = 'All';
        _targetProgram = 'All';
        _priority = 'Normal';
        _files.clear();
        _links.clear();
      });

      await _loadAnnouncements();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement posted!'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notice?'),
        content: Text('This will permanently remove "${announcement.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await SupabaseService.deleteAnnouncement(announcement.id);
      if (!mounted) return;
      setState(() {
        _announcements.removeWhere((item) => item.id == announcement.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'Emergency':
        return Colors.redAccent;
      case 'High':
        return Colors.orange;
      default:
        return const Color(0xFF2ECC71);
    }
  }

  String _label(String value) {
    if (value == 'all') return 'All';
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(
                e == 'All' ? 'All' : e,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Post New Announcement',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  InputField(
                    controller: _titleController,
                    keyboardType: TextInputType.text,
                    label: 'Title',
                    hint: 'e.g. 9-5PM CSE Routine Fall_26',
                    icon: Icons.title,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  InputField(
                    controller: _bodyController,
                    keyboardType: TextInputType.multiline,
                    label: 'Message',
                    hint: 'Write the announcement here...',
                    icon: Icons.message_outlined,
                    maxLines: 6,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Message is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final vertical = constraints.maxWidth < 620;
                      final department = _dropdown(
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

                      if (vertical) {
                        return Column(
                          children: [
                            department,
                            const SizedBox(height: 10),
                            program,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: department),
                          const SizedBox(width: 10),
                          Expanded(child: program),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final vertical = constraints.maxWidth < 520;
                      final buttons = _priorities.map((p) {
                        final selected = _priority == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _priority = p),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: vertical ? 0 : (p != _priorities.last ? 8 : 0),
                                bottom: vertical ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: selected ? _priorityColor(p) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _priorityColor(p)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _label(p),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : _priorityColor(p),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList();

                      if (vertical) {
                        return Column(
                          children: buttons.map((button) => SizedBox(width: double.infinity, child: button)).toList(),
                        );
                      }

                      return Row(children: buttons);
                    },
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: _posting
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                          )
                        : ElevatedButton.icon(
                            onPressed: _post,
                            icon: const Icon(Icons.send, size: 18),
                            label: Text(
                              'Post Announcement',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Posted Announcements',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF2ECC71), size: 20),
              onPressed: _loadAnnouncements,
            ),
          ],
        ),
        if (_loadingList)
          const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
        else if (_announcements.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No announcements yet.', style: TextStyle(color: Colors.grey[500])),
            ),
          )
        else
          ..._announcements.map((a) => _AdminAnnouncementCard(
                announcement: a,
                color: _priorityColor(a.priority),
                onDelete: () => _deleteAnnouncement(a),
              )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AdminAnnouncementCard extends StatelessWidget {
  const _AdminAnnouncementCard({
    required this.announcement,
    required this.color,
    required this.onDelete,
  });

  final Announcement announcement;
  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priority = announcement.priority.toLowerCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  radius: 18,
                  child: Icon(
                    priority == 'Emergency'
                        ? Icons.warning_amber_rounded
                        : priority == 'High'
                            ? Icons.priority_high
                            : Icons.notifications_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${announcement.targetDepartment == 'All' ? 'All Depts' : announcement.targetDepartment} · ${DateFormat('dd MMM, hh:mm a').format(announcement.createdAt.toLocal())}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete notice',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinkifiedText(
              text: announcement.body,
              style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF425466)),
            ),
            if (announcement.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              AttachmentViewer(attachments: announcement.attachments),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniChip(label: priority.toUpperCase(), color: color),
                _MiniChip(label: announcement.targetProgram == 'All' ? 'All Programs' : announcement.targetProgram, color: const Color(0xFF1E8449)),
                if (announcement.imageCount > 0) _MiniChip(label: '${announcement.imageCount} image', color: const Color(0xFF1E8449)),
                if (announcement.fileCount > 0) _MiniChip(label: '${announcement.fileCount} file', color: const Color(0xFF1E8449)),
                if (announcement.linkCount > 0) _MiniChip(label: '${announcement.linkCount} link', color: const Color(0xFF1E8449)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ComplaintsTab extends StatefulWidget {
  const _ComplaintsTab();

  @override
  State<_ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<_ComplaintsTab> {
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getAllComplaints();
    if (mounted) {
      setState(() {
      _complaints = data;
      _loading = false;
    });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await SupabaseService.updateComplaintStatus(
        complaintId: id, status: status);
    await _load();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'resolved': return const Color(0xFF2ECC71);
      case 'in_review': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'in_review': return 'In Review';
      case 'resolved': return 'Resolved';
      default: return 'Pending';
    }
  }

  List<ComplaintModel> get _filtered {
    if (_filterStatus == 'all') return _complaints;
    return _complaints.where((c) => c.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('Filter:',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey[600])),
              const SizedBox(width: 8),
              ...['all', 'pending', 'in_review', 'resolved'].map((s) {
                final selected = _filterStatus == s;
                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1E8449)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s == 'All'
                          ? 'All'
                          : s == 'in_review'
                              ? 'In Review'
                              : s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: Color(0xFF2ECC71), size: 20),
                onPressed: _load,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (_filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No complaints found.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final c = _filtered[i];
                final statusColor = _statusColor(c.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ComplaintDetailPage(complaint: c),
                        ),
                      );
                      _load();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(c.subject,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: const Color(0xFF2C3E50))),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: statusColor),
                                ),
                                child: Text(
                                  _statusLabel(c.status),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${c.userName} · ${c.userDepartment} · ${c.category}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1E8449)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy')
                                    .format(c.createdAt),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              const Spacer(),
                              if (c.status != 'resolved') ...[
                                if (c.status == 'pending')
                                  _ActionChip(
                                    label: 'Mark In Review',
                                    color: Colors.blue,
                                    onTap: () => _updateStatus(
                                        c.id, 'in_review'),
                                  ),
                                const SizedBox(width: 6),
                                _ActionChip(
                                  label: 'Resolve',
                                  color: const Color(0xFF2ECC71),
                                  onTap: () =>
                                      _updateStatus(c.id, 'resolved'),
                                ),
                              ] else
                                const Text('✅ Resolved',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2ECC71),
                                        fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

class _BusesTab extends StatefulWidget {
  const _BusesTab();

  @override
  State<_BusesTab> createState() => _BusesTabState();
}

class _BusesTabState extends State<_BusesTab> {
  List<Map<String, dynamic>> _buses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getBusLocations();
    if (mounted) {
      setState(() {
      _buses = data;
      _loading = false;
    });
    }
  }

  String _lastSeen(String? updatedAt) {
    if (updatedAt == null) return 'Unknown';
    final dt = DateTime.tryParse(updatedAt);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  bool _isOnline(String? updatedAt) {
    if (updatedAt == null) return false;
    final dt = DateTime.tryParse(updatedAt);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inSeconds < 30;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2ECC71),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('Live Bus Overview',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF2C3E50))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: Color(0xFF2ECC71), size: 20),
                onPressed: _load,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Buses broadcasting right now',
            style:
                TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          if (_buses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.directions_bus_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('No buses broadcasting',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      'Drivers need to open the app\nand start broadcasting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._buses.map((b) {
              final online = _isOnline(b['updated_at'] as String?);
              final routeName =
                  (b['route_name'] as String?)?.isNotEmpty == true
                      ? b['route_name'] as String
                      : 'Unknown Route';
              final driverName =
                  (b['driver_name'] as String?)?.isNotEmpty == true
                      ? b['driver_name'] as String
                      : 'Unknown Driver';
              final driverPhone =
                  (b['driver_phone'] as String?)?.isNotEmpty == true
                      ? b['driver_phone'] as String
                      : '';
              final lat = (b['latitude'] as num?)?.toDouble();
              final lng = (b['longitude'] as num?)?.toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: online
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: online
                              ? const Color(0xFF2ECC71)
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          color: online ? Colors.white : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driverName,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: const Color(0xFF2C3E50))),
                            const SizedBox(height: 2),
                            Text(routeName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E8449))),
                            if (driverPhone.isNotEmpty)
                              Text(
                                driverPhone,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF123D35)),
                              ),
                            if (lat != null && lng != null)
                              Text(
                                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: online
                                  ? const Color(0xFF2ECC71)
                                      .withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: online
                                    ? const Color(0xFF2ECC71)
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: online
                                        ? const Color(0xFF2ECC71)
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  online ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: online
                                        ? const Color(0xFF1E8449)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lastSeen(b['updated_at'] as String?),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}