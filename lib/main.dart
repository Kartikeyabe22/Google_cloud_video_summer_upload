import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';

import 'api.dart';

void main() {
  runApp(MaterialApp(
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _video;
  Uint8List? _videoBytes;
  String? _videoName;
  final picker = ImagePicker();
  late CloudApi _api;
  VideoPlayerController? _videoController;

  bool isUploaded = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  void _initializeApi() async {
    try {
      final json = await rootBundle.loadString('assets/credentials.json');
      _api = CloudApi(json);
    } catch (e) {
      print('Error initializing API: $e');
    }
  }

  void _saveVideo() async {
    setState(() {
      loading = true;
    });
    try {
      if (_videoBytes != null) {
        await _api.save(_videoName!, _videoBytes!);
        print('Video uploaded successfully.');
      } else {
        print('No video data available to upload.');
      }
    } catch (e) {
      print('Error uploading video: $e');
    }
    setState(() {
      loading = false;
      isUploaded = true;
    });
  }

  void _getVideo() async {
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _video = File(pickedFile.path);
        _videoName = _video!.path.split('/').last;
        isUploaded = false;

        _compressVideo(_video!).then((compressedVideo) {
          setState(() {
            _videoBytes = compressedVideo.readAsBytesSync();
            _videoController = VideoPlayerController.file(compressedVideo)
              ..initialize().then((_) {
                setState(() {});
                _videoController!.play();
              });
          });
        });
      } else {
        print('No Video Selected');
      }
    });
  }

  Future<File> _compressVideo(File videoFile) async {
    // final info = await VideoCompress.compressVideo(
    //   videoFile.path,
    //   quality: VideoQuality.LowQuality,
    //   deleteOrigin: false,
    // );
    // return info!.file!;
    return videoFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: Center(
          child: _videoBytes == null
              ? Text('No Video selected')
              : Stack(
            children: [
              if (_videoController != null && _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              if (loading)
                Center(
                  child: CircularProgressIndicator(),
                ),
              isUploaded
                  ? Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              )
                  : Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: _saveVideo,
                  child: Text('Save to cloud'),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_api != null) {
            _getVideo();
          } else {
            print('API not initialized');
          }
        },
        tooltip: 'Select Video',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
