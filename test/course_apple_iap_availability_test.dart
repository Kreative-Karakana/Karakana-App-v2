import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/courses/screens/course_detail_screen.dart';

void main() {
  test('paid iOS course without a product id is unavailable for purchase', () {
    expect(
      isAppleCoursePurchaseDisabled(
        isIOS: true,
        isFree: false,
        productId: null,
      ),
      isTrue,
    );
    expect(
      isAppleCoursePurchaseDisabled(isIOS: true, isFree: false, productId: ''),
      isTrue,
    );
  });

  test(
    'free courses and configured products are not disabled by this guard',
    () {
      expect(
        isAppleCoursePurchaseDisabled(
          isIOS: true,
          isFree: true,
          productId: null,
        ),
        isFalse,
      );
      expect(
        isAppleCoursePurchaseDisabled(
          isIOS: true,
          isFree: false,
          productId: 'course.product',
        ),
        isFalse,
      );
    },
  );
}
