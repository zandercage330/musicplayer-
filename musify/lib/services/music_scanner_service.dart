import 'dart:async'; // For StreamController
import 'dart:convert'; // For jsonEncode/Decode
import 'dart:typed_data'; // For Uint8List
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musify/services/permission_service.dart'; // To check permissions before scanning
import 'package:musify/models/track.dart'; // Import the Track model
import 'package:shared_preferences/shared_preferences.dart'; // For caching
import 'package:musify/utils/error_handler.dart'; // Added ErrorHandler

// Class to hold scan progress information
class ScanProgress {
  final int processedCount;
  final int totalCount;
  final String? currentFilePath; // Optional: path of file being processed
  final String
  statusMessage; // e.g., "Scanning...", "Fetching artwork...", "Complete"

  ScanProgress({
    required this.processedCount,
    required this.totalCount,
    this.currentFilePath,
    required this.statusMessage,
  });

  @override
  String toString() {
    return 'ScanProgress(processed: $processedCount/$totalCount, status: $statusMessage, current: $currentFilePath)';
  }
}

class MusicScannerService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final PermissionService _permissionService = PermissionService();

  static const String _cachedTracksKey = 'cached_tracks_v1';
  static const String _lastScanTimestampKey = 'last_scan_timestamp_v1';
  // Cache duration: 1 day (in milliseconds)
  static const int _cacheDurationMs = 24 * 60 * 60 * 1000;

  // Stream controller for progress updates
  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();
  Stream<ScanProgress> get scanProgressStream => _progressController.stream;

  // Method to dispose the stream controller when the service is no longer needed
  void dispose() {
    _progressController.close();
  }

  // _supportedExtensions was part of the manual scan logic, on_audio_query handles types.
  // final List<String> _supportedExtensions = [
  //   '.mp3', '.m4a', '.flac', '.wav', '.aac', '.ogg'
  // ];

  // Removed the recently added scanAudioFiles, _requestAndCheckPermissions,
  // and _isApiLevel methods as their functionality is covered by
  // getTracks and _scanAndProcessTracksFromDevice, and PermissionService.

  Future<List<Track>> getTracks({bool forceRefresh = false}) async {
    _progressController.add(
      ScanProgress(
        processedCount: 0,
        totalCount: 0,
        statusMessage: "Checking cache...",
      ),
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      int? lastScanTimestamp = prefs.getInt(_lastScanTimestampKey);
      if (lastScanTimestamp != null) {
        bool isCacheStale =
            DateTime.now().millisecondsSinceEpoch - lastScanTimestamp >
            _cacheDurationMs;
        if (!isCacheStale) {
          List<Track>? cachedTracks = await _loadTracksFromCache(prefs);
          if (cachedTracks != null && cachedTracks.isNotEmpty) {
            _progressController.add(
              ScanProgress(
                processedCount: cachedTracks.length,
                totalCount: cachedTracks.length,
                statusMessage: "Loaded from cache",
              ),
            );
            print(
              'MusicScannerService: Loaded ${cachedTracks.length} tracks from cache.',
            );
            return cachedTracks;
          }
        } else {
          _progressController.add(
            ScanProgress(
              processedCount: 0,
              totalCount: 0,
              statusMessage: "Cache stale, preparing fresh scan...",
            ),
          );
          print('MusicScannerService: Cache is stale. Performing fresh scan.');
        }
      }
    }

    _progressController.add(
      ScanProgress(
        processedCount: 0,
        totalCount: 0,
        statusMessage: "Starting fresh scan (forceRefresh: $forceRefresh)...",
      ),
    );
    print(
      'MusicScannerService: Performing fresh scan (forceRefresh: $forceRefresh).',
    );
    List<Track> freshTracks = await _scanAndProcessTracksFromDevice();
    await _saveTracksToCache(prefs, freshTracks);
    _progressController.add(
      ScanProgress(
        processedCount: freshTracks.length,
        totalCount: freshTracks.length,
        statusMessage: "Scan complete",
      ),
    );
    return freshTracks;
  }

  Future<List<Track>> _scanAndProcessTracksFromDevice() async {
    _progressController.add(
      ScanProgress(
        processedCount: 0,
        totalCount: 0,
        statusMessage: "Checking permissions...",
      ),
    );
    PermissionRequestUIAction action =
        await _permissionService.determinePermissionRequestUIAction();

    if (action != PermissionRequestUIAction.proceed) {
      _progressController.add(
        ScanProgress(
          processedCount: 0,
          totalCount: 0,
          statusMessage: "Permissions not granted",
        ),
      );
      print('MusicScannerService: Permissions not granted. Cannot scan files.');
      return [];
    }

    List<SongModel> songModels = []; // Initialize here
    List<Track> tracks = []; // Initialize here
    int processedCountInCatch = 0;
    int totalCountInCatch = 0;

    try {
      _progressController.add(
        ScanProgress(
          processedCount: 0,
          totalCount: 0,
          statusMessage: "Querying audio files...",
        ),
      );
      songModels = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      totalCountInCatch = songModels.length; // Update for catch block
      print(
        'MusicScannerService: Found ${songModels.length} song models from device.',
      );
      if (songModels.isEmpty) {
        _progressController.add(
          ScanProgress(
            processedCount: 0,
            totalCount: 0,
            statusMessage: "No audio files found.",
          ),
        );
        return [];
      }
      _progressController.add(
        ScanProgress(
          processedCount: 0,
          totalCount: songModels.length,
          statusMessage: "Processing files...",
        ),
      );

      int currentProcessed = 0;
      for (SongModel songModel in songModels) {
        Track track = Track.fromSongModel(songModel);
        if (track.albumId != null) {
          _progressController.add(
            ScanProgress(
              processedCount: currentProcessed,
              totalCount: songModels.length,
              statusMessage: "Fetching artwork for ${track.title}...",
              currentFilePath: track.filePath,
            ),
          );
          try {
            Uint8List? artwork = await _audioQuery.queryArtwork(
              track.albumId!,
              ArtworkType.ALBUM,
              format: ArtworkFormat.JPEG,
              size: 200,
            );
            track.albumArt = artwork;
          } catch (e, s) {
            ErrorHandler.logError(
              'Error querying artwork for albumId ${track.albumId}',
              error: e,
              stackTrace: s,
            );
          }
        }
        tracks.add(track);
        currentProcessed++;
        processedCountInCatch = currentProcessed; // Update for catch block
        if (currentProcessed % 10 == 0 ||
            currentProcessed == songModels.length) {
          _progressController.add(
            ScanProgress(
              processedCount: currentProcessed,
              totalCount: songModels.length,
              statusMessage: "Processing files...",
              currentFilePath: track.filePath,
            ),
          );
        }
      }
      print(
        'MusicScannerService: Processed ${tracks.length} tracks from device.',
      );
      return tracks;
    } catch (e, s) {
      _progressController.add(
        ScanProgress(
          processedCount: processedCountInCatch,
          totalCount: totalCountInCatch,
          statusMessage: "Error during scan: ${e.toString()}",
        ),
      );
      ErrorHandler.logError(
        'Error scanning/processing tracks from device',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<void> _saveTracksToCache(
    SharedPreferences prefs,
    List<Track> tracks,
  ) async {
    try {
      List<String> jsonTracks =
          tracks.map((track) => jsonEncode(track.toJson())).toList();
      await prefs.setStringList(_cachedTracksKey, jsonTracks);
      await prefs.setInt(
        _lastScanTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('MusicScannerService: Saved ${tracks.length} tracks to cache.');
    } catch (e, s) {
      ErrorHandler.logError(
        'Error saving tracks to cache',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<List<Track>?> _loadTracksFromCache(SharedPreferences prefs) async {
    try {
      List<String>? jsonTracks = prefs.getStringList(_cachedTracksKey);
      if (jsonTracks == null || jsonTracks.isEmpty) {
        return null;
      }
      List<Track> tracks =
          jsonTracks
              .map(
                (jsonTrack) => Track.fromJson(
                  jsonDecode(jsonTrack) as Map<String, dynamic>,
                ),
              )
              .toList();
      return tracks;
    } catch (e, s) {
      ErrorHandler.logError(
        'Error loading tracks from cache',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<void> clearCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedTracksKey);
    await prefs.remove(_lastScanTimestampKey);
    print('MusicScannerService: Cache cleared.');
  }

  // Placeholder for requesting permission explicitly from the service if needed,
  // though it's better handled by UI interaction flow.
  // Future<bool> ensurePermissions() async {
  //   PermissionRequestUIAction action = await _permissionService.determinePermissionRequestUIAction();
  //   if (action == PermissionRequestUIAction.proceed) return true;
  //
  //   // Here, we'd ideally notify the UI to show appropriate dialogs based on 'action'
  //   // For a service, it might be better to just return false or throw specific error.
  //   print("Permissions not granted. UI should handle dialogs.");
  //   return false;
  // }
}
