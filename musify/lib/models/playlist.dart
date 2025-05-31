import 'dart:convert';

// TODO: Add uuid package to pubspec.yaml (e.g., flutter pub add uuid)
import 'package:uuid/uuid.dart'; // For generating UUIDs

class Playlist {
  final String id;
  String name;
  String? description;
  String? coverImagePath;
  List<int> trackIds; // List of Track IDs
  DateTime creationDate;
  DateTime modificationDate;
  String? creatorDisplayName; // Added field for creator's display name

  Playlist({
    String? id,
    required this.name,
    this.description,
    this.coverImagePath,
    List<int>? trackIds,
    DateTime? creationDate,
    DateTime? modificationDate,
    this.creatorDisplayName, // Added to constructor
  }) : id = id ?? Uuid().v4(), // Generate UUID if not provided
       trackIds = trackIds ?? [],
       creationDate = creationDate ?? DateTime.now(),
       modificationDate = modificationDate ?? DateTime.now();

  // Method to update modification date whenever a change is made
  void touch() {
    modificationDate = DateTime.now();
  }

  // Example of a method that modifies the playlist and calls touch
  void setName(String newName) {
    name = newName;
    touch();
  }

  void setDescription(String? newDescription) {
    description = newDescription;
    touch();
  }

  void setCoverImagePath(String? newPath) {
    coverImagePath = newPath;
    touch();
  }

  void addTrack(int trackId) {
    if (!trackIds.contains(trackId)) {
      trackIds.add(trackId);
      touch();
    }
  }

  void removeTrack(int trackId) {
    if (trackIds.contains(trackId)) {
      trackIds.remove(trackId);
      touch();
    }
  }

  void reorderTracks(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= trackIds.length ||
        newIndex < 0 ||
        newIndex >= trackIds.length) {
      return; // Invalid indices
    }
    final int item = trackIds.removeAt(oldIndex);
    trackIds.insert(newIndex, item);
    touch();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'coverImagePath': coverImagePath,
    'trackIds': jsonEncode(trackIds), // Encode list of ints to JSON string
    'creationDate': creationDate.toIso8601String(),
    'modificationDate': modificationDate.toIso8601String(),
    'creatorDisplayName': creatorDisplayName, // Added field
  };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    List<dynamic> decodedTrackIdsDynamic = jsonDecode(
      json['trackIds'] as String,
    );
    List<int> decodedTrackIdsInt =
        decodedTrackIdsDynamic.map((id) => id as int).toList();

    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      trackIds: decodedTrackIdsInt,
      creationDate: DateTime.parse(json['creationDate'] as String),
      modificationDate: DateTime.parse(json['modificationDate'] as String),
      creatorDisplayName: json['creatorDisplayName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Playlist{id: $id, name: $name, tracks: ${trackIds.length}}';
  }
}
