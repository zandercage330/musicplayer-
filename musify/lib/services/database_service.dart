import 'dart:async';
import 'package:path/path.dart';
// TODO: Add sqflite and path_provider packages to pubspec.yaml
// e.g., flutter pub add sqflite path_provider
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // --- Table and Column Names ---
  static const String tablePlaylists = 'playlists';
  static const String colPlaylistId = 'id'; // TEXT (UUID)
  static const String colPlaylistName = 'name'; // TEXT
  static const String colPlaylistDescription = 'description'; // TEXT
  static const String colPlaylistCoverImagePath = 'coverImagePath'; // TEXT
  static const String colPlaylistCreationDate =
      'creationDate'; // TEXT (ISO8601)
  static const String colPlaylistModificationDate =
      'modificationDate'; // TEXT (ISO8601)
  static const String colPlaylistCreatorDisplayName =
      'creatorDisplayName'; // TEXT

  static const String tablePlaylistTracks = 'playlist_tracks';
  static const String colPlaylistTracksId =
      'id'; // INTEGER PRIMARY KEY AUTOINCREMENT (optional, for join table simplicity)
  static const String colPlaylistTracksPlaylistId =
      'playlist_id'; // TEXT (FK to playlists.id)
  static const String colPlaylistTracksTrackId =
      'track_id'; // INTEGER (FK to a conceptual tracks table, or just the ID)
  static const String colPlaylistTracksOrder =
      'track_order'; // INTEGER (for ordering within playlist)
  // --- End Table and Column Names ---

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'musify_playlists.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // For future schema migrations
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePlaylists (
        $colPlaylistId TEXT PRIMARY KEY,
        $colPlaylistName TEXT NOT NULL,
        $colPlaylistDescription TEXT,
        $colPlaylistCoverImagePath TEXT,
        $colPlaylistCreationDate TEXT NOT NULL,
        $colPlaylistModificationDate TEXT NOT NULL,
        $colPlaylistCreatorDisplayName TEXT 
      )
      ''');

    await db.execute('''
      CREATE TABLE $tablePlaylistTracks (
        $colPlaylistTracksId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colPlaylistTracksPlaylistId TEXT NOT NULL,
        $colPlaylistTracksTrackId INTEGER NOT NULL,
        $colPlaylistTracksOrder INTEGER NOT NULL,
        FOREIGN KEY ($colPlaylistTracksPlaylistId) REFERENCES $tablePlaylists ($colPlaylistId) ON DELETE CASCADE,
        UNIQUE ($colPlaylistTracksPlaylistId, $colPlaylistTracksTrackId) ON CONFLICT REPLACE,
        UNIQUE ($colPlaylistTracksPlaylistId, $colPlaylistTracksOrder) ON CONFLICT REPLACE 
      )
      ''');
    print("Database tables $tablePlaylists and $tablePlaylistTracks created.");
  }

  // Example for future migrations:
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   if (oldVersion < 2) {
  //     // await db.execute("ALTER TABLE $tablePlaylists ADD COLUMN new_column TEXT;");
  //   }
  // }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
