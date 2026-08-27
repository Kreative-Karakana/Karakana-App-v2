import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/home/screens/main_screen.dart';

void main() {
  test('bottom navigation exposes descriptive labels for all five tabs', () {
    expect(
      List.generate(5, mainTabSemanticLabel),
      ['Nyumbani', 'Tafuta', 'Zana', 'Fursa', 'Akaunti'],
    );
  });
}
