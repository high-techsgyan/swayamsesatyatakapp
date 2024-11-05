import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePage extends StatelessWidget {
  final String apkUrl;

  UpdatePage({Key? key, required this.apkUrl}) : super(key: key);
  Future<void> _downloadAndInstall(BuildContext context) async {
    final Uri uri = Uri.parse(apkUrl); // Convert String to Uri
    print('Launching URL: $uri'); // Debugging line to check URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorDialog(context); // Show error dialog
    }
  }

  void _showErrorDialog(BuildContext context) {
    // Show an error dialog if the URL can't be launched
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text(
              'Could not launch the update URL. Please try again later.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text("Update Available")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("A new version is available!"),
            ElevatedButton(
              onPressed: () => _downloadAndInstall(
                  context), // Pass context to the download method
              child: const Text("Download Update"),
            ),
          ],
        ),
      ),
    );
  }
}
