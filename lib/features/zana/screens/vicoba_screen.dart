import 'package:flutter/material.dart';

class VicobScreen extends StatelessWidget {
  const VicobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('e-VICOBA')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'e-VICOBA is coming soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
