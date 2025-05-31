import 'package:flutter/material.dart';
import 'package:musify/services/audio_player_service.dart'; // Import the service
import 'package:musify/models/track.dart'; // Import Track model for type safety
import 'dart:async'; // For StreamSubscription
import 'package:just_audio/just_audio.dart'; // For PlayerState and LoopMode
import 'package:musify/widgets/track_details_bottom_sheet.dart'; // Import the bottom sheet
import 'package:provider/provider.dart'; // Added for provider
import 'package:musify/providers/music_library_provider.dart'; // Added for provider

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {
  late final AudioPlayerService _audioPlayerService;
  StreamSubscription? _currentTrackSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _shuffleModeSubscription;
  StreamSubscription? _loopModeSubscription;

  // State variables to hold current values from streams
  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  // For handling seek bar dragging
  bool _isSeeking = false;
  Duration _dragPosition = Duration.zero;

  // For play/pause animation
  late AnimationController _playPauseAnimationController;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = AudioPlayerService(); // Get instance
    print(
      '[NowPlayingScreen] initState: _audioPlayerService.currentTrackValue: ${_audioPlayerService.currentTrackValue?.title}',
    ); // Log NPS 1

    _playPauseAnimationController = AnimationController(
      vsync: this, // Requires TickerProviderStateMixin
      duration: const Duration(milliseconds: 300),
    );

    // Subscribe to streams
    _currentTrackSubscription = _audioPlayerService.currentTrackStream.listen((
      track,
    ) {
      if (mounted) setState(() => _currentTrack = track);
    });

    _playingSubscription = _audioPlayerService.playingStream.listen((
      isPlaying,
    ) {
      if (mounted) {
        setState(() => _isPlaying = isPlaying);
        if (isPlaying) {
          _playPauseAnimationController.forward();
        } else {
          _playPauseAnimationController.reverse();
        }
      }
    });

    _positionSubscription = _audioPlayerService.positionStream.listen((
      position,
    ) {
      if (mounted) setState(() => _currentPosition = position);
    });

    _durationSubscription = _audioPlayerService.durationStream.listen((
      duration,
    ) {
      if (mounted) setState(() => _totalDuration = duration ?? Duration.zero);
    });

    _shuffleModeSubscription = _audioPlayerService.shuffleModeEnabledStream
        .listen((enabled) {
          if (mounted) setState(() => _isShuffleEnabled = enabled);
        });

    _loopModeSubscription = _audioPlayerService.loopModeStream.listen((mode) {
      if (mounted) setState(() => _loopMode = mode);
    });

    // Set initial values from service if available (for BehaviorSubjects)
    // _currentTrack = _audioPlayerService.currentTrackValue; // Removed direct assignment
    print(
      '[NowPlayingScreen] initState: _currentTrack initially set to: ${_currentTrack?.title}',
    ); // Log NPS 2
    _isShuffleEnabled = _audioPlayerService.shuffleModeEnabledValue;
    _loopMode = _audioPlayerService.loopModeValue;
    // _isPlaying and _playPauseAnimationController.value will be set by the playingStream listener shortly after init.
    // Removed attempt to access _audioPlayerService.playingStream.value directly here to avoid type issues.
  }

  @override
  void dispose() {
    _playPauseAnimationController.dispose();
    _currentTrackSubscription?.cancel();
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _shuffleModeSubscription?.cancel();
    _loopModeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      '[NowPlayingScreen] build: _currentTrack: ${_currentTrack?.title}, _isPlaying: $_isPlaying',
    ); // Log NPS 3
    // Using MediaQuery for responsive sizing, though specific values are placeholders for now
    // final screenHeight = MediaQuery.of(context).size.height; // Removed
    // final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF070707), // Dark background from image
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
            vertical: 16.0,
          ), // Adjusted padding
          child:
              _currentTrack == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // Top Navigation Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFFFAFAFA),
                            ), // Icon color
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            tooltip: 'Back',
                          ),
                          Row(
                            // Row for favorite and more options
                            children: [
                              if (_currentTrack !=
                                  null) // Ensure _currentTrack is not null before using its ID
                                Consumer<MusicLibraryProvider>(
                                  builder: (context, libraryProvider, child) {
                                    return FutureBuilder<bool>(
                                      future: libraryProvider.isFavorite(
                                        _currentTrack!.id,
                                      ), // Use int ID
                                      builder: (context, snapshot) {
                                        bool isFav =
                                            false; // Default to not favorite
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.hasData) {
                                          isFav = snapshot.data!;
                                        }
                                        // Show a placeholder or a disabled button during loading if desired
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const IconButton(
                                            icon: Icon(
                                              Icons.favorite_border,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24.0,
                                            tooltip:
                                                'Loading favorite status...',
                                            onPressed:
                                                null, // Disabled while loading
                                          );
                                        }

                                        return IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                isFav
                                                    ? Colors.redAccent
                                                    : const Color(0xFFFAFAFA),
                                          ),
                                          iconSize: 24.0,
                                          onPressed: () {
                                            if (_currentTrack != null) {
                                              // Redundant check, but good practice
                                              libraryProvider.toggleFavorite(
                                                _currentTrack!,
                                              ); // Pass the whole Track object
                                            }
                                          },
                                          tooltip:
                                              isFav
                                                  ? 'Remove from Favorites'
                                                  : 'Add to Favorites',
                                        );
                                      },
                                    );
                                  },
                                ),
                              const SizedBox(
                                width: 8,
                              ), // Spacing between favorite and more_vert
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFFFAFAFA),
                                ), // Icon color
                                onPressed: () {
                                  // _currentTrack will not be null here
                                  _showMoreOptions(context, _currentTrack!);
                                },
                                tooltip: 'More options',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Cover Art
                      Expanded(
                        flex:
                            5, // Adjusted flex, or consider a fixed height/aspectRatio
                        child: Container(
                          // width: screenWidth * 0.75, // Will be constrained by padding now
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                          ), // No extra margin if using padding
                          decoration: BoxDecoration(
                            color:
                                Colors.grey[800], // Darker placeholder for art
                            borderRadius: BorderRadius.circular(
                              32.0,
                            ), // Radius from image
                            image:
                                _currentTrack?.albumArt != null
                                    ? DecorationImage(
                                      image: MemoryImage(
                                        _currentTrack!.albumArt!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              _currentTrack?.albumArt == null
                                  ? const Center(
                                    child: Icon(
                                      Icons.music_note,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Track Title and Artist
                      Column(
                        children: <Widget>[
                          Text(
                            _currentTrack?.title ?? 'Track Title Placeholder',
                            style: const TextStyle(
                              fontFamily: 'Oxygen',
                              fontWeight: FontWeight.w700, // bold
                              fontSize: 32,
                              color: Color(0xFFFAFAFA),
                              height: 1.5, // Line height 150%
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentTrack?.artist ?? 'Artist Name Placeholder',
                            style: TextStyle(
                              fontFamily: 'Oxygen',
                              fontWeight: FontWeight.w400, // regular
                              fontSize: 14,
                              color: const Color(0xFFFAFAFA).withAlpha(153),
                              height: 1.5, // Line height 150%
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress Bar and Time
                      Column(
                        children: [
                          Slider(
                            value:
                                _isSeeking
                                    ? (_dragPosition.inSeconds.toDouble() /
                                            (_totalDuration.inSeconds > 0
                                                ? _totalDuration.inSeconds
                                                    .toDouble()
                                                : 1.0))
                                        .clamp(0.0, 1.0)
                                    : (_totalDuration.inSeconds > 0
                                        ? (_currentPosition.inSeconds
                                                    .toDouble() /
                                                _totalDuration.inSeconds
                                                    .toDouble())
                                            .clamp(0.0, 1.0)
                                        : 0.0),
                            onChangeStart: (value) {
                              if (mounted) {
                                setState(() {
                                  _isSeeking = true;
                                  // Initialize _dragPosition with the slider's current value mapped to duration
                                  _dragPosition = Duration(
                                    seconds:
                                        (value * _totalDuration.inSeconds)
                                            .toInt(),
                                  );
                                });
                              }
                            },
                            onChanged: (value) {
                              if (mounted && _isSeeking) {
                                setState(() {
                                  _dragPosition = Duration(
                                    seconds:
                                        (value * _totalDuration.inSeconds)
                                            .toInt(),
                                  );
                                });
                              }
                            },
                            onChangeEnd: (value) {
                              if (mounted) {
                                final newPosition = Duration(
                                  seconds:
                                      (value * _totalDuration.inSeconds)
                                          .toInt(),
                                );
                                _audioPlayerService.seek(newPosition);
                                setState(() {
                                  _isSeeking = false;
                                });
                              }
                            },
                            min: 0.0,
                            max:
                                1.0, // Slider now represents 0.0 to 1.0 for percentage
                            activeColor: const Color(
                              0xFF34D1BF,
                            ), // Teal/Cyan for active part
                            inactiveColor: const Color(
                              0xFFFFFFFF,
                            ).withAlpha(77), // Softer inactive part
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  _formatDuration(
                                    _isSeeking
                                        ? _dragPosition
                                        : _currentPosition,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFFAFAFA),
                                    fontSize: 12,
                                  ), // Style time text
                                ),
                                Text(
                                  _formatDuration(_totalDuration),
                                  style: const TextStyle(
                                    color: Color(0xFFFAFAFA),
                                    fontSize: 12,
                                  ), // Style time text
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Color(0xFFFAFAFA),
                            ), // Icon color
                            iconSize: 36.0,
                            onPressed: _audioPlayerService.seekToPrevious,
                            tooltip: 'Previous',
                          ),
                          IconButton(
                            icon: AnimatedIcon(
                              icon: AnimatedIcons.play_pause,
                              progress: _playPauseAnimationController,
                              color: const Color(0xFFFAFAFA), // Icon color
                            ),
                            iconSize: 64.0,
                            onPressed: () {
                              if (_isPlaying) {
                                _audioPlayerService.pause();
                              } else {
                                _audioPlayerService.play();
                              }
                            },
                            tooltip: _isPlaying ? 'Pause' : 'Play',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Color(0xFFFAFAFA),
                            ), // Icon color
                            iconSize: 36.0,
                            onPressed: _audioPlayerService.seekToNext,
                            tooltip: 'Next',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Shuffle and Repeat Buttons
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.shuffle),
                              color:
                                  _isShuffleEnabled
                                      ? const Color(
                                        0xFF34D1BF,
                                      ) // Active color from design
                                      : const Color(
                                        0xFFFAFAFA,
                                      ).withAlpha(153), // Inactive color
                              onPressed: () {
                                _audioPlayerService.setShuffleModeEnabled(
                                  !_isShuffleEnabled,
                                );
                              },
                              tooltip: 'Shuffle',
                            ),
                            IconButton(
                              icon: Icon(_getRepeatIcon()),
                              color:
                                  _loopMode != LoopMode.off
                                      ? const Color(
                                        0xFF34D1BF,
                                      ) // Active color from design
                                      : const Color(
                                        0xFFFAFAFA,
                                      ).withAlpha(153), // Inactive color
                              onPressed: _audioPlayerService.cycleLoopMode,
                              tooltip: 'Repeat',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows bottom sheet to take up more height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        // Using a simple menu structure directly in the builder for now
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Track Details'),
                onTap: () {
                  Navigator.pop(bc); // Close the options menu
                  showModalBottomSheet(
                    context:
                        context, // Use the original context for the new bottom sheet
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (BuildContext innerBc) {
                      return TrackDetailsBottomSheet(track: track);
                    },
                  );
                },
              ),
              // TODO: Add other options here (e.g., Add to playlist, Lyrics, etc.)
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist (Placeholder)'),
                onTap: () {
                  Navigator.pop(bc);
                  // TODO: Implement Add to Playlist functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add to Playlist - Not implemented'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  IconData _getRepeatIcon() {
    switch (_loopMode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons
            .repeat_on; // Or Icons.repeat if you prefer it for 'all' too
    }
  }
}
