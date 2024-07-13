import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Picker App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  File? _resultImage;
  final picker = ImagePicker();
  TextEditingController _urlController = TextEditingController(); // Controller for endpoint URL text field

  @override
  void dispose() {
    _urlController.dispose(); // Dispose of the controller when not needed
    super.dispose();
  }

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _resultImage = null;
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> uploadImage(File imageFile, String endpointUrl) async {
    var url = endpointUrl.endsWith('/') ? endpointUrl : '$endpointUrl/';
    url += 'detect/'; // Append "/detect/" to the endpoint URL

    var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();

    var uri = Uri.parse(url); // Parse endpoint URL from input

    var request = http.MultipartRequest("POST", uri);
    var multipartFile = http.MultipartFile('file', stream, length, filename: basename(imageFile.path));

    request.files.add(multipartFile);
    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      var documentDirectory = await getApplicationDocumentsDirectory();
      var filePath = join(documentDirectory.path, 'response_image.jpg');

      File file = File(filePath);
      file.writeAsBytesSync(responseData.bodyBytes);

      setState(() {
        _resultImage = file;
      });

      print('Image uploaded and result image saved successfully.');
    } else {
      print('Image upload failed with status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car parts identifier'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null
                  ? Text('No image selected.')
                  : Image.file(_image!),
              SizedBox(height: 20),
              _resultImage == null
                  ? Container()
                  : Image.file(_resultImage!),
              SizedBox(height: 20),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Enter Endpoint URL (e.g., https://example.com)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => getImage(ImageSource.gallery),
                child: Text('Pick Image from Gallery'),
              ),
              ElevatedButton(
                onPressed: () => getImage(ImageSource.camera),
                child: Text('Take a Picture'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_image != null && _urlController.text.isNotEmpty) {
                    uploadImage(_image!, _urlController.text);
                  }
                },
                child: Text('Upload Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
