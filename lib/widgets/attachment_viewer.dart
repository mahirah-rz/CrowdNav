import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_attachment.dart';

class AttachmentViewer extends StatelessWidget {
  const AttachmentViewer({
    super.key,
    required this.attachments,
    this.title,
    this.compact = false,
  });

  final List<AppAttachment> attachments;
  final String? title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where((a) => a.isImage).toList();
    final others = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.trim().isNotEmpty) ...[
          _SectionTitle(text: title!, compact: compact),
          SizedBox(height: compact ? 6 : 8),
        ],
        if (images.isNotEmpty) ...[
          if (title == null && !compact) ...[
            const _SectionTitle(text: 'Images / screenshots'),
            const SizedBox(height: 8),
          ],
          ...images.map((image) => _ImagePreviewTile(attachment: image, compact: compact)),
        ],
        if (others.isNotEmpty) ...[
          if (images.isNotEmpty) SizedBox(height: compact ? 6 : 10),
          if (title == null && !compact) ...[
            const _SectionTitle(text: 'Links and documents'),
            const SizedBox(height: 8),
          ],
          ...others.map((item) => _AttachmentActionTile(attachment: item, compact: compact)),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF123D35),
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  const _ImagePreviewTile({required this.attachment, required this.compact});

  final AppAttachment attachment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(compact ? 10 : 14);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => _showImagePreview(context, attachment),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  attachment.fileUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFFE8F5EA),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE8F5EA),
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined, size: compact ? 30 : 42),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 12,
                    vertical: compact ? 6 : 8,
                  ),
                  color: Colors.black.withValues(alpha: 0.58),
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined, color: Colors.white, size: compact ? 15 : 18),
                      SizedBox(width: compact ? 6 : 8),
                      Expanded(
                        child: Text(
                          attachment.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: compact ? 11 : 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.zoom_out_map, color: Colors.white, size: compact ? 15 : 18),
                    ],
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

class _AttachmentActionTile extends StatelessWidget {
  const _AttachmentActionTile({required this.attachment, required this.compact});

  final AppAttachment attachment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLink = attachment.isLink;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(color: const Color(0xFFDCEFE3)),
      ),
      child: ListTile(
        dense: compact,
        minLeadingWidth: compact ? 28 : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 0 : 4,
        ),
        leading: CircleAvatar(
          radius: compact ? 15 : 20,
          backgroundColor: isLink ? const Color(0xFFEAF3FF) : const Color(0xFFE8F5EA),
          foregroundColor: isLink ? const Color(0xFF2E73B8) : const Color(0xFF1E8E4E),
          child: Icon(isLink ? Icons.link : _fileIcon(attachment.fileName), size: compact ? 16 : 22),
        ),
        title: Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          isLink ? _cleanUrlHost(attachment.fileUrl) : _formatSize(attachment.fileSize),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: compact ? 10 : 12),
        ),
        trailing: SizedBox(
          width: compact ? 72 : 88,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isLink ? 'Open link' : 'View / download file',
                icon: Icon(isLink ? Icons.open_in_new : Icons.download_outlined, size: compact ? 18 : 22),
                color: const Color(0xFF1E8E4E),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: compact ? 34 : 40, height: compact ? 34 : 40),
                onPressed: () => _openUrl(context, attachment.fileUrl),
              ),
              IconButton(
                tooltip: 'Copy link',
                icon: Icon(Icons.copy, size: compact ? 17 : 20),
                color: const Color(0xFF425466),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: compact ? 34 : 40, height: compact ? 34 : 40),
                onPressed: () => _copyUrl(context, attachment.fileUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LinkifiedText extends StatelessWidget {
  const LinkifiedText({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  static final RegExp _urlRegex = RegExp(
    r'((https?:\/\/)?([\w-]+\.)+[\w-]{2,}(:\d+)?(\/[^\s]*)?)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    int index = 0;

    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }

      final rawUrl = match.group(0) ?? '';
      final url = rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
          ? rawUrl
          : 'https://$rawUrl';

      spans.add(
        TextSpan(
          text: rawUrl,
          style: const TextStyle(
            color: Color(0xFF1669C1),
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w800,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(context, url),
        ),
      );
      index = match.end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }

    return SelectableText.rich(
      TextSpan(style: style, children: spans),
      textAlign: TextAlign.start,
    );
  }
}

Future<void> _showImagePreview(BuildContext context, AppAttachment attachment) async {
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open',
                    onPressed: () => _openUrl(context, attachment.fileUrl),
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: 'Copy link',
                    onPressed: () => _copyUrl(context, attachment.fileUrl),
                    icon: const Icon(Icons.copy, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    attachment.fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openUrl(BuildContext context, String rawUrl) async {
  final url = rawUrl.trim();
  final uri = Uri.tryParse(url.startsWith('http://') || url.startsWith('https://') ? url : 'https://$url');
  if (uri == null) {
    _message(context, 'Invalid link.');
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {
    if (context.mounted) _message(context, 'Could not open this link/file.');
  }
}

Future<void> _copyUrl(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) _message(context, 'Link copied.');
}

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

String _formatSize(int bytes) {
  if (bytes <= 0) return 'File';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _cleanUrlHost(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || uri.host.isEmpty) return rawUrl;
  return uri.host.replaceFirst('www.', '');
}

IconData _fileIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
  if (lower.endsWith('.doc') || lower.endsWith('.docx')) return Icons.description_outlined;
  if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return Icons.table_chart_outlined;
  if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return Icons.slideshow_outlined;
  if (lower.endsWith('.txt')) return Icons.article_outlined;
  return Icons.insert_drive_file_outlined;
}
