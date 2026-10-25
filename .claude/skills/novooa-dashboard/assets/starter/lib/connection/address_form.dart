import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../app/dashboard_theme.dart';
import '../l10n/dashboard_keys.dart';

/// Adresse der Runtime (nur Desktop und Mobil; im Web steht sie fest).
class AddressForm extends StatefulWidget {
  const AddressForm({super.key, required this.address, this.failureText});

  final String address;
  final String? failureText;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late final _address = TextEditingController(text: widget.address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<RuntimeConnectionCubit>().connect(_address.text.trim());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DashboardKeys.connectionTitle.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.lg),
        TextField(
          controller: _address,
          keyboardType: TextInputType.url,
          autofillHints: const [AutofillHints.url],
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: DashboardKeys.connectionAddress.tr(),
            hintText: DashboardKeys.connectionAddressHint.tr(),
            errorText: widget.failureText,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: Spacing.md),
        FilledButton(
          onPressed: _submit,
          child: Text(DashboardKeys.connectionConnect.tr()),
        ),
      ],
    );
  }
}
