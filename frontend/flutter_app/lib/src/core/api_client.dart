import "dart:convert";

import "package:http/http.dart" as http;

import "auth_gateway.dart";
import "config.dart";

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final authToken = token ?? await AuthGateway.instance.getToken();
    final response = await _client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/$path"),
      headers: {
        "content-type": "application/json",
        "authorization": "Bearer $authToken",
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
    String? token,
  }) async {
    final authToken = token ?? await AuthGateway.instance.getToken();
    final uri = Uri.parse("${AppConfig.apiBaseUrl}/$path").replace(queryParameters: query);
    final response = await _client.get(uri, headers: {"authorization": "Bearer $authToken"});
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(decoded["error"] ?? "Request failed");
    }
    return decoded;
  }
}
