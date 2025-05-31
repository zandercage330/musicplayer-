import 'package:flutter/material.dart';
import 'package:musify/screens/tabs/home_tab_screen.dart';
import 'package:musify/screens/tabs/search_tab_screen.dart';
import 'package:musify/screens/library_screen.dart';
import 'package:musify/screens/playlist_screen.dart';
import 'package:musify/screens/tabs/favorites_tab_screen.dart';
import 'package:musify/screens/tabs/profile_tab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:musify/widgets/mini_player_widget.dart'; // Added import
import 'package:musify/services/audio_player_service.dart'; // Added
import 'package:musify/models/track.dart'; // Added

const String _kLastSelectedTabKey = 'last_selected_tab_index';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // To keep track of the selected tab
  // Access AudioPlayerService instance
  final AudioPlayerService _audioPlayerService = AudioPlayerService(); // Added

  // Placeholder list of widgets to display for each tab
  // These will be replaced by actual screen widgets in a later subtask (7.3)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeTabScreen(),
    SearchTabScreen(),
    LibraryScreen(),
    PlaylistScreen(),
    FavoritesTabScreen(),
    ProfileTabScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedIndex();
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt(_kLastSelectedTabKey) ?? 0;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSelectedTabKey, index);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveSelectedIndex(index); // Save the index when a tab is tapped
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are on the NowPlayingScreen
    final ModalRoute<dynamic>? currentRoute = ModalRoute.of(context);
    final bool onNowPlayingScreen =
        currentRoute?.settings.name == 'NowPlayingScreen';

    return PopScope(
      canPop: _selectedIndex == 0, // Only allow pop if on the first tab (Home)
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return; // If already popped (e.g. by system back), do nothing
        }
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Navigate to Home tab
            _saveSelectedIndex(0); // Save this change
          });
          // Do not pop, as we handled it by changing tab
        }
        // If _selectedIndex is already 0, canPop is true, so it will pop normally.
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Musify'), // Optional AppBar
        // ),
        body: IndexedStack(
          // Using IndexedStack to keep state of inactive tabs
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Track?>(
              stream: _audioPlayerService.currentTrackStream,
              builder: (context, snapshot) {
                // Show miniplayer if snapshot has data, the data (track) is not null,
                // and not on NowPlayingScreen
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    !onNowPlayingScreen) {
                  return const MiniPlayerWidget();
                }
                return const SizedBox.shrink(); // Otherwise, show nothing
              },
            ),
            BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home), // Example active icon
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search), // Example active icon
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(
                    Icons.library_music,
                  ), // Added Library tab icon
                  label: 'Library', // Added Library tab label
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.playlist_play_outlined),
                  activeIcon: Icon(Icons.playlist_play),
                  label: 'Playlists',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border_outlined),
                  activeIcon: Icon(Icons.favorite), // Example active icon
                  label: 'Favorites',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person), // Example active icon
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              // Styling based on common practices, assuming a dark theme from NowPlayingScreen
              backgroundColor: const Color(
                0xFF121212,
              ), // Dark background for nav bar
              selectedItemColor:
                  Theme.of(context)
                      .colorScheme
                      .secondary, // Use a theme color (e.g., the teal from NowPlaying)
              unselectedItemColor: Colors.grey[600],
              showUnselectedLabels: true, // Or false based on design
              onTap: _onItemTapped,
              type:
                  BottomNavigationBarType
                      .fixed, // Ensures all labels are visible and items don't shift
            ),
          ],
        ),
      ),
    );
  }
}
