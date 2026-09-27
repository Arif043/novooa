import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';
import 'runtime_endpoint.dart';
import 'runtime_license_form.dart';
import 'runtime_password_setup_form.dart';

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
                      RuntimeConnectionNeedsPassword(
                        :final endpoint,
                        :final errorMessage,
                      ) =>
                        _PasswordForm(
                          endpoint: endpoint,
                          errorMessage: errorMessage,
                        ),
                      RuntimeConnectionNeedsLicense(
                        :final endpoint,
                        :final errorMessage,
                      ) => RuntimeLicenseForm(
                        endpoint: endpoint,
                        errorMessage: errorMessage,
                      ),
                      RuntimeConnectionNeedsPasswordSetup(
                        :final endpoint,
                        :final errorMessage,
                      ) => RuntimePasswordSetupForm(
                        endpoint: endpoint,
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
          'Gib die IP-Adresse des Rechners im LAN ein, auf dem novooa läuft. '
          'Ist die Runtime über eine Domain mit Zertifikat erreichbar, gib '
          'stattdessen die Domain ein — die Verbindung läuft dann '
          'verschlüsselt. Für einen internen Hostnamen ohne Zertifikat stelle '
          'http:// voran.',
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
            labelText: 'Adresse der Runtime',
            hintText: '192.168.1.42 oder novooa.beispiel.de',
            errorText: widget.errorMessage,
            errorMaxLines: 4,
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

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({required this.endpoint, this.errorMessage});

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline, size: 48, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Anmeldung erforderlich',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Gib das Zugriffs-Passwort dieser Runtime ein.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Passwort',
            errorText: widget.errorMessage,
            prefixIcon: const Icon(Icons.password_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _login,
          icon: const Icon(Icons.login),
          label: const Text('Anmelden'),
        ),
      ],
    );
  }

  void _login() {
    context.read<RuntimeConnectionCubit>().login(
      widget.endpoint,
      _passwordController.text,
    );
  }
}
