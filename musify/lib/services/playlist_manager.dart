import 'package:musify/models/playlist.dart';
import 'package:musify/repositories/playlist_repository.dart';
// Assuming your Track model is here, if needed for any validation or future logic
// import 'package:musify/models/track.dart';

class PlaylistManager {
  final PlaylistRepository _repository = PlaylistRepository();

  Future<void> createPlaylist(Playlist playlist) async {
    // Basic validation: Playlist name should not be empty
    if (playlist.name.trim().isEmpty) {
      throw ArgumentError('Playlist name cannot be empty.');
    }
    // The Playlist model constructor already handles default ID, dates, and empty trackIds.
    // The repository handles saving the playlist and its initial tracks.
    await _repository.createPlaylist(playlist);
  }

  Future<Playlist?> getPlaylist(String id) async {
    return await _repository.getPlaylistById(id);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    return await _repository.getAllPlaylists();
  }

  Future<void> updatePlaylistDetails(Playlist playlist) async {
    if (playlist.name.trim().isEmpty) {
      throw ArgumentError('Playlist name cannot be empty.');
    }
    playlist.touch(); // Update modification date
    await _repository.updatePlaylist(playlist);
  }

  Future<void> deletePlaylist(String id) async {
    await _repository.deletePlaylist(id);
  }

  Future<void> addTrackToPlaylist(String playlistId, int trackId) async {
    Playlist? playlist = await getPlaylist(playlistId);
    if (playlist != null) {
      if (!playlist.trackIds.contains(trackId)) {
        // Create a new list and add the trackId
        List<int> updatedTrackIds = List.from(playlist.trackIds)..add(trackId);
        // Update the playlist object (important for modificationDate and trackIds list)
        playlist.trackIds = updatedTrackIds;
        playlist.touch();
        await _repository.addTrackToPlaylist(
          playlist.id,
          trackId,
          playlist.trackIds.length - 1,
          playlist.modificationDate,
        );
      } else {
        // Track already in playlist, maybe log or do nothing
        print('Track $trackId already in playlist $playlistId');
      }
    } else {
      throw Exception('Playlist not found: $playlistId');
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, int trackId) async {
    Playlist? playlist = await getPlaylist(playlistId);
    if (playlist != null) {
      if (playlist.trackIds.contains(trackId)) {
        List<int> updatedTrackIds = List.from(playlist.trackIds)
          ..remove(trackId);
        playlist.trackIds = updatedTrackIds;
        playlist.touch();
        await _repository.removeTrackFromPlaylist(
          playlist.id,
          trackId,
          playlist.modificationDate,
        );
      } else {
        print('Track $trackId not found in playlist $playlistId for removal.');
      }
    } else {
      throw Exception('Playlist not found: $playlistId');
    }
  }

  Future<void> setPlaylistTracks(String playlistId, List<int> trackIds) async {
    Playlist? playlist = await getPlaylist(playlistId);
    if (playlist != null) {
      playlist.trackIds = List.from(
        trackIds,
      ); // Ensure it's a new list, though trackIds is already new from map
      playlist.touch(); // Update modification date
      // This repository method will handle clearing old tracks and adding new ones in order
      await _repository.setPlaylistTracks(
        playlist.id,
        playlist.trackIds,
        playlist.modificationDate,
      );
    } else {
      throw Exception('Playlist not found: $playlistId for reordering.');
    }
  }

  // TODO: Add methods for reordering tracks if not handled by setPlaylistTracks directly
  // For example, moveTrackInPlaylist(String playlistId, int oldIndex, int newIndex)
  // However, setPlaylistTracks with the full new list is often simpler for the repository.
}
