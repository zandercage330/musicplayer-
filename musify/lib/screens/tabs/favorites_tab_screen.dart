import 'package:flutter/material.dart';
import 'package:musify/providers/music_library_provider.dart';
import 'package:musify/widgets/placeholder_content_widget.dart';
import 'package:provider/provider.dart';
import 'package:musify/models/track.dart';
import 'package:musify/screens/now_playing_screen.dart'; // For navigation

class FavoritesTabScreen extends StatelessWidget {
  const FavoritesTabScreen({super.key});

  String _sortTypeToString(FavoriteSortType sortType) {
    switch (sortType) {
      case FavoriteSortType.dateFavoritedDesc:
        return 'Recently Added';
      case FavoriteSortType.dateFavoritedAsc:
        return 'Oldest Added';
      case FavoriteSortType.titleAsc:
        return 'Title (A-Z)';
      case FavoriteSortType.titleDesc:
        return 'Title (Z-A)';
      case FavoriteSortType.artistAsc:
        return 'Artist (A-Z)';
      case FavoriteSortType.artistDesc:
        return 'Artist (Z-A)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          Consumer<MusicLibraryProvider>(
            builder: (context, libraryProvider, child) {
              if (libraryProvider.favoriteTracks.isEmpty) {
                return const SizedBox.shrink(); // Hide buttons if no favorites
              }
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Play All Favorites',
                    onPressed: () {
                      final List<Track> currentFavorites =
                          libraryProvider.favoriteTracks;
                      if (currentFavorites.isNotEmpty) {
                        libraryProvider.playSong(
                          currentFavorites.first,
                          queue: currentFavorites,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NowPlayingScreen(),
                            settings: const RouteSettings(
                              name: 'NowPlayingScreen',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  PopupMenuButton<FavoriteSortType>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort by',
                    initialValue: libraryProvider.currentFavoriteSortType,
                    onSelected: (FavoriteSortType result) {
                      libraryProvider.sortFavoriteTracks(result);
                    },
                    itemBuilder:
                        (BuildContext context) =>
                            FavoriteSortType.values.map((sortType) {
                              return PopupMenuItem<FavoriteSortType>(
                                value: sortType,
                                child: Text(_sortTypeToString(sortType)),
                              );
                            }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MusicLibraryProvider>(
        builder: (context, libraryProvider, child) {
          final List<Track> favoriteTracks = libraryProvider.favoriteTracks;

          if (libraryProvider.isLoading && favoriteTracks.isEmpty) {
            // Show loading indicator only if favorites are empty and still loading library
            // (e.g., initial app load before library/favorites are ready)
            return const Center(child: CircularProgressIndicator());
          }

          if (favoriteTracks.isEmpty) {
            return const PlaceholderContentWidget(
              iconData: Icons.favorite_outline,
              message: 'No Favorites Yet',
              details: 'Tap the heart on any song to add it to your favorites!',
            );
          }

          return ListView.builder(
            itemCount: favoriteTracks.length,
            itemBuilder: (context, index) {
              final track = favoriteTracks[index];
              return Dismissible(
                key: Key(
                  'favorite_track_${track.id}',
                ), // Unique key for Dismissible
                direction:
                    DismissDirection.endToStart, // Swipe from right to left
                onDismissed: (direction) {
                  libraryProvider.toggleFavorite(
                    track,
                  ); // Remove from favorites
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed "${track.title}" from Favorites'),
                      duration: const Duration(seconds: 2),
                      // Optionally add an Undo action
                      /*action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          // This would require adding the track back
                          // libraryProvider.toggleFavorite(track); // Add it back
                        },
                      ),*/
                    ),
                  );
                },
                background: Container(
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading:
                      track.albumArt != null && track.albumArt!.isNotEmpty
                          ? Image.memory(
                            track.albumArt!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.music_note, size: 50),
                          )
                          : const Icon(Icons.music_note, size: 50),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${track.artist ?? 'Unknown Artist'} - ${track.album ?? 'Unknown Album'}'
                        .trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.redAccent),
                    tooltip: 'Remove from Favorites',
                    onPressed: () {
                      libraryProvider.toggleFavorite(track);
                    },
                  ),
                  onTap: () {
                    libraryProvider.playSong(track, queue: favoriteTracks);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NowPlayingScreen(),
                        settings: const RouteSettings(
                          name: 'NowPlayingScreen',
                        ), // Ensure route name
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
