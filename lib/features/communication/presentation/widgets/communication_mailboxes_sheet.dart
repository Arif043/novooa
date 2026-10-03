import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';

import '../cubits/communication_cubit.dart';
import 'communication_mailbox_list.dart';
import 'communication_provider_list.dart';
import 'mail_provider_option.dart';

enum _Page { mailboxes, providers }

/// Dialog der verbundenen Postfächer. Er liefert den Anbieter, bei dem der
/// Nutzer ein Postfach (neu) verbinden will, oder `null` beim Schließen. Das
/// Verbinden selbst startet der Aufrufer, denn die Anmeldung öffnet den
/// Browser und gehört nicht in den Dialog.
class CommunicationMailboxesSheet extends StatefulWidget {
  const CommunicationMailboxesSheet({
    super.key,
    required this.style,
    required this.startWithProviders,
  });

  final AdaptiveSheetStyle style;

  /// Ohne Postfach gibt es nichts aufzulisten: Dann beginnt der Dialog bei
  /// den Anbietern.
  final bool startWithProviders;

  static Future<MailProviderOption?> show(
    BuildContext context, {
    required CommunicationCubit cubit,
    required bool startWithProviders,
  }) {
    return showAdaptiveSheet<MailProviderOption>(
      context: context,
      builder: (_, style) => BlocProvider.value(
        value: cubit,
        child: CommunicationMailboxesSheet(
          style: style,
          startWithProviders: startWithProviders,
        ),
      ),
    );
  }

  @override
  State<CommunicationMailboxesSheet> createState() =>
      _CommunicationMailboxesSheetState();
}

class _CommunicationMailboxesSheetState
    extends State<CommunicationMailboxesSheet> {
  static const _windowSheetHeight = 520.0;

  late _Page _page = widget.startWithProviders
      ? _Page.providers
      : _Page.mailboxes;
  var _forward = true;

  bool get _onProviders => _page == _Page.providers;

  @override
  Widget build(BuildContext context) {
    final isWindow = widget.style.isWindow;
    return PopScope(
      canPop: !_onProviders || widget.startWithProviders,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_Page.mailboxes);
      },
      child: SizedBox(
        height: isWindow
            ? _windowSheetHeight
            : MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onProviders: _onProviders,
              onBack: widget.startWithProviders
                  ? null
                  : () => _goTo(_Page.mailboxes),
            ),
            Expanded(child: _switcher(context)),
            if (isWindow) ...[const Divider(height: 1), _footer(context)],
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final canGoBack = _onProviders && !widget.startWithProviders;
    return SheetFooter(
      onBack: canGoBack ? () => _goTo(_Page.mailboxes) : null,
      cancelLabel: _onProviders ? 'Abbrechen' : 'Schließen',
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  Widget _switcher(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 250),
      reverseDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: _transition,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(_page), child: _content(context)),
    );
  }

  /// Die neue Seite gleitet herein, die alte blendet nur schneller aus: Das
  /// zeigt die Richtung, ohne dass zwei Seiten einander überfahren.
  Widget _transition(Widget child, Animation<double> animation) {
    final incoming = (child.key as ValueKey<_Page>).value == _page;
    if (!incoming) return FadeTransition(opacity: animation, child: child);
    final from = Offset(_forward ? .15 : -.15, 0);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: from, end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (_onProviders) {
      return CommunicationProviderList(onSelected: _close);
    }
    return CommunicationMailboxList(
      onAddMailbox: () => _goTo(_Page.providers),
      onReconnect: (mailbox) => _close(mailProviderFor(mailbox.provider)),
    );
  }

  void _close(MailProviderOption? option) {
    if (option != null) Navigator.of(context).pop(option);
  }

  void _goTo(_Page page) {
    setState(() {
      _forward = page == _Page.providers;
      _page = page;
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onProviders, required this.onBack});

  final bool onProviders;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onProviders && onBack != null)
            IconButton(
              tooltip: 'Zurück',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            )
          else
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onProviders ? 'Anbieter wählen' : 'Postfächer',
                    style: textTheme.titleLarge,
                  ),
                  if (onProviders) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Bei welchem Anbieter liegt das Postfach?',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
