import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/fursa/models/fursa_item.dart';
import 'package:karakana_app/features/fursa/services/fursa_service.dart';

FursaItem _item({
  required int id,
  String title = 'Opportunity',
  String deadlineText = '',
}) {
  return FursaItem(
    id: id,
    title: title,
    subtitle: '',
    deadlineText: deadlineText,
    summary: '',
    sourceLabel: '',
    sourceUrl: '',
    ctaText: '',
    category: '',
    badgeText: '',
    amountText: '',
    imageUrl: null,
    isFeatured: false,
    publishedAt: '',
  );
}

void main() {
  group('FursaItem expiry', () {
    test('is not expired when the deadline is in the future', () {
      final item = _item(id: 1, deadlineText: '1st January 2099');
      expect(item.isExpired, isFalse);
    });

    test('is expired when the deadline has passed', () {
      final item = _item(id: 1, deadlineText: '1st January 2000');
      expect(item.isExpired, isTrue);
    });

    test('is not expired when the deadline text is empty or unparseable', () {
      expect(_item(id: 1, deadlineText: '').isExpired, isFalse);
      expect(_item(id: 1, deadlineText: 'Ongoing').isExpired, isFalse);
    });

    test('isExpiredAsOf treats a fixed reference date consistently', () {
      final item = _item(id: 1, deadlineText: '5th June 2026');
      expect(item.isExpiredAsOf(DateTime(2026, 6, 4)), isFalse);
      expect(item.isExpiredAsOf(DateTime(2026, 6, 6)), isTrue);
    });
  });

  group('FursaService.selectItemsToShow', () {
    late FursaService service;

    setUp(() => service = FursaService());

    test('returns backend items when present and unexpired', () {
      final backendItems = [
        _item(
            id: 10,
            title: 'Real opportunity',
            deadlineText: '1st January 2099'),
      ];

      final result = service.selectItemsToShow(backendItems);

      expect(result.map((i) => i.id), [10]);
    });

    test('drops expired items even when the backend returns some', () {
      final backendItems = [
        _item(id: 10, title: 'Expired', deadlineText: '1st January 2000'),
        _item(id: 11, title: 'Still valid', deadlineText: '1st January 2099'),
      ];

      final result = service.selectItemsToShow(backendItems);

      expect(result.map((i) => i.id), [11]);
    });

    test('falls back to emergency content when backend list is empty', () {
      final result = service.selectItemsToShow(const []);

      // The bundled emergency items all carry deadlines that are already
      // in the past relative to any realistic "now", so they must not
      // leak through - this proves stale hardcoded fallback data can no
      // longer be displayed.
      expect(result, isEmpty);
    });

    test(
        'falls back to emergency content when backend returns only placeholders',
        () {
      final backendItems = [
        _item(id: 1, title: 'Fursa ya Instagram #1'),
        _item(id: 2, title: 'Fursa ya Instagram #2'),
      ];

      final result = service.selectItemsToShow(backendItems);

      expect(result, isEmpty);
    });

    test('never returns an expired opportunity from either source', () {
      final backendItems = [
        _item(
            id: 1,
            title: 'Expired backend item',
            deadlineText: '1st January 2000'),
      ];

      final result = service.selectItemsToShow(backendItems);

      expect(result.every((item) => !item.isExpired), isTrue);
    });
  });
}
