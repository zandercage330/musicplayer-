import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for PlatformException
import 'package:image_picker/image_picker.dart';
import 'package:musify/providers/profile_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import for openAppSettings
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _imagePath;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    _nameController = TextEditingController(text: profileProvider.name ?? '');
    _imagePath = profileProvider.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image;
    String message = 'No image selected.';

    setState(() {
      _isPickingImage = true;
    });

    try {
      image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imagePath = image!.path;
        });
        message = 'Image selected successfully!';
      } else {
        message =
            'Image selection cancelled.'; // More specific cancellation message
      }
    } on PlatformException catch (e) {
      message = 'Failed to pick image: ${e.message}';
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        // Codes might vary by plugin version/OS
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (BuildContext context) => AlertDialog(
                  title: const Text('Permission Denied'),
                  content: const Text(
                    'To select an image, please grant gallery access in your app settings.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text('Open Settings'),
                      onPressed: () {
                        openAppSettings();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
          );
          // Set message to null to prevent SnackBar if dialog is shown
          message = '';
        }
      }
    } catch (e) {
      message = 'Error picking image: ${e.toString()}';
    }

    setState(() {
      _isPickingImage = false;
    });

    if (mounted && message.isNotEmpty) {
      // Only show SnackBar if message is not empty
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                profileProvider.updateProfile(
                  name: _nameController.text,
                  imagePath: _imagePath,
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _imagePath != null
                              ? FileImage(File(_imagePath!))
                              : null,
                      child:
                          _imagePath == null
                              ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _isPickingImage ? null : _pickImage,
                        ),
                      ),
                    ),
                    if (_isPickingImage) const CircularProgressIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              // Add more fields here if needed (e.g., email, bio)
            ],
          ),
        ),
      ),
    );
  }
}
