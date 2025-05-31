import 'package:flutter/material.dart';
import 'package:musify/models/track.dart';
import 'package:musify/services/music_scanner_service.dart';

class AddTracksToPlaylistScreen extends StatefulWidget {
  final List<int>
  existingTrackIdsInPlaylist; // To disable or indicate already added tracks

  const AddTracksToPlaylistScreen({
    super.key,
    required this.existingTrackIdsInPlaylist,
  });

  @override
  State<AddTracksToPlaylistScreen> createState() =>
      _AddTracksToPlaylistScreenState();
}

class _AddTracksToPlaylistScreenState extends State<AddTracksToPlaylistScreen> {
  final MusicScannerService _musicScannerService = MusicScannerService();
  List<Track> _allTracks = [];
  bool _isLoading = true;
  final Set<int> _selectedTrackIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllTracks();
  }

  Future<void> _loadAllTracks() async {
    setState(() => _isLoading = true);
    try {
      _allTracks = await _musicScannerService.getTracks();
    } catch (e) {
      print("Error loading all tracks: $e");
      // Handle error, maybe show a snackbar
    }
    setState(() => _isLoading = false);
  }

  void _toggleTrackSelection(int trackId) {
    setState(() {
      if (_selectedTrackIds.contains(trackId)) {
        _selectedTrackIds.remove(trackId);
      } else {
        _selectedTrackIds.add(trackId);
      }
    });
  }

  void _doneSelection() {
    Navigator.of(context).pop(List<int>.from(_selectedTrackIds));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tracks'),
        actions: [
          TextButton(
            onPressed: _selectedTrackIds.isEmpty ? null : _doneSelection,
            child: Text('Add Selected (${_selectedTrackIds.length})'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allTracks.isEmpty
              ? const Center(child: Text('No tracks found on device.'))
              : ListView.builder(
                itemCount: _allTracks.length,
                itemBuilder: (context, index) {
                  final track = _allTracks[index];
                  final bool isSelected = _selectedTrackIds.contains(track.id);
                  final bool alreadyInPlaylist = widget
                      .existingTrackIdsInPlaylist
                      .contains(track.id);

                  return ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged:
                          alreadyInPlaylist
                              ? null
                              : (bool? value) {
                                _toggleTrackSelection(track.id);
                              },
                    ),
                    title: Text(track.title),
                    subtitle: Text(track.artist ?? 'Unknown Artist'),
                    enabled: !alreadyInPlaylist,
                    onTap:
                        alreadyInPlaylist
                            ? null
                            : () {
                              _toggleTrackSelection(track.id);
                            },
                  );
                },
              ),
    );
  }
}
