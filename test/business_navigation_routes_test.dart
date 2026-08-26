import 'package:flutter_test/flutter_test.dart';

import 'package:karakana_app/core/router/app_router.dart';

void main() {
  test('business management routes remain nested under the Zana hub', () {
    expect(AppRoutes.zana, '/zana');
    expect(AppRoutes.zanaBusiness, '/zana/biz-manager');
    expect(AppRoutes.zanaBusiness.startsWith('${AppRoutes.zana}/'), isTrue);
  });
}
