import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis_safe/network_error_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Learning Materials uses the exact English network copy', () {
    final error = Exception(
      'ClientException: Connection closed while receiving data from '
      'https://example.supabase.co/rest/v1/learning_material_mobile_view',
    );

    expect(isNetworkError(error), isTrue);
    expect(learningMaterialsErrorCopy(error, isTagalog: false), (
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
    ));
    expect(learningMaterialsErrorCopy(error, isTagalog: true), (
      title: 'Walang Internet Connection',
      message: 'Pakisuri ang iyong internet connection at subukan muli.',
    ));
  });

  test('typed connection and timeout failures are network failures', () {
    expect(isNetworkError(const SocketException('offline')), isTrue);
    expect(isNetworkError(TimeoutException('request timed out')), isTrue);
  });

  test('an existing failure can be rendered in the newly selected language', () {
    const wasNetworkFailure = true;
    expect(
      learningMaterialsErrorCopyForNetwork(
        wasNetworkFailure,
        isTagalog: false,
      ).title,
      'No Internet Connection',
    );
    expect(
      learningMaterialsErrorCopyForNetwork(
        wasNetworkFailure,
        isTagalog: true,
      ).title,
      'Walang Internet Connection',
    );
  });

  test('backend and unrelated client failures use generic safe copy', () {
    final failures = [
      Exception('ClientException: invalid response payload'),
      PostgrestException(
        message: 'relation learning_material_mobile_view does not exist',
        code: '42P01',
      ),
    ];

    for (final error in failures) {
      expect(isNetworkError(error), isFalse);
      expect(learningMaterialsErrorCopy(error, isTagalog: false), (
        title: 'Unable to Load Learning Materials',
        message: 'Something went wrong. Please try again.',
      ));
      expect(learningMaterialsErrorCopy(error, isTagalog: true), (
        title: 'Hindi Ma-load ang Learning Materials',
        message: 'May nangyaring problema. Pakisubukang muli.',
      ));
    }
  });

  test('unknown auth provider text is never returned', () {
    final error = AuthException(
      'Error at https://example.supabase.co/auth/v1/token: secret details',
    );
    expect(
      friendlyAuthErrorMessage(error, isTagalog: false),
      'Something went wrong. Please try again.',
    );
  });

  test('auth connection and credential failures have safe localized copy', () {
    expect(
      friendlyAuthErrorMessage(
        const AuthException('Connection closed while receiving data'),
        isTagalog: true,
      ),
      'Pakisuri ang iyong internet connection at subukan muli.',
    );
    expect(
      friendlyAuthErrorMessage(
        const AuthException('Invalid login credentials'),
        isTagalog: false,
      ),
      'Incorrect email or password. Please try again.',
    );
  });
}
