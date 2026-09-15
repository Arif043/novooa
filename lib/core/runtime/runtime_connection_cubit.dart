import 'package:flutter_bloc/flutter_bloc.dart';

import 'runtime_availability.dart';
import 'runtime_connection_state.dart';
import 'runtime_endpoint.dart';
import 'runtime_endpoint_store.dart';

class RuntimeConnectionCubit extends Cubit<RuntimeConnectionState> {
  RuntimeConnectionCubit(this._endpoints, this._availability)
    : super(const RuntimeConnectionLoading());

  final RuntimeEndpointStore _endpoints;
  final RuntimeAvailability _availability;

  Future<void> initialize(RuntimeEndpoint defaultEndpoint) async {
    try {
      final endpoint = await _endpoints.load() ?? defaultEndpoint;
      await connect(endpoint.address);
    } on Object {
      emit(
        RuntimeConnectionNeedsAddress(
          defaultEndpoint.address,
          errorMessage:
              'Die gespeicherte Runtime-Adresse konnte nicht geladen werden.',
        ),
      );
    }
  }

  Future<void> connect(String address) async {
    emit(RuntimeConnectionConnecting(address));
    try {
      final endpoint = RuntimeEndpoint.fromAddress(address);
      await _availability.check(endpoint);
      await _endpoints.save(endpoint);
      emit(RuntimeConnectionReady(endpoint));
    } on RuntimeEndpointValidationFailure {
      emit(
        RuntimeConnectionNeedsAddress(
          address,
          errorMessage: 'Bitte gib eine private IPv4-Adresse ein.',
        ),
      );
    } on Object {
      emit(
        RuntimeConnectionNeedsAddress(
          address,
          errorMessage:
              'Die Runtime konnte unter dieser Adresse nicht erreicht werden.',
        ),
      );
    }
  }
}
