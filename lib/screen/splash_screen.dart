import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _supabaseUrl = "https://gksxshcgikuirnfhbxbw.supabase.co";
  final String _apiKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdrc3hzaGNnaWt1aXJuZmhieGJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA2ODYzMTAsImV4cCI6MjA0NjI2MjMxMH0.5xuyPQsCgxfMmzbQFofMvcWG-TE7P3lwuIYoa8_ZOm0"; // Your API key
  final String currentVersion = "1.0.1"; // Your current app version

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_supabaseUrl/rest/v1/app_versions?select=*&order=created_at.desc&limit=1'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'apikey': _apiKey,
          'Content-Type': 'application/json'
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> versions = json.decode(response.body);

        // Ensure there is at least one version available
        if (versions.isNotEmpty) {
          final String latestVersion = versions[0]['version'];
          final String downloadUrl = versions[0]['url'];

          // Compare with the current app version
          if (latestVersion != currentVersion) {
            _showUpdateDialog(latestVersion, downloadUrl);
          } else {
            _navigateToNextScreen();
          }
        } else {
          _showErrorDialog("No version information available.");
        }
      } else {
        _showErrorDialog(
            "Failed to fetch version info. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error: $e");
      _showErrorDialog("Network error: ${e.toString()}");
    }
  }

  void _showUpdateDialog(String latestVersion, String downloadUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Available'),
          content: Text(
              'A new version $latestVersion is available. Do you want to update?'),
          actions: [
            TextButton(
              child: Text('Ignore'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToNextScreen();
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _downloadAndUpdate(downloadUrl);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndUpdate(String downloadUrl) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final File file = File('${tempDir.path}/app-release.apk');
        await file.writeAsBytes(response.bodyBytes);

        // Show download progress (optional)
        _showDownloadProgress(file.path);
      } else {
        _showErrorDialog(
            "Failed to download the update. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Download error: $e");
      _showErrorDialog("Download error: ${e.toString()}");
    }
  }

  void _showDownloadProgress(String filePath) {
    // Show a dialog or a snackbar with progress information
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Downloading APK...'),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );

    // Simulating download completion and opening the APK file
    Future.delayed(Duration(seconds: 2), () {
      OpenFile.open(filePath);
      Navigator.of(context).pop(); // Close the dialog after opening the file
      Timer(Duration(seconds: 5),
          _navigateToNextScreen); // Navigate to next screen after a delay
    });
  }

  void _navigateToNextScreen() {
    User? user = _auth.currentUser;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/walkthrough');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToNextScreen();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/swayam_se_satya_tak.png', width: 200),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
