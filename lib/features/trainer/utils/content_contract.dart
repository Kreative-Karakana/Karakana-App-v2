/// Payload builders for the trainer section/lesson content APIs.
///
/// Mirrors `SectionWriteSerializer` / `LessonWriteSerializer` in the
/// backend (`api/v1/courses/serializers.py`): both only accept `title`
/// (required), plus `mux_playback_id` for lessons. `index`/`order`,
/// `status`, and `duration` have no model field on `Section`/`Lesson`
/// and are silently dropped server-side, so they must never be sent —
/// doing so only misleads trainers into thinking those values took
/// effect.
class ContentContract {
  ContentContract._();

  static Map<String, dynamic> buildSectionPayload(String title) {
    return {'title': title.trim()};
  }

  static Map<String, dynamic> buildLessonPayload(
    String title, {
    String? muxPlaybackId,
  }) {
    final trimmedMux = muxPlaybackId?.trim() ?? '';
    return {
      'title': title.trim(),
      if (trimmedMux.isNotEmpty) 'mux_playback_id': trimmedMux,
    };
  }
}
