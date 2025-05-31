import 'dart:convert'; // For jsonEncode/Decode
import 'package:shared_preferences/shared_preferences.dart'; // Restored for other functionalities
import 'package:musify/models/track.dart'; // Or your Song model if you decide to switch
import 'package:musify/services/music_scanner_service.dart';
import 'package:musify/services/audio_player_service.dart'; // Added import
import 'package:musify/utils/error_handler.dart'; // Added ErrorHandler
import 'package:flutter/material.dart'; // Added for BuildContext

// NEW IMPORTS for Drift database and FavoriteTrack model
import 'package:musify/data/database.dart';
import 'package:musify/models/favorite_track.dart' as model_favorite_track;
import 'package:musify/repositories/favorites_repository.dart';
import 'package:musify/models/playlist.dart'; // Import Playlist model

// FavoriteEntry is no longer needed as we'll use model_favorite_track.FavoriteTrack
// // Define a simple structure for storing favorite entry
// class FavoriteEntry {
//   final String trackId;
//   final int timestampAdded;
//
//   FavoriteEntry({required this.trackId, required this.timestampAdded});
//
//   Map<String, dynamic> toJson() => {
//     'trackId': trackId,
//     'timestamp': timestampAdded,
//   };
//
//   factory FavoriteEntry.fromJson(Map<String, dynamic> json) => FavoriteEntry(
//     trackId: json['trackId'] as String,
//     timestampAdded: json['timestamp'] as int,
//   );
// }

enum SortType {
  titleAsc,
  titleDesc,
  artistAsc,
  artistDesc,
  albumAsc,
  albumDesc,
  durationAsc,
  durationDesc,
  dateAddedAsc,
  dateAddedDesc,
  playCountDesc, // For most played artists
}

// Enum for sorting favorites
enum FavoriteSortType {
  dateFavoritedDesc, // Default: Most recently favorited
  dateFavoritedAsc,
  titleAsc,
  titleDesc,
  artistAsc,
  artistDesc,
}

class MusicLibraryProvider with ChangeNotifier {
  final MusicScannerService _scannerService = MusicScannerService();
  final AudioPlayerService _audioPlayerService =
      AudioPlayerService(); // Added instance

  // NEW: Database and Repository instances
  late AppDatabase _appDatabase;
  late FavoritesRepository _favoritesRepository;

  List<Track> _tracks = [];
  List<Track> _originalTracks =
      []; // For restoring after search filter is cleared
  SortType _currentSortType =
      SortType.dateAddedDesc; // Default sort for main library
  static const String _kLastSortTypeKey =
      'library_last_sort_type'; // Key for main library sort

  bool _isLoading = false;
  String _loadingMessage = '';
  ScanProgress _scanProgress = ScanProgress(
    processedCount: 0,
    totalCount: 0,
    currentFilePath: '',
    statusMessage: 'Initializing...',
  );

  List<Track> _recentlyPlayed = [];
  static const String _recentlyPlayedKey = 'recently_played_tracks_v1';
  static const int _maxRecentlyPlayed = 20;

  Map<String, int> _artistPlayCounts = {};
  static const String _artistPlayCountsKey = 'artist_play_counts_v1';

  Track? _currentlyPlayingSong;
  List<Track> _playQueue = [];
  int _currentQueueIndex = -1;

  // --- For Favorites (Task 16) ---
  // OLD: List<FavoriteEntry> _favorites = [];
  // OLD: static const String _favoritesKey = 'favorite_tracks_v1'; // No longer using SharedPreferences for this

  // NEW: Using the model from FavoriteTrack.dart and fetched from repository
  List<model_favorite_track.FavoriteTrack> _dbFavorites = [];
  List<Track> _detailedFavoriteTracks =
      []; // To store full Track objects for favorites

  FavoriteSortType _currentFavoriteSortType =
      FavoriteSortType.dateFavoritedDesc; // Default sort
  // Key for favorite sort type can remain if you still want to save user's sort preference locally
  static const String _kLastFavoriteSortTypeKey =
      'library_last_favorite_sort_type';

  // --- For Playlists ---
  List<Playlist> _playlists = []; // In-memory list for playlists
  static const String _playlistsKey =
      'user_playlists_v1'; // Key for SharedPreferences
  // --- End Playlists ---

  List<Track> get tracks => _tracks;
  SortType get currentSortType => _currentSortType;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  ScanProgress get scanProgress => _scanProgress;
  List<Track> get recentlyPlayed => _recentlyPlayed;
  Map<String, int> get artistPlayCounts => _artistPlayCounts;
  Track? get currentlyPlayingSong => _currentlyPlayingSong;
  List<Track> get playQueue => _playQueue;
  int get currentQueueIndex => _currentQueueIndex;

  // --- Getter for Playlists ---
  List<Playlist> get playlists => _playlists;
  // --- End Getter for Playlists ---

  // --- Getter for Just Added Tracks ---
  List<Track> get justAddedTracks {
    // Use _originalTracks to ensure we're looking at the complete library
    // not a potentially filtered list like _tracks.
    List<Track> sortedByDate = List.from(_originalTracks);
    // Sort by dateAdded, newest first. Handle null dates by placing them last.
    sortedByDate.sort((a, b) {
      if (a.dateAdded == null && b.dateAdded == null) return 0;
      if (a.dateAdded == null) return 1; // a is null, b is not, b comes first
      if (b.dateAdded == null) return -1; // b is null, a is not, a comes first
      return b.dateAdded!.compareTo(a.dateAdded!); // Both not null, compare
    });
    // Return the top N tracks, e.g., top 10
    return sortedByDate.take(10).toList();
  }
  // --- End Getter for Just Added Tracks ---

  // --- Getter for Most Played Artists ---
  List<MapEntry<String, int>> get mostPlayedArtists {
    if (_artistPlayCounts.isEmpty) return [];

    List<MapEntry<String, int>> sortedArtists =
        _artistPlayCounts.entries.toList();

    // Sort by play count (value) in descending order
    // If play counts are equal, sort by artist name (key) in ascending order for consistent results
    sortedArtists.sort((a, b) {
      int playCountCompare = b.value.compareTo(
        a.value,
      ); // Descending for play count
      if (playCountCompare == 0) {
        return a.key.toLowerCase().compareTo(
          b.key.toLowerCase(),
        ); // Ascending for artist name
      }
      return playCountCompare;
    });

    // Return the top N artists, e.g., top 10
    return sortedArtists.take(10).toList();
  }
  // --- End Getter for Most Played Artists ---

  // --- Getter for Tracks by a specific artist (Task 25.2) ---
  List<Track> getTracksByArtist(String artistName) {
    if (artistName.isEmpty) return [];
    return _originalTracks
        .where(
          (track) =>
              track.artist != null &&
              track.artist!.toLowerCase() == artistName.toLowerCase(),
        )
        .toList();
  }
  // --- End Getter for Tracks by a specific artist ---

  MusicLibraryProvider() {
    // Initialize database and repository here or in an async init method
    _appDatabase =
        AppDatabase(); // Assuming AppDatabase has a default constructor
    _favoritesRepository = FavoritesRepository(_appDatabase);

    _loadRecentlyPlayed();
    _loadArtistPlayCounts();
    _loadFavorites(); // Load favorites on initialization (now from DB)
    _loadPlaylists(); // Load playlists on initialization
    _scannerService.scanProgressStream.listen((progress) {
      _isLoading = true; // Or set based on specific progress messages
      _loadingMessage = progress.statusMessage;
      _scanProgress = progress;
      if (progress.statusMessage == "Scan complete" ||
          progress.statusMessage == "Loaded from cache" ||
          progress.statusMessage == "No audio files found." ||
          progress.statusMessage == "Permissions not granted") {
        _isLoading = false;
      }
      notifyListeners();
    });
  }

  Future<void> initializeLibrary({
    required BuildContext context,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _loadingMessage = "Initializing library...";
    notifyListeners(); // Notify at the beginning of loading state change
    try {
      // Ensure DB and repo are initialized if not done in constructor (e.g. if they are async)
      // If AppDatabase() or FavoritesRepository() were async, you'd await them here or in a dedicated init.

      _tracks = await _scannerService.getTracks(forceRefresh: forceRefresh);
      _originalTracks = List.from(_tracks);
      await _loadSortType(); // Load and apply sort for main library
      await _loadRecentlyPlayed();
      await _loadArtistPlayCounts();
      await _loadFavorites(); // Now loads from DB via repository
      await _loadPlaylists(); // Load playlists

      if (_tracks.isEmpty && !forceRefresh) {
        // Attempt a scan if library is empty and not explicitly refreshing an empty lib
        _loadingMessage = "No tracks found. Scanning device...";
        notifyListeners();
        _tracks = await _scannerService.getTracks(forceRefresh: true);
        _originalTracks = List.from(_tracks);
        await _loadSortType(); // Re-apply sort after scan
      }
      print(
        '[MusicLibraryProvider] Library initialized with ${_tracks.length} tracks.',
      );
    } catch (e, s) {
      ErrorHandler.handleError(
        context,
        logMessage: 'Failed to initialize music library',
        userMessage: 'Could not load music. Please try again.',
        error: e,
        stackTrace: s,
      );
      _tracks = [];
      _originalTracks = [];
    }
    _isLoading = false;
    _loadingMessage = ''; // Clear loading message
    notifyListeners();
  }

  // void _setLoadingState(bool loading, [String message = '']) {
  //   _isLoading = loading;
  //   _loadingMessage = message;
  //   notifyListeners();
  // }

  @override
  void dispose() {
    _scannerService.dispose(); // Dispose the stream controller in the service
    super.dispose();
  }

  // Placeholder for other states and methods to be added in subsequent subtasks:
  // List<Track> _recentlyPlayed = [];
  // Track? _currentlyPlaying;
  // List<Track> _playQueue = [];

  // Methods for sorting, filtering, managing play queue, etc.

  // --- Core Methods for Subtask 5.3 ---

  void playSong(Track song, {List<Track>? queue}) {
    print('[MusicLibraryProvider] playSong called for: ${song.title}');
    _currentlyPlayingSong = song;
    if (queue != null && queue.isNotEmpty) {
      _playQueue = List.from(queue);
      _currentQueueIndex = _playQueue.indexWhere((t) => t.id == song.id);
      print(
        '[MusicLibraryProvider] Queue set with ${queue.length} songs. Current index: $_currentQueueIndex',
      );
    } else {
      _playQueue = [song];
      _currentQueueIndex = 0;
      print(
        '[MusicLibraryProvider] Queue set with 1 song (current). Current index: $_currentQueueIndex',
      );
    }
    addToRecentlyPlayed(song);
    _incrementArtistPlayCount(song.artist);

    if (_playQueue.isNotEmpty && _currentQueueIndex != -1) {
      print(
        '[MusicLibraryProvider] Calling _audioPlayerService.loadPlaylist and .play()',
      );
      _audioPlayerService.loadPlaylist(
        _playQueue,
        initialIndex: _currentQueueIndex,
      );
      _audioPlayerService.play();
    } else {
      print(
        '[MusicLibraryProvider] Condition to play not met. Queue empty or index -1.',
      );
    }
    notifyListeners();
  }

  void setPlayQueue(List<Track> newQueue, {Track? initialSong}) {
    if (newQueue.isEmpty) {
      clearPlayQueue();
      return;
    }
    _playQueue = List.from(newQueue);
    if (initialSong != null) {
      _currentQueueIndex = _playQueue.indexWhere((t) => t.id == initialSong.id);
      if (_currentQueueIndex != -1) {
        _currentlyPlayingSong = _playQueue[_currentQueueIndex];
        addToRecentlyPlayed(_currentlyPlayingSong!);
        _incrementArtistPlayCount(_currentlyPlayingSong!.artist);
      } else {
        _currentQueueIndex = 0;
        _currentlyPlayingSong = _playQueue[_currentQueueIndex];
        addToRecentlyPlayed(_currentlyPlayingSong!);
        _incrementArtistPlayCount(_currentlyPlayingSong!.artist);
      }
    } else {
      _currentQueueIndex = 0;
      _currentlyPlayingSong = _playQueue[_currentQueueIndex];
      addToRecentlyPlayed(_currentlyPlayingSong!);
      _incrementArtistPlayCount(_currentlyPlayingSong!.artist);
    }
    notifyListeners();
  }

  bool playNext() {
    if (_playQueue.isEmpty || _currentQueueIndex == -1) return false;
    if (_currentQueueIndex < _playQueue.length - 1) {
      _currentQueueIndex++;
      _currentlyPlayingSong = _playQueue[_currentQueueIndex];
      addToRecentlyPlayed(_currentlyPlayingSong!);
      _incrementArtistPlayCount(_currentlyPlayingSong!.artist);
      _audioPlayerService.seekToNext();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool playPrevious() {
    if (_playQueue.isEmpty || _currentQueueIndex == -1) return false;
    if (_currentQueueIndex > 0) {
      _currentQueueIndex--;
      _currentlyPlayingSong = _playQueue[_currentQueueIndex];
      addToRecentlyPlayed(_currentlyPlayingSong!);
      _incrementArtistPlayCount(_currentlyPlayingSong!.artist);
      _audioPlayerService.seekToPrevious();
      notifyListeners();
      return true;
    }
    return false;
  }

  void addToQueue(Track track) {
    // Avoid duplicates if track is already in queue by ID
    if (!_playQueue.any((t) => t.id == track.id)) {
      _playQueue.add(track);
      notifyListeners();
    }
  }

  void removeFromQueue(Track track) {
    int indexToRemove = _playQueue.indexWhere((t) => t.id == track.id);
    if (indexToRemove != -1) {
      _playQueue.removeAt(indexToRemove);
      if (_playQueue.isEmpty) {
        _currentlyPlayingSong = null;
        _currentQueueIndex = -1;
      } else if (indexToRemove == _currentQueueIndex) {
        // If the currently playing song was removed
        if (_currentQueueIndex >= _playQueue.length) {
          // If it was the last song, move to the new last song
          _currentQueueIndex = _playQueue.length - 1;
        }
        // If queue is not empty, _playQueue[_currentQueueIndex] will be the new current song
        _currentlyPlayingSong = _playQueue[_currentQueueIndex];
      } else if (indexToRemove < _currentQueueIndex) {
        _currentQueueIndex--; // Adjust index if an earlier song was removed
      }
      notifyListeners();
    }
  }

  void clearPlayQueue() {
    _playQueue = [];
    _currentlyPlayingSong =
        null; // Optionally clear current song or let it finish
    _currentQueueIndex = -1;
    notifyListeners();
  }

  void addToRecentlyPlayed(Track track) {
    // Remove if already present to move it to the top (most recent)
    _recentlyPlayed.removeWhere((t) => t.id == track.id);
    _recentlyPlayed.insert(0, track);
    // Optional: Limit the size of recently played list
    if (_recentlyPlayed.length > _maxRecentlyPlayed) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, _maxRecentlyPlayed);
    }
    _saveRecentlyPlayed(); // Save after modification
    notifyListeners();
  }

  // --- Persistence for Recently Played (Subtask 5.4) ---
  Future<void> _saveRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> recentlyPlayedJson =
          _recentlyPlayed.map((track) => jsonEncode(track.toJson())).toList();
      await prefs.setStringList(_recentlyPlayedKey, recentlyPlayedJson);
    } catch (e, s) {
      ErrorHandler.logError(
        'Error saving recently played tracks',
        error: e,
        stackTrace: s,
      );
      // Optionally, notify UI or log to a more robust system
    }
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? recentlyPlayedJson = prefs.getStringList(
        _recentlyPlayedKey,
      );
      if (recentlyPlayedJson != null) {
        _recentlyPlayed =
            recentlyPlayedJson
                .map((jsonString) {
                  try {
                    return Track.fromJson(
                      jsonDecode(jsonString) as Map<String, dynamic>,
                    );
                  } catch (e) {
                    print(
                      "Error decoding a recently played track: $e. Skipping item.",
                    );
                    return null; // Return null for items that fail to decode
                  }
                })
                .where((track) => track != null)
                .cast<Track>()
                .toList(); // Filter out nulls and cast
        notifyListeners(); // Update UI if tracks were loaded
      }
    } catch (e, s) {
      ErrorHandler.logError(
        'Error loading recently played tracks',
        error: e,
        stackTrace: s,
      );
      _recentlyPlayed = []; // Ensure a clean state on error
      // Optionally, notify UI or log
    }
  }
  // --- End of Persistence ---

  // --- Persistence for Artist Play Counts (Subtask 8.5.3) ---
  Future<void> _saveArtistPlayCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // SharedPreferences doesn't directly support Map<String, int>.
      // So, convert to JSON string or two lists (keys, values).
      // Using JSON string for simplicity here.
      String jsonMap = jsonEncode(_artistPlayCounts);
      await prefs.setString(_artistPlayCountsKey, jsonMap);
    } catch (e, s) {
      ErrorHandler.logError(
        'Error saving artist play counts',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _loadArtistPlayCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonMap = prefs.getString(_artistPlayCountsKey);
      if (jsonMap != null) {
        Map<String, dynamic> decodedMap = jsonDecode(jsonMap);
        _artistPlayCounts = decodedMap.map(
          (key, value) => MapEntry(key, value as int),
        );
      }
    } catch (e, s) {
      ErrorHandler.logError(
        'Error loading artist play counts',
        error: e,
        stackTrace: s,
      );
      _artistPlayCounts = {}; // Reset on error
    }
    notifyListeners(); // Notify even if loaded empty or error, to update UI if needed
  }

  Future<void> clearRecentlyPlayed() async {
    _recentlyPlayed = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentlyPlayedKey);
    print('[MusicLibraryProvider] Recently Played cleared.');
    notifyListeners();
  }

  void _incrementArtistPlayCount(String? artistName) {
    if (artistName == null || artistName.trim().isEmpty) return;
    _artistPlayCounts.update(
      artistName,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    _saveArtistPlayCounts(); // Save after each increment
    // notifyListeners(); // PlaySong and others already notify. Could notify if this was called independently.
  }

  // --- End of Core Methods for Subtask 5.3 ---

  // --- Sorting for Main Library ---
  void sortTracks(SortType sortType) {
    _currentSortType = sortType;
    switch (sortType) {
      case SortType.titleAsc:
        _tracks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortType.titleDesc:
        _tracks.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SortType.artistAsc:
        _tracks.sort(
          (a, b) => (a.artist ?? 'zzzz').toLowerCase().compareTo(
            (b.artist ?? 'zzzz').toLowerCase(),
          ),
        );
        break;
      case SortType.artistDesc:
        _tracks.sort(
          (a, b) => (b.artist ?? 'zzzz').toLowerCase().compareTo(
            (a.artist ?? 'zzzz').toLowerCase(),
          ),
        );
        break;
      case SortType.albumAsc:
        _tracks.sort(
          (a, b) => (a.album ?? 'zzzz').toLowerCase().compareTo(
            (b.album ?? 'zzzz').toLowerCase(),
          ),
        );
        break;
      case SortType.albumDesc:
        _tracks.sort(
          (a, b) => (b.album ?? 'zzzz').toLowerCase().compareTo(
            (a.album ?? 'zzzz').toLowerCase(),
          ),
        );
        break;
      case SortType.durationAsc:
        _tracks.sort(
          (a, b) => (a.durationMs ?? 0).compareTo(b.durationMs ?? 0),
        );
        break;
      case SortType.durationDesc:
        _tracks.sort(
          (a, b) => (b.durationMs ?? 0).compareTo(a.durationMs ?? 0),
        );
        break;
      case SortType.dateAddedAsc:
        _tracks.sort((a, b) => (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0));
        break;
      case SortType.dateAddedDesc:
        _tracks.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
      case SortType.playCountDesc:
        print(
          '[MusicLibraryProvider] SortType.playCountDesc for tracks is not fully implemented, sorting by title instead.',
        );
        _tracks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
    }
    _saveSortType(); // Correct: This calls the existing _saveSortType for main library
    notifyListeners();
  }

  Future<void> _loadSortType() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSortTypeName = prefs.getString(_kLastSortTypeKey);
    if (lastSortTypeName != null) {
      try {
        _currentSortType = SortType.values.byName(lastSortTypeName);
      } catch (e) {
        ErrorHandler.logError('Error loading last sort type for library: $e');
        _currentSortType = SortType.dateAddedDesc;
      }
    }
    // Apply sort after loading, only if tracks exist and sort type is not default (or to ensure default is applied)
    if (_tracks.isNotEmpty) {
      sortTracks(_currentSortType); // This will notify listeners
    } else {
      notifyListeners(); // Still notify if tracks are empty but sort type might have changed
    }
  }

  Future<void> _saveSortType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSortTypeKey, _currentSortType.name);
  }

  void filterTracks(String query) {
    if (query.isEmpty) {
      _tracks = List.from(_originalTracks); // Reset to sorted original list
    } else {
      final lowerQuery = query.toLowerCase();
      _tracks =
          _originalTracks.where((track) {
            return (track.title.toLowerCase().contains(lowerQuery)) ||
                (track.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
                (track.album?.toLowerCase().contains(lowerQuery) ?? false);
          }).toList();
      // Re-apply current sort to the filtered list to maintain consistency
      // This step is optional if the _originalTracks is always kept sorted
      // sortTracks(_currentSortType); // if _originalTracks wasn't sorted, or sort the filtered subset
    }
    notifyListeners();
  }

  // --- End of Sorting and Filtering ---

  // --- Favorites Methods (Task 16) ---

  // NEW getter for favorite tracks, now using _detailedFavoriteTracks
  List<Track> get favoriteTracks {
    _sortDetailedFavoriteTracks(); // Apply current sort before returning
    return _detailedFavoriteTracks;
  }

  FavoriteSortType get currentFavoriteSortType => _currentFavoriteSortType;

  // Helper to fetch full Track details for a list of FavoriteTrack entries
  Future<List<Track>> _fetchTrackDetailsForFavorites(
    List<model_favorite_track.FavoriteTrack> favEntries,
  ) async {
    if (favEntries.isEmpty) return [];
    if (_originalTracks.isEmpty) {
      // Ensure main library is loaded, this might need better handling
      // if initializeLibrary hasn't run or completed.
      print(
        "[MusicLibraryProvider] Warning: _originalTracks is empty while fetching favorite details.",
      );
      // Consider awaiting initializeLibrary or a part of it if this happens.
      // For now, returning empty to avoid errors, but this indicates a potential state issue.
      // You might need to call `await initializeLibrary(...)` if _originalTracks is empty.
      // However, be careful of recursive calls if _loadFavorites itself calls this.
      // A flag like `_isLibraryInitialized` could help.
      return [];
    }

    final Set<int> favoriteTrackIds =
        favEntries.map((fe) => fe.trackId).toSet();
    return _originalTracks
        .where((track) => favoriteTrackIds.contains(track.id))
        .toList();
  }

  // Refactored sorting to work with _detailedFavoriteTracks and _dbFavorites for timestamps
  void _sortDetailedFavoriteTracks() {
    if (_detailedFavoriteTracks.isEmpty) return;

    // Create a map of trackId to FavoriteTrack for easy timestamp lookup
    final Map<int, model_favorite_track.FavoriteTrack> dbFavoritesMap = {
      for (var fav in _dbFavorites) fav.trackId: fav,
    };

    switch (_currentFavoriteSortType) {
      case FavoriteSortType.dateFavoritedDesc:
        _detailedFavoriteTracks.sort((a, b) {
          final favA = dbFavoritesMap[a.id];
          final favB = dbFavoritesMap[b.id];
          return (favB?.dateFavorited ?? DateTime(0)).compareTo(
            favA?.dateFavorited ?? DateTime(0),
          );
        });
        break;
      case FavoriteSortType.dateFavoritedAsc:
        _detailedFavoriteTracks.sort((a, b) {
          final favA = dbFavoritesMap[a.id];
          final favB = dbFavoritesMap[b.id];
          return (favA?.dateFavorited ?? DateTime(0)).compareTo(
            favB?.dateFavorited ?? DateTime(0),
          );
        });
        break;
      case FavoriteSortType.titleAsc:
        _detailedFavoriteTracks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case FavoriteSortType.titleDesc:
        _detailedFavoriteTracks.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case FavoriteSortType.artistAsc:
        _detailedFavoriteTracks.sort(
          (a, b) => (a.artist ?? 'zzzz').toLowerCase().compareTo(
            (b.artist ?? 'zzzz').toLowerCase(),
          ),
        );
        break;
      case FavoriteSortType.artistDesc:
        _detailedFavoriteTracks.sort(
          (a, b) => (b.artist ?? 'zzzz').toLowerCase().compareTo(
            (a.artist ?? 'zzzz').toLowerCase(),
          ),
        );
        break;
    }
  }

  void sortFavoriteTracks(FavoriteSortType sortType) {
    _currentFavoriteSortType = sortType;
    _saveLastFavoriteSortType(sortType); // Save preference
    _sortDetailedFavoriteTracks(); // Apply sort to the detailed list
    notifyListeners();
  }

  Future<void> _loadLastFavoriteSortType() async {
    // This method can remain as is, using SharedPreferences for user preference
    final prefs = await SharedPreferences.getInstance();
    final String? lastSortTypeName = prefs.getString(_kLastFavoriteSortTypeKey);
    if (lastSortTypeName != null) {
      try {
        _currentFavoriteSortType = FavoriteSortType.values.byName(
          lastSortTypeName,
        );
      } catch (e) {
        ErrorHandler.logError('Error loading last favorite sort type: $e');
        _currentFavoriteSortType = FavoriteSortType.dateFavoritedDesc;
      }
    }
  }

  Future<void> _saveLastFavoriteSortType(FavoriteSortType sortType) async {
    // This method can remain as is
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastFavoriteSortTypeKey, sortType.name);
  }

  // Uses repository now
  Future<bool> isFavorite(int trackId) async {
    // Check against the local _dbFavorites list first for responsiveness,
    // but the source of truth is the repository.
    // For consistency, always query the repository or ensure _dbFavorites is perfectly synced.
    return await _favoritesRepository.isFavorite(trackId);
  }

  // Uses repository now
  Future<void> toggleFavorite(Track track) async {
    final isCurrentlyFavorite = await _favoritesRepository.isFavorite(track.id);
    if (isCurrentlyFavorite) {
      await _favoritesRepository.removeFavorite(track.id);
    } else {
      // Note: FavoritesRepository.addFavorite expects a model_track.Track.
      // If your 'track' parameter here is already of that type, great.
      // If it's a different Track model, ensure conversion or adjust repository.
      // Assuming 'track' is compatible or FavoritesRepository handles it.
      await _favoritesRepository.addFavorite(track);
    }
    await _loadFavorites(); // Reload from DB to update local state and UI
    // notifyListeners(); // _loadFavorites will call notifyListeners
  }

  // Uses repository now
  Future<void> _loadFavorites() async {
    try {
      _dbFavorites =
          await _appDatabase.getAllFavoriteTracks(); // Directly from DB
      _detailedFavoriteTracks = await _fetchTrackDetailsForFavorites(
        _dbFavorites,
      );
      await _loadLastFavoriteSortType(); // Load sort preference
      _sortDetailedFavoriteTracks(); // Apply sort
    } catch (e, s) {
      ErrorHandler.logError(
        'Error loading favorites from database: $e',
        error: e,
        stackTrace: s,
      );
      _dbFavorites = [];
      _detailedFavoriteTracks = [];
    }
    notifyListeners();
  }

  // _saveFavorites is no longer needed as persistence is handled by FavoritesRepository/Drift.
  // Future<void> _saveFavorites() async {
  //   // final prefs = await SharedPreferences.getInstance();
  //   // final String favoritesJson = jsonEncode(
  //   //   _favorites.map((fav) => fav.toJson()).toList(),
  //   // );
  //   // await prefs.setString(_favoritesKey, favoritesJson);
  // }

  // --- End Favorites Methods ---

  // --- Playlist Methods ---
  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsJson = prefs.getString(_playlistsKey);
    if (playlistsJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(playlistsJson);
        _playlists =
            decodedList
                .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
                .toList();
      } catch (e) {
        print('Error decoding playlists from SharedPreferences: $e');
        _playlists = []; // Reset to empty list on error
      }
    } else {
      _playlists = []; // Initialize if not found
    }
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String playlistsJson = jsonEncode(
      _playlists.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_playlistsKey, playlistsJson);
  }

  void addPlaylist(Playlist playlist) {
    // Check if a playlist with the same ID or name already exists to prevent duplicates
    if (!_playlists.any(
      (p) => p.id == playlist.id || p.name == playlist.name,
    )) {
      _playlists.add(playlist);
      _savePlaylists();
      notifyListeners();
    } else {
      // Optionally, handle duplicate playlist scenario (e.g., show a message)
      print(
        'Playlist with ID ${playlist.id} or name ${playlist.name} already exists.',
      );
    }
  }

  void removePlaylist(String playlistId) {
    _playlists.removeWhere((p) => p.id == playlistId);
    _savePlaylists();
    notifyListeners();
  }

  void updatePlaylist(Playlist updatedPlaylist) {
    final index = _playlists.indexWhere((p) => p.id == updatedPlaylist.id);
    if (index != -1) {
      _playlists[index] = updatedPlaylist;
      _savePlaylists();
      notifyListeners();
    }
  }

  void addTrackToPlaylist(Track track, String playlistId) {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex != -1) {
      // Assuming track.id is an int as per Playlist model (trackIds: List<int>)
      final trackIdInt =
          track.id; // Ensure track.id is int, or parse if it's String
      _playlists[playlistIndex].addTrack(trackIdInt);
      _savePlaylists();
      notifyListeners();
    } else {
      print('Playlist with ID $playlistId not found.');
    }
  }

  void removeTrackFromPlaylist(int trackId, String playlistId) {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex != -1) {
      _playlists[playlistIndex].removeTrack(trackId);
      _savePlaylists();
      notifyListeners();
    }
  }

  // --- End Playlist Methods ---
}
