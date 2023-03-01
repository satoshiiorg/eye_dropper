import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerButton extends StatelessWidget {
  const ImagePickerButton({super.key, required this.onSelected});

  final ValueChanged<Uint8List> onSelected;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: selectImage,
      child: const Text('画像を選択'),
    );
  }

  /// カメラロールから画像を選択し imageProvider にセット
  Future<void> selectImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if(image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    onSelected(bytes);
  }
}
