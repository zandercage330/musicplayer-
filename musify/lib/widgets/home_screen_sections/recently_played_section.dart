import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:musify/models/track.dart';
import 'package:musify/providers/music_library_provider.dart'; // Import the provider
import 'package:provider/provider.dart'; // Import provider package
import 'package:musify/screens/now_playing_screen.dart'; // Added import

// Placeholder data removed, will use provider
// final List<Track> _placeholderRecentlyPlayed = ... ;

class RecentlyPlayedSection extends StatelessWidget {
  const RecentlyPlayedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicLibraryProvider>(
      builder: (context, libraryProvider, child) {
        final List<Track> recentlyPlayedTracks = libraryProvider.recentlyPlayed;
        // final bool isLoading = libraryProvider.isLoading; // Use if a specific loading for RP exists

        // if (isLoading) { // If there was a specific loading state for recently played
        //   return const Center(child: CircularProgressIndicator());
        // }

        if (recentlyPlayedTracks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recently Played',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('No recently played tracks yet. Play some music!'),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Recently Played',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentlyPlayedTracks.length,
                itemBuilder: (context, index) {
                  final track = recentlyPlayedTracks[index];
                  // TODO: Add onTap to play the track and navigate to NowPlayingScreen
                  return _RecentlyPlayedItemCard(track: track);
                },
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentlyPlayedItemCard extends StatelessWidget {
  final Track track;

  const _RecentlyPlayedItemCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    ); // listen: false if only calling methods

    return FutureBuilder<bool>(
      future: libraryProvider.isFavorite(track.id), // Use int ID
      builder: (context, snapshot) {
        bool isFav = false;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          isFav = snapshot.data!;
        }

        return Material(
          // Added Material for InkWell
          type: MaterialType.transparency, // To ensure ripple is visible
          child: InkWell(
            // Replaced GestureDetector with InkWell
            onTap: () {
              HapticFeedback.mediumImpact(); // Added haptic feedback
              final List<Track> recentlyPlayedQueue =
                  libraryProvider.recentlyPlayed;
              libraryProvider.playSong(track, queue: recentlyPlayedQueue);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NowPlayingScreen(),
                  settings: const RouteSettings(name: 'NowPlayingScreen'),
                ),
              );
            },
            onLongPress: () async {
              HapticFeedback.mediumImpact(); // Added haptic feedback
              await libraryProvider.toggleFavorite(track); // Pass track object
              if (context.mounted) {
                final bool isNowActuallyFavorite = await libraryProvider
                    .isFavorite(track.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isNowActuallyFavorite
                          ? 'Added to Favorites'
                          : 'Removed from Favorites',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8.0), // For ripple shape
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8.0),
                            image:
                                track.albumArt != null
                                    ? DecorationImage(
                                      image: MemoryImage(track.albumArt!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              track.albumArt == null
                                  ? const Center(
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  )
                                  : null,
                        ),
                        if (isFav)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(128),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist ?? 'Unknown Artist',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
