import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class FileUtils {
  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<XFile?> runFilePicker() async {
    // Android | IOS only
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    return pickedFile;
  }
}
