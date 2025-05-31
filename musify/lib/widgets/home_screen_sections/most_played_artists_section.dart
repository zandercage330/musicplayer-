import 'package:flutter/material.dart';
import 'package:musify/providers/music_library_provider.dart';
import 'package:musify/screens/artist_detail_screen.dart';
import 'package:provider/provider.dart';

// Placeholder data removed

class MostPlayedArtistsSection extends StatelessWidget {
  const MostPlayedArtistsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicLibraryProvider>(
      builder: (context, libraryProvider, child) {
        final List<MapEntry<String, int>> mostPlayedArtists =
            libraryProvider.mostPlayedArtists;

        if (mostPlayedArtists.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most Played Artists',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Play some music to see your top artists!'),
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
                'Most Played Artists',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mostPlayedArtists.length,
                itemBuilder: (context, index) {
                  final artistEntry = mostPlayedArtists[index];
                  // TODO: Add onTap to navigate to an artist detail page or filter by artist
                  return _MostPlayedArtistAvatar(artistName: artistEntry.key);
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

class _MostPlayedArtistAvatar extends StatelessWidget {
  final String artistName;

  const _MostPlayedArtistAvatar({required this.artistName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: InkWell(
        onTap: () {
          // Navigate to ArtistDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailScreen(artistName: artistName),
            ),
          );

          // The existing filter functionality can be kept or moved to a long-press
          // For now, let's keep it here as well for demonstration, though typically
          // a tap would navigate, and a long-press might offer other options.
          // If the task specifies primary tap for navigation AND long-press for filter,
          // then this part (filtering on simple tap) should be removed or conditional.
          // Based on Task 25 description: "Primary tap: Navigate to the artist's detail page"
          // So, we will remove the direct filtering call from here later or make it part of a different gesture.

          // Provider.of<MusicLibraryProvider>(
          //   context,
          //   listen: false,
          // ).filterTracks(artistName);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       'Tracks filtered by: $artistName. Library tab will show results.',
          //     ),
          //   ),
          // );
        },
        onLongPress: () {
          // Implement filtering on long press as per Task 25 description
          Provider.of<MusicLibraryProvider>(
            context,
            listen: false,
          ).filterTracks(artistName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tracks filtered by: $artistName. Library tab will show results.',
              ),
              duration: const Duration(
                seconds: 2,
              ), // Shorter duration for feedback
            ),
          );
          // TODO: Consider navigating to Library tab after filtering if desired UX
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey[700],
                child: Text(
                  artistName.isNotEmpty ? artistName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                artistName,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
