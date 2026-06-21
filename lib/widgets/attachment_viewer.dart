import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_attachment.dart';

class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool showDetectedLinks;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.showDetectedLinks = true,
  });

  static final RegExp _urlRegex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);

  static List<String> extractLinks(String input) {
    return _urlRegex
        .allMatches(input)
        .map((m) => m.group(0) ?? '')
        .map((u) => u.replaceAll(RegExp(r'[),.;।]+$'), ''))
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final links = extractLinks(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(text, style: style ?? const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF2C3E50))),
        if (showDetectedLinks && links.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: links
                .map((u) => ActionChip(
                      avatar: const Icon(Icons.open_in_new, size: 16),
                      label: Text(_shortUrl(u), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () => AttachmentActions.openUrl(context, u),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  static String _shortUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host.contains('docs.google.com')) return 'Google Docs / Sheet';
    return uri.host.isEmpty ? url : uri.host;
  }
}

class AttachmentViewer extends StatelessWidget {
  final List<AppAttachment> attachments;
  final String title;
  final bool compact;

  const AttachmentViewer({
    super.key,
    required this.attachments,
    this.title = 'Attachments',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where((a) => a.isImage).toList();
    final linksAndFiles = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF123D35))),
          const SizedBox(height: 8),
        ],
        if (images.isNotEmpty)
          SizedBox(
            height: compact ? 72 : 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final a = images[index];
                return GestureDetector(
                  onTap: () => _showImage(context, a),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: compact ? 72 : 150,
                      color: Colors.grey[200],
                      child: Image.network(
                        a.fileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (linksAndFiles.isNotEmpty) ...[
          if (images.isNotEmpty) const SizedBox(height: 10),
          ...linksAndFiles.map((a) => _AttachmentTile(attachment: a)),
        ],
      ],
    );
  }

  void _showImage(BuildContext context, AppAttachment a) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(a.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.copy), onPressed: () => AttachmentActions.copyUrl(context, a.fileUrl)),
                IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => AttachmentActions.openUrl(context, a.fileUrl)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(a.fileUrl, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final AppAttachment attachment;

  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final color = attachment.isLink ? const Color(0xFF2E86DE) : const Color(0xFF1E8449);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.22)),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha:0.12),
          child: Icon(_icon(), color: color, size: 20),
        ),
        title: Text(attachment.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(attachment.isLink ? attachment.fileUrl : '${_formatSize(attachment.fileSize)} • ${attachment.mimeType}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'open') AttachmentActions.openUrl(context, attachment.fileUrl);
            if (v == 'copy') AttachmentActions.copyUrl(context, attachment.fileUrl);
            if (v == 'download') AttachmentActions.openUrl(context, attachment.fileUrl);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'copy', child: Text('Copy link')),
            PopupMenuItem(value: 'download', child: Text('Download / View')),
          ],
        ),
        onTap: () => AttachmentActions.openUrl(context, attachment.fileUrl),
      ),
    );
  }

  IconData _icon() {
    if (attachment.isLink) return Icons.link;
    final n = attachment.fileName.toLowerCase();
    if (n.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (n.endsWith('.doc') || n.endsWith('.docx')) return Icons.description_outlined;
    if (n.endsWith('.xls') || n.endsWith('.xlsx')) return Icons.table_chart_outlined;
    if (n.endsWith('.ppt') || n.endsWith('.pptx')) return Icons.slideshow_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'file';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class AttachmentActions {
  static Future<void> openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _snack(context, 'Invalid link');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _snack(context, 'Could not open link');
  }

  static Future<void> copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) _snack(context, 'Link copied');
  }

  static void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
