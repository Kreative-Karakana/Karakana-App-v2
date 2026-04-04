import 'package:flutter/material.dart';

class VideoLessonScreen extends StatelessWidget {
  final int lessonId;

  const VideoLessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lesson $lessonId')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Video lesson player placeholder for lesson $lessonId.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
