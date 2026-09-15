import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';

class RuntimeConnectionPage extends StatelessWidget {
  const RuntimeConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pageMobile),
              child:
                  BlocBuilder<RuntimeConnectionCubit, RuntimeConnectionState>(
                    builder: (context, state) => switch (state) {
                      RuntimeConnectionLoading() => const _ConnectionLoading(),
                      RuntimeConnectionConnecting(:final address) =>
                        _AddressForm(address: address, isConnecting: true),
                      RuntimeConnectionNeedsAddress(
                        :final address,
                        :final errorMessage,
                      ) =>
                        _AddressForm(
                          address: address,
                          errorMessage: errorMessage,
                        ),
                      RuntimeConnectionReady() => const _ConnectionLoading(),
                    },
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionLoading extends StatelessWidget {
  const _ConnectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: AppSpacing.md),
        Text('Runtime wird verbunden ...'),
      ],
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({
    required this.address,
    this.errorMessage,
    this.isConnecting = false,
  });

  final String address;
  final String? errorMessage;
  final bool isConnecting;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address);
  }

  @override
  void didUpdateWidget(covariant _AddressForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _addressController.text = widget.address;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.dns_outlined, size: 48, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Runtime verbinden',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Gib die IP-Adresse des Rechners ein, auf dem novooa ausgeführt wird.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _addressController,
          enabled: !widget.isConnecting,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'IP-Adresse der Runtime',
            hintText: '192.168.1.42',
            errorText: widget.errorMessage,
            prefixIcon: const Icon(Icons.lan_outlined),
          ),
          onSubmitted: (_) => _connect(),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: widget.isConnecting ? null : _connect,
          icon: widget.isConnecting
              ? const SizedBox.square(
                  dimension: AppSpacing.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link),
          label: Text(widget.isConnecting ? 'Wird verbunden ...' : 'Verbinden'),
        ),
      ],
    );
  }

  void _connect() {
    context.read<RuntimeConnectionCubit>().connect(_addressController.text);
  }
}
