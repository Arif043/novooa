import '../transport/workspace_api_client.dart';
import 'runtime_availability.dart';
import 'runtime_endpoint.dart';

class HttpRuntimeAvailability implements RuntimeAvailability {
  const HttpRuntimeAvailability();

  @override
  Future<void> check(RuntimeEndpoint endpoint) {
    return HttpWorkspaceApiClient(
      baseUri: endpoint.apiUri,
      timeout: const Duration(seconds: 3),
    ).get('/healthz');
  }
}
