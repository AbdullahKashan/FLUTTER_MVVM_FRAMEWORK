import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

/// Represents a file to be transmitted as part of a multipart form-data request.
class MultipartFile {
  /// The form field name for this file.
  final String field;

  /// The raw binary content of the file.
  final Uint8List bytes;

  /// The original filename.
  final String filename;

  /// The MIME media type of the file.
  final MediaType? contentType;

  const MultipartFile({
    required this.field,
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  /// Factory constructor for creating a [MultipartFile] from byte data.
  factory MultipartFile.fromBytes(
    String field,
    List<int> bytes, {
    required String filename,
    MediaType? contentType,
  }) {
    return MultipartFile(
      field: field,
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      contentType: contentType,
    );
  }
}
