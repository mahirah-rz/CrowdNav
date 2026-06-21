import 'dart:typed_data';

class PickedAttachment {
  final String name;
  final Uint8List bytes;
  final int size;

  const PickedAttachment({
    required this.name,
    required this.bytes,
    required this.size,
  });
}

class NoticeLink {
  final String title;
  final String url;

  const NoticeLink({required this.title, required this.url});
}

class AppAttachment {
  final String id;
  final String ownerId;
  final String? replyId;
  final String kind; 
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int fileSize;
  final String storagePath;
  final DateTime createdAt;

  const AppAttachment({
    required this.id,
    required this.ownerId,
    this.replyId,
    required this.kind,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSize,
    required this.storagePath,
    required this.createdAt,
  });

  bool get isImage => kind == 'image' || mimeType.startsWith('image/');
  bool get isLink => kind == 'link';
  bool get isFile => kind == 'file';

  factory AppAttachment.fromMap(Map<String, dynamic> map) {
    return AppAttachment(
      id: (map['id'] ?? '').toString(),
      ownerId: (map['announcement_id'] ?? map['complaint_id'] ?? '').toString(),
      replyId: map['reply_id']?.toString(),
      kind: (map['kind'] ?? 'file').toString(),
      fileName: (map['file_name'] ?? 'Attachment').toString(),
      fileUrl: (map['file_url'] ?? '').toString(),
      mimeType: (map['mime_type'] ?? '').toString(),
      fileSize: map['file_size'] is int ? map['file_size'] as int : int.tryParse('${map['file_size'] ?? 0}') ?? 0,
      storagePath: (map['storage_path'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
