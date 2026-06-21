import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_attachment.dart';

class AttachmentPickerPanel extends StatefulWidget {
  final List<PickedAttachment> files;
  final List<NoticeLink> links;
  final ValueChanged<List<PickedAttachment>> onFilesChanged;
  final ValueChanged<List<NoticeLink>> onLinksChanged;
  final String title;

  const AttachmentPickerPanel({
    super.key,
    required this.files,
    required this.links,
    required this.onFilesChanged,
    required this.onLinksChanged,
    this.title = 'Attachments and Links',
  });

  @override
  State<AttachmentPickerPanel> createState() => _AttachmentPickerPanelState();
}

class _AttachmentPickerPanelState extends State<AttachmentPickerPanel> {
  bool _picking = false;

  Future<void> _pickFiles() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
        ],
      );
      if (result == null) return;

      final selected = [...widget.files];
      for (final f in result.files) {
        final bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        final size = f.size > 0 ? f.size : bytes.length;
        if (size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${f.name} skipped. Maximum file size is 10 MB.')),
            );
          }
          continue;
        }
        selected.add(PickedAttachment(name: f.name, bytes: bytes, size: size));
      }
      widget.onFilesChanged(selected);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _addLink() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    final link = await showDialog<NoticeLink>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Link title',
                hintText: 'Updated Bisemester',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://docs.google.com/...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final rawUrl = urlController.text.trim();
              if (rawUrl.isEmpty) return;
              final url = rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
                  ? rawUrl
                  : 'https://$rawUrl';
              final title = titleController.text.trim().isEmpty ? url : titleController.text.trim();
              Navigator.pop(context, NoticeLink(title: title, url: url));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    titleController.dispose();
    urlController.dispose();

    if (link != null) {
      widget.onLinksChanged([...widget.links, link]);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return Icons.description_outlined;
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return Icons.table_chart_outlined;
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return Icons.slideshow_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Widget _actionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 360;

        final uploadButton = OutlinedButton.icon(
          onPressed: _picking ? null : _pickFiles,
          icon: _picking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Upload file/photo'),
          ),
        );

        final linkButton = OutlinedButton.icon(
          onPressed: _addLink,
          icon: const Icon(Icons.link),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Add link'),
          ),
        );

        if (useVerticalLayout) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: uploadButton),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: linkButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: uploadButton),
            const SizedBox(width: 10),
            Expanded(child: linkButton),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FBF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.green.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Color(0xFF1E8449), size: 19),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF123D35),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _actionButtons(),
            if (widget.files.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...widget.files.asMap().entries.map((entry) {
                final i = entry.key;
                final f = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_fileIcon(f.name), color: const Color(0xFF1E8449)),
                  title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_formatSize(f.size)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () {
                      final updated = [...widget.files]..removeAt(i);
                      widget.onFilesChanged(updated);
                    },
                  ),
                );
              }),
            ],
            if (widget.links.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...widget.links.asMap().entries.map((entry) {
                final i = entry.key;
                final link = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, color: Color(0xFF2E86DE)),
                  title: Text(link.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(link.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () {
                      final updated = [...widget.links]..removeAt(i);
                      widget.onLinksChanged(updated);
                    },
                  ),
                );
              }),
            ],
            const SizedBox(height: 4),
            const Text(
              'Supported: JPG, PNG, WEBP, PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, TXT. Max 10 MB each.',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
