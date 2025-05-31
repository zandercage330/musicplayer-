import 'package:musify/data/database.dart';
import 'package:musify/models/favorite_track.dart' as model_favorite_track;
import 'package:musify/models/track.dart' as model_track;

// Define an abstract interface for the repository if you plan for testability/DI
abstract class IFavoritesRepository {
  Future<void> addFavorite(model_track.Track track);
  Future<void> removeFavorite(int trackId);
  Future<bool> isFavorite(int trackId);
  Future<List<model_track.Track>> getAllFavoriteTracksDetails(
    AppDatabase db, // Pass db instance, or manage it internally
  );
  // TODO: Add methods for sorting, specific queries, etc.
  // TODO: Consider how to get full Track details. This might involve joins or separate queries.
}

class FavoritesRepository implements IFavoritesRepository {
  final AppDatabase _database;

  FavoritesRepository(this._database);

  @override
  Future<void> addFavorite(model_track.Track track) async {
    final favoriteEntry = model_favorite_track.FavoriteTrack(
      trackId: track.id,
      dateFavorited: DateTime.now(),
      // Other fields like userId, customOrder could be passed or defaulted here
    );
    await _database.addFavoriteTrack(favoriteEntry);
    // TODO: Consider migrating SharedPreferences data here if it's the first time
    // or as a separate utility.
  }

  @override
  Future<void> removeFavorite(int trackId) async {
    await _database.removeFavoriteTrack(trackId);
  }

  @override
  Future<bool> isFavorite(int trackId) async {
    return await _database.isTrackFavorited(trackId);
  }

  // This method needs access to the main tracks data to return full Track objects
  // For simplicity, it currently assumes you'll fetch all Track objects from elsewhere
  // and then filter them. A more optimized way would be a JOIN in SQL if Tracks were in Drift.
  @override
  Future<List<model_track.Track>> getAllFavoriteTracksDetails(
    AppDatabase db, // Example: Pass db or use MusicScannerService
  ) async {
    final favoriteEntries = await db.getAllFavoriteTracks();
    if (favoriteEntries.isEmpty) return [];

    // This is inefficient for large libraries. Ideally, you'd have a way to get
    // tracks by IDs efficiently, or store more track details in FavoriteTrackEntry.
    // For now, let's assume a way to get all tracks (e.g. from MusicScannerService or a TrackRepository)
    // final allTracks = await MusicScannerService().getTracks(); // Placeholder
    // final Map<int, model_track.Track> allTracksMap = {
    //   for (var t in allTracks) t.id: t
    // };

    // final List<model_track.Track> result = [];
    // for (var favEntry in favoriteEntries) {
    //   if (allTracksMap.containsKey(favEntry.trackId)) {
    //     result.add(allTracksMap[favEntry.trackId]!);
    //   }
    // }
    // return result;

    // Placeholder - needs a proper way to get Track details from trackIds
    print(
      "Warning: getAllFavoriteTracksDetails needs a proper way to fetch full Track objects.",
    );
    // Returning empty for now, or you could map just the IDs if that's useful temporarily.
    // For this to work, the FavoriteTabScreen would need to adapt to get Track details by ID.
    // Or, MusicLibraryProvider would do this mapping.
    return []; // Replace with actual implementation
  }

  Future<model_favorite_track.FavoriteTrack?> getFavoriteEntryByTrackId(
    int trackId,
  ) async {
    return await _database.getFavoriteByTrackId(trackId);
  }

  // TODO: Implement migration from SharedPreferences if needed
  // Future<void> migrateFromSharedPreferences(SharedPreferences prefs, String oldKey) async { ... }
}
