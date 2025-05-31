import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:musify/models/track.dart'; // Assuming Track model
import 'package:musify/providers/music_library_provider.dart'; // Added
import 'package:musify/screens/now_playing_screen.dart'; // Added
import 'package:musify/services/audio_player_service.dart'; // Added for currentTrackStream
import 'package:provider/provider.dart'; // Added

// Placeholder data for a new release track
final Track _placeholderNewRelease = Track(
  id: 100, // Example ID
  filePath: 'placeholder_new_release.mp3',
  title: 'Brand New Hit Single',
  artist: 'Future Superstar',
  album: 'Upcoming Album Sensation',
  // albumArt: null, // Or placeholder Uint8List
  // duration: Duration(minutes: 3, seconds: 15),
);

class NewReleaseSection extends StatelessWidget {
  const NewReleaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Track newReleaseTrack = _placeholderNewRelease;
    final libraryProvider = Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    );
    final audioPlayerService = AudioPlayerService(); // Access singleton

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Release',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Material(
            // Added Material for InkWell splash
            color:
                Colors
                    .transparent, // Ensure Material doesn't obscure underlying color
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                // Create a queue with just this track for now
                // In a real scenario, this might be part of a larger "new releases" queue
                final List<Track> queue = [newReleaseTrack];
                libraryProvider.playSong(newReleaseTrack, queue: queue);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NowPlayingScreen(),
                    settings: const RouteSettings(name: 'NowPlayingScreen'),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(
                12.0,
              ), // Match container's border radius
              splashColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              highlightColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(
                    128,
                  ), // Semi-transparent background
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Art
                    Container(
                      width: 100, // Fixed width for cover art
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[700], // Placeholder color
                        borderRadius: BorderRadius.circular(8.0),
                        image:
                            newReleaseTrack.albumArt != null
                                ? DecorationImage(
                                  image: MemoryImage(newReleaseTrack.albumArt!),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          newReleaseTrack.albumArt == null
                              ? const Center(
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    // Track Info and Actions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween, // Align items vertically
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                newReleaseTrack.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                newReleaseTrack.artist ?? 'Unknown Artist',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[400]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (newReleaseTrack.album != null)
                                Text(
                                  newReleaseTrack.album!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8), // Spacer
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .end, // Align buttons to the right
                            children: [
                              StreamBuilder<Track?>(
                                stream: audioPlayerService.currentTrackStream,
                                builder: (context, snapshot) {
                                  final bool isCurrentlyPlaying =
                                      snapshot.hasData &&
                                      snapshot.data?.id == newReleaseTrack.id;
                                  if (isCurrentlyPlaying) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                      ), // Match IconButton padding roughly
                                      child: Icon(
                                        Icons.equalizer,
                                        color:
                                            Colors
                                                .white70, // Or Theme.of(context).colorScheme.primary
                                        // size: 24, // Default IconButton icon size
                                      ),
                                    );
                                  } else {
                                    return IconButton(
                                      icon: const Icon(
                                        Icons.favorite_border,
                                        color: Colors.white70,
                                      ),
                                      tooltip: 'Like',
                                      onPressed: () {
                                        HapticFeedback.mediumImpact(); // Added haptic feedback
                                        // TODO: Implement like functionality
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Like - Not implemented',
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
