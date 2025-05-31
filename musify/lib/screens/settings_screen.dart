import 'package:flutter/material.dart';
import 'package:musify/services/audio_player_service.dart'; // Assuming direct singleton access

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioPlayerService _audioPlayerService =
      AudioPlayerService(); // Access singleton

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        children: <Widget>[
          StreamBuilder<bool>(
            stream: _audioPlayerService.autoResumePreferenceStream,
            builder: (context, snapshot) {
              final bool currentValue =
                  snapshot.data ??
                  true; // Default to true if stream hasn't emitted

              return SwitchListTile(
                title: const Text('Auto-resume playback'),
                subtitle: const Text(
                  'Automatically resume playback after an audio interruption ends.',
                ),
                value: currentValue,
                onChanged: (bool newValue) {
                  _audioPlayerService.setAutoResumePreference(newValue);
                  // The StreamBuilder will rebuild with the new value from the stream
                },
                secondary: const Icon(Icons.play_arrow_outlined),
                activeColor: Theme.of(context).colorScheme.primary,
              );
            },
          ),
          const Divider(),
          // Add other settings here in the future
        ],
      ),
    );
  }
}
