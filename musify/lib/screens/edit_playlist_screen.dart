import 'package:flutter/material.dart';
import 'package:musify/models/playlist.dart';
import 'package:musify/repositories/playlist_repository.dart'; // Assuming direct access for now

// TODO: Replace with your actual PlaylistProvider or state management solution
// import 'package:provider/provider.dart';
// import 'package:musify/providers/playlist_provider.dart';

class EditPlaylistScreen extends StatefulWidget {
  final Playlist playlist;

  const EditPlaylistScreen({super.key, required this.playlist});

  static Future<void> navigateTo(BuildContext context, Playlist playlist) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPlaylistScreen(playlist: playlist),
      ),
    );
  }

  @override
  State<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends State<EditPlaylistScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // TODO: This is a placeholder. You should get the repository instance
  // from your dependency injection setup or state management.
  final PlaylistRepository _playlistRepository = PlaylistRepository();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _descriptionController = TextEditingController(
      text: widget.playlist.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePlaylist() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Create a new playlist object or update the existing one
      // Since Playlist model does not have copyWith, we modify the existing one
      // and rely on the `updatePlaylist` in repository to handle it.
      // A more robust approach might involve creating a new instance if Playlist
      // were immutable or had a copyWith method.

      widget.playlist.setName(_nameController.text.trim());
      widget.playlist.setDescription(
        _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      ); // Set to null if empty
      // The touch() method is called internally by setName/setDescription

      try {
        // TODO: Replace with your actual provider/repository call
        // final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
        // await playlistProvider.updatePlaylist(updatedPlaylist);
        await _playlistRepository.updatePlaylist(widget.playlist);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playlist updated successfully!')),
          );
          Navigator.of(context).pop(); // Pop back after saving
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating playlist: \$e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Playlist'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePlaylist,
              tooltip: 'Save Playlist',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter playlist name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Playlist name cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter a short description',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                // No validator needed as it's optional
              ),
              const SizedBox(height: 30),
              // Potentially add cover image editing here in the future
            ],
          ),
        ),
      ),
    );
  }
}
