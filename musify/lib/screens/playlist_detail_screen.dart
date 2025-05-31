import 'dart:io'; // For File, if not already imported at top
import 'package:flutter/material.dart';
import 'package:musify/models/playlist.dart';
import 'package:musify/models/track.dart';
import 'package:musify/services/music_scanner_service.dart'; // To fetch track details
import 'package:musify/services/playlist_manager.dart'; // To manage playlist modifications
import 'package:musify/services/audio_player_service.dart'; // For playback
import 'package:share_plus/share_plus.dart'; // For sharing
import './add_tracks_to_playlist_screen.dart'; // Import the new screen
import './edit_playlist_screen.dart'; // Import the edit screen
import 'package:provider/provider.dart'; // Added
import 'package:musify/providers/music_library_provider.dart'; // Added

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final MusicScannerService _musicScannerService = MusicScannerService();
  final PlaylistManager _playlistManager = PlaylistManager();

  late Playlist _currentPlaylist;
  List<Track> _playlistTracks = [];
  bool _isLoadingTracks = true;
  bool _isUpdatingPlaylist = false; // To show loading for add/remove operations
  bool _isReordering = false; // To disable other actions during reorder

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist; // Initial playlist state
    _fetchPlaylistTracks();
  }

  Future<void> _fetchPlaylistTracks({Playlist? updatedPlaylist}) async {
    setState(() {
      _isLoadingTracks = true;
      if (updatedPlaylist != null) {
        _currentPlaylist =
            updatedPlaylist; // Update if a new playlist object is passed
      }
    });
    try {
      List<Track> allTracks = await _musicScannerService.getTracks();
      Map<int, Track> allTracksMap = {for (var t in allTracks) t.id: t};

      List<Track> tracksToShow = [];
      for (int trackId in _currentPlaylist.trackIds) {
        if (allTracksMap.containsKey(trackId)) {
          tracksToShow.add(allTracksMap[trackId]!);
        }
      }
      tracksToShow.sort(
        (a, b) => _currentPlaylist.trackIds
            .indexOf(a.id)
            .compareTo(_currentPlaylist.trackIds.indexOf(b.id)),
      );

      setState(() {
        _playlistTracks = tracksToShow;
        _isLoadingTracks = false;
      });
    } catch (e) {
      print("Error fetching playlist tracks: $e");
      setState(() {
        _isLoadingTracks = false;
      });
    }
  }

  Future<void> _navigateAndAddTracks() async {
    final List<int>? selectedTrackIds = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddTracksToPlaylistScreen(
              existingTrackIdsInPlaylist: List<int>.from(
                _currentPlaylist.trackIds,
              ),
            ),
      ),
    );

    if (selectedTrackIds != null && selectedTrackIds.isNotEmpty) {
      setState(() => _isUpdatingPlaylist = true);
      try {
        for (int trackId in selectedTrackIds) {
          // The Playlist model's addTrack method handles duplicates and touches modificationDate
          // but persistence is via PlaylistManager
          await _playlistManager.addTrackToPlaylist(
            _currentPlaylist.id,
            trackId,
          );
        }
        // Refresh the entire playlist from manager to get updated trackIds and modificationDate
        Playlist? refreshedPlaylist = await _playlistManager.getPlaylist(
          _currentPlaylist.id,
        );
        if (refreshedPlaylist != null) {
          _fetchPlaylistTracks(updatedPlaylist: refreshedPlaylist);
        } else {
          _fetchPlaylistTracks(); // Fallback to refetch with old playlist id if somehow not found
        }
      } catch (e) {
        print("Error adding tracks: $e");
        // Show error
      }
      setState(() => _isUpdatingPlaylist = false);
    }
  }

  Future<void> _removeTrackFromPlaylist(Track trackToRemove) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Track'),
          content: Text(
            'Are you sure you want to remove "${trackToRemove.title}" from this playlist?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isUpdatingPlaylist = true);
      try {
        await _playlistManager.removeTrackFromPlaylist(
          _currentPlaylist.id,
          trackToRemove.id,
        );
        Playlist? refreshedPlaylist = await _playlistManager.getPlaylist(
          _currentPlaylist.id,
        );
        if (refreshedPlaylist != null) {
          _fetchPlaylistTracks(updatedPlaylist: refreshedPlaylist);
        } else {
          _fetchPlaylistTracks();
        }
      } catch (e) {
        print("Error removing track: $e");
        // Show error snackbar or message
      }
      setState(() => _isUpdatingPlaylist = false);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Track item = _playlistTracks.removeAt(oldIndex);
    _playlistTracks.insert(newIndex, item);

    final List<int> newTrackOrderIds =
        _playlistTracks.map((t) => t.id).toList();

    setState(() {
      _isReordering = true; // Indicate reordering is in progress
    });

    try {
      await _playlistManager.setPlaylistTracks(
        _currentPlaylist.id,
        newTrackOrderIds,
      );
      // Fetch the updated playlist to ensure consistency, though local reorder is done
      Playlist? refreshedPlaylist = await _playlistManager.getPlaylist(
        _currentPlaylist.id,
      );
      if (refreshedPlaylist != null) {
        // Update currentPlaylist and trackIds to reflect the persisted order
        _currentPlaylist = refreshedPlaylist;
        // _playlistTracks is already locally reordered, but _fetchPlaylistTracks
        // will re-fetch based on the new _currentPlaylist.trackIds order.
        // This also ensures any other playlist detail changes are picked up.
        await _fetchPlaylistTracks(updatedPlaylist: refreshedPlaylist);
      } else {
        // Fallback or error handling if playlist couldn't be refreshed
        await _fetchPlaylistTracks();
      }
    } catch (e) {
      print("Error reordering tracks: $e");
      // Optionally revert local reorder or show error
      // For now, just log and refetch to be safe
      await _fetchPlaylistTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error reordering tracks: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReordering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for dynamic sizing if needed, though SliverAppBar handles much of this
    // final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Using CustomScrollView to allow for SliverAppBar and SliverList
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200.0, // Adjust as needed
            floating: false,
            pinned: true,
            snap: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _currentPlaylist.name,
                style: const TextStyle(
                  fontSize: 16.0,
                ), // Adjust title size for FlexibleSpaceBar
              ),
              background:
                  _currentPlaylist.coverImagePath != null &&
                          _currentPlaylist.coverImagePath!.isNotEmpty
                      ? Image.file(
                        File(_currentPlaylist.coverImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800], // Fallback background
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          );
                        },
                      )
                      : Container(
                        color:
                            Colors.grey[800], // Fallback background if no image
                        child: const Center(
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Play All',
                onPressed:
                    _isUpdatingPlaylist || _playlistTracks.isEmpty
                        ? null
                        : () async {
                          await AudioPlayerService().loadPlaylist(
                            _playlistTracks,
                            initialIndex: 0,
                          );
                          await AudioPlayerService().play();
                        },
              ),
              IconButton(
                icon: const Icon(Icons.shuffle),
                tooltip: 'Shuffle Play',
                onPressed:
                    _isUpdatingPlaylist || _playlistTracks.isEmpty
                        ? null
                        : () async {
                          final shuffledTracks = List<Track>.from(
                            _playlistTracks,
                          )..shuffle();
                          await AudioPlayerService().loadPlaylist(
                            shuffledTracks,
                            initialIndex: 0,
                          );
                          await AudioPlayerService().play();
                        },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Playlist',
                onPressed:
                    _isUpdatingPlaylist || _playlistTracks.isEmpty
                        ? null
                        : () {
                          final trackTitles = _playlistTracks
                              .map((t) => t.title)
                              .join(', ');
                          Share.share(
                            'Check out my playlist: ${_currentPlaylist.name}\nTracks: $trackTitles',
                            subject: 'Playlist: ${_currentPlaylist.name}',
                          );
                        },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Playlist Details',
                onPressed:
                    _isUpdatingPlaylist || _isReordering
                        ? null
                        : () async {
                          await EditPlaylistScreen.navigateTo(
                            context,
                            _currentPlaylist,
                          );
                          Playlist? refreshedPlaylist = await _playlistManager
                              .getPlaylist(_currentPlaylist.id);
                          if (refreshedPlaylist != null) {
                            _fetchPlaylistTracks(
                              updatedPlaylist: refreshedPlaylist,
                            );
                          } else {
                            setState(() {});
                          }
                        },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Tracks',
                onPressed:
                    _isUpdatingPlaylist || _isReordering
                        ? null
                        : _navigateAndAddTracks,
              ),
            ],
          ),
          _isLoadingTracks || _isUpdatingPlaylist
              ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
              : _playlistTracks.isEmpty
              ? const SliverFillRemaining(
                child: Center(child: Text('This playlist is empty.')),
              )
              : SliverReorderableList(
                itemBuilder: (BuildContext context, int index) {
                  final track = _playlistTracks[index];
                  // Get MusicLibraryProvider here for use in the item
                  final libraryProvider = Provider.of<MusicLibraryProvider>(
                    context,
                    listen: false,
                  );

                  return ReorderableDragStartListener(
                    key: ValueKey(
                      'reorderable-${track.id}',
                    ), // Ensure unique key for reorderable item
                    index: index,
                    child: ListTile(
                      // key: ValueKey(track.id), // Original key, moved to ReorderableDragStartListener parent
                      leading: const Icon(Icons.music_note),
                      title: Text(track.title),
                      subtitle: Text(track.artist ?? 'Unknown Artist'),
                      onTap:
                          _isUpdatingPlaylist ||
                                  _isReordering // Disable if reordering
                              ? null
                              : () async {
                                await AudioPlayerService().loadPlaylist(
                                  _playlistTracks,
                                  initialIndex: index,
                                );
                                await AudioPlayerService().play();
                              },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favorite Context Menu (New)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.favorite_border,
                            ), // Placeholder, might change based on state
                            tooltip: 'Favorite options',
                            onSelected: (String value) async {
                              if (value == 'toggle_favorite') {
                                await libraryProvider.toggleFavorite(track);
                                if (context.mounted) {
                                  final bool isNowFavorite =
                                      await libraryProvider.isFavorite(
                                        track.id,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isNowFavorite
                                            ? 'Added to Favorites'
                                            : 'Removed from Favorites',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                  // No need to call setState here as provider should notify relevant widgets
                                }
                              }
                            },
                            itemBuilder:
                                (
                                  BuildContext context,
                                ) => <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'toggle_favorite',
                                    child: FutureBuilder<bool>(
                                      future: libraryProvider.isFavorite(
                                        track.id,
                                      ),
                                      builder: (context, snapshot) {
                                        bool isFav = false;
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.hasData) {
                                          isFav = snapshot.data!;
                                        }
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const ListTile(
                                            leading: Icon(
                                              Icons.hourglass_empty,
                                            ),
                                            title: Text('Loading Favorite...'),
                                          );
                                        }
                                        return ListTile(
                                          leading: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                          ),
                                          title: Text(
                                            isFav
                                                ? 'Remove from Favorites'
                                                : 'Add to Favorites',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove from playlist',
                            onPressed:
                                _isUpdatingPlaylist ||
                                        _isReordering // Disable if reordering
                                    ? null
                                    : () => _removeTrackFromPlaylist(track),
                          ),
                          // Add a drag handle for reordering
                          ReorderableDelayedDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: _playlistTracks.length,
                onReorder: _onReorder,
              ),
        ],
      ),
    );
  }
}
