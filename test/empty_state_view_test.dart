import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/widgets/common/empty_state_view.dart';

void main() {
  testWidgets('renders the shared empty state without an action',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EmptyStateView(
        icon: Icons.inbox_outlined,
        title: 'Nothing here',
        subtitle: 'Try again later.',
      ),
    ));

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Try again later.'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('renders and invokes an optional action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: EmptyStateView(
        icon: Icons.inbox_outlined,
        title: 'Nothing here',
        actionLabel: 'Create one',
        onAction: () => tapped = true,
      ),
    ));

    await tester.tap(find.text('Create one'));
    expect(tapped, isTrue);
  });
}
