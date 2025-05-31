import 'package:flutter/material.dart';

class PlaceholderContentWidget extends StatelessWidget {
  final IconData iconData;
  final String message;
  final String? details;

  const PlaceholderContentWidget({
    super.key,
    required this.iconData,
    required this.message,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(iconData, size: 80.0, color: Colors.grey[600]),
            const SizedBox(height: 24.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (details != null && details!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  details!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
