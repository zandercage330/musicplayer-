import 'package:flutter/material.dart';
import 'package:musify/models/track.dart';

class TrackDetailsBottomSheet extends StatelessWidget {
  final Track track;

  const TrackDetailsBottomSheet({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            track.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Artist: ${track.artist ?? "Unknown Artist"}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Album: ${track.album ?? "Unknown Album"}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          if (track.durationMs != null)
            Text(
              'Duration: ${_formatDuration(Duration(milliseconds: track.durationMs!))}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 4),
          Text(
            'Path: ${track.filePath}',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          // TODO: Add more details if needed (e.g., album art, date added, etc.)
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
