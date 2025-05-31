import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added
import 'package:musify/models/playlist.dart';
import 'package:musify/services/playlist_manager.dart';
import 'package:uuid/uuid.dart';

class PlaylistCreateEditDialog extends StatefulWidget {
  final Playlist? playlistToEdit;

  const PlaylistCreateEditDialog({super.key, this.playlistToEdit});

  @override
  State<PlaylistCreateEditDialog> createState() =>
      _PlaylistCreateEditDialogState();
}

class _PlaylistCreateEditDialogState extends State<PlaylistCreateEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _creatorNameController;
  final PlaylistManager _playlistManager = PlaylistManager();
  String? _selectedCoverImagePath; // Added
  final ImagePicker _picker = ImagePicker(); // Added

  bool get _isEditing => widget.playlistToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.playlistToEdit?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.playlistToEdit?.description ?? '',
    );
    _creatorNameController = TextEditingController(
      text: widget.playlistToEdit?.creatorDisplayName ?? '',
    );
    _selectedCoverImagePath = widget.playlistToEdit?.coverImagePath; // Added
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _creatorNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Optional: to compress image a bit
        maxWidth: 500, // Optional: to resize image
        maxHeight: 500,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedCoverImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _savePlaylist() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final creatorName = _creatorNameController.text.trim();

      if (_isEditing) {
        // Update existing playlist
        if (widget.playlistToEdit != null) {
          Playlist updatedPlaylist = widget.playlistToEdit!;
          updatedPlaylist.name = name;
          updatedPlaylist.description =
              description.isNotEmpty ? description : null;
          updatedPlaylist.creatorDisplayName =
              creatorName.isNotEmpty ? creatorName : null;
          updatedPlaylist.coverImagePath = _selectedCoverImagePath;
          updatedPlaylist.touch(); // Update modification date

          try {
            await _playlistManager.updatePlaylistDetails(updatedPlaylist);
            if (mounted) {
              Navigator.of(
                context,
              ).pop(updatedPlaylist); // Return updated playlist
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating playlist: $e')),
              );
            }
          }
        }
      } else {
        // Create new playlist
        final newPlaylist = Playlist(
          id: const Uuid().v4(), // Generate a unique ID
          name: name,
          description: description.isNotEmpty ? description : null,
          coverImagePath: _selectedCoverImagePath,
          trackIds: [], // Initially empty
          creationDate: DateTime.now(),
          modificationDate: DateTime.now(),
          creatorDisplayName: creatorName.isNotEmpty ? creatorName : null,
        );
        try {
          await _playlistManager.createPlaylist(newPlaylist);
          if (mounted) {
            Navigator.of(context).pop(newPlaylist); // Return new playlist
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating playlist: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Playlist' : 'Create Playlist'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                  image:
                      _selectedCoverImagePath != null &&
                              _selectedCoverImagePath!.isNotEmpty
                          ? DecorationImage(
                            image: FileImage(File(_selectedCoverImagePath!)),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _selectedCoverImagePath == null ||
                            _selectedCoverImagePath!.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                'Cover',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                        : null,
              ),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Playlist Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a playlist name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 2,
            ),
            TextFormField(
              controller: _creatorNameController,
              decoration: const InputDecoration(
                labelText: 'Creator Name (Optional)',
              ),
            ),
            // TODO: Add option to pick a cover image
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(
              context,
            ).pop(null); // Changed from pop(false) to pop(null)
          },
        ),
        TextButton(
          onPressed: _savePlaylist,
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
