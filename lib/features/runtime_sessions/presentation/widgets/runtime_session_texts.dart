import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../domain/entities/runtime_session.dart';
import '../../domain/entities/runtime_session_failure.dart';
import '../../domain/entities/session_device.dart';

extension SessionDeviceTexts on SessionDevice {
  /// z. B. „Chrome auf macOS“, „Windows-App“ oder bei einem Kunden-Dashboard
  /// „Lager-Dashboard · Chrome auf Windows“.
  String get label {
    if (!isKnown) return LocaleKeys.runtime_sessions_unknown_device.tr();
    final client = _clientLabel;
    if (isOfficialApp || app.isEmpty) return client;
    return '$app · $client';
  }

  IconData get icon => switch ((browser, os)) {
    (String(), _) => Icons.language_outlined,
    (_, DeviceOs.android || DeviceOs.ios) => Icons.smartphone_outlined,
    (_, DeviceOs.macos || DeviceOs.windows || DeviceOs.linux) =>
      Icons.computer_outlined,
    (_, DeviceOs.unknown) => Icons.devices_other_outlined,
  };

  String get _clientLabel {
    final osName = _osNames[os];
    return switch ((browser, osName)) {
      (final String browser, final String osName) =>
        LocaleKeys.runtime_sessions_browser_on_os.tr(args: [browser, osName]),
      (final String browser, null) => browser,
      (null, final String osName) => LocaleKeys.runtime_sessions_native_app.tr(
        args: [osName],
      ),
      (null, null) => LocaleKeys.runtime_sessions_unknown_device.tr(),
    };
  }
}

/// Produktnamen werden nicht übersetzt.
const _osNames = {
  DeviceOs.android: 'Android',
  DeviceOs.ios: 'iOS',
  DeviceOs.macos: 'macOS',
  DeviceOs.windows: 'Windows',
  DeviceOs.linux: 'Linux',
};

extension RuntimeSessionTexts on RuntimeSession {
  String signedInText(Locale locale) => LocaleKeys.runtime_sessions_signed_in_on
      .tr(args: [DateFormat.yMMMd(locale.toLanguageTag()).format(signedInAt)]);

  /// Die Runtime schreibt die Nutzung nur stündlich; genauer wird es nicht.
  String lastActiveText(DateTime now) {
    final elapsed = now.difference(lastActiveAt);
    if (elapsed.inHours < 1) {
      return LocaleKeys.runtime_sessions_active_recently.tr();
    }
    if (elapsed.inDays < 1) {
      return LocaleKeys.runtime_sessions_active_hours_ago.tr(
        args: ['${elapsed.inHours}'],
      );
    }
    if (elapsed.inDays == 1) {
      return LocaleKeys.runtime_sessions_active_one_day_ago.tr();
    }
    return LocaleKeys.runtime_sessions_active_days_ago.tr(
      args: ['${elapsed.inDays}'],
    );
  }
}

extension RuntimeSessionFailureText on RuntimeSessionFailure {
  String get text => switch (kind) {
    RuntimeSessionFailureKind.runtimeUnavailable =>
      LocaleKeys.runtime_sessions_failure_runtime_unavailable.tr(),
    RuntimeSessionFailureKind.notFound =>
      LocaleKeys.runtime_sessions_failure_not_found.tr(),
    RuntimeSessionFailureKind.unexpected =>
      LocaleKeys.runtime_sessions_failure_unexpected.tr(),
  };
}
