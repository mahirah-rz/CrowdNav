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
  final TextEditingController _searchController = TextEditingController();
  List<Announcement> _announcements = [];
  bool _loading = true;
  bool _isAdmin = false;
  String _role = 'All';
  String _department = 'All';
  String _program = 'All';
  RealtimeChannel? _announcementChannel;

  @override
  void initState() {
    super.initState();
    _loadProfileAndAnnouncements();
    _announcementChannel = SupabaseService.announcementStream(() => _loadAnnouncements());
  }

  @override
  void dispose() {
    final channel = _announcementChannel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndAnnouncements() async {
    final profile = await SupabaseService.getProfile();
    _isAdmin = await SupabaseService.isCurrentUserAdmin();
    _role = profile?.role ?? 'All';
    _department = profile?.department ?? 'All';
    _program = profile?.program ?? 'All';
    await _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _loading = true);
    final items = await SupabaseService.getAnnouncements(
      role: _role,
      department: _department,
      program: _program,
    );
    if (!mounted) return;
    setState(() {
      _announcements = items;
      _loading = false;
    });
  }

  Future<void> _openCreatePage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateAnnouncementPage()),
    );
    if (result == true) _loadAnnouncements();
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

  List<Announcement> get _filteredAnnouncements {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _announcements;
    return _announcements.where((item) {
      final fileMatch = item.attachments.any((attachment) =>
          attachment.fileName.toLowerCase().contains(query) ||
          attachment.fileUrl.toLowerCase().contains(query));
      return item.title.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query) ||
          fileMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAnnouncements;
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E8E4E),
        foregroundColor: Colors.white,
        title: Text(
          'Announcements',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnnouncements,
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'create-notice',
              backgroundColor: const Color(0xFF1E8E4E),
              foregroundColor: Colors.white,
              onPressed: _openCreatePage,
              icon: const Icon(Icons.add),
              label: const Text('Notice'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search announcements, files or links...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF31C96F)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF31C96F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF31C96F)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _EmptyState(isAdmin: _isAdmin, onCreate: _openCreatePage)
                      : RefreshIndicator(
                          onRefresh: _loadAnnouncements,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final announcement = filtered[index];
                              return _AnnouncementCard(
                                announcement: announcement,
                                canDelete: _isAdmin,
                                onDelete: () => _deleteAnnouncement(announcement),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.canDelete,
    required this.onDelete,
  });

  final Announcement announcement;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priority = announcement.priority.toLowerCase();
    final priorityColor = switch (priority) {
      'emergency' => Colors.redAccent,
      'high' => Colors.orange,
      _ => const Color(0xFF1E8E4E),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withValues(alpha: 0.65), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: priorityColor,
                foregroundColor: Colors.white,
                child: const Icon(Icons.notifications_none),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(announcement.createdAt.toLocal()),
                      style: GoogleFonts.poppins(
                        color: Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  tooltip: 'Delete notice',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinkifiedText(
            text: announcement.body,
            style: GoogleFonts.poppins(
              color: const Color(0xFF425466),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (announcement.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            AttachmentViewer(attachments: announcement.attachments),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: announcement.targetDepartment.toLowerCase() == 'All' ? 'All Departments' : announcement.targetDepartment),
              _Chip(label: announcement.targetProgram.toLowerCase() == 'All' ? 'All Programs' : announcement.targetProgram),
              _Chip(label: priority.toUpperCase()),
              if (announcement.imageCount > 0) _Chip(label: '${announcement.imageCount} image'),
              if (announcement.fileCount > 0) _Chip(label: '${announcement.fileCount} file'),
              if (announcement.linkCount > 0) _Chip(label: '${announcement.linkCount} link'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: const Color(0xFF1E8E4E),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAdmin, required this.onCreate});

  final bool isAdmin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_outlined, size: 56, color: Color(0xFF1E8E4E)),
            const SizedBox(height: 12),
            Text(
              'No notices found',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              isAdmin ? 'Create the first notice for users.' : 'Please check again later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create Notice'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
