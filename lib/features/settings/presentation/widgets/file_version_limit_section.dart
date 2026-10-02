import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/files/domain/usecases/save_file_version_limit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_settings_cubit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_settings_state.dart';

import 'settings_section.dart';

/// Legt fest, wie viele Versionen pro Datei erhalten bleiben; ältere werden
/// beim Speichern einer neuen Version gelöscht (Standalone).
class FileVersionLimitSection extends StatelessWidget {
  const FileVersionLimitSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<FileSettingsCubit>()..load(),
      child: SettingsSection(
        icon: Icons.history,
        title: 'Dateiversionen',
        description:
            'Pro Datei bleiben nur die neuesten Versionen erhalten. Ältere werden beim Speichern einer neuen Version gelöscht.',
        child: BlocConsumer<FileSettingsCubit, FileSettingsState>(
          listener: (context, state) {
            if (state case FileSettingsReady(:final message?)) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) => switch (state) {
            FileSettingsLoading() => const LinearProgressIndicator(),
            FileSettingsFailure(:final message) => Text(message),
            FileSettingsReady() => _VersionLimitForm(state: state),
          },
        ),
      ),
    );
  }
}

class _VersionLimitForm extends StatefulWidget {
  const _VersionLimitForm({required this.state});

  final FileSettingsReady state;

  @override
  State<_VersionLimitForm> createState() => _VersionLimitFormState();
}

class _VersionLimitFormState extends State<_VersionLimitForm> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.state.versionLimit}',
  );

  @override
  void didUpdateWidget(_VersionLimitForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.versionLimit != widget.state.versionLimit) {
      _controller.text = '${widget.state.versionLimit}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value => int.tryParse(_controller.text);

  bool get _isValid {
    final value = _value;
    return value != null &&
        value >= SaveFileVersionLimit.minimum &&
        value <= SaveFileVersionLimit.maximum;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: _controller,
            enabled: !state.isSaving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Versionen pro Datei',
              helperText:
                  '${SaveFileVersionLimit.minimum}–${SaveFileVersionLimit.maximum}',
              errorText: _isValid ? null : 'Ungültiger Wert',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton(
          onPressed: state.isSaving || !_isValid
              ? null
              : () =>
                    context.read<FileSettingsCubit>().saveVersionLimit(_value!),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
