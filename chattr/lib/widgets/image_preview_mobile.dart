import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Widget getPreviewImage(XFile? file) {
  if (file == null) return const SizedBox();
  return Image.file(File(file.path), fit: BoxFit.cover);
}
