import 'package:flutter/material.dart';

class FursaScreen extends StatelessWidget {
  const FursaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline,
                size: 64, color: Color(0xFFE87722)),
            const SizedBox(height: 16),
            const Text(
              'Fursa Zinakuja Hivi Karibuni',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tunatengeneza fursa za biashara\nna masoko kwa ajili yako.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      )),
    );
  }
}
