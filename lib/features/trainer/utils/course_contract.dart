class CourseLevelOption {
  final String value;
  final String label;

  const CourseLevelOption(this.value, this.label);
}

class CourseStatusPresentation {
  final String label;
  final int colorValue;

  const CourseStatusPresentation(this.label, this.colorValue);
}

class CourseValidationResult {
  final Map<String, String> fieldErrors;

  const CourseValidationResult(this.fieldErrors);

  bool get isValid => fieldErrors.isEmpty;
  String? get firstError =>
      fieldErrors.values.isEmpty ? null : fieldErrors.values.first;
}

class CoursePayloadInput {
  final String title;
  final String description;
  final String priceText;
  final String level;
  final String categoryId;
  final String status;

  const CoursePayloadInput({
    required this.title,
    required this.description,
    required this.priceText,
    required this.level,
    required this.categoryId,
    required this.status,
  });
}

class CourseContract {
  static const statusDraft = 'draft';
  static const statusPendingReview = 'pending_review';
  static const statusPublished = 'published';
  static const statusRejected = 'rejected';

  static const levelBeginner = 'beginner';
  static const levelIntermediate = 'intermediate';
  static const levelAdvanced = 'advanced';
  static const levelShortCourse = 'short_course';

  static const submitForReviewStatus = statusPendingReview;

  static const levelOptions = [
    CourseLevelOption(levelBeginner, 'Mwanzo'),
    CourseLevelOption(levelIntermediate, 'Kati'),
    CourseLevelOption(levelAdvanced, 'Juu'),
    CourseLevelOption(levelShortCourse, 'Kozi Fupi'),
  ];

  static const levelLabels = {
    levelBeginner: 'Mwanzo',
    levelIntermediate: 'Kati',
    levelAdvanced: 'Juu',
    levelShortCourse: 'Kozi Fupi',
  };

  static const statusPresentations = {
    statusDraft: CourseStatusPresentation('Rasimu', 0xFF6B7280),
    statusPendingReview: CourseStatusPresentation(
      'Inasubiri Ukaguzi',
      0xFFE87722,
    ),
    statusPublished: CourseStatusPresentation('Imechapishwa', 0xFF2E7D32),
    statusRejected: CourseStatusPresentation('Imekataliwa', 0xFFB71C1C),
  };

  // What the trainer should understand/do next for each lifecycle state.
  static const statusGuidance = {
    statusDraft:
        'Bado haijawasilishwa. Kamilisha maelezo kisha tuma kwa ukaguzi.',
    statusPendingReview:
        'Timu ya Kreative Karakana inaipitia kozi yako. Tutakujulisha baada ya ukaguzi.',
    statusPublished: 'Kozi yako imechapishwa na inapatikana kwa wanafunzi.',
    statusRejected:
        'Kozi yako haikukubaliwa. Rekebisha kulingana na sababu iliyotolewa kisha uwasilishe tena.',
  };

  static String normalizeLevel(String? value) {
    if (levelLabels.containsKey(value)) return value!;
    return levelBeginner;
  }

  static String normalizeStatus(String? value) {
    if (statusPresentations.containsKey(value)) return value!;
    return statusDraft;
  }

  static String levelLabel(String? value) {
    final normalized = normalizeLevel(value);
    return levelLabels[normalized] ?? normalized;
  }

  static CourseStatusPresentation statusPresentation(String? value) {
    return statusPresentations[normalizeStatus(value)]!;
  }

  static String statusGuidanceFor(String? value) {
    return statusGuidance[normalizeStatus(value)] ?? '';
  }

  static bool isRejected(String? value) =>
      normalizeStatus(value) == statusRejected;

  /// Extracts the trainer-facing rejection reason from a raw course JSON map,
  /// if the backend provided one. Returns null when absent/blank so callers
  /// only render a reason when it is actually available.
  static String? rejectionReason(Map? course) {
    final raw = course?['rejection_reason'];
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String submitActionLabel(String? value) {
    return isRejected(value) ? 'Wasilisha Tena' : 'Tuma kwa Ukaguzi';
  }

  static CourseValidationResult validatePayloadInput(
    CoursePayloadInput input, {
    required bool requireCategory,
  }) {
    final errors = <String, String>{};
    if (input.title.trim().isEmpty) {
      errors['title'] = 'Jaza jina la kozi.';
    }
    if (input.description.trim().isEmpty) {
      errors['description'] = 'Jaza maelezo ya kozi.';
    }
    if (requireCategory && input.categoryId.trim().isEmpty) {
      errors['category'] = 'Chagua kategoria ya kozi.';
    }
    final priceText = input.priceText.trim();
    final price = double.tryParse(priceText);
    if (priceText.isEmpty || price == null || price < 0) {
      errors['price'] = 'Weka bei sahihi ya kozi.';
    }
    if (!levelLabels.containsKey(input.level)) {
      errors['level'] = 'Chagua kiwango sahihi cha kozi.';
    }
    if (input.status != statusDraft && input.status != statusPendingReview) {
      errors['status'] = 'Hali hii ya kozi haiwezi kutumwa kutoka hapa.';
    }
    return CourseValidationResult(errors);
  }

  static Map<String, dynamic> buildPayload(CoursePayloadInput input) {
    final category = int.tryParse(input.categoryId.trim());
    return {
      'title': input.title.trim(),
      'description': input.description.trim(),
      'price': double.parse(input.priceText.trim()),
      'level': normalizeLevel(input.level),
      'status': input.status,
      if (category != null) 'category': category,
    };
  }
}
