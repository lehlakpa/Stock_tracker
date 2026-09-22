import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_error.dart';

/// Firebase's callable protocol for platforms without a Functions plugin.
Future<void> callAuthenticatedFunction({
  required Uri endpoint,
  required String token,
  required Map<String, dynamic> data,
  http.Client? client,
}) async {
  final transport = client ?? http.Client();
  try {
    final response = await transport
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 60));
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const AppException(
        'The account service is unavailable. Check that Firebase functions are deployed.',
      );
    }
    if (body is Map && body['error'] is Map) {
      throw AppException(
        body['error']['message'] as String? ?? 'Account creation failed.',
      );
    }
    if (response.statusCode != 200 ||
        body is! Map ||
        (!body.containsKey('data') && !body.containsKey('result'))) {
      throw const AppException(
        'The account service returned an invalid response.',
      );
    }
  } finally {
    if (client == null) transport.close();
  }
}
