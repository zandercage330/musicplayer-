import 'dart:io'; // For Image.file
import 'package:flutter/material.dart';
// import 'package:musify/widgets/placeholder_content_widget.dart'; // No longer used directly here for main body
import 'package:musify/services/search_service.dart'; // Import SearchService
import 'package:musify/services/audio_player_service.dart'; // Import AudioPlayerService
import 'package:on_audio_query/on_audio_query.dart'; // Import QueryArtworkWidget
import 'package:musify/screens/album_details_screen.dart'; // Import AlbumDetailsScreen
import 'package:musify/screens/artist_details_screen.dart'; // Import ArtistDetailsScreen
import 'package:musify/screens/playlist_detail_screen.dart'; // Import PlaylistDetailScreen
import 'dart:async'; // Import Timer
import 'package:provider/provider.dart'; // Added for MusicLibraryProvider
import 'package:musify/providers/music_library_provider.dart'; // Added for MusicLibraryProvider

class SearchTabScreen extends StatefulWidget {
  const SearchTabScreen({super.key});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  late final SearchService _searchService;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  final Set<SearchCategory> _selectedCategories = {
    SearchCategory.tracks,
  }; // Default to tracks
  SearchResults? _searchResults;
  bool _isLoading = false;
  List<String> _suggestions = [];
  bool _isFetchingSuggestions = false;
  List<String> _searchHistoryItems = []; // Added for search history

  Timer? _debounce;
  final FocusNode _searchFocusNode = FocusNode(); // Added FocusNode

  @override
  void initState() {
    super.initState();
    _searchService = SearchService();
    _searchController = TextEditingController();
    _loadSearchHistory(); // Load history on init

    _searchController.addListener(() {
      final query = _searchController.text;
      if (query != _searchQuery) {
        // Only update if text actually changed
        setState(() {
          _searchQuery = query;
        });
        if (query.trim().isNotEmpty) {
          _fetchSuggestions();
        } else {
          setState(() {
            _suggestions = [];
            _searchResults = null;
            // When query becomes empty, potentially show history if focused
            if (_searchFocusNode.hasFocus) {
              _loadSearchHistory(); // Refresh history view
            }
          });
        }
      }
    });

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        _loadSearchHistory(); // Load and show history when field is focused and empty
        setState(() {
          _suggestions = []; // Ensure suggestions are hidden
          _searchResults = null; // Ensure full results are hidden
        });
      } else if (!_searchFocusNode.hasFocus) {
        // Optionally clear history display when focus is lost and field is still empty
        // setState(() { _searchHistoryItems = []; });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose(); // Dispose FocusNode
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistoryItems = history;
      });
    }
  }

  Future<void> _clearAndLoadSearchHistory() async {
    await _searchService.clearSearchHistory();
    await _loadSearchHistory(); // Refresh the list
  }

  Future<void> _fetchSuggestions() async {
    if (_searchQuery.trim().isEmpty || _selectedCategories.isEmpty) {
      setState(() {
        _suggestions = [];
        _isFetchingSuggestions = false;
      });
      return;
    }
    setState(() {
      _isFetchingSuggestions = true;
      // Optionally clear full results when typing for new suggestions
      // _searchResults = null;
    });

    // Simple debounce
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      try {
        final fetchedSuggestions = await _searchService.getSearchSuggestions(
          _searchQuery.trim(),
          _selectedCategories, // Use currently selected categories for suggestions
          limitPerCategory: 3, // Limit suggestions per category
        );
        if (mounted) {
          setState(() {
            _suggestions = fetchedSuggestions;
            _isFetchingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isFetchingSuggestions = false;
            // Handle error, maybe show a toast or log
            print("Error fetching suggestions: $e");
            _suggestions = []; // Clear suggestions on error
          });
        }
      }
    });
  }

  Future<void> _performSearch({String? specificQuery}) async {
    final queryToUse = specificQuery ?? _searchQuery.trim();
    if (queryToUse.isEmpty || _selectedCategories.isEmpty) {
      setState(() {
        _searchResults = SearchResults();
        _isLoading = false;
      });
      return;
    }

    // Add to history before performing search
    if (queryToUse.isNotEmpty) {
      await _searchService.addSearchTermToHistory(queryToUse);
      // Optionally reload history if it's visible and you want it to update immediately
      // if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) { _loadSearchHistory(); }
    }

    setState(() {
      _isLoading = true;
    });
    final results = await _searchService.search(
      queryToUse,
      _selectedCategories,
    );
    if (mounted) {
      // Check if the widget is still in the tree
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode, // Assign FocusNode
              decoration: InputDecoration(
                hintText: 'Search tracks, albums, artists, playlists...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery
                            .isNotEmpty // Show clear button only if query is not empty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear search query',
                          onPressed: () {
                            _searchController.clear();
                            // _performSearch(); // Optionally re-perform search or just clear results
                            setState(() {
                              _searchResults =
                                  null; // Clear results when query is cleared
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onSubmitted: (String value) {
                final trimmedValue = value.trim();
                if (trimmedValue.isNotEmpty) {
                  // Add to history before performing search
                  _searchService.addSearchTermToHistory(trimmedValue);
                }
                setState(() {
                  _suggestions = [];
                  _isFetchingSuggestions =
                      false; // Ensure suggestion fetching stops if it was ongoing
                  if (_debounce?.isActive ?? false) {
                    _debounce!.cancel(); // Cancel any pending suggestion fetch
                  }
                });
                _performSearch(
                  specificQuery: trimmedValue,
                ); // Perform search with the submitted value
              },
              // onChanged is not strictly needed here as listener handles it
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              // Wrap Wrap and Suggestions List in a Column
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      SearchCategory.values.map((category) {
                        return ChoiceChip(
                          label: Text(
                            category.name[0].toUpperCase() +
                                category.name.substring(1),
                          ),
                          selected: _selectedCategories.contains(category),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                // Keep at least one category selected, or allow zero?
                                // For now, allowing zero, but search won't run.
                                _selectedCategories.remove(category);
                              }
                            });
                            _performSearch(); // Perform search when categories change
                          },
                        );
                      }).toList(),
                ),
                // Suggestions List (conditionally visible)
                if (_searchQuery.isNotEmpty &&
                    _suggestions.isNotEmpty &&
                    !_isLoading &&
                    !_isFetchingSuggestions)
                  SizedBox(
                    height:
                        200, // Adjust height as needed, or use Flexible/Expanded if appropriate in layout
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.lightbulb_outline,
                            semanticLabel: 'Suggestion',
                          ), // Suggestion icon
                          title: Text(suggestion),
                          onTap: () {
                            _searchController.text = suggestion;
                            _searchController
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _searchController.text.length,
                              ),
                            );
                            // Add to history before performing search
                            _searchService.addSearchTermToHistory(suggestion);
                            setState(() {
                              _suggestions = [];
                              _searchQuery = suggestion;
                            });
                            _performSearch(specificQuery: suggestion);
                          },
                        );
                      },
                    ),
                  ),
                // Search History List (conditionally visible)
                if (_searchFocusNode.hasFocus &&
                    _searchController.text.isEmpty &&
                    _searchHistoryItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Searches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearAndLoadSearchHistory,
                          child: const Text('Clear'),
                          // Consider adding a tooltip for clarity if TextButton supports it directly
                          // or wrapping with Semantics for a better label if needed.
                        ),
                      ],
                    ),
                  ),
                if (_searchFocusNode.hasFocus &&
                    _searchController.text.isEmpty &&
                    _searchHistoryItems.isNotEmpty)
                  SizedBox(
                    height: 200, // Adjust height as needed
                    child: ListView.builder(
                      itemCount: _searchHistoryItems.length,
                      itemBuilder: (context, index) {
                        final historyItem = _searchHistoryItems[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.history,
                            semanticLabel: 'Recent search',
                          ), // Added semanticLabel
                          title: Text(historyItem),
                          onTap: () {
                            _searchController.text = historyItem;
                            _searchController
                                .selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _searchController.text.length,
                              ),
                            );
                            // No need to add to history again, _performSearch will handle it if logic changes
                            setState(() {
                              _suggestions = []; // Clear suggestions if any
                              _searchQuery =
                                  historyItem; // Update searchQuery for _performSearch
                            });
                            _performSearch(specificQuery: historyItem);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults == null || _searchResults!.isEmpty
                    ? Center(
                      child: Text(
                        _searchQuery.trim().isEmpty
                            ? 'Start typing to search'
                            : 'No results found.',
                      ),
                    )
                    : _buildResultsList(), // TODO: Implement _buildResultsList
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchResults == null || _searchResults!.isEmpty) {
      return const Center(child: Text('No results to display.'));
    }

    List<Widget> sectionWidgets = [];

    // Tracks Section
    if (_searchResults!.tracks.isNotEmpty) {
      sectionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Semantics(
            header: true,
            child: Text(
              'Tracks (${_searchResults!.tracks.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
      sectionWidgets.addAll(
        _searchResults!.tracks.map((track) {
          final libraryProvider = Provider.of<MusicLibraryProvider>(
            context,
            listen: false,
          );
          return ListTile(
            leading: QueryArtworkWidget(
              id: track.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: const Icon(Icons.music_note),
              artworkBorder: BorderRadius.circular(4.0),
              artworkHeight: 50,
              artworkWidth: 50,
            ),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<bool>(
                  future: libraryProvider.isFavorite(track.id),
                  builder: (context, snapshot) {
                    bool isFav = false;
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      isFav = snapshot.data!;
                    }
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.redAccent : null,
                      ),
                      tooltip:
                          isFav ? 'Remove from favorites' : 'Add to favorites',
                      onPressed: () async {
                        await libraryProvider.toggleFavorite(track);
                        // The FutureBuilder will rebuild the icon, force a state update on the list if needed
                        // For now, assume provider notifies listeners which should rebuild this part of the tree.
                        // If not, might need to call setState on the SearchTabScreen or use a more local state management for the item.
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Play track', // Existing tooltip, ensure it's clear
                  onPressed: () async {
                    print('Play track: ${track.title}');
                    await AudioPlayerService().loadPlaylist([
                      track,
                    ], initialIndex: 0);
                    await AudioPlayerService().play();
                  },
                ),
              ],
            ),
            onTap: () async {
              // Handle track tap - play the track
              print('Tapped track: ${track.title}, playing...');
              await AudioPlayerService().loadPlaylist([track], initialIndex: 0);
              await AudioPlayerService().play();
              // TODO: Potentially show mini_player or navigate to full player screen
            },
          );
        }),
      );
      sectionWidgets.add(const Divider());
    }

    // Albums Section
    if (_searchResults!.albums.isNotEmpty) {
      sectionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Semantics(
            header: true,
            child: Text(
              'Albums (${_searchResults!.albums.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
      sectionWidgets.addAll(
        _searchResults!.albums.map(
          (album) => ListTile(
            leading: QueryArtworkWidget(
              id: album.id,
              type: ArtworkType.ALBUM,
              nullArtworkWidget: const Icon(Icons.album),
              artworkBorder: BorderRadius.circular(4.0),
              artworkHeight: 50,
              artworkWidth: 50,
            ),
            title: Text(
              album.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              album.artist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              print('Tapped album: ${album.album}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumDetailsScreen(album: album),
                ),
              );
            },
          ),
        ),
      );
      sectionWidgets.add(const Divider());
    }

    // Artists Section
    if (_searchResults!.artists.isNotEmpty) {
      sectionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Semantics(
            header: true,
            child: Text(
              'Artists (${_searchResults!.artists.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
      sectionWidgets.addAll(
        _searchResults!.artists.map(
          (artist) => ListTile(
            leading: QueryArtworkWidget(
              id: artist.id,
              type: ArtworkType.ARTIST,
              nullArtworkWidget: const Icon(Icons.person),
              artworkBorder: BorderRadius.circular(25.0),
              artworkHeight: 50,
              artworkWidth: 50,
            ),
            title: Text(
              artist.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${artist.numberOfAlbums ?? 0} Albums, ${artist.numberOfTracks ?? 0} Tracks',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              print('Tapped artist: ${artist.artist}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistDetailsScreen(artist: artist),
                ),
              );
            },
          ),
        ),
      );
      sectionWidgets.add(const Divider());
    }

    // Playlists Section
    if (_searchResults!.playlists.isNotEmpty) {
      sectionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Semantics(
            header: true,
            child: Text(
              'Playlists (${_searchResults!.playlists.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
      sectionWidgets.addAll(
        _searchResults!.playlists.map((playlist) {
          Widget leadingWidget;
          if (playlist.coverImagePath != null &&
              playlist.coverImagePath!.isNotEmpty) {
            try {
              leadingWidget = SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Image.file(
                    File(playlist.coverImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50);
                    },
                  ),
                ),
              );
            } catch (e) {
              leadingWidget = const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.playlist_play, size: 50),
              );
            }
          } else {
            leadingWidget = const SizedBox(
              width: 50,
              height: 50,
              child: Icon(Icons.playlist_play, size: 50),
            );
          }
          return ListTile(
            leading: leadingWidget,
            title: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${playlist.trackIds.length} tracks',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              print('Tapped playlist: ${playlist.name}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PlaylistDetailScreen(playlist: playlist),
                ),
              );
            },
          );
        }),
      );
      sectionWidgets.add(const Divider());
    }

    if (sectionWidgets.isNotEmpty && sectionWidgets.last is Divider) {
      sectionWidgets.removeLast();
    }

    return ListView(children: sectionWidgets);
  }
}
