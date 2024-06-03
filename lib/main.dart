import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

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
  File? _image;
  Uint8List? _imageBytes;
  String? _imageName;
  final picker = ImagePicker();
  late CloudApi _api;

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

  // void saveImage() async {
  //   if (_imageBytes != null) {
  //     final response = await _api.save('test', _imageBytes!);
  //     print(response.downloadLink);
  //   }
  // }

  void _saveImage() async {
    setState(() {
      loading = true;
    });
    try {
      if (_imageBytes != null) {
        final response = await _api.save(_imageName!, _imageBytes!);
        print('Image uploaded successfully. Download link: ${response.downloadLink}');
      } else {
        print('No image data available to upload.');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    setState(() {
      loading = false;
      isUploaded = true;
    });
  }


  void _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        print(pickedFile.path);
        _image = File(pickedFile.path);
        _imageBytes = _image!.readAsBytesSync();
        _imageName = _image!.path.split('/').last;
        isUploaded = false;
      } else {
        print('No Image Selected');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: Center(
          child: _imageBytes == null
              ? Text('No Image selected')
              : Stack(
            children: [
              Image.memory(_imageBytes!),
              if(loading)
                Center(
                    child: CircularProgressIndicator(),
                  ),
               isUploaded
                ? Center(
                  child:CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                )

            :  Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: _saveImage,
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
            _getImage();
          } else {
            print('API not initialized ');
          }
        },
        tooltip: 'Select Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
