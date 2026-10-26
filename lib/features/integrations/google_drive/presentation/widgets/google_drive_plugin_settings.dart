import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_cubit.dart';
import 'package:syscat2/features/google_accounts/presentation/widgets/google_accounts_section.dart';

/// Einstellungen des Drive-Plugins: die verbundenen Google-Konten.
class GoogleDrivePluginSettings extends StatelessWidget {
  const GoogleDrivePluginSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<GoogleAccountsCubit>()..load(),
      child: const GoogleAccountsSection(),
    );
  }
}
