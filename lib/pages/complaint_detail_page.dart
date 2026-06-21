import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/app_attachment.dart';
import '../models/complaint_model.dart';
import '../services/supabase_service.dart';
import '../widgets/attachment_picker_panel.dart';
import '../widgets/attachment_viewer.dart';

class ComplaintDetailPage extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final _replyController = TextEditingController();
  final List<PickedAttachment> _replyFiles = [];
  final List<NoticeLink> _replyLinks = [];

  List<ComplaintReply> _replies = [];
  List<AppAttachment> _complaintAttachments = [];
  bool _loading = true;
  bool _sending = false;
  bool _showAttachPanel = false;

  @override
  void initState() {
    super.initState();
    _complaintAttachments = widget.complaint.attachments;
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final replies = await SupabaseService.getComplaintReplies(widget.complaint.id);
    final attachments = await SupabaseService.getComplaintAttachments(widget.complaint.id);
    if (mounted) {
      setState(() {
        _replies = replies;
        _complaintAttachments = attachments.where((a) => a.replyId == null).toList();
        _loading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty && _replyFiles.isEmpty && _replyLinks.isEmpty) return;

    setState(() => _sending = true);
    try {
      await SupabaseService.postComplaintReply(
        complaintId: widget.complaint.id,
        message: text.isEmpty ? 'Attached file/link' : text,
        files: _replyFiles,
        links: _replyLinks,
      );
      _replyController.clear();
      setState(() {
        _replyFiles.clear();
        _replyLinks.clear();
        _showAttachPanel = false;
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reply failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.redAccent;
      case 'high':
        return Colors.orange;
      default:
        return const Color(0xFF2ECC71);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        title: Text('Complaint Details', style: GoogleFonts.inter()),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF2ECC71),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.complaint.subject,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(widget.complaint.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _statusColor(widget.complaint.status)),
                                ),
                                child: Text(
                                  _statusLabel(widget.complaint.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(widget.complaint.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _Chip(label: widget.complaint.category, color: const Color(0xFF1E8449)),
                              _Chip(label: widget.complaint.priority.toUpperCase(), color: _priorityColor(widget.complaint.priority)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinkifiedText(
                            text: widget.complaint.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          AttachmentViewer(
                            attachments: _complaintAttachments,
                            title: 'Complaint proof',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Submitted ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.complaint.createdAt.toLocal())}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Conversation',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_replies.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No replies yet.\nThe proctor will respond soon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], height: 1.5),
                        ),
                      ),
                    )
                  else
                    ..._replies.map((reply) {
                      final isMe = reply.senderId == currentUserId;
                      return _ReplyBubble(reply: reply, isMe: isMe);
                    }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (widget.complaint.status != 'resolved')
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showAttachPanel)
                      AttachmentPickerPanel(
                        title: 'Reply attachments and links',
                        files: _replyFiles,
                        links: _replyLinks,
                        onFilesChanged: (v) => setState(() {
                          _replyFiles
                            ..clear()
                            ..addAll(v);
                        }),
                        onLinksChanged: (v) => setState(() {
                          _replyLinks
                            ..clear()
                            ..addAll(v);
                        }),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showAttachPanel ? Icons.close : Icons.attach_file,
                            color: const Color(0xFF1E8449),
                          ),
                          onPressed: () => setState(() => _showAttachPanel = !_showAttachPanel),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Type message or attach file/link...',
                              filled: true,
                              fillColor: const Color(0xFFECF0F1),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _sending
                            ? const SizedBox(
                                width: 42,
                                height: 42,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2ECC71),
                                ),
                              )
                            : GestureDetector(
                                onTap: _sendReply,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2ECC71),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
              child: const Text(
                '✅ This complaint has been resolved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E8449),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final ComplaintReply reply;
  final bool isMe;

  const _ReplyBubble({required this.reply, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: reply.senderRole == 'admin' ? const Color(0xFF1E8449) : Colors.blueGrey,
                    child: Text(
                      reply.senderName.isNotEmpty ? reply.senderName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    isMe ? 'You' : '${reply.senderName} (${reply.senderRole == 'admin' ? 'Proctor' : reply.senderRole})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2ECC71) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LinkifiedText(
                text: reply.message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isMe ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ),
            if (reply.attachments.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: AttachmentViewer(attachments: reply.attachments, compact: true),
              ),
            const SizedBox(height: 3),
            Text(
              DateFormat('hh:mm a, dd MMM').format(reply.createdAt.toLocal()),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
