import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../domain/entities/run_effect.dart';

/// Symbol und Satz zu einer Folge, in der App-Sprache.
({IconData icon, String text}) runEffectPresentation(RunEffect effect) {
  final text = _text(effect);
  final round = effect.iteration;
  return (
    icon: _icon(effect),
    text: round == null
        ? text
        : '$text · ${LocaleKeys.run_effects_round.tr(namedArgs: {'round': '${round + 1}'})}',
  );
}

IconData _icon(RunEffect effect) => switch (effect) {
  FileWrittenEffect() => Icons.description_outlined,
  MessageSentEffect(:final channel) => switch (channel) {
    MessageChannel.email => Icons.mail_outline,
    MessageChannel.whatsapp || MessageChannel.sms => Icons.sms_outlined,
  },
  NotificationSentEffect() => Icons.notifications_none,
  RecordsChangedEffect() => Icons.dataset_outlined,
  HttpRequestedEffect() => Icons.public,
  ExternalActionEffect() => Icons.extension_outlined,
};

String _text(RunEffect effect) => switch (effect) {
  FileWrittenEffect(:final displayName, :final isNewFile) =>
    (isNewFile
            ? LocaleKeys.run_effects_file_created
            : LocaleKeys.run_effects_file_version)
        .tr(namedArgs: {'name': displayName}),
  MessageSentEffect() => _message(effect),
  NotificationSentEffect(:final title) =>
    LocaleKeys.run_effects_notification_sent.tr(namedArgs: {'title': title}),
  RecordsChangedEffect() => _records(effect),
  HttpRequestedEffect(:final method, :final status, :final host) =>
    LocaleKeys.run_effects_http_requested.tr(
      namedArgs: {
        'method': method,
        'status': '$status',
        'host': host ?? LocaleKeys.run_effects_http_connection.tr(),
      },
    ),
  ExternalActionEffect() => _external(effect),
};

String _message(MessageSentEffect effect) {
  final args = {'recipient': effect.recipient, 'subject': effect.subject ?? ''};
  return switch (effect.channel) {
    MessageChannel.email when effect.subject != null =>
      LocaleKeys.run_effects_email_sent_subject.tr(namedArgs: args),
    MessageChannel.email => LocaleKeys.run_effects_email_sent.tr(
      namedArgs: args,
    ),
    MessageChannel.whatsapp => LocaleKeys.run_effects_whatsapp_sent.tr(
      namedArgs: args,
    ),
    MessageChannel.sms => LocaleKeys.run_effects_sms_sent.tr(namedArgs: args),
  };
}

String _records(RecordsChangedEffect effect) {
  final single = effect.count == 1;
  final key = switch (effect.operation) {
    RecordOperation.created =>
      single
          ? LocaleKeys.run_effects_record_created
          : LocaleKeys.run_effects_records_created,
    RecordOperation.updated =>
      single
          ? LocaleKeys.run_effects_record_updated
          : LocaleKeys.run_effects_records_updated,
    RecordOperation.deleted =>
      single
          ? LocaleKeys.run_effects_record_deleted
          : LocaleKeys.run_effects_records_deleted,
  };
  return key.tr(namedArgs: {'count': '${effect.count}'});
}

String _external(ExternalActionEffect effect) {
  final args = {'label': effect.label, 'plugin': effect.plugin};
  return switch ((effect.plugin, effect.action)) {
    ('shopware', 'changeOrderStatus') =>
      LocaleKeys.run_effects_shopware_order_status.tr(namedArgs: args),
    ('shopware', 'updateProduct') => LocaleKeys.run_effects_shopware_product.tr(
      namedArgs: args,
    ),
    ('googleDrive', 'upload') => LocaleKeys.run_effects_drive_upload.tr(
      namedArgs: args,
    ),
    _ => LocaleKeys.run_effects_external_action.tr(namedArgs: args),
  };
}
