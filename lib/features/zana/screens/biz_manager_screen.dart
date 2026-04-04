import 'package:flutter/material.dart';

class BizManagerScreen extends StatelessWidget {
  const BizManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Manager')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Business Manager architecture is ready for the next build step.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
