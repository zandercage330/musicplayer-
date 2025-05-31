import 'package:flutter/material.dart';
import 'package:musify/services/permission_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionScreen({super.key, required this.onPermissionGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    PermissionRequestUIAction action =
        await _permissionService.determinePermissionRequestUIAction();

    if (mounted) {
      setState(() => _isLoading = false);
      if (action == PermissionRequestUIAction.proceed) {
        widget.onPermissionGranted();
      } else if (action == PermissionRequestUIAction.showSettingsDialog) {
        // Show a dialog asking user to go to settings
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Permission Required'),
                content: const Text(
                  'Storage permission is permanently denied. Please go to app settings to enable it.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  TextButton(
                    child: const Text('Open Settings'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _permissionService.openAppSettingsPage();
                    },
                  ),
                ],
              ),
        );
      } else {
        // For showRationale or unknownError, for simplicity, just show a generic message for now
        // A more robust app might show a specific rationale message before re-requesting.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission is required to scan for music. Please grant permission.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        // Could offer another button to try _permissionService.requestStoragePermission() again here.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_open, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Access Music Files',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Musify needs permission to access your storage to find and play your local music files.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Grant Permission'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: _requestPermission,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
