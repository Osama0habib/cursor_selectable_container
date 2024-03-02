import 'dart:io';

import 'package:cursor_selectable_container/const.dart';
import 'package:flutter/cupertino.dart';

ImageProvider buildImageView(String imagePath) {
    switch (imagePath.imageType) {
      case ImageType.file:
        return FileImage(
          File(imagePath),
        );
      case ImageType.network:
        return NetworkImage(
          imagePath,
        );
      case ImageType.png:
      default:
        return AssetImage(
          imagePath,
        );
    }
}
