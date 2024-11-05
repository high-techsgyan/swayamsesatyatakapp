import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request Image Permission
  Future<bool> requestImagePermission(BuildContext context) async {
    return await _requestMediaPermission(
      Permission.photos,
      context,
      "Images",
      fallback: Permission.storage,
    );
  }

  /// Core function to handle media permissions
  Future<bool> _requestMediaPermission(
      Permission permission, BuildContext context, String mediaType,
      {Permission? fallback}) async {
    // Check if the media permission is already granted
    var status = await permission.status;
    if (status.isGranted) return true;

    // Handle permission based on status
    if (status.isDenied) {
      // Request permission
      var result = await permission.request();
      if (result.isGranted) {
        return true;
      } else if (result.isDenied) {
        _showPermissionDeniedDialog(context, mediaType);
      }
    } else if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, mediaType);
    }

    // Fallback to storage permission for older Android versions if necessary
    if (fallback != null) {
      var fallbackStatus = await fallback.status;
      if (fallbackStatus.isGranted) return true;

      var fallbackResult = await fallback.request();
      if (fallbackResult.isGranted) return true;
    }

    return false;
  }

  /// Display a dialog for temporarily denied permissions
  void _showPermissionDeniedDialog(
      BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permission Denied"),
        content: Text(
          "The $permissionName permission was denied. Please allow it to use this feature.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Display a dialog for permanently denied permissions with an option to open settings
  void _showPermanentlyDeniedDialog(
      BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permission Permanently Denied"),
        content: Text(
          "The $permissionName permission is permanently denied. Please enable it in the app settings to use this feature.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }
}
