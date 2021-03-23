// RAJ ARYAN
// BT19CSE043
// CSE A

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  XFile image;
  var path;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;
            Map<PermissionGroup, PermissionStatus> permissions =
                await PermissionHandler()
                    .requestPermissions([PermissionGroup.storage]);
            // Attempt to take a picture and get the file `image`
            // where it was saved.
            image = await _controller.takePicture();

            if (permissions[PermissionGroup.storage] ==
                PermissionStatus.granted) {
              final path = join(
                (await ExtStorage.getExternalStoragePublicDirectory(
                    ExtStorage.DIRECTORY_PICTURES)),
                '${DateTime.now()}.jpg',
              );
              image.saveTo(path);
            } else {}

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image?.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }

  // Future<String> getFilePath() async {
  //   Directory appDocumentsDirectory = await getExternalStorageDirectory();
  //   String appDocumentsPath = appDocumentsDirectory.path;
  //   String filePath = '$appDocumentsPath/demoTextFile.txt';
  //   print(ExtStorage.DIRECTORY_DOWNLOADS);
  //   return filePath;
  // }

  // void saveFile() async {
  //   File file = File(await getFilePath());
  //   file.writeAsString(
  //       "This is my demo text that will be saved to : demoTextFile.txt");
  // }

  // void readFile() async {
  //   File file = File(await getFilePath());
  //   String fileContent = await file.readAsString();

  //   print('File Content: $file');
  // }

  // void _example2() async {
  //   var path = await ExtStorage.getExternalStoragePublicDirectory(
  //       ExtStorage.DIRECTORY_PICTURES);
  //   print(path); // /storage/emulated/0/Pictures
  // }

  // Future<void> _saveimg() {}
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TakePictureScreenState().saveFile();
          // TakePictureScreenState().readFile();
          // TakePictureScreenState()._example2();
          Navigator.pop(context);
        },
        label: Text('Go Back'),
      ),
    );
  }
}
