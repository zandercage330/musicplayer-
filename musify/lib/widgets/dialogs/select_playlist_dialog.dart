import 'package:flutter/material.dart';
import 'package:musify/models/playlist.dart';
import 'package:musify/services/playlist_manager.dart';

// Special object to signal that the user wants to create a new playlist.
const Object createNewPlaylistSignal = Object();

class SelectPlaylistDialog extends StatefulWidget {
  const SelectPlaylistDialog({super.key});

  @override
  State<SelectPlaylistDialog> createState() => _SelectPlaylistDialogState();
}

class _SelectPlaylistDialogState extends State<SelectPlaylistDialog> {
  final PlaylistManager _playlistManager = PlaylistManager();
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _playlistManager.getAllPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Playlist'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Playlist>>(
          future: _playlistsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No playlists. Create one first!'),
              );
            }
            final playlists = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.trackIds.length} tracks'),
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pop(playlist); // Return selected playlist
                  },
                );
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('New Playlist'),
          onPressed: () {
            // Pop this dialog and return the signal to create a new playlist.
            Navigator.of(context).pop(createNewPlaylistSignal);
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(null); // Return null if cancelled
          },
        ),
      ],
    );
  }
}
