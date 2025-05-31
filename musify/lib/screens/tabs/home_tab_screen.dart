import 'package:flutter/material.dart';
import 'package:musify/widgets/home_screen_sections/recently_played_section.dart'; // Import the section
// import 'package:musify/widgets/home_screen_sections/new_release_section.dart'; // Old import
import 'package:musify/widgets/home_screen_sections/just_added_section.dart'; // New import
import 'package:musify/widgets/home_screen_sections/favorite_artists_section.dart'; // Import the new section
import 'package:musify/screens/notification_screen.dart'; // Added import for NotificationScreen
import 'package:musify/providers/notification_provider.dart'; // Import NotificationProvider
import 'package:provider/provider.dart'; // Import Provider

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Musify',
          style: TextStyle(
            fontFamily: 'Oxygen', // Ensuring consistent font
            fontWeight: FontWeight.bold,
            // color: Colors.white, // Assuming dark theme, AppBar will handle contrast
          ),
        ),
        backgroundColor:
            Theme.of(context).colorScheme.surface, // Use theme surface color
        elevation: 0, // Flat app bar
        actions: [
          Consumer<NotificationProvider>(
            // Wrap IconButton with Consumer
            builder: (context, notificationProvider, child) {
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none, // Allow badge to overflow
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red, // Badge color
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ), // Optional: border for contrast
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '${notificationProvider.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
                tooltip: 'Notifications',
              );
            },
          ),
        ],
      ),
      body: ListView(
        // Changed Center to ListView to accommodate multiple sections
        children: const <Widget>[
          SizedBox(height: 16), // Spacing from AppBar
          RecentlyPlayedSection(),
          SizedBox(height: 24), // Spacing between sections
          // NewReleaseSection(), // Old widget
          JustAddedSection(), // New widget
          SizedBox(height: 24), // Spacing between sections
          FavoriteArtistsSection(),
          SizedBox(height: 16), // Spacing at the bottom
        ],
      ),
    );
  }
}
