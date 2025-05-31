import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musify/services/audio_player_service.dart';
import 'package:musify/models/track.dart';
import 'package:musify/screens/album_details_screen.dart'; // For navigation to album details
import 'package:provider/provider.dart'; // Added
import 'package:musify/providers/music_library_provider.dart'; // Added

class ArtistDetailsScreen extends StatefulWidget {
  final ArtistModel artist;

  const ArtistDetailsScreen({super.key, required this.artist});

  @override
  State<ArtistDetailsScreen> createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<AlbumModel> _artistAlbums = [];
  List<SongModel> _artistSongs = []; // All songs by artist, can be many
  bool _isLoadingAlbums = true;
  bool _isLoadingSongs = true;
  String? _errorAlbums;
  String? _errorSongs;

  @override
  void initState() {
    super.initState();
    _fetchArtistAlbums();
    _fetchArtistSongs();
  }

  Future<void> _fetchArtistAlbums() async {
    setState(() {
      _isLoadingAlbums = true;
      _errorAlbums = null;
    });
    try {
      // Fetch all albums first
      List<AlbumModel> allAlbums = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL, // Ensure these parameters are suitable
        ignoreCase: true,
      );
      // Then filter by artist ID. Assuming AlbumModel has artistId.
      // If not, filter by artist name: album.artist == widget.artist.artist
      _artistAlbums =
          allAlbums
              .where((album) => album.artistId == widget.artist.id)
              .toList();
    } catch (e) {
      print('Error fetching artist albums: $e');
      _errorAlbums = 'Failed to load albums.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAlbums = false;
        });
      }
    }
  }

  Future<void> _fetchArtistSongs() async {
    setState(() {
      _isLoadingSongs = true;
      _errorSongs = null;
    });
    try {
      _artistSongs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ARTIST_ID,
        widget.artist.id,
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    } catch (e) {
      print('Error fetching artist songs: $e');
      _errorSongs = 'Failed to load songs.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSongs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.artist.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingAlbums || _isLoadingSongs) {
      return const Center(child: CircularProgressIndicator());
    }

    // Access MusicLibraryProvider here
    final libraryProvider = Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    );

    // Handle errors more gracefully later, for now, just show first error
    if (_errorAlbums != null) {
      return Center(child: Text(_errorAlbums!));
    }
    if (_errorSongs != null) {
      return Center(child: Text(_errorSongs!));
    }

    List<Widget> content = [];

    // Display Artist Info (Art, Name, Stats)
    content.add(
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            QueryArtworkWidget(
              id: widget.artist.id,
              type: ArtworkType.ARTIST,
              nullArtworkWidget: const Icon(Icons.person, size: 60),
              artworkBorder: BorderRadius.circular(30.0),
              artworkHeight: 60,
              artworkWidth: 60,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.artist.artist,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${widget.artist.numberOfAlbums ?? 0} Albums, ${widget.artist.numberOfTracks ?? 0} Songs',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    content.add(const Divider());

    // Albums Section
    if (_artistAlbums.isNotEmpty) {
      content.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Albums', style: Theme.of(context).textTheme.titleLarge),
        ),
      );
      content.add(
        SizedBox(
          height: 180, // Adjust height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _artistAlbums.length,
            itemBuilder: (context, index) {
              final album = _artistAlbums[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailsScreen(album: album),
                    ),
                  );
                },
                child: Container(
                  width: 140, // Adjust width as needed
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: QueryArtworkWidget(
                          id: album.id,
                          type: ArtworkType.ALBUM,
                          nullArtworkWidget: const Icon(Icons.album, size: 100),
                          artworkBorder: BorderRadius.circular(8.0),
                          artworkWidth: double.infinity,
                          artworkHeight: 120,
                          artworkFit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        album.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      content.add(const Divider());
    }

    // All Songs Section (Top Songs / All Songs)
    if (_artistSongs.isNotEmpty) {
      content.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Top Songs',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
      // Using ListView.shrinkWrap and NeverScrollableScrollPhysics because it's inside a SingleChildScrollView (or another ListView)
      // This is generally not recommended for very long lists, but for top songs, it might be acceptable.
      // Consider limiting the number of songs shown or using a more complex layout if performance is an issue.
      content.addAll(
        _artistSongs.take(10).map((songModel) {
          // Show top 10 songs for example
          final track = Track.fromSongModel(songModel);
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
              songModel.album ?? 'Unknown Album',
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
                        _artistSongs
                            .map((s) => Track.fromSongModel(s))
                            .toList();
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
                    // TODO: Add other options like 'Add to playlist'
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
              ],
            ),
            onTap: () async {
              final List<Track> playlistTracks =
                  _artistSongs.map((s) => Track.fromSongModel(s)).toList();
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
          );
        }).toList(),
      );
    }

    if (content.isEmpty ||
        (content.length == 2 &&
            _artistAlbums.isEmpty &&
            _artistSongs.isEmpty)) {
      // Only info and divider
      return const Center(child: Text('No information found for this artist.'));
    }

    return ListView(children: content);
  }
}
