import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:musify/models/playlist.dart';
import 'package:musify/services/playlist_manager.dart';
import 'package:musify/widgets/dialogs/playlist_create_edit_dialog.dart';
import './playlist_detail_screen.dart'; // Import the detail screen

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final PlaylistManager _playlistManager = PlaylistManager();
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlistsFuture = _playlistManager.getAllPlaylists();
    });
  }

  void _navigateToPlaylistDetail(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    ).then((_) {
      // Potentially refresh if playlist details (like track count or name) could have changed
      // For now, we might not need immediate refresh if detail screen manages its own state
      // and updates are reflected through PlaylistManager indirectly.
      // However, if name/desc can be edited from detail screen, a refresh here would be good.
      _loadPlaylists();
    });
  }

  void _showEditPlaylistDialog(Playlist playlistToEdit) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return PlaylistCreateEditDialog(playlistToEdit: playlistToEdit);
      },
    ).then((result) {
      if (result == true) {
        _loadPlaylists(); // Refresh if changes were made
      }
    });
  }

  void _showCreatePlaylistDialog() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const PlaylistCreateEditDialog();
      },
    ).then((result) {
      // If the dialog returned true, it means a playlist was created/updated successfully.
      if (result == true) {
        _loadPlaylists(); // Refresh the list of playlists
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: FutureBuilder<List<Playlist>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading playlists: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No playlists yet. Create one!'));
          }

          final playlists = snapshot.data!;
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Dismissible(
                key: ValueKey(playlist.id),
                direction:
                    DismissDirection
                        .endToStart, // Or .startToEnd, or .horizontal
                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: AlignmentDirectional.centerEnd,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (DismissDirection direction) async {
                  // Show a confirmation dialog before actually dismissing and deleting
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: Text(
                          "Are you sure you want to delete '${playlist.name}'?",
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Delete"),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await _playlistManager.deletePlaylist(playlist.id);
                    // Remove from the local list to update UI immediately before full reload
                    // Or simply reload. For robustness, let's reload.
                    _loadPlaylists(); // Reload to reflect deletion
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("'${playlist.name}' deleted")),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error deleting playlist: ${e.toString()}",
                          ),
                        ),
                      );
                    }
                    // If deletion failed, reload to revert UI optimistically or show error
                    _loadPlaylists();
                  }
                },
                child: _PlaylistListItem(
                  playlist: playlist,
                  onTap: () => _navigateToPlaylistDetail(playlist),
                  onEdit: (Playlist p) => _showEditPlaylistDialog(p),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        tooltip: 'Create Playlist',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PlaylistListItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final Function(Playlist) onEdit; // Callback for edit
  // final Function(Playlist) onDelete; // Optional: Callback for delete via menu

  const _PlaylistListItem({
    required this.playlist,
    required this.onTap,
    required this.onEdit,
    // required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    if (playlist.coverImagePath != null &&
        playlist.coverImagePath!.isNotEmpty) {
      try {
        // Check if the file exists before trying to display it
        // Note: File operations can be slow, consider if this check is needed everywhere
        // or if errorBuilder is sufficient.
        // For simplicity here, we assume errorBuilder handles non-existent files gracefully.
        leadingWidget = SizedBox(
          width: 50, // Standard size for list item leading art
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.file(
              File(playlist.coverImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.music_note, size: 30); // Fallback icon
              },
            ),
          ),
        );
      } catch (e) {
        // Catch potential errors from File constructor if path is invalid, though unlikely here
        print("Error loading cover image for playlist ${playlist.id}: $e");
        leadingWidget = const SizedBox(
          width: 50,
          height: 50,
          child: Center(child: Icon(Icons.broken_image, size: 30)),
        );
      }
    } else {
      leadingWidget = const SizedBox(
        width: 50,
        height: 50,
        child: Center(child: Icon(Icons.music_note, size: 30)), // Default icon
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: leadingWidget,
        title: Text(
          playlist.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${playlist.trackIds.length} tracks'),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Playlist options',
          onSelected: (String value) {
            if (value == 'edit') {
              onEdit(playlist);
            } else if (value == 'delete') {
              // If we add delete here, call onDelete(playlist)
              // For now, delete is handled by swipe
              print(
                'Delete selected for ${playlist.name} via menu - not implemented via menu yet',
              );
            }
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                // Example: Add delete option here if desired
                // const PopupMenuItem<String>(
                //   value: 'delete',
                //   child: ListTile(
                //     leading: Icon(Icons.delete),
                //     title: Text('Delete'),
                //   ),
                // ),
              ],
        ),
        onTap: onTap,
      ),
    );
  }
}
