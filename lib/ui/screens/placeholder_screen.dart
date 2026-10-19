import 'package:flutter/material.dart';

import '../theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(
      {super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(description,
              style: const TextStyle(color: AppColors.muted, height: 1.4)),
        ],
      ),
    );
  }
}
