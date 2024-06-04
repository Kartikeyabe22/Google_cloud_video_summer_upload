import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:mime/mime.dart';

class CloudApi {
  final auth.ServiceAccountCredentials _credentials;
  auth.AutoRefreshingAuthClient? _client;

  CloudApi(String json)
      : _credentials = auth.ServiceAccountCredentials.fromJson(json);

  Future<void> _initializeClient() async {
    if (_client == null) {
      _client = await auth.clientViaServiceAccount(_credentials, [
        'https://www.googleapis.com/auth/devstorage.full_control'
      ]);
    }
  }

  Future<String> _initiateResumableUpload(String name) async {
    await _initializeClient();
    final uri = Uri.parse('https://www.googleapis.com/upload/storage/v1/b/mybucket_12345/o?uploadType=resumable&name=$name');
    final response = await _client!.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Type': lookupMimeType(name) ?? 'application/octet-stream',
      },
      body: '{"name": "$name"}',
    );

    if (response.statusCode == 200) {
      return response.headers['location']!;
    } else {
      throw Exception('Failed to initiate resumable upload: ${response.body}');
    }
  }

  Future<void> _uploadChunks(String sessionUri, Uint8List fileBytes) async {
    int start = 0;
    int chunkSize = 256 * 1024; // 256 KB
    int end = chunkSize;
    final totalSize = fileBytes.length;

    while (start < totalSize) {
      if (end > totalSize) end = totalSize;

      final chunk = fileBytes.sublist(start, end);
      final request = http.Request('PUT', Uri.parse(sessionUri))
        ..headers.addAll({
          'Content-Length': chunk.length.toString(),
          'Content-Range': 'bytes $start-${end - 1}/$totalSize',
        })
        ..bodyBytes = chunk;

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        break;
      } else if (response.statusCode == 308) {
        start = end;
        end += chunkSize;
      } else {
        throw Exception('Failed to upload chunk: ${await response.stream.bytesToString()}');
      }
    }
  }

  Future<void> save(String name, Uint8List fileBytes) async {
    try {
      final sessionUri = await _initiateResumableUpload(name);
      await _uploadChunks(sessionUri, fileBytes);
      print('Video uploaded successfully.');
    } catch (e) {
      print('Error in save method: $e');
      rethrow; // Rethrow the exception for higher-level handling
    }
  }
}
