import "dart:convert";

import "package:http/http.dart" as http;

import "config.dart";

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String token = "demo-user",
  }) async {
    final response = await _client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/$path"),
      headers: {
        "content-type": "application/json",
        "authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(decoded["error"] ?? "Request failed");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    String token = "demo-user",
  }) async {
    final uri = Uri.parse("${AppConfig.apiBaseUrl}/$path").replace(queryParameters: query);
    final response = await _client.get(uri, headers: {"authorization": "Bearer $token"});
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(decoded["error"] ?? "Request failed");
    }
    return decoded;
  }
}
