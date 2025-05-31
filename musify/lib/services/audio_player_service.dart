import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:io'; // Added for File operations
import 'package:just_audio_background/just_audio_background.dart';
import 'package:musify/models/track.dart';
import 'package:path_provider/path_provider.dart'; // Added for temp directory
import 'package:rxdart/rxdart.dart';
import 'package:audio_session/audio_session.dart';
import 'package:musify/utils/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for settings

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  // Make AudioPlayer instance public
  late final AudioPlayer audioPlayer;

  // Custom Stream Subjects (Subtask 6.4)
  final BehaviorSubject<Track?> _currentTrackSubject = BehaviorSubject.seeded(
    null,
  );
  Stream<Track?> get currentTrackStream => _currentTrackSubject.stream;
  Track? get currentTrackValue => _currentTrackSubject.valueOrNull;

  final BehaviorSubject<List<Track>> _playlistSubject = BehaviorSubject.seeded(
    [],
  );
  Stream<List<Track>> get playlistStream => _playlistSubject.stream;
  List<Track> get playlistValue => _playlistSubject.value;

  final BehaviorSubject<bool> _shuffleModeEnabledSubject =
      BehaviorSubject.seeded(false);
  Stream<bool> get shuffleModeEnabledStream =>
      _shuffleModeEnabledSubject.stream;
  bool get shuffleModeEnabledValue => _shuffleModeEnabledSubject.value;

  final BehaviorSubject<LoopMode> _loopModeSubject = BehaviorSubject.seeded(
    LoopMode.off,
  );
  Stream<LoopMode> get loopModeStream => _loopModeSubject.stream;
  LoopMode get loopModeValue => _loopModeSubject.value;

  // Storing the loaded tracks for currentTrackSubject logic
  List<Track> _currentLoadedTracks = [];

  // State for interruption handling (Task 19.2)
  bool _wasPlayingBeforeInterruption = false;

  // User preference for auto-resume (Task 19.3)
  bool _autoResumeAfterInterruption = true; // Default value
  static const String _autoResumeKey = 'audio_auto_resume_preference';

  final BehaviorSubject<bool> _autoResumePreferenceSubject =
      BehaviorSubject.seeded(true);
  Stream<bool> get autoResumePreferenceStream =>
      _autoResumePreferenceSubject.stream;

  // Getter for the current preference value (Task: Profile Screen integration)
  bool get currentAutoResumePreference => _autoResumeAfterInterruption;

  // Cache for converted AudioSources (Task 20.2)
  // Key: track.id, Value: AudioSource. This is a simple in-memory cache.
  // For a more robust solution, consider LRU cache or persistent cache if tracks are numerous.
  final Map<int, AudioSource> _audioSourceCache = {};

  AudioPlayerService._internal() : audioPlayer = AudioPlayer() {
    // Initialize subjects with player's current state
    _shuffleModeEnabledSubject.add(audioPlayer.shuffleModeEnabled);
    _loopModeSubject.add(audioPlayer.loopMode);

    // Listen to player events to update streams (Subtask 6.4)
    audioPlayer.currentIndexStream.listen((index) {
      print('[AudioPlayerService] currentIndexStream listener: index = $index');
      print(
        '[AudioPlayerService] _currentLoadedTracks.length: ${_currentLoadedTracks.length}',
      );
      if (index != null) {
        print('[AudioPlayerService] Condition: index != null is TRUE');
        if (_currentLoadedTracks.isNotEmpty) {
          print(
            '[AudioPlayerService] Condition: _currentLoadedTracks.isNotEmpty is TRUE',
          );
          if (index < _currentLoadedTracks.length) {
            print(
              '[AudioPlayerService] Condition: index < _currentLoadedTracks.length is TRUE (index: $index, length: ${_currentLoadedTracks.length})',
            );
            final track = _currentLoadedTracks[index];
            print(
              '[AudioPlayerService] currentIndexStream: Setting current track to ${track.title} (ID: ${track.id})',
            );
            _currentTrackSubject.add(track);
          } else {
            print(
              '[AudioPlayerService] Condition: index < _currentLoadedTracks.length is FALSE (index: $index, length: ${_currentLoadedTracks.length})',
            );
            _currentTrackSubject.add(null);
          }
        } else {
          print(
            '[AudioPlayerService] Condition: _currentLoadedTracks.isNotEmpty is FALSE',
          );
          _currentTrackSubject.add(null);
        }
      } else {
        print('[AudioPlayerService] Condition: index != null is FALSE');
        _currentTrackSubject.add(null);
      }
    });

    audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      _shuffleModeEnabledSubject.add(enabled);
    });

    audioPlayer.loopModeStream.listen((mode) {
      _loopModeSubject.add(mode);
    });

    // Configure audio session (Subtask 6.5)
    _initAudioSession();
    _loadAutoResumePreference(); // Load preference at init
  }

  Future<void> _loadAutoResumePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoResumeAfterInterruption =
          prefs.getBool(_autoResumeKey) ?? true; // Default to true if not set
      _autoResumePreferenceSubject.add(_autoResumeAfterInterruption);
      print(
        '[AudioPlayerService] Loaded auto-resume preference: $_autoResumeAfterInterruption',
      );
    } catch (e) {
      print('[AudioPlayerService] Error loading auto-resume preference: $e');
      _autoResumeAfterInterruption = true; // Fallback to default
      _autoResumePreferenceSubject.add(true);
    }
  }

  Future<void> setAutoResumePreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoResumeKey, enabled);
      _autoResumeAfterInterruption = enabled;
      _autoResumePreferenceSubject.add(enabled);
      print(
        '[AudioPlayerService] Saved auto-resume preference: $_autoResumeAfterInterruption',
      );
    } catch (e) {
      print('[AudioPlayerService] Error saving auto-resume preference: $e');
    }
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle interruptions (Task 19.1 & 19.2)
      session.interruptionEventStream.listen((AudioInterruptionEvent event) {
        print(
          '[AudioPlayerService] Interruption event: type=${event.type}, begin=${event.begin}',
        );
        if (event.begin) {
          // Interruption begins
          if (audioPlayer.playing) {
            _wasPlayingBeforeInterruption = true;
          } else {
            // If player is already paused (e.g. by user), don't automatically resume later
            _wasPlayingBeforeInterruption = false;
          }

          switch (event.type) {
            case AudioInterruptionType.duck:
              print('[AudioPlayerService] Ducking audio - Pausing for now');
              // Consider a more nuanced ducking like audioPlayer.setVolume(0.2) if app should continue playing softly
              audioPlayer.pause();
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              print('[AudioPlayerService] Pausing audio due to interruption');
              audioPlayer.pause();
              break;
          }
        } else {
          // Interruption ended
          switch (event.type) {
            case AudioInterruptionType.duck:
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              print(
                '[AudioPlayerService] Interruption ended. Type: ${event.type}',
              );
              if (_wasPlayingBeforeInterruption &&
                  _autoResumeAfterInterruption) {
                // Check preference
                print(
                  '[AudioPlayerService] Resuming audio as it was playing before and auto-resume is enabled.',
                );
                audioPlayer.play();
              } else if (_wasPlayingBeforeInterruption &&
                  !_autoResumeAfterInterruption) {
                print(
                  '[AudioPlayerService] Not resuming: auto-resume disabled by user preference.',
                );
              } else {
                print(
                  '[AudioPlayerService] Not resuming audio as it was not playing before or user paused.',
                );
              }
              _wasPlayingBeforeInterruption =
                  false; // Reset state after handling interruption end
              break;
          }
        }
      });

      // Also listen to player state changes to reset _wasPlayingBeforeInterruption if user manually pauses/plays
      audioPlayer.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          _wasPlayingBeforeInterruption =
              false; // Don't resume if track finished
        }
        // If user manually pauses, they likely don't want it to resume from an interruption ending
        if (!playerState.playing) {
          // This might be too aggressive if an interruption itself causes `!playerState.playing`
          // Consider if _wasPlayingBeforeInterruption should only be reset by explicit user actions.
          // For now, let's keep it simple: if it's not playing, it shouldn't auto-resume.
          // This also handles the case where an interruption pauses, then user pauses again.
        } else {
          // If playing (e.g. user hits play), then it *should* continue if an interruption ends.
          // However, this is tricky if an interruption is ALREADY active.
          // The primary control should be the `_wasPlayingBeforeInterruption` flag set AT THE START of an interruption.
        }
      });
    } catch (e, s) {
      ErrorHandler.logError(
        'Error initializing audio session',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> init() async {
    // Initialization logic if any (e.g. for audio_session or other setup)
    // For just_audio_background, main initialization is in main.dart
    print("AudioPlayerService Initialized");
  }

  // --- Core Playback Methods (Subtask 6.2) ---

  Future<void> play() async {
    _wasPlayingBeforeInterruption = false; // User explicitly wants to play
    await audioPlayer.play();
  }

  Future<void> pause() async {
    _wasPlayingBeforeInterruption = false; // User explicitly wants to pause
    await audioPlayer.pause();
  }

  Future<void> stop() async {
    _wasPlayingBeforeInterruption = false; // User explicitly wants to stop
    await audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }

  Future<void> seekToNext() async {
    await audioPlayer.seekToNext();
  }

  Future<void> seekToPrevious() async {
    await audioPlayer.seekToPrevious();
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await audioPlayer.setShuffleModeEnabled(enabled);
  }

  // Cycle through LoopMode: none -> all -> one -> none
  Future<void> cycleLoopMode() async {
    final currentMode = audioPlayer.loopMode;
    if (currentMode == LoopMode.off) {
      await audioPlayer.setLoopMode(LoopMode.all);
    } else if (currentMode == LoopMode.all) {
      await audioPlayer.setLoopMode(LoopMode.one);
    } else {
      await audioPlayer.setLoopMode(LoopMode.off);
    }
  }

  LoopMode get currentLoopMode => audioPlayer.loopMode;
  bool get isShuffleModeEnabled => audioPlayer.shuffleModeEnabled;

  // --- Loading Audio (Subtask 6.3 will enhance this) ---
  // Placeholder for loading a single track.
  // Subtask 6.3 will involve setting up MediaItem for notifications.
  Future<void> loadTrack(
    String trackPathOrUrl, {
    bool isLocal = true,
    required String id,
    required String title,
    String? album,
    String? artist,
    String? artUri,
    Map<String, dynamic>? extras,
    // It's tricky to get the full Track object here if we only have path/id.
    // For now, currentTrackSubject will rely on playlist loads or a separate mechanism.
    // If loadTrack implies a single track playlist, we can update subjects here.
  }) async {
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(isLocal ? 'file://$trackPathOrUrl' : trackPathOrUrl),
        tag: MediaItem(
          id: id,
          album: album ?? "Unknown Album",
          title: title,
          artist: artist ?? "Unknown Artist",
          artUri: artUri != null ? Uri.parse(artUri) : null,
          extras: extras,
        ),
      );
      await audioPlayer.setAudioSource(audioSource);
      // For a single track, we don't have a full Track object easily.
      // We could construct a dummy one or rely on metadata from the player if available.
      // For now, clearing playlist and current track when a single track is loaded this way.
      _currentLoadedTracks = []; // Or create a single Track list if possible
      _playlistSubject.add(_currentLoadedTracks);
      // currentTrackSubject will be updated by currentIndexStream listener (usually to null or first item)
    } catch (e, s) {
      ErrorHandler.logError(
        'Error loading single track: ${isLocal ? trackPathOrUrl : trackPathOrUrl}',
        error: e,
        stackTrace: s,
      );
      // Handle error (e.g., show a message to the user via a different mechanism or rethrow)
    }
  }

  // Placeholder for loading a playlist
  // Future<void> loadPlaylist(List<Track> tracks, {int initialIndex = 0}) async {
  //   // TODO Subtask 6.3: Convert List<Track> to List<AudioSource> with MediaItem tags
  //   // and then use _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: sources...));
  // }

  Future<List<AudioSource>> _convertTracksToAudioSources(
    List<Track> tracks,
    Directory tempDir,
  ) async {
    List<AudioSource> audioSources = [];
    for (var track in tracks) {
      // Check cache first (Task 20.2)
      if (_audioSourceCache.containsKey(track.id)) {
        audioSources.add(_audioSourceCache[track.id]!);
        print(
          '[AudioPlayerService] Used cached AudioSource for track ID: ${track.id}',
        );
        continue;
      }

      Uri? artFileUri;
      if (track.albumArt != null && track.albumArt!.isNotEmpty) {
        try {
          final String fileName =
              'art_${track.id}_${track.albumId ?? "noalbum"}.jpg';
          final File artFile = File('${tempDir.path}/$fileName');
          // TODO: Consider checking if file exists and matches to avoid rewrite
          await artFile.writeAsBytes(track.albumArt!);
          artFileUri = artFile.uri;
        } catch (e, s) {
          ErrorHandler.logError(
            'Error saving album art to temp file for track ${track.id}',
            error: e,
            stackTrace: s,
          );
        }
      }

      final audioSource = AudioSource.uri(
        // Ensure filePath is properly encoded for Uri.file
        // Using Uri.file constructor handles special characters and platform differences.
        Uri.file(track.filePath),
        tag: MediaItem(
          id: track.id.toString(),
          album: track.album ?? "Unknown Album",
          title: track.title,
          artist: track.artist ?? "Unknown Artist",
          genre: track.genre, // Added genre (Task 20.1)
          duration:
              track.durationMs != null && track.durationMs! > 0
                  ? Duration(
                    milliseconds: track.durationMs!,
                  ) // Added duration (Task 20.1)
                  : null,
          artUri: artFileUri,
          extras: {
            // Added extras (Task 20.1)
            'filePath': track.filePath,
            if (track.year != null) 'year': track.year.toString(),
            if (track.dateAdded != null)
              'dateAdded': track.dateAdded.toString(),
          },
        ),
      );
      _audioSourceCache[track.id] =
          audioSource; // Cache the new source (Task 20.2)
      audioSources.add(audioSource);
    }
    return audioSources;
  }

  Future<void> loadPlaylist(List<Track> tracks, {int initialIndex = 0}) async {
    print(
      '[AudioPlayerService] loadPlaylist called with ${tracks.length} tracks, initialIndex: $initialIndex',
    );
    if (tracks.isEmpty) {
      print("[AudioPlayerService] Playlist is empty, not loading.");
      _currentLoadedTracks = [];
      _playlistSubject.add([]);
      _currentTrackSubject.add(null);
      // Clear cache if playlist is empty or new set of tracks significantly differs?
      // For now, individual track caching in _convertTracksToAudioSources handles reuse.
      // _audioSourceCache.clear(); // Optional: Clear cache on empty playlist
      return;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      // Use the refactored conversion method
      final List<AudioSource> audioSources = await _convertTracksToAudioSources(
        tracks,
        tempDir,
      );

      if (audioSources.isEmpty && tracks.isNotEmpty) {
        print(
          "[AudioPlayerService] Conversion resulted in no audio sources, though tracks were provided. Aborting load.",
        );
        // Potentially update UI or log a more specific error that conversion failed for all tracks.
        _currentLoadedTracks = [];
        _playlistSubject.add([]);
        _currentTrackSubject.add(null);
        return;
      }

      final playlist = ConcatenatingAudioSource(
        children: audioSources,
        // Consider adding useLazyPreparation: true for large playlists
      );

      _currentLoadedTracks = List.from(
        tracks,
      ); // Store a copy BEFORE setAudioSource
      _playlistSubject.add(
        _currentLoadedTracks,
      ); // Also update playlist subject here

      await audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
      print('[AudioPlayerService] audioPlayer.setAudioSource completed.');
      // currentTrackSubject will be updated by currentIndexStream listener
      print(
        '[AudioPlayerService] _currentLoadedTracks is now updated, count: ${_currentLoadedTracks.length}',
      );
    } catch (e, s) {
      ErrorHandler.logError('Error loading playlist', error: e, stackTrace: s);
      // Handle error
    }
  }

  // --- Resource Management ---
  void dispose() {
    // TODO: Subtask 6.4: Close stream controllers
    // _playerStateSubject.close();
    // ... close other subjects
    _currentTrackSubject.close();
    _playlistSubject.close();
    _shuffleModeEnabledSubject.close();
    _loopModeSubject.close();
    _autoResumePreferenceSubject.close();
    _audioSourceCache.clear(); // Clear cache on dispose (Task 20.2)

    audioPlayer.dispose();
    print("AudioPlayerService Disposed");
  }

  // --- Stream Getters (Subtask 6.4) ---
  Stream<PlayerState> get playerStateStream => audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => audioPlayer.durationStream;
  Stream<Duration> get positionStream => audioPlayer.positionStream;
  Stream<int?> get currentIndexStream => audioPlayer.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream =>
      audioPlayer.sequenceStateStream;
  Stream<bool> get playingStream => audioPlayer.playingStream;
}
