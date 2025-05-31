import 'package:flutter/material.dart';
// import 'package:musify/models/artist.dart'; // Assuming you have an Artist model - REMOVED
import 'package:musify/models/track.dart'; // Assuming you have a Track model
import 'package:musify/providers/music_library_provider.dart';
import 'package:provider/provider.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;

  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  // Placeholder for artist biography
  String _artistBiography = "Loading biography...";
  List<Track> _artistTracks = [];

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    // Simulate fetching artist data
    // In a real app, you would fetch this from a service or database
    // For now, we'll use the MusicLibraryProvider to get tracks by this artist.
    final libraryProvider = Provider.of<MusicLibraryProvider>(
      context,
      listen: false,
    );

    // Placeholder for artist biography fetching
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    _artistBiography =
        "This is a placeholder biography for ${widget.artistName}. More details about their music and career will be displayed here.";

    // Get tracks by the artist
    // Assuming MusicLibraryProvider has a method to get all tracks
    // and we filter them here, or it has a direct method.
    // For simplicity, let's assume it has a way to get tracks for an artist.
    // This might need adjustment based on your actual MusicLibraryProvider implementation.
    _artistTracks = libraryProvider.getTracksByArtist(widget.artistName);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.artistName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biography',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(_artistBiography),
            const SizedBox(height: 24.0),
            Text(
              'Tracks',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            _artistTracks.isEmpty
                ? const Text('No tracks found for this artist.')
                : ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // To disable ListView's own scrolling
                  itemCount: _artistTracks.length,
                  itemBuilder: (context, index) {
                    final track = _artistTracks[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note), // Placeholder icon
                      title: Text(track.title),
                      subtitle: Text(
                        track.album ?? 'Unknown Album',
                      ), // Handle null album
                      onTap: () {
                        // TODO: Implement track playback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Playing ${track.title} - Not implemented',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
