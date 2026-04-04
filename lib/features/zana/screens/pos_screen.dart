import 'package:flutter/material.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ZanaPlaceholderScreen(
      title: 'POS',
      subtitle: 'Point of Sale architecture is coming next.',
    );
  }
}

class _ZanaPlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ZanaPlaceholderScreen({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
