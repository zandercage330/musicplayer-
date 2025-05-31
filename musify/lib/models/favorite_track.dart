// File: musify/lib/models/favorite_track.dart
class FavoriteTrack {
  final int? id; // Auto-generated primary key from the database
  final int trackId; // Foreign key to Track.id
  final DateTime dateFavorited;
  final String? userId; // Optional: for multi-user support
  final bool isSynced; // Optional: for cloud sync status
  final int? customOrder; // Optional: for manual sorting by user

  FavoriteTrack({
    this.id,
    required this.trackId,
    required this.dateFavorited,
    this.userId,
    this.isSynced = false,
    this.customOrder,
  });

  // Factory constructor for creating a new FavoriteTrack instance from a map
  factory FavoriteTrack.fromJson(Map<String, dynamic> json) {
    return FavoriteTrack(
      id: json['id'] as int?,
      trackId: json['trackId'] as int,
      dateFavorited: DateTime.parse(json['dateFavorited'] as String),
      userId: json['userId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      customOrder: json['customOrder'] as int?,
    );
  }

  // Method for converting a FavoriteTrack instance to a map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackId': trackId,
      'dateFavorited': dateFavorited.toIso8601String(),
      'userId': userId,
      'isSynced': isSynced,
      'customOrder': customOrder,
    };
  }

  // Optional: copyWith method for easier updates if objects are treated as immutable
  FavoriteTrack copyWith({
    int? id,
    int? trackId,
    DateTime? dateFavorited,
    String? userId,
    bool? isSynced,
    int? customOrder,
    bool allowNullUserId = false, // To explicitly set userId to null
    bool allowNullCustomOrder = false, // To explicitly set customOrder to null
  }) {
    return FavoriteTrack(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      dateFavorited: dateFavorited ?? this.dateFavorited,
      userId: allowNullUserId ? userId : (userId ?? this.userId),
      isSynced: isSynced ?? this.isSynced,
      customOrder:
          allowNullCustomOrder
              ? customOrder
              : (customOrder ?? this.customOrder),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          trackId == other.trackId;

  @override
  int get hashCode => id.hashCode ^ trackId.hashCode;
}
