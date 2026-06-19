import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint_model.dart';
import '../services/supabase_service.dart';

class ComplaintDetailPage extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final _replyController = TextEditingController();
  List<ComplaintReply> _replies = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() => _loading = true);
    final replies = await SupabaseService.getComplaintReplies(widget.complaint.id);
    if (mounted) {
      setState(() {
        _replies = replies;
        _loading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      await SupabaseService.postComplaintReply(
        complaintId: widget.complaint.id,
        message: text,
      );
      _replyController.clear();
      await _loadReplies();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reply. Try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: AppBar(
        title: Text('Complaint Detail', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E8449),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(widget.complaint.status)
                                    .withOpacity( 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor(widget.complaint.status),
                                ),
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
                        Row(
                          children: [
                            _Chip(
                              label: widget.complaint.category,
                              color: const Color(0xFF1E8449),
                            ),
                            const SizedBox(width: 6),
                            _Chip(
                              label: widget.complaint.priority.toUpperCase(),
                              color: _priorityColor(widget.complaint.priority),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.complaint.description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Submitted ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.complaint.createdAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
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
          if (widget.complaint.status != 'resolved')
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: const Color(0xFFECF0F1),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                          ),
                        ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF2ECC71).withOpacity( 0.1),
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: reply.senderRole == 'admin'
                        ? const Color(0xFF1E8449)
                        : Colors.blueGrey,
                    child: Text(
                      reply.senderName.isNotEmpty
                          ? reply.senderName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  isMe
                      ? 'You'
                      : '${reply.senderName} (${reply.senderRole == 'admin' ? 'Proctor' : reply.senderRole})',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF2ECC71)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity( 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                reply.message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isMe ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('hh:mm a, dd MMM').format(reply.createdAt),
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
        color: color.withOpacity( 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity( 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}