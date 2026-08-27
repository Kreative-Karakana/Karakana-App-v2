import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/courses/widgets/star_rating_input.dart';
import 'package:karakana_app/widgets/common/minimum_tap_target.dart';

void main() {
  testWidgets('stars have minimum tap targets, spacing, and exact selection',
      (tester) async {
    var selectedRating = 5;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Center(
            child: StarRatingInput(
              rating: selectedRating,
              onChanged: (rating) => setState(() => selectedRating = rating),
            ),
          ),
        ),
      ),
    );

    final targets = List.generate(
      5,
      (index) => find.byKey(ValueKey('rating-star-${index + 1}')),
    );
    for (final target in targets) {
      expect(
        tester.getSize(target),
        const Size(
          MinimumTapTarget.minimumWidth,
          MinimumTapTarget.minimumHeight,
        ),
      );
    }

    final firstRect = tester.getRect(targets[0]);
    final secondRect = tester.getRect(targets[1]);
    expect(secondRect.left - firstRect.right, StarRatingInput.spacing);

    await tester.tap(targets[2]);
    await tester.pump();
    expect(selectedRating, 3);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });
}
