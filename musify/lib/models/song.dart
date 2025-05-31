class Song {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final String filePath;
  final String? artworkPath; // Path to cached artwork or embedded art reference
  final int? year;
  final String? genre;
  // Add other relevant metadata fields as needed

  Song({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    required this.filePath,
    this.artworkPath,
    this.year,
    this.genre,
  });

  // Optional: Factory constructor for creating a Song from a map (e.g., from JSON or database)
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      duration:
          map['duration_ms'] != null
              ? Duration(milliseconds: map['duration_ms'] as int)
              : null,
      filePath: map['filePath'] as String,
      artworkPath: map['artworkPath'] as String?,
      year: map['year'] as int?,
      genre: map['genre'] as String?,
    );
  }

  // Optional: Method to convert a Song instance to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration_ms': duration?.inMilliseconds,
      'filePath': filePath,
      'artworkPath': artworkPath,
      'year': year,
      'genre': genre,
    };
  }

  // Optional: Override toString for better debugging output
  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, album: $album, duration: $duration, filePath: $filePath)';
  }

  // Optional: Implement == and hashCode for comparisons if Song objects will be stored in sets or used as map keys
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Song &&
        other.id == id &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.duration == duration &&
        other.filePath == filePath &&
        other.artworkPath == artworkPath &&
        other.year == year &&
        other.genre == genre;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        artist.hashCode ^
        album.hashCode ^
        duration.hashCode ^
        filePath.hashCode ^
        artworkPath.hashCode ^
        year.hashCode ^
        genre.hashCode;
  }
}
