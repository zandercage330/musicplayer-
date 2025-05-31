import 'package:fuzzy/fuzzy.dart' as fuzzyhide; // Renamed to avoid conflict
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p; // For basenameWithoutExtension
import 'dart:collection'; // For LinkedHashMap if we want LRU cache later
import 'package:shared_preferences/shared_preferences.dart'; // Added for search history

import 'package:musify/models/track.dart'; // Assuming your Track model
import 'package:musify/models/playlist.dart'; // Added import for Playlist
import 'package:musify/repositories/playlist_repository.dart';

// Enum to define what categories to search for
enum SearchCategory {
  tracks,
  albums,
  artists,
  playlists, // Playlists are out of scope for now
}

// Class to hold the results of a search operation
class SearchResults {
  final List<Track> tracks;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<Playlist> playlists; // Playlists are out of scope

  SearchResults({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [], // Playlists are out of scope
  });

  bool get isEmpty =>
      tracks.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;
}

class SearchService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final PlaylistRepository _playlistRepository = PlaylistRepository(); // Added

  // In-memory cache for search results with a size limit
  static const int _searchCacheMaxSize = 20;
  final LinkedHashMap<String, SearchResults> _searchResultsCache =
      LinkedHashMap<String, SearchResults>();
  // In-memory cache for suggestions (optional, could be added if suggestion fetching is heavy)
  // final Map<String, List<String>> _suggestionsCache = {};

  // Constants for search history
  static const String _searchHistoryKey = 'search_history';
  static const int _searchHistoryLimit = 15;

  // Helper method to add to cache and manage size
  void _addResultToCache(String key, SearchResults results) {
    if (_searchResultsCache.length >= _searchCacheMaxSize) {
      // Remove the oldest entry (first key in LinkedHashMap)
      final oldestKey = _searchResultsCache.keys.first;
      _searchResultsCache.remove(oldestKey);
      print("Cache full. Removed oldest entry: $oldestKey");
    }
    _searchResultsCache[key] = results;
    print(
      "Cached search results for key: $key. Cache size: ${_searchResultsCache.length}",
    );
  }

  String _generateCacheKey(String query, Set<SearchCategory> categories) {
    // Sort category names to ensure consistent key regardless of set order
    final categoryKey = categories.map((c) => c.name).toList()..sort();
    return '$query-${categoryKey.join(',')}';
  }

  // Helper method for checking if all query terms match a set of fields
  bool _matchesAllTerms(
    List<String> terms,
    List<String?> fieldsToSearch, {
    double threshold = 0.4, // Lower is more strict, higher is more lenient
  }) {
    if (terms.isEmpty) {
      return true;
    }

    final List<String> nonNullFields =
        fieldsToSearch
            .where((field) => field != null && field.isNotEmpty)
            .cast<String>()
            .toList();
    if (nonNullFields.isEmpty) {
      return false; // No fields to search in
    }

    // Initialize Fuzzy with the non-null fields of the current item
    final fuse = fuzzyhide.Fuzzy(
      nonNullFields,
      options: fuzzyhide.FuzzyOptions(
        threshold: threshold,
        findAllMatches:
            false, // We only need to know if a term matches at least one field
        tokenize: true, // Tokenize the fields and the search terms
        // Consider adding other options like `isCaseSensitive: false` if not default
        // or `shouldSort: true` if we want to prioritize better matches first (though not strictly needed for just matching)
      ),
    );

    for (final term in terms) {
      final results = fuse.search(term);
      if (results.isEmpty) {
        return false; // If any term does not produce a fuzzy match in any field, it's not a match
      }
    }
    return true; // All terms produced at least one fuzzy match
  }

  Future<SearchResults> search(
    String query,
    Set<SearchCategory> categories,
  ) async {
    if (query.isEmpty || categories.isEmpty) {
      return SearchResults(); // Return empty results if query or categories are empty
    }

    final cacheKey = _generateCacheKey(query, categories);
    if (_searchResultsCache.containsKey(cacheKey)) {
      print("Returning search results from cache for key: $cacheKey");
      return _searchResultsCache[cacheKey]!;
    }
    print("Cache miss for search results. Key: $cacheKey");

    final String normalizedQuery = query.toLowerCase().trim();
    final List<String> queryTerms =
        normalizedQuery.split(' ').where((term) => term.isNotEmpty).toList();

    if (queryTerms.isEmpty) {
      return SearchResults();
    }

    List<Track> foundTracks = [];
    List<AlbumModel> foundAlbums = [];
    List<ArtistModel> foundArtists = [];
    List<Playlist> foundPlaylists = []; // Added

    if (categories.contains(SearchCategory.tracks)) {
      try {
        List<SongModel> allSongModels = await _audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );

        for (final songModel in allSongModels) {
          Track track = Track.fromSongModel(songModel);
          List<String?> fieldsToSearch = [
            track.title,
            track.artist,
            track.album,
            track.filePath.isNotEmpty
                ? p.basenameWithoutExtension(track.filePath)
                : null,
            track.genre,
          ];
          if (_matchesAllTerms(queryTerms, fieldsToSearch)) {
            foundTracks.add(track);
          }
        }
      } catch (e) {
        // Handle or log error if querying songs fails
        print('Error querying songs: $e');
      }
    }

    if (categories.contains(SearchCategory.albums)) {
      try {
        List<AlbumModel> allAlbumModels = await _audioQuery.queryAlbums(
          sortType: AlbumSortType.ALBUM,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );

        for (final albumModel in allAlbumModels) {
          List<String?> fieldsToSearch = [albumModel.album, albumModel.artist];
          if (_matchesAllTerms(queryTerms, fieldsToSearch)) {
            foundAlbums.add(albumModel);
          }
        }
      } catch (e) {
        // Handle or log error if querying albums fails
        print('Error querying albums: $e');
      }
    }

    if (categories.contains(SearchCategory.artists)) {
      try {
        List<ArtistModel> allArtistModels = await _audioQuery.queryArtists(
          sortType: ArtistSortType.ARTIST,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );

        for (final artistModel in allArtistModels) {
          List<String?> fieldsToSearch = [
            artistModel.artist,
            // artistModel.numberOfAlbums, // Not text, but for future filtering if needed
            // artistModel.numberOfTracks, // Not text
          ];
          if (_matchesAllTerms(queryTerms, fieldsToSearch)) {
            foundArtists.add(artistModel);
          }
        }
      } catch (e) {
        // Handle or log error if querying artists fails
        print('Error querying artists: $e');
      }
    }

    if (categories.contains(SearchCategory.playlists) || categories.isEmpty) {
      try {
        List<Playlist> allPlaylists =
            await _playlistRepository.getAllPlaylists();
        for (Playlist playlist in allPlaylists) {
          List<String?> fieldsToSearch = [
            playlist.name,
            playlist.description,
            playlist.creatorDisplayName,
          ];
          if (_matchesAllTerms(queryTerms, fieldsToSearch)) {
            foundPlaylists.add(playlist);
          }
        }
      } catch (e) {
        // Handle or log error if querying playlists fails
        print('Error querying playlists: $e');
      }
    }

    final SearchResults searchResultsToCache = SearchResults(
      tracks: foundTracks,
      albums: foundAlbums,
      artists: foundArtists,
      playlists: foundPlaylists, // Added
    );

    _addResultToCache(
      cacheKey,
      searchResultsToCache,
    ); // Use helper to add and manage size
    return searchResultsToCache;
  }

  Future<List<String>> getSearchSuggestions(
    String query,
    Set<SearchCategory> categories, {
    int limitPerCategory = 3,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    final String normalizedQuery = query.toLowerCase().trim();
    final List<String> queryTerms =
        normalizedQuery.split(' ').where((term) => term.isNotEmpty).toList();

    if (queryTerms.isEmpty) {
      return [];
    }

    Set<String> suggestions = {}; // Use a Set to ensure uniqueness

    // Tracks Suggestions
    if (categories.contains(SearchCategory.tracks)) {
      try {
        List<SongModel> allSongModels = await _audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        int count = 0;
        for (final songModel in allSongModels) {
          if (count >= limitPerCategory) break;
          Track track = Track.fromSongModel(songModel);
          List<String?> fieldsToSearch = [
            track.title,
            track.artist,
            track.album,
          ]; // Simplified fields for suggestions
          if (_matchesAllTerms(queryTerms, fieldsToSearch, threshold: 0.5)) {
            // More lenient threshold for suggestions
            if (track.title.isNotEmpty) suggestions.add(track.title);
            count++;
          }
        }
      } catch (e) {
        print('Error querying songs for suggestions: $e');
      }
    }

    // Albums Suggestions
    if (categories.contains(SearchCategory.albums)) {
      try {
        List<AlbumModel> allAlbumModels = await _audioQuery.queryAlbums(
          sortType: AlbumSortType.ALBUM,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        int count = 0;
        for (final albumModel in allAlbumModels) {
          if (count >= limitPerCategory) break;
          List<String?> fieldsToSearch = [albumModel.album, albumModel.artist];
          if (_matchesAllTerms(queryTerms, fieldsToSearch, threshold: 0.5)) {
            if (albumModel.album.isNotEmpty) suggestions.add(albumModel.album);
            count++;
          }
        }
      } catch (e) {
        print('Error querying albums for suggestions: $e');
      }
    }

    // Artists Suggestions
    if (categories.contains(SearchCategory.artists)) {
      try {
        List<ArtistModel> allArtistModels = await _audioQuery.queryArtists(
          sortType: ArtistSortType.ARTIST,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        int count = 0;
        for (final artistModel in allArtistModels) {
          if (count >= limitPerCategory) break;
          List<String?> fieldsToSearch = [artistModel.artist];
          if (_matchesAllTerms(queryTerms, fieldsToSearch, threshold: 0.5)) {
            if (artistModel.artist.isNotEmpty)
              suggestions.add(artistModel.artist);
            count++;
          }
        }
      } catch (e) {
        print('Error querying artists for suggestions: $e');
      }
    }

    // Playlists Suggestions
    if (categories.contains(SearchCategory.playlists)) {
      try {
        List<Playlist> allPlaylists =
            await _playlistRepository.getAllPlaylists();
        int count = 0;
        for (final playlist in allPlaylists) {
          if (count >= limitPerCategory) break;
          List<String?> fieldsToSearch = [
            playlist.name,
            playlist.description,
            playlist.creatorDisplayName,
          ];
          if (_matchesAllTerms(queryTerms, fieldsToSearch, threshold: 0.5)) {
            if (playlist.name.isNotEmpty) suggestions.add(playlist.name);
            count++;
          }
        }
      } catch (e) {
        print('Error querying playlists for suggestions: $e');
      }
    }
    return suggestions.toList();
  }

  // --- Search History Methods ---

  Future<void> addSearchTermToHistory(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];

    // Remove if already exists to move to top
    history.removeWhere(
      (item) => item.toLowerCase() == term.toLowerCase().trim(),
    );

    // Add to the beginning
    history.insert(0, term.trim());

    // Trim to limit
    if (history.length > _searchHistoryLimit) {
      history = history.sublist(0, _searchHistoryLimit);
    }

    await prefs.setStringList(_searchHistoryKey, history);
    print("Added '$term' to search history. New history: $history");
  }

  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchHistoryKey) ?? [];
    print("Retrieved search history: $history");
    return history;
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
    print("Search history cleared.");
  }
}
