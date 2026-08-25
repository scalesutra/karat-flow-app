import 'dart:typed_data';

sealed class SketchEvent {
  const SketchEvent();
}

final class FetchSketchesEvent extends SketchEvent {
  const FetchSketchesEvent({this.status = ''});
  final String status;
}

final class UploadRawSketchEvent extends SketchEvent {
  const UploadRawSketchEvent({
    required this.designNumber,
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  final String designNumber;
  final String title;
  final String fileName;
  final Uint8List bytes;
}

final class ReuploadRawSketchEvent extends SketchEvent {
  const ReuploadRawSketchEvent({
    required this.sketchId,
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  final String sketchId;
  final String title;
  final String fileName;
  final Uint8List bytes;
}
