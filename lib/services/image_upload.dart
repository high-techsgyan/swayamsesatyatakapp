import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:swayamsesatyatak/services/permission_handler.dart';
 // Import your PermissionService here

class ImageUploadService {
  static final PermissionService _permissionService = PermissionService();

  // Function to pick an image from the gallery
  static Future<File?> pickImage(BuildContext context) async {
    // Request image permission
    bool hasPermission =
        await _permissionService.requestImagePermission(context);
    if (!hasPermission) {
      return null; // Permission denied, return null
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      print("No image selected");
      return null;
    }
  }

  // Function to upload the image to Cloudinary
  static Future<String?> uploadImage(File imageFile) async {
    const cloudinaryUploadUrl =
        'https://api.cloudinary.com/v1_1/dqlwdqzcf/image/upload';
    const uploadPreset = 'quote_image';

    final request = http.MultipartRequest(
        'POST', Uri.parse(cloudinaryUploadUrl))
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      return jsonResponse['secure_url']; // Return the URL of the uploaded image
    } else {
      print("Image upload failed with status: ${response.statusCode}");
      return null;
    }
  }

  // Function to pick an image and upload it to Cloudinary
  static Future<String?> pickAndUploadImage(BuildContext context) async {
    final imageFile = await pickImage(context);
    if (imageFile != null) {
      return await uploadImage(imageFile);
    }
    return null;
  }
}
