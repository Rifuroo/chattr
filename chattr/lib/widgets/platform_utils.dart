import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'image_preview_stub.dart'
    if (dart.library.io) 'image_preview_mobile.dart'
    if (dart.library.html) 'image_preview_web.dart';

Widget previewImage(XFile? file) {
  return getPreviewImage(file);
}
