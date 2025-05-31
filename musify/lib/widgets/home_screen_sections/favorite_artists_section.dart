import 'package:flutter/material.dart';

// Placeholder: Using artist names from a mock track list for simplicity
// In a real app, you'd have a dedicated Artist model and data source.
final List<String> _placeholderFavoriteArtists =
    {
      'Artist 1',
      'Future Superstar',
      'Artist 3',
      'Artist 4',
      'Artist 5',
      'Artist 2', // Example artist names
    }.toList(); // Use toSet().toList() to get unique names if source has duplicates

class FavoriteArtistsSection extends StatelessWidget {
  const FavoriteArtistsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> favoriteArtists = _placeholderFavoriteArtists;

    if (favoriteArtists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Your Favorite Artists',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 120, // Adjust height for circular avatars and text
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favoriteArtists.length,
            itemBuilder: (context, index) {
              final artistName = favoriteArtists[index];
              return _FavoriteArtistAvatar(artistName: artistName);
            },
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ),
      ],
    );
  }
}

class _FavoriteArtistAvatar extends StatelessWidget {
  final String artistName;
  // final String? artistImageUrl; // Optional: if you have image URLs

  const _FavoriteArtistAvatar({
    required this.artistName,
    // this.artistImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, // Adjust width for avatar and text
      margin: const EdgeInsets.only(right: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35, // Size of the circular avatar
            backgroundColor: Colors.grey[700], // Placeholder background
            // backgroundImage: artistImageUrl != null && artistImageUrl!.isNotEmpty
            //     ? NetworkImage(artistImageUrl!) // Or AssetImage for local placeholders
            //     : null,
            child: /*artistImageUrl == null || artistImageUrl!.isEmpty
                ?*/ Text(
              artistName.isNotEmpty
                  ? artistName[0].toUpperCase()
                  : '?', // Display initial
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            /*: null,*/
          ),
          const SizedBox(height: 8.0),
          Text(
            artistName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
