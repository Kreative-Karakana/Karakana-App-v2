import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/trainer/utils/content_contract.dart';

void main() {
  group('ContentContract', () {
    test('builds a section payload with only the backend-writable field', () {
      final payload = ContentContract.buildSectionPayload('  Utangulizi  ');

      expect(payload, {'title': 'Utangulizi'});
      expect(payload.containsKey('order'), isFalse);
      expect(payload.containsKey('index'), isFalse);
      expect(payload.containsKey('status'), isFalse);
    });

    test('builds a lesson payload without mux_playback_id when omitted', () {
      final payload = ContentContract.buildLessonPayload('  Somo la 1  ');

      expect(payload, {'title': 'Somo la 1'});
      expect(payload.containsKey('mux_playback_id'), isFalse);
      expect(payload.containsKey('status'), isFalse);
      expect(payload.containsKey('duration'), isFalse);
    });

    test('builds a lesson payload with a trimmed mux_playback_id when provided',
        () {
      final payload = ContentContract.buildLessonPayload(
        'Somo la 1',
        muxPlaybackId: '  abc123xyz  ',
      );

      expect(payload, {'title': 'Somo la 1', 'mux_playback_id': 'abc123xyz'});
    });

    test('omits mux_playback_id when it is blank', () {
      final payload = ContentContract.buildLessonPayload(
        'Somo la 1',
        muxPlaybackId: '   ',
      );

      expect(payload.containsKey('mux_playback_id'), isFalse);
    });
  });
}
