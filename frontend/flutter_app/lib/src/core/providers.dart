import "package:flutter_riverpod/flutter_riverpod.dart";

import "api_client.dart";

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final sessionIdProvider = StateProvider<String>((ref) => "session-demo-1");
