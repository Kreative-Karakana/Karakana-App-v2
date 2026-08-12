import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/network/api_client.dart';
import 'package:karakana_app/features/auth/services/auth_service.dart';

/// Records the last request Dio tried to send and returns a canned
/// response, without touching the network — no mocking package needed,
/// Dio's HttpClientAdapter is a small enough interface to fake directly.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({'token': 'fake-knox-token'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;

  setUp(() {
    adapter = _RecordingAdapter();
    ApiClient().dio.httpClientAdapter = adapter;
  });

  group('AuthService.exchangeAppleToken', () {
    test('includes authorization_code in the request body when supplied', () async {
      await AuthService().exchangeAppleToken(
        idToken: 'id-token-value',
        firstName: 'Zuri',
        lastName: 'Mkulima',
        authorizationCode: 'auth-code-value',
      );

      final body = adapter.lastRequest!.data as Map;
      expect(adapter.lastRequest!.path, '/api/apple-oauth/');
      expect(body['id_token'], 'id-token-value');
      expect(body['authorization_code'], 'auth-code-value');
    });

    test('omits authorization_code when Apple did not supply one', () async {
      await AuthService().exchangeAppleToken(idToken: 'id-token-value');

      final body = adapter.lastRequest!.data as Map;
      expect(body.containsKey('authorization_code'), isFalse);
    });

    test('never sends the identity token under the authorization_code key', () async {
      await AuthService().exchangeAppleToken(
        idToken: 'id-token-value',
        authorizationCode: 'auth-code-value',
      );

      final body = adapter.lastRequest!.data as Map;
      expect(body['authorization_code'], isNot(equals(body['id_token'])));
    });
  });
}
