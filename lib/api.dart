import 'dart:typed_data';
import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class CloudApi {
 final auth.ServiceAccountCredentials _credentials;
 auth.AutoRefreshingAuthClient? _client;

 CloudApi(String json)
     : _credentials = auth.ServiceAccountCredentials.fromJson(json);

 Future<ObjectInfo> save(String name, Uint8List imgBytes) async {
  try {
   // Create a client
   if (_client == null) {
    _client = await auth.clientViaServiceAccount(_credentials, Storage.SCOPES);
   }

   // Instantiate objects to cloud storage
   var storage = Storage(_client!, 'Image Upload Google Storage');
   var bucket = storage.bucket('mybucket_12345');

   // Save to the bucket
   return await bucket.writeBytes(name, imgBytes);
  } catch (e) {
   print('Error in save method: $e');
   rethrow; // Rethrow the exception for higher-level handling
  }
 }
}
