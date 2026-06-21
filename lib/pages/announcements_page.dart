import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement_model.dart';
import '../services/supabase_service.dart';
import '../widgets/attachment_viewer.dart';
import 'create_announcement_page.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<Announcement> _all = [];
  List<Announcement> _filtered = [];
  bool _loading = true;
  bool _isAdmin = false;
  String _search = '';
  String _role = 'All';
  String _department = 'All';
  String _program = 'All';
  RealtimeChannel? _announcementChannel;

  @override
  void initState() {
    super.initState();
    _loadProfileAndAnnouncements();
    _announcementChannel = SupabaseService.announcementStream(_load);
  }

  @override
  void dispose() {
    final channel = _announcementChannel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  Future<void> _loadProfileAndAnnouncements() async {
    final profile = await SupabaseService.getProfileMap();
    if (profile != null) {
      _role = (profile['role'] ?? 'student').toString();
      _department = (profile['department'] ?? '').toString().isEmpty ? 'All' : profile['department'].toString();
      _program = (profile['program'] ?? '').toString().isEmpty ? 'All' : profile['program'].toString();
      _isAdmin = _role == 'admin';
    }
    await _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final data = await SupabaseService.getAnnouncements(
      role: _role,
      department: _department,
      program: _program,
    );
    if (mounted) {
      setState(() {
        _all = data;
        _loading = false;
      });
      _applySearch(_search, refreshOnly: true);
    }
  }

  void _applySearch(String query, {bool refreshOnly = false}) {
    setState(() {
      if (!refreshOnly) _search = query;
      final active = refreshOnly ? _search : query;
      if (active.trim().isEmpty) {
        _filtered = _all;
      } else {
        final q = active.toLowerCase();
        _filtered = _all
            .where((a) =>
                a.title.toLowerCase().contains(q) ||
                a.body.toLowerCase().contains(q) ||
                a.targetDepartment.toLowerCase().contains(q) ||
                a.attachments.any((x) => x.fileName.toLowerCase().contains(q) || x.fileUrl.toLowerCase().contains(q)))
            .toList();
      }
    });
  }

  Future<void> _createAnnouncement() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementPage()));
    if (result == true) await _load();
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'emergency':
        return Colors.redAccent;
      case 'high':
        return Colors.orange;
      default:
        return const Color(0xFF2E7D32);
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.priority_high;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _createAnnouncement,
              backgroundColor: const Color(0xFF1E8449),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Notice'),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              onChanged: _applySearch,
              decoration: InputDecoration(
                hintText: 'Search announcements, files or links…',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2ECC71)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _search.isNotEmpty ? 'No results for "$_search"' : 'No announcements yet',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF2ECC71),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _AnnouncementCard(
                            announcement: _filtered[i],
                            priorityColor: _priorityColor(_filtered[i].priority),
                            priorityIcon: _priorityIcon(_filtered[i].priority),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final Color priorityColor;
  final IconData priorityIcon;

  const _AnnouncementCard({
    required this.announcement,
    required this.priorityColor,
    required this.priorityIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: priorityColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: priorityColor,
                  child: Icon(priorityIcon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(announcement.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(announcement.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinkifiedText(text: announcement.body),
            AttachmentViewer(attachments: announcement.attachments, title: 'Notice files and links'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(label: announcement.targetDepartment == 'all' ? 'All Departments' : announcement.targetDepartment, color: priorityColor),
                _Chip(label: announcement.targetProgram == 'all' ? 'All Programs' : announcement.targetProgram, color: priorityColor),
                _Chip(label: announcement.priority.toUpperCase(), color: priorityColor),
                if (announcement.imageCount > 0) _Chip(label: '${announcement.imageCount} photo(s)', color: Colors.blueGrey),
                if (announcement.fileCount > 0) _Chip(label: '${announcement.fileCount} file(s)', color: Colors.blueGrey),
                if (announcement.linkCount > 0) _Chip(label: '${announcement.linkCount} link(s)', color: Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
