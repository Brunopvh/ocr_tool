import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocr_tool/widgets/picker_option_widget.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _extractedText = '';

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter OCR')),
      body: Column(
        children: [
          const Text(
            'Select a Option',
            style: TextStyle(fontSize: 22.0),
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PickerOptionWidget(
                  label: 'From Gallery',
                  color: Colors.blueAccent,
                  icon: Icons.image_outlined,
                  onTap: () => _processImageExtractText(
                    imageSource: ImageSource.gallery,
                  ),
                ),
                const SizedBox(width: 10.0),
                PickerOptionWidget(
                  label: 'From Camera',
                  color: Colors.redAccent,
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _processImageExtractText(
                                imageSource: ImageSource.camera,),
                  ),
              ],
            ),
          ),
          if (_extractedText.isNotEmpty) ...{
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Previously Read',
                    style: TextStyle(fontSize: 22.0),
                  ),
                  IconButton(
                    onPressed: _copyToClipBoard,
                    icon: const Icon(Icons.copy),
                  )
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10.0,
                      bottom: 20.0,
                    ),
                    child: Text(_extractedText),
                  ),
                ),
              ),
            )
          },
        ],
      ),
    );
  }

  Future<File?> _pickerImage({required ImageSource source}) async {
    // Selecionar imagem do dispositivo
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return File(image.path);
    }
    return null;
  } // _pickerImage

  Future<CroppedFile?> _cropImage({required File imageFile}) async {
    // Cortador de imagem
    CroppedFile? croppedfile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      ],
    );

    if (croppedfile != null) {
      return croppedfile;
    }

    return null;
  } // _cropImage

  Future<String> _recognizeTextFromImage({required String imgPath}) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final image = InputImage.fromFile(File(imgPath));
    final recognized = await textRecognizer.processImage(image);

    return recognized.text;
  } // _recognizeTextFromImage

  void _copyToClipBoard() { 
  Clipboard.setData(ClipboardData(text: _extractedText)); 

  ScaffoldMessenger.of(context).showSnackBar( 
    const SnackBar( 
      content: Text( 'Copiado para a área de transferência' ), 
    ), 
  ); 
}

  Future<void> _processImageExtractText({
    required ImageSource imageSource,
  }) async {
    // Processo que usa os 3 metodos anteriores
    final imageFile = await _pickerImage(source: imageSource);

    if (imageFile == null) return;

    final croppedImage = await _cropImage(
      imageFile: imageFile,
    );

    if (croppedImage == null) return;

    final recognizedText = await _recognizeTextFromImage(
      imgPath: croppedImage.path,
    );

    setState(() => _extractedText = recognizedText);
  }
}
