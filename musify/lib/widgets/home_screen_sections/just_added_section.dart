import 'package:flutter/material.dart';
import 'package:musify/models/track.dart';
import 'package:musify/providers/music_library_provider.dart';
import 'package:provider/provider.dart';
import 'package:musify/screens/now_playing_screen.dart';

// Placeholder data removed

class JustAddedSection extends StatelessWidget {
  const JustAddedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicLibraryProvider>(
      builder: (context, libraryProvider, child) {
        final List<Track> justAddedTracks = libraryProvider.justAddedTracks;

        if (justAddedTracks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Just Added',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No new tracks recently added.',
                ), // Or SizedBox.shrink()
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
                'Just Added',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height:
                  180, // Same height as RecentlyPlayedSection for consistency
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: justAddedTracks.length,
                itemBuilder: (context, index) {
                  final track = justAddedTracks[index];
                  return _JustAddedItemCard(track: track);
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

class _JustAddedItemCard extends StatelessWidget {
  final Track track;

  const _JustAddedItemCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    ); // listen: false if only calling methods

    // Use FutureBuilder for isFav status and icon display
    return FutureBuilder<bool>(
      future: libraryProvider.isFavorite(track.id), // Use int ID
      builder: (context, snapshot) {
        bool isFav = false;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          isFav = snapshot.data!;
        }
        // Show a simple placeholder or the content directly if snapshot is not waiting
        // For this card, we can build the UI and let the favorite icon update when future resolves.

        return GestureDetector(
          onTap: () {
            final List<Track> justAddedTracks = libraryProvider.justAddedTracks;
            libraryProvider.playSong(track, queue: justAddedTracks);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NowPlayingScreen(),
                settings: const RouteSettings(name: 'NowPlayingScreen'),
              ),
            );
          },
          onLongPress: () async {
            // Make async to await toggle and then check status
            await libraryProvider.toggleFavorite(track); // Pass track object
            if (context.mounted) {
              // Re-check favorite status AFTER toggling for correct SnackBar message
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
              // No need to call setState here as Provider should handle UI updates for the icon via FutureBuilder
            }
          },
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    // Use Stack to overlay favorite icon
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
                              color: Colors.black.withOpacity(0.5),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
        );
      }, // FutureBuilder builder
    ); // FutureBuilder
  }
}
