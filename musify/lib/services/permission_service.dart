import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure SharedPreferences is imported
import 'package:device_info_plus/device_info_plus.dart';
// Import for checking Android version, if needed later for MANAGE_EXTERNAL_STORAGE
// import 'package:device_info_plus/device_info_plus.dart';

// Enum to guide UI on what action to take after a permission request attempt
enum PermissionRequestUIAction {
  proceed, // Permission granted, UI can proceed
  showRationale, // Permission denied, show rationale and allow re-request
  showSettingsDialog, // Permission permanently denied/restricted, prompt to open settings
  unknownError, // Some other issue occurred
}

class PermissionService {
  static const String _storagePermissionGrantedKey =
      'storage_permission_granted_v3';

  Future<bool> requestStoragePermission() async {
    bool isGranted;

    if (await _isAndroid13OrHigher()) {
      PermissionStatus audioStatus = await Permission.audio.request();
      isGranted = audioStatus.isGranted;
    } else {
      PermissionStatus storageStatus = await Permission.storage.request();
      isGranted = storageStatus.isGranted;
    }

    if (isGranted) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storagePermissionGrantedKey, true);
    }
    return isGranted;
  }

  Future<bool> _isAndroid13OrHigher() async {
    // This check should only be relevant on Android.
    // For other platforms, you might return false or handle appropriately.
    // final plugin = DeviceInfoPlugin(); // This makes the linter error if not on Android, this is not platform specific, and does not need to be this way.
    // final androidInfo = await plugin.androidInfo;
    // return androidInfo.version.sdkInt >= 33;

    // To make this platform-agnostic for the purpose of this example,
    // let's assume if not Android, it doesn't meet the criteria.
    // A more robust solution would use conditional imports or check Platform.isAndroid.
    try {
      // Attempt to get Android-specific info. If it fails, assume not Android or not relevant.
      // This is a simplified approach. For production, consider Platform.isAndroid.
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      // If not on Android or error fetching info, assume not Android 13+ for this logic.
      // This means on non-Android platforms, it will fall back to Permission.storage request logic.
      // Which might be fine if Permission.storage is a sensible fallback on other platforms,
      // or you might want to handle non-Android platforms differently.
      print('Error getting Android SDK version: $e. Assuming not Android 13+.');
      return false;
    }
  }

  Future<PermissionStatus> getAudioPermissionStatus() async {
    return await Permission.audio.status;
  }

  Future<PermissionStatus> getStoragePermissionStatus() async {
    return await Permission.storage.status;
  }

  Future<PermissionRequestUIAction> determinePermissionRequestUIAction({
    bool forceShowRationaleIfPreviouslyGranted = false,
  }) async {
    // Corrected parameter name
    // Check live status first
    PermissionStatus currentStatus;
    if (await _isAndroid13OrHigher()) {
      currentStatus = await Permission.audio.status;
    } else {
      currentStatus = await Permission.storage.status;
    }

    if (currentStatus.isGranted) {
      return PermissionRequestUIAction.proceed;
    }

    // If not currently granted, then attempt to request or determine next step
    bool grantedAfterRequest = await requestStoragePermission();

    if (grantedAfterRequest) {
      return PermissionRequestUIAction.proceed;
    }

    // If still not granted after request, determine why
    PermissionStatus statusAfterRequest;
    if (await _isAndroid13OrHigher()) {
      statusAfterRequest = await Permission.audio.status;
    } else {
      statusAfterRequest = await Permission.storage.status;
    }

    if (statusAfterRequest.isPermanentlyDenied ||
        statusAfterRequest.isRestricted) {
      return PermissionRequestUIAction.showSettingsDialog;
    }

    if (statusAfterRequest.isDenied) {
      return PermissionRequestUIAction.showRationale;
    }

    return PermissionRequestUIAction.unknownError;
  }

  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }

  Future<bool> hasStoragePermissionBeenGrantedPreviously() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_storagePermissionGrantedKey) ?? false;
  }

  // Example of how one might check for MANAGE_EXTERNAL_STORAGE if needed:
  // Future<bool> requestManageExternalStoragePermission() async {
  //   if (await Permission.manageExternalStorage.isGranted) {
  //     return true;
  //   }
  //   PermissionStatus status = await Permission.manageExternalStorage.request();
  //   return status.isGranted;
  // }

  // Future<bool> hasStoragePermissionBeenRequestedBefore() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.getBool('storage_permission_granted_v2') ?? false;
  // }
}
