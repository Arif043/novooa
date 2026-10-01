import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/features/licensing/domain/entities/runtime_license.dart';
import 'package:syscat2/features/licensing/infrastructure/repositories/http_runtime_license_repository.dart';

void main() {
  final licenseKey = RuntimeLicenseKey.tryCreate('A3K9-N7P2-Q4R6-T8W5')!;

  Future<RuntimeLicenseFailureKind?> failureKindFor(int statusCode) async {
    final repository = HttpRuntimeLicenseRepository(
      _FailingClient(
        WorkspaceHttpException(
          statusCode,
          const WorkspaceApiError(message: 'Runtime-Meldung'),
        ),
      ),
    );
    final statusOrFailure = await repository.activate(licenseKey);
    return switch (statusOrFailure) {
      Success() => null,
      Error(error: final failure) => failure.kind,
    };
  }

  test('distinguishes the causes reported by the runtime', () async {
    expect(
      await failureKindFor(400),
      RuntimeLicenseFailureKind.invalidLicenseKey,
    );
    expect(
      await failureKindFor(401),
      RuntimeLicenseFailureKind.activationRejected,
    );
    expect(
      await failureKindFor(502),
      RuntimeLicenseFailureKind.gatewayUnavailable,
    );
    expect(await failureKindFor(500), RuntimeLicenseFailureKind.unexpected);
  });
}

class _FailingClient implements WorkspaceApiClient {
  const _FailingClient(this.error);

  final Object error;

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) =>
      Future.error(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
