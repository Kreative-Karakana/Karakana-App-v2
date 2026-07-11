class TrainerCourseFilters {
  static const ownedCoursesPageSize = 100;

  static const ownedCoursesQueryParameters = <String, dynamic>{
    'page_size': ownedCoursesPageSize,
  };

  static List<Map<String, dynamic>> ownedCoursesFromResponse(dynamic data) {
    final rawList = data is Map
        ? (data['results'] as List? ?? const [])
        : (data as List? ?? const []);

    return rawList
        .whereType<Map>()
        .map((course) => Map<String, dynamic>.from(course))
        .where(isOwnedByCurrentTrainer)
        .toList();
  }

  static bool isOwnedByCurrentTrainer(Map<String, dynamic> course) {
    final trainer = course['trainer'];
    if (trainer is! Map) return false;
    return trainer['is_owner'] == true;
  }
}
