import 'dart:typed_data';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String username = '';
  String fullName = '';
  String email = '';
  String phone = '';
  String country = '';
  String state = '';
  String pincode = '';
  String userProfileImageUrl = '';
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  final cloudinary = Cloudinary.unsignedConfig(
    cloudName: 'dqlwdqzcf', // Replace with your actual cloud name
  );

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firebase Realtime Database
  Future<void> _fetchUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('Users/${user!.uid}');
      final snapshot = await userRef.once();
      if (snapshot.snapshot.value != null) {
        final userData = snapshot.snapshot.value as Map;

        setState(() {
          username = userData['username'] ?? 'Unknown User';
          fullName = userData['fullname'] ?? 'Full Name';
          email = user?.email ?? '';
          phone = userData['phone'] ?? '';
          country = userData['country'] ?? '';
          state = userData['state'] ?? '';
          pincode = userData['pincode'] ?? '';
          userProfileImageUrl = userData['userprofile'] ?? '';
        });
      } else {
        _showErrorDialog('No user data found.');
      }
    } else {
      _showErrorDialog('User is not logged in.');
    }
  }

  // Function to upload profile picture
  // Function to upload profile picture
Future<void> _uploadProfilePicture() async {
  if (_imageFile == null) {
    _showErrorDialog('No image selected.');
    return;
  }

  try {
    Uint8List imageData;

    // Compress image if it exceeds 15 KB
    int fileSize = await _imageFile!.length();
    if (fileSize > 15 * 1024) {
      imageData = await _imageFile!.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageData);

      int quality = 85;
      Uint8List? compressedImageData;
      do {
        compressedImageData = img.encodeJpg(originalImage!, quality: quality);
        quality -= 5;
        if (quality < 0) break;
      } while (compressedImageData.length > 15 * 1024);

      imageData = compressedImageData;
    } else {
      imageData = await _imageFile!.readAsBytes();
    }

    const uploadPreset = 'profile_pictures_upload'; // Ensure this is correct
    const cloudinaryFolder = 'profile_pictures';

    final response = await cloudinary.unsignedUpload(
      fileBytes: imageData,
      uploadPreset: uploadPreset,
      resourceType: CloudinaryResourceType.image,
      folder: cloudinaryFolder,
      fileName: '${user!.uid}_profile',
      progressCallback: (count, total) {
        print('Uploading: $count/$total');
      },
    );

    if (response.isSuccessful && response.secureUrl != null) {
      String uploadedImageUrl = response.secureUrl!;
      DatabaseReference userRef = FirebaseDatabase.instance.ref('Users/${user!.uid}');
      await userRef.update({'userprofile': uploadedImageUrl});

      setState(() {
        userProfileImageUrl = uploadedImageUrl;
      });
      _showSuccessDialog('Profile picture uploaded successfully!');
    } else {
      // Directly print response.error if it’s a String
      print('Cloudinary upload failed: ${response.error}');
      _showErrorDialog('Failed to upload profile picture: ${response.error ?? "Unknown error"}');
    }
  } catch (error) {
    // General error handling
    print('Exception during Cloudinary upload: $error');
    _showErrorDialog('Failed to upload profile picture: ${error.toString()}');
  }
}



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Okay'),
          ),
        ],
      ),
    );
  }

  // Function to show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Okay'),
          ),
        ],
      ),
    );
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: userProfileImageUrl.isNotEmpty
                          ? NetworkImage(userProfileImageUrl)
                          : AssetImage('assets/images/default_profile.png')
                              as ImageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.edit),
                      color: Colors.blue,
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Full Name: $fullName', style: TextStyle(fontSize: 16)),
            Text('Username: $username', style: TextStyle(fontSize: 16)),
            Text('Email: $email', style: TextStyle(fontSize: 16)),
            Text('Phone: $phone', style: TextStyle(fontSize: 16)),
            Text('Country: $country', style: TextStyle(fontSize: 16)),
            Text('State: $state', style: TextStyle(fontSize: 16)),
            Text('Pincode: $pincode', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _editUserDetails,
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to edit user details (similar to your previous implementation)
  void _editUserDetails() {
    //... Implementation for editing user details goes here
  }
}
