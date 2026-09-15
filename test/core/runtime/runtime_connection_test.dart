import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_availability.dart';
import 'package:syscat2/core/runtime/runtime_connection_cubit.dart';
import 'package:syscat2/core/runtime/runtime_connection_state.dart';
import 'package:syscat2/core/runtime/runtime_endpoint.dart';
import 'package:syscat2/core/runtime/runtime_endpoint_store.dart';

void main() {
  group('RuntimeEndpoint', () {
    test('accepts private IPv4 addresses', () {
      expect(
        RuntimeEndpoint.fromAddress('192.168.1.42').apiUri.toString(),
        'http://192.168.1.42:8090',
      );
      expect(RuntimeEndpoint.fromAddress('10.0.0.12').address, '10.0.0.12');
      expect(RuntimeEndpoint.fromAddress('172.16.0.1').address, '172.16.0.1');
    });

    test('rejects public addresses', () {
      expect(
        () => RuntimeEndpoint.fromAddress('8.8.8.8'),
        throwsA(isA<RuntimeEndpointValidationFailure>()),
      );
    });
  });

  group('RuntimeConnectionCubit', () {
    test('connects with the stored address and persists it', () async {
      final endpoints = _MemoryEndpointStore(
        RuntimeEndpoint.fromAddress('192.168.1.20'),
      );
      final cubit = RuntimeConnectionCubit(
        endpoints,
        const _AvailableRuntime(),
      );

      await cubit.initialize(RuntimeEndpoint.fromAddress('127.0.0.1'));

      expect(cubit.state, isA<RuntimeConnectionReady>());
      expect(
        (cubit.state as RuntimeConnectionReady).endpoint.address,
        '192.168.1.20',
      );
      expect(endpoints.savedAddress, '192.168.1.20');
      await cubit.close();
    });

    test('shows an input error for an invalid address', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        const _AvailableRuntime(),
      );

      await cubit.connect('8.8.8.8');

      final state = cubit.state as RuntimeConnectionNeedsAddress;
      expect(state.errorMessage, 'Bitte gib eine private IPv4-Adresse ein.');
      await cubit.close();
    });
  });
}

class _MemoryEndpointStore implements RuntimeEndpointStore {
  _MemoryEndpointStore(this._endpoint);

  RuntimeEndpoint? _endpoint;
  String? savedAddress;

  @override
  Future<RuntimeEndpoint?> load() async => _endpoint;

  @override
  Future<void> save(RuntimeEndpoint endpoint) async {
    _endpoint = endpoint;
    savedAddress = endpoint.address;
  }
}

class _AvailableRuntime implements RuntimeAvailability {
  const _AvailableRuntime();

  @override
  Future<void> check(RuntimeEndpoint endpoint) async {}
}
