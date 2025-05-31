import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musify/providers/profile_provider.dart';
import 'package:musify/services/audio_player_service.dart';
import 'package:provider/provider.dart';
import 'package:musify/screens/appearance_screen.dart';
import 'package:musify/screens/edit_profile_screen.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(
      context,
      listen: false,
    );
    // Use a Consumer to listen to ProfileProvider changes
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        Widget profileAvatar = CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[300],
          backgroundImage:
              profileProvider.imagePath != null
                  ? FileImage(File(profileProvider.imagePath!))
                  : null,
          child:
              profileProvider.imagePath == null
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
        );

        String profileName = profileProvider.name ?? 'User Name';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile & Settings'),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: ListView(
            children: <Widget>[
              ListTile(
                leading: profileAvatar, // Use the avatar here
                title: Text(profileName), // Display the name
                subtitle: const Text('View and edit profile'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Appearance'),
                subtitle: const Text('Change theme, colors, etc.'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppearanceScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              StreamBuilder<bool>(
                stream: audioPlayerService.autoResumePreferenceStream,
                initialData: audioPlayerService.currentAutoResumePreference,
                builder: (context, snapshot) {
                  final bool autoResumeEnabled =
                      snapshot.hasData
                          ? snapshot.data!
                          : audioPlayerService.currentAutoResumePreference;
                  return SwitchListTile(
                    secondary: const Icon(Icons.play_circle_outline),
                    title: const Text('Auto-resume playback'),
                    subtitle: const Text(
                      'Automatically resume after interruptions if possible',
                    ),
                    value: autoResumeEnabled,
                    onChanged: (bool value) {
                      audioPlayerService.setAutoResumePreference(value);
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Musify'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('About Musify - Not implemented'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
