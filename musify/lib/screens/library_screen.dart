import 'package:flutter/material.dart';
import 'package:musify/models/track.dart'; // For Track model
import 'package:musify/providers/music_library_provider.dart';
import 'package:musify/screens/now_playing_screen.dart'; // Import NowPlayingScreen
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:transparent_image/transparent_image.dart'; // Import for kTransparentImage
import 'package:musify/widgets/dialogs/select_playlist_dialog.dart'; // Added
import 'package:musify/widgets/dialogs/playlist_create_edit_dialog.dart'; // Added for direct creation
import 'package:musify/services/playlist_manager.dart'; // Added
import 'package:musify/models/playlist.dart'; // Added
import 'package:musify/screens/settings_screen.dart'; // Added for navigation

const String _kLastSortTypeKey = 'library_last_sort_type';
const String _kLastScrollOffsetKey = 'library_last_scroll_offset';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Added ScrollController

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScrollChanged); // Add listener for scroll
    _loadLastSortType();
    _loadLastScrollPosition(); // Load last scroll position
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScrollChanged); // Remove listener
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  Future<void> _loadLastSortType() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSortTypeName = prefs.getString(_kLastSortTypeKey);
    if (lastSortTypeName != null) {
      try {
        final SortType lastSortType = SortType.values.byName(lastSortTypeName);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<MusicLibraryProvider>(
              context,
              listen: false,
            ).sortTracks(lastSortType);
          }
        });
      } catch (e) {
        print('Error loading last sort type: $e');
      }
    }
  }

  Future<void> _saveLastSortType(SortType sortType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSortTypeKey, sortType.name);
  }

  void _onSearchChanged() {
    Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    ).filterTracks(_searchController.text);
  }

  void _onScrollChanged() {
    // Save scroll position when scrolling ends
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // At the top, do nothing specific unless you want to save '0.0' explicitly
      } else {
        // At the bottom, or if you want to save on any scroll end
      }
    }
    // More robust: save on scroll end notification
    // This basic listener saves on every scroll event, which can be too frequent.
    // A better approach is to use NotificationListener<ScrollNotification> later if needed.
    // For now, let's save when scroll ends (approximately)
    // The current implementation with _scrollController.addListener(_onScrollChanged) will save on every change.
    // Let's refine this to save on ScrollEndNotification or after a debounce.
    // For simplicity in this step, we'll save directly, but acknowledge it's not optimal.
    _saveLastScrollPosition(_scrollController.offset);
  }

  Future<void> _saveLastScrollPosition(double offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLastScrollOffsetKey, offset);
  }

  Future<void> _loadLastScrollPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final double? lastOffset = prefs.getDouble(_kLastScrollOffsetKey);
    if (lastOffset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _scrollController.hasClients &&
            libraryProviderTracksNotEmpty(context)) {
          // Ensure list has items and controller is attached
          _scrollController.jumpTo(lastOffset);
        }
      });
    }
  }

  // Helper to check if libraryProvider.tracks is not empty safely
  bool libraryProviderTracksNotEmpty(BuildContext context) {
    try {
      return Provider.of<MusicLibraryProvider>(
        context,
        listen: false,
      ).tracks.isNotEmpty;
    } catch (e) {
      return false; // Provider not ready or other error
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      } else {
        // Optionally, request focus
      }
    });
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null || milliseconds < 0) return '--:--';
    final int seconds = (milliseconds / 1000).truncate();
    final int minutes = (seconds / 60).truncate();
    final String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    final String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search library...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                )
                : const Text('Library'),
        actions:
            _isSearching
                ? [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSearch,
                    tooltip: 'Close search',
                  ),
                ]
                : [
                  Consumer<MusicLibraryProvider>(
                    builder: (context, libraryProvider, child) {
                      return PopupMenuButton<SortType>(
                        icon: const Icon(Icons.sort),
                        tooltip: 'Sort by',
                        initialValue:
                            libraryProvider
                                .currentSortType, // Reflect current sort
                        onSelected: (SortType result) {
                          libraryProvider.sortTracks(result);
                          _saveLastSortType(result); // Save selected sort type
                        },
                        itemBuilder:
                            (BuildContext context) =>
                                <PopupMenuEntry<SortType>>[
                                  const PopupMenuItem<SortType>(
                                    value: SortType.titleAsc,
                                    child: Text('Title (A-Z)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.titleDesc,
                                    child: Text('Title (Z-A)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.artistAsc,
                                    child: Text('Artist (A-Z)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.artistDesc,
                                    child: Text('Artist (Z-A)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.albumAsc,
                                    child: Text('Album (A-Z)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.albumDesc,
                                    child: Text('Album (Z-A)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.durationAsc,
                                    child: Text('Duration (Shortest)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.durationDesc,
                                    child: Text('Duration (Longest)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.dateAddedAsc,
                                    child: Text('Date Added (Oldest)'),
                                  ),
                                  const PopupMenuItem<SortType>(
                                    value: SortType.dateAddedDesc,
                                    child: Text('Date Added (Newest)'),
                                  ),
                                ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _toggleSearch,
                    tooltip: 'Search',
                  ),
                  PopupMenuButton<String>(
                    // Added Library Options Menu
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Library options',
                    onSelected: (String result) {
                      // Handle selection
                      if (result == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      } else if (result == 'create_playlist') {
                        showDialog<Playlist?>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            // PlaylistCreateEditDialog does not take an onCreate callback.
                            // It handles creation internally and pops with the new Playlist or null.
                            return const PlaylistCreateEditDialog();
                          },
                        ).then((newlyCreatedPlaylist) {
                          if (newlyCreatedPlaylist != null) {
                            // Optionally, refresh playlist display or show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Playlist \'${newlyCreatedPlaylist.name}\' created',
                                ),
                              ),
                            );
                            // Provider.of<PlaylistManager>(context, listen: false) might need to notify listeners if it doesn't already.
                            // Or, if MusicLibraryProvider/PlaylistManager handles playlists, ensure they refresh.
                          }
                        });
                      } else if (result == 'scan_music') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Scan for music selected - Not implemented yet',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$result selected - Not implemented yet',
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'create_playlist',
                            child: ListTile(
                              leading: Icon(Icons.playlist_add),
                              title: Text('Create new playlist'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'scan_music',
                            child: ListTile(
                              leading: Icon(Icons.folder_open),
                              title: Text('Scan for music'),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'settings',
                            child: ListTile(
                              leading: Icon(Icons.settings),
                              title: Text('Settings'),
                            ),
                          ),
                        ],
                  ), // End of Library Options Menu
                ],
      ),
      body: Consumer<MusicLibraryProvider>(
        builder: (context, libraryProvider, child) {
          if (libraryProvider.isLoading && libraryProvider.tracks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (libraryProvider.tracks.isEmpty && !_isSearching) {
            // also check !_isSearching for empty state
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.music_off_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Music Found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan your device for music or check permissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Library'),
                    onPressed: () {
                      libraryProvider.initializeLibrary(
                        context: context,
                        forceRefresh: true,
                      );
                    },
                  ),
                ],
              ),
            );
          } else if (libraryProvider.tracks.isEmpty && _isSearching) {
            return const Center(
              child: Text(
                'No tracks match your search.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh:
                () => libraryProvider.initializeLibrary(
                  context: context,
                  forceRefresh: true,
                ),
            child: ListView.builder(
              controller: _scrollController, // Assign controller to ListView
              itemCount: libraryProvider.tracks.length,
              itemBuilder: (context, index) {
                final track = libraryProvider.tracks[index];
                return _SongListItem(
                  track: track,
                  formatDuration: _formatDuration,
                  onTap: () {
                    libraryProvider.playSong(
                      track,
                      queue: libraryProvider.tracks,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NowPlayingScreen(),
                        settings: const RouteSettings(name: 'NowPlayingScreen'),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SongListItem extends StatelessWidget {
  final Track track;
  final String Function(int?) formatDuration;
  final VoidCallback onTap;

  const _SongListItem({
    required this.track,
    required this.formatDuration,
    required this.onTap,
  });

  Future<void> _addTrackToPlaylist(
    BuildContext context,
    Playlist playlist,
    Track track,
  ) async {
    try {
      await PlaylistManager().addTrackToPlaylist(playlist.id, track.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${track.title}" to "${playlist.name}"'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding track: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showAddToPlaylistDialog(
    BuildContext context,
    Track track,
  ) async {
    final result = await showDialog<dynamic>(
      // Can return Playlist or createNewPlaylistSignal
      context: context,
      builder: (BuildContext dialogContext) {
        return const SelectPlaylistDialog();
      },
    );

    if (result == null) return; // Dialog was cancelled

    if (result == createNewPlaylistSignal) {
      // User wants to create a new playlist
      final newPlaylist = await showDialog<Playlist?>(
        context: context, // Use the original context that can show dialogs
        builder: (BuildContext dialogContext) {
          return const PlaylistCreateEditDialog(); // No playlistToEdit for new one
        },
      );

      if (newPlaylist != null) {
        // If a new playlist was successfully created, add the track to it
        // ignore: use_build_context_synchronously
        await _addTrackToPlaylist(context, newPlaylist, track);
      }
    } else if (result is Playlist) {
      // User selected an existing playlist
      await _addTrackToPlaylist(context, result, track);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(context);

    return ListTile(
      leading:
          track.albumArt != null && track.albumArt!.isNotEmpty
              ? SizedBox(
                width: 50,
                height: 50,
                child: FadeInImage(
                  placeholder: MemoryImage(kTransparentImage),
                  image: MemoryImage(track.albumArt!),
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.music_note,
                      size: 50,
                    ); // Fallback icon
                  },
                ),
              )
              : const Icon(Icons.music_note, size: 50), // Default icon
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        track.artist ?? 'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<bool>(
            future: libraryProvider.isFavorite(track.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data!) {
                return const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Text(formatDuration(track.durationMs)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (String value) async {
              if (value == 'toggle_favorite') {
                await libraryProvider.toggleFavorite(track);
                if (context.mounted) {
                  final bool isNowFavorite = await libraryProvider.isFavorite(
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
                }
              } else if (value == 'add_to_playlist') {
                await _showAddToPlaylistDialog(context, track);
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'toggle_favorite',
                    child: FutureBuilder<bool>(
                      future: libraryProvider.isFavorite(track.id),
                      builder: (context, snapshot) {
                        bool isFav = false;
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          isFav = snapshot.data!;
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            leading: Icon(Icons.hourglass_empty),
                            title: Text('Loading Favorite...'),
                          );
                        }
                        return ListTile(
                          leading: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
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
                  const PopupMenuItem<String>(
                    value: 'add_to_playlist',
                    child: ListTile(
                      leading: Icon(Icons.playlist_add),
                      title: Text('Add to Playlist'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
