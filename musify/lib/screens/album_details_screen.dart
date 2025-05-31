import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musify/services/audio_player_service.dart'; // For playback
import 'package:musify/models/track.dart'; // To convert SongModel to Track
import 'package:provider/provider.dart'; // Added for MusicLibraryProvider
import 'package:musify/providers/music_library_provider.dart'; // Added for MusicLibraryProvider

class AlbumDetailsScreen extends StatefulWidget {
  final AlbumModel album;

  const AlbumDetailsScreen({super.key, required this.album});

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _albumSongs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAlbumSongs();
  }

  Future<void> _fetchAlbumSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Query songs specifically for this album ID
      _albumSongs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        widget.album.id,
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    } catch (e) {
      print('Error fetching album songs: $e');
      _error = 'Failed to load songs.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.album.album,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Potentially add album art to app bar later
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchAlbumSongs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_albumSongs.isEmpty) {
      return const Center(child: Text('No songs found in this album.'));
    }

    // Access MusicLibraryProvider here, once
    final libraryProvider = Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    );

    return ListView.builder(
      itemCount: _albumSongs.length,
      itemBuilder: (context, index) {
        final songModel = _albumSongs[index];
        // Convert SongModel to Track if your AudioPlayerService expects Track objects
        // Or if you need fields from your Track model not in SongModel
        final track = Track.fromSongModel(
          songModel,
        ); // Assuming you have this constructor

        return ListTile(
          leading: QueryArtworkWidget(
            id: songModel.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const Icon(Icons.music_note),
            artworkBorder: BorderRadius.circular(4.0),
            artworkHeight: 40,
            artworkWidth: 40,
          ),
          title: Text(
            songModel.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            songModel.artist ?? 'Unknown Artist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Persistent Favorite Icon
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
              // Play Button (existing)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () async {
                  final List<Track> playlistTracks =
                      _albumSongs.map((s) => Track.fromSongModel(s)).toList();
                  int currentTrackIndex = playlistTracks.indexWhere(
                    (t) => t.id == track.id,
                  );
                  if (currentTrackIndex == -1) currentTrackIndex = 0;

                  await AudioPlayerService().loadPlaylist(
                    playlistTracks,
                    initialIndex: currentTrackIndex,
                  );
                  await AudioPlayerService().play();
                },
              ),
              // Favorite Context Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
                onSelected: (String value) async {
                  if (value == 'toggle_favorite') {
                    await libraryProvider.toggleFavorite(track);
                    if (context.mounted) {
                      final bool isNowFavorite = await libraryProvider
                          .isFavorite(track.id);
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
                  }
                  // TODO: Add other options like 'Add to playlist' if needed
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'toggle_favorite',
                        child: FutureBuilder<bool>(
                          future: libraryProvider.isFavorite(track.id),
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
                    ],
              ),
            ],
          ),
          onTap: () {
            final List<Track> playlistTracks =
                _albumSongs.map((s) => Track.fromSongModel(s)).toList();
            int currentTrackIndex = playlistTracks.indexWhere(
              (t) => t.id == track.id,
            );
            if (currentTrackIndex == -1) currentTrackIndex = 0;

            AudioPlayerService().loadPlaylist(
              playlistTracks,
              initialIndex: currentTrackIndex,
            );
            AudioPlayerService().play();
          },
        );
      },
    );
  }
}
