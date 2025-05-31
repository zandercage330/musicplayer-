import 'package:flutter/material.dart';
import 'package:musify/models/track.dart';
import 'package:musify/providers/music_library_provider.dart';
import 'package:musify/services/audio_player_service.dart';
import 'package:musify/screens/now_playing_screen.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart'; // For PlayerState

class MiniPlayerWidget extends StatefulWidget {
  const MiniPlayerWidget({super.key});

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    );
    // Listen to current track stream from AudioPlayerService for more direct updates
    return StreamBuilder<Track?>(
      stream: _audioPlayerService.currentTrackStream,
      builder: (context, snapshot) {
        final Track? currentTrack = snapshot.data;
        print(
          '[MiniPlayerWidget] build: currentTrack from stream: ${currentTrack?.title}',
        ); // Log 14

        // If no track, or on NowPlayingScreen, hide the miniplayer
        final ModalRoute<dynamic>? currentRoute = ModalRoute.of(context);
        // It's important that NowPlayingScreen is pushed with settings: RouteSettings(name: 'NowPlayingScreen')
        final bool onNowPlayingScreen =
            currentRoute?.settings.name == 'NowPlayingScreen';
        print(
          '[MiniPlayerWidget] build: onNowPlayingScreen = $onNowPlayingScreen (Route: ${currentRoute?.settings.name})',
        ); // Log 15

        if (currentTrack == null || onNowPlayingScreen) {
          print(
            '[MiniPlayerWidget] Hiding: currentTrack is null or on NowPlayingScreen.',
          ); // Log 16
          return const SizedBox.shrink(); // Hidden
        }

        print(
          '[MiniPlayerWidget] Showing for track: ${currentTrack.title}',
        ); // Log 17
        return Material(
          elevation: 8.0, // Add some shadow
          child: Container(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Bar
                StreamBuilder<Duration>(
                  stream: _audioPlayerService.audioPlayer.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: _audioPlayerService.audioPlayer.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        return LinearProgressIndicator(
                          value:
                              (duration.inMilliseconds > 0)
                                  ? position.inMilliseconds /
                                      duration.inMilliseconds
                                  : 0.0,
                          backgroundColor: Colors.grey[700],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.secondary,
                          ),
                          minHeight: 2.5,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    // Album Art
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4.0),
                        image:
                            currentTrack.albumArt != null
                                ? DecorationImage(
                                  image: MemoryImage(currentTrack.albumArt!),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          currentTrack.albumArt == null
                              ? const Icon(
                                Icons.music_note,
                                color: Colors.grey,
                                size: 30,
                              )
                              : null,
                    ),
                    const SizedBox(width: 12.0),
                    // Track Info
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NowPlayingScreen(),
                              settings: const RouteSettings(
                                name: 'NowPlayingScreen',
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentTrack.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentTrack.artist ?? 'Unknown Artist',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Controls
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayerService.audioPlayer.playerStateStream,
                      builder: (context, playerStateSnapshot) {
                        final playerState = playerStateSnapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing ?? false;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              iconSize: 28.0,
                              onPressed: () {
                                libraryProvider.playPrevious();
                              },
                              tooltip: 'Previous',
                            ),
                            if (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering)
                              const SizedBox(
                                width: 28.0, // IconSize
                                height: 28.0, // IconSize
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    4.0,
                                  ), // Adjust padding to make CircularProgressIndicator smaller
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(
                                  playing ? Icons.pause : Icons.play_arrow,
                                ),
                                iconSize: 28.0,
                                onPressed: () {
                                  if (playing) {
                                    _audioPlayerService.pause();
                                  } else {
                                    _audioPlayerService.play();
                                  }
                                },
                                tooltip: playing ? 'Pause' : 'Play',
                              ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              iconSize: 28.0,
                              onPressed: () {
                                libraryProvider.playNext();
                              },
                              tooltip: 'Next',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
