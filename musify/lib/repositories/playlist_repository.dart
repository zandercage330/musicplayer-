import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:musify/services/database_service.dart';
import 'package:musify/models/playlist.dart';

class PlaylistRepository {
  final DatabaseService _dbService = DatabaseService();

  // Create a new playlist
  Future<int> createPlaylist(Playlist playlist) async {
    final db = await _dbService.database;
    int playlistRowId = -1;
    await db.transaction((txn) async {
      playlistRowId = await txn.insert(
        DatabaseService.tablePlaylists,
        _playlistToDbMap(playlist),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      if (playlist.trackIds.isNotEmpty) {
        sqflite.Batch batch = txn.batch();
        for (int i = 0; i < playlist.trackIds.length; i++) {
          batch.insert(DatabaseService.tablePlaylistTracks, {
            DatabaseService.colPlaylistTracksPlaylistId: playlist.id,
            DatabaseService.colPlaylistTracksTrackId: playlist.trackIds[i],
            DatabaseService.colPlaylistTracksOrder: i,
          });
        }
        batch.execute('');
      }
    });
    return playlistRowId;
  }

  // Get a single playlist by its ID
  Future<Playlist?> getPlaylistById(String id) async {
    final db = await _dbService.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.tablePlaylists,
      where: '${DatabaseService.colPlaylistId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      Map<String, dynamic> playlistMap = maps.first;
      List<int> trackIds = await _getTrackIdsForPlaylist(db, id);
      return _playlistFromDbMap(playlistMap, trackIds);
    } else {
      return null;
    }
  }

  // Get all playlists
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await _dbService.database;
    List<Map<String, dynamic>> playlistMaps = await db.query(
      DatabaseService.tablePlaylists,
      orderBy: '${DatabaseService.colPlaylistModificationDate} DESC',
    );
    List<Playlist> playlists = [];
    for (var map in playlistMaps) {
      List<int> trackIds = await _getTrackIdsForPlaylist(
        db,
        map[DatabaseService.colPlaylistId] as String,
      );
      playlists.add(_playlistFromDbMap(map, trackIds));
    }
    return playlists;
  }

  // Helper to get track IDs for a playlist
  Future<List<int>> _getTrackIdsForPlaylist(
    sqflite.DatabaseExecutor db,
    String playlistId,
  ) async {
    List<Map<String, dynamic>> trackMaps = await db.query(
      DatabaseService.tablePlaylistTracks,
      columns: [DatabaseService.colPlaylistTracksTrackId],
      where: '${DatabaseService.colPlaylistTracksPlaylistId} = ?',
      whereArgs: [playlistId],
      orderBy: DatabaseService.colPlaylistTracksOrder,
    );
    return trackMaps
        .map((m) => m[DatabaseService.colPlaylistTracksTrackId] as int)
        .toList();
  }

  // Update an existing playlist (name, description, cover, and its tracks order/content)
  Future<void> updatePlaylist(Playlist playlist) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update(
        DatabaseService.tablePlaylists,
        _playlistToDbMap(playlist),
        where: '${DatabaseService.colPlaylistId} = ?',
        whereArgs: [playlist.id],
      );
      // Clear existing tracks for this playlist
      await txn.delete(
        DatabaseService.tablePlaylistTracks,
        where: '${DatabaseService.colPlaylistTracksPlaylistId} = ?',
        whereArgs: [playlist.id],
      );
      // Add new tracks with order
      if (playlist.trackIds.isNotEmpty) {
        sqflite.Batch batch = txn.batch();
        for (int i = 0; i < playlist.trackIds.length; i++) {
          batch.insert(DatabaseService.tablePlaylistTracks, {
            DatabaseService.colPlaylistTracksPlaylistId: playlist.id,
            DatabaseService.colPlaylistTracksTrackId: playlist.trackIds[i],
            DatabaseService.colPlaylistTracksOrder: i,
          });
        }
        batch.execute('');
      }
    });
  }

  // Delete a playlist
  Future<void> deletePlaylist(String id) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseService.tablePlaylists,
        where: '${DatabaseService.colPlaylistId} = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseService.tablePlaylistTracks,
        where: '${DatabaseService.colPlaylistTracksPlaylistId} = ?',
        whereArgs: [id],
      );
    });
  }

  // Add a single track to a playlist (appends to the end)
  Future<void> addTrackToPlaylist(
    String playlistId,
    int trackId,
    int order,
    DateTime modificationDate,
  ) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Insert into join table
      await txn.insert(
        DatabaseService.tablePlaylistTracks,
        {
          DatabaseService.colPlaylistTracksPlaylistId: playlistId,
          DatabaseService.colPlaylistTracksTrackId: trackId,
          DatabaseService.colPlaylistTracksOrder:
              order, // This order is the new end of the list
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.ignore,
      ); // Ignore if somehow already there (should be handled by manager)

      // Update playlist's modification date
      await txn.update(
        DatabaseService.tablePlaylists,
        {
          DatabaseService.colPlaylistModificationDate:
              modificationDate.toIso8601String(),
        },
        where: '${DatabaseService.colPlaylistId} = ?',
        whereArgs: [playlistId],
      );
    });
  }

  // Remove a single track from a playlist
  Future<void> removeTrackFromPlaylist(
    String playlistId,
    int trackId,
    DateTime modificationDate,
  ) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseService.tablePlaylistTracks,
        where:
            '${DatabaseService.colPlaylistTracksPlaylistId} = ? AND ${DatabaseService.colPlaylistTracksTrackId} = ?',
        whereArgs: [playlistId, trackId],
      );

      // Update modification date and re-index order of remaining tracks
      List<int> remainingTrackIds = await _getTrackIdsForPlaylist(
        txn,
        playlistId,
      ); // Should reflect the deletion
      sqflite.Batch batch = txn.batch();
      for (int i = 0; i < remainingTrackIds.length; i++) {
        batch.update(
          DatabaseService.tablePlaylistTracks,
          {DatabaseService.colPlaylistTracksOrder: i},
          where:
              '${DatabaseService.colPlaylistTracksPlaylistId} = ? AND ${DatabaseService.colPlaylistTracksTrackId} = ?',
          whereArgs: [playlistId, remainingTrackIds[i]],
        );
      }
      batch.execute('');

      await txn.update(
        DatabaseService.tablePlaylists,
        {
          DatabaseService.colPlaylistModificationDate:
              modificationDate.toIso8601String(),
        },
        where: '${DatabaseService.colPlaylistId} = ?',
        whereArgs: [playlistId],
      );
    });
  }

  // Set all tracks for a playlist (clears old, adds new in specified order)
  Future<void> setPlaylistTracks(
    String playlistId,
    List<int> trackIds,
    DateTime modificationDate,
  ) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // Clear existing tracks
      await txn.delete(
        DatabaseService.tablePlaylistTracks,
        where: '${DatabaseService.colPlaylistTracksPlaylistId} = ?',
        whereArgs: [playlistId],
      );
      // Add new tracks with new order
      if (trackIds.isNotEmpty) {
        sqflite.Batch batch = txn.batch();
        for (int i = 0; i < trackIds.length; i++) {
          batch.insert(DatabaseService.tablePlaylistTracks, {
            DatabaseService.colPlaylistTracksPlaylistId: playlistId,
            DatabaseService.colPlaylistTracksTrackId: trackIds[i],
            DatabaseService.colPlaylistTracksOrder: i,
          });
        }
        batch.execute('');
      }
      // Update playlist's modification date
      await txn.update(
        DatabaseService.tablePlaylists,
        {
          DatabaseService.colPlaylistModificationDate:
              modificationDate.toIso8601String(),
        },
        where: '${DatabaseService.colPlaylistId} = ?',
        whereArgs: [playlistId],
      );
    });
  }

  // --- Helper Methods for DB Mapping ---
  Map<String, dynamic> _playlistToDbMap(Playlist playlist) {
    return {
      DatabaseService.colPlaylistId: playlist.id,
      DatabaseService.colPlaylistName: playlist.name,
      DatabaseService.colPlaylistDescription: playlist.description,
      DatabaseService.colPlaylistCoverImagePath: playlist.coverImagePath,
      DatabaseService.colPlaylistCreationDate:
          playlist.creationDate.toIso8601String(),
      DatabaseService.colPlaylistModificationDate:
          playlist.modificationDate.toIso8601String(),
      DatabaseService.colPlaylistCreatorDisplayName:
          playlist.creatorDisplayName,
    };
  }

  Playlist _playlistFromDbMap(Map<String, dynamic> map, List<int> trackIds) {
    return Playlist(
      id: map[DatabaseService.colPlaylistId] as String,
      name: map[DatabaseService.colPlaylistName] as String,
      description: map[DatabaseService.colPlaylistDescription] as String?,
      coverImagePath: map[DatabaseService.colPlaylistCoverImagePath] as String?,
      trackIds: trackIds, // Passed in after fetching from join table
      creationDate: DateTime.parse(
        map[DatabaseService.colPlaylistCreationDate] as String,
      ),
      modificationDate: DateTime.parse(
        map[DatabaseService.colPlaylistModificationDate] as String,
      ),
      creatorDisplayName:
          map[DatabaseService.colPlaylistCreatorDisplayName] as String?,
    );
  }
}
