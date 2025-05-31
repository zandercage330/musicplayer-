import 'dart:convert'; // For jsonEncode/Decode and base64
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart'; // For SongModel
import 'package:path/path.dart' as p; // For basename

class Track {
  final int id; // Using the ID from on_audio_query's SongModel
  final String filePath;
  final String title;
  final String? artist;
  final String? album;
  final int? durationMs;
  final int? albumId;
  Uint8List? albumArt; // Keep as Uint8List for runtime, convert for JSON
  final int? dateAdded; // Seconds since Epoch
  final int? dateModified; // Seconds since Epoch
  final String? genre; // Added genre
  final int? year; // Added year

  Track({
    required this.id,
    required this.filePath,
    required this.title,
    this.artist,
    this.album,
    this.durationMs,
    this.albumId,
    this.albumArt,
    this.dateAdded,
    this.dateModified,
    this.genre, // Added genre
    this.year, // Added year
  });

  Duration? get duration {
    if (durationMs != null && durationMs! > 0) {
      return Duration(milliseconds: durationMs!);
    }
    return null;
  }

  // Factory constructor to create a Track from on_audio_query's SongModel
  factory Track.fromSongModel(SongModel song) {
    String displayTitle = song.title;
    if (displayTitle.isEmpty) {
      // Fallback to display name (often filename without extension)
      displayTitle = song.displayName;
      // Further fallback: use filename from path if display name is also empty
      if (displayTitle.isEmpty && song.data.isNotEmpty) {
        try {
          displayTitle = p.basenameWithoutExtension(song.data);
        } catch (e) {
          displayTitle = "Unknown Title"; // Ultimate fallback
        }
      }
    }
    if (displayTitle.isEmpty) displayTitle = "Unknown Title";

    return Track(
      id: song.id,
      filePath: song.data,
      title: displayTitle,
      artist: song.artist?.isEmpty ?? true ? null : song.artist,
      album: song.album?.isEmpty ?? true ? null : song.album,
      durationMs: song.duration,
      albumId: song.albumId,
      dateAdded: song.dateAdded,
      dateModified: song.dateModified,
      genre:
          song.genre?.isEmpty ?? true
              ? null
              : song.genre, // Added genre mapping
      year: _extractYear(song), // Updated to use helper
    );
  }

  static int? _extractYear(SongModel song) {
    // Attempt 1: Directly from getMap if platform provides it (e.g., 'year' key)
    try {
      if (song.getMap['year'] != null) {
        final yearFromMap = song.getMap['year'];
        if (yearFromMap is int) {
          return yearFromMap;
        }
        if (yearFromMap is String) {
          return int.tryParse(yearFromMap);
        }
      }
    } catch (e) {
      // Silent catch, try next method
    }

    // Attempt 2: From dateAdded (if it's a timestamp in seconds)
    if (song.dateAdded != null && song.dateAdded! > 0) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(song.dateAdded! * 1000).year;
      } catch (e) {
        // Silent catch
      }
    }
    // Attempt 3: From dateModified (less ideal, but a fallback)
    if (song.dateModified != null && song.dateModified! > 0) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(
          song.dateModified! * 1000,
        ).year;
      } catch (e) {
        // Silent catch
      }
    }
    // Add more specific extraction logic if known for certain tags/formats
    return null; // Return null if year cannot be determined
  }

  // For JSON serialization/deserialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'title': title,
    'artist': artist,
    'album': album,
    'durationMs': durationMs,
    'albumId': albumId,
    'albumArt':
        albumArt != null
            ? base64Encode(albumArt!)
            : null, // Encode Uint8List to base64 String
    'dateAdded': dateAdded,
    'dateModified': dateModified,
    'genre': genre, // Added genre
    'year': year, // Added year
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as int,
    filePath: json['filePath'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String?,
    album: json['album'] as String?,
    durationMs: json['durationMs'] as int?,
    albumId: json['albumId'] as int?,
    albumArt:
        json['albumArt'] != null
            ? base64Decode(json['albumArt'] as String)
            : null, // Decode base64 String to Uint8List
    dateAdded: json['dateAdded'] as int?,
    dateModified: json['dateModified'] as int?,
    genre: json['genre'] as String?, // Added genre
    year: json['year'] as int?, // Added year
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath;

  @override
  int get hashCode => id.hashCode ^ filePath.hashCode;

  @override
  String toString() {
    return 'Track{id: $id, title: $title, artist: $artist, filePath: $filePath, modified: $dateModified}';
  }
}
