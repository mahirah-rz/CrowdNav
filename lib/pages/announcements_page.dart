import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement_model.dart';
import '../services/supabase_service.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<Announcement> _all = [];
  List<Announcement> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _department = 'all';
  String _program = 'all';
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
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _loadProfileAndAnnouncements() async {
    final profile = await SupabaseService.getProfile();
    if (profile != null) {
      _department = profile.department.isEmpty ? 'all' : profile.department;
      _program = profile.program.isEmpty ? 'all' : profile.program;
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getAnnouncements(department: _department, program: _program);
    if (mounted) {
      setState(() {
        _all = data;
        _filtered = data;
        _loading = false;
      });
    }
  }

  void _applySearch(String query) {
    setState(() {
      _search = query;
      if (query.trim().isEmpty) {
        _filtered = _all;
      } else {
        final q = query.toLowerCase();
        _filtered = _all
            .where((a) =>
                a.title.toLowerCase().contains(q) ||
                a.body.toLowerCase().contains(q) ||
                a.targetDepartment.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'emergency': return Colors.redAccent;
      case 'high': return Colors.orange;
      default: return const Color(0xFF2E7D32);
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'emergency': return Icons.warning_amber_rounded;
      case 'high': return Icons.priority_high;
      default: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              onChanged: _applySearch,
              decoration: InputDecoration(
                hintText: 'Search announcements…',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2ECC71)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final a = _filtered[i];
                            final color = _priorityColor(a.priority);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: color, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: color,
                                      child: Icon(_priorityIcon(a.priority), color: Colors.white),
                                    ),
                                    title: Text(
                                      a.title,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(a.body, style: const TextStyle(fontSize: 13)),
                                    ),
                                    isThreeLine: true,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            a.targetDepartment == 'all' ? 'All Departments' : a.targetDepartment,
                                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            a.priority.toUpperCase(),
                                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat('dd MMM, hh:mm a').format(a.createdAt),
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}