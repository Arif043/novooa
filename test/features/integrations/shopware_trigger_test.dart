import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/domain/entities/connection_draft.dart';
import 'package:syscat2/features/connections/domain/entities/connection_failure.dart';
import 'package:syscat2/features/connections/domain/entities/connection_test_result.dart';
import 'package:syscat2/features/connections/domain/repositories/connection_repository.dart';
import 'package:syscat2/features/connections/domain/usecases/connection_use_cases.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_actions.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_app_manifest.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_trigger_params.dart';
import 'package:syscat2/features/integrations/shopware/presentation/widgets/shopware_app_dialog.dart';
import 'package:syscat2/features/integrations/shopware/presentation/widgets/shopware_trigger_controls.dart';
import 'package:syscat2/features/schedule/domain/entities/event_trigger_config.dart';
import 'package:syscat2/features/schedule/infrastructure/models/event_trigger_config_mapper.dart';
import 'package:syscat2/features/schedule/presentation/widgets/schedule_formatters.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _shop = Connection(
  id: 'c1',
  name: 'Mein Shop',
  baseUrl: 'https://shop.example.com',
  auth: BearerAuth(),
  updatedAt: 'x',
);

void main() {
  group('ShopwareTriggerParams', () {
    test('schickt nur, was für das Ereignis gilt', () {
      const base = ShopwareTriggerParams(connectionId: 'c1');

      expect(base.toMap(), {'event': 'orderPlaced', 'connectionId': 'c1'});
      expect(
        base
            .copyWith(
              event: ShopwareTriggerEvent.orderStatus,
              scope: ShopwareStateScope.delivery,
            )
            .toMap(),
        {
          'event': 'orderStatus',
          'connectionId': 'c1',
          'scope': 'order_delivery',
          'state': 'shipped',
        },
      );
      expect(
        base
            .copyWith(event: ShopwareTriggerEvent.stockLow, threshold: 3)
            .toMap(),
        {'event': 'stockLow', 'connectionId': 'c1', 'threshold': 3},
      );
      expect(
        base
            .copyWith(
              event: ShopwareTriggerEvent.newsletterSubscribed,
              confirmedOnly: false,
            )
            .toMap(),
        {
          'event': 'newsletterSubscribed',
          'connectionId': 'c1',
          'confirmedOnly': false,
        },
      );
    });

    test('Rundlauf über toMap und fromMap', () {
      const params = ShopwareTriggerParams(
        event: ShopwareTriggerEvent.orderStatus,
        connectionId: 'c1',
        scope: ShopwareStateScope.order,
        state: 'cancelled',
      );

      expect(ShopwareTriggerParams.fromMap(params.toMap()), params);
    });

    test('beim Wechsel des Statusbereichs gilt dessen Standardzustand', () {
      const params = ShopwareTriggerParams(
        event: ShopwareTriggerEvent.orderStatus,
        state: 'paid',
      );

      expect(
        params.copyWith(scope: ShopwareStateScope.delivery).state,
        'shipped',
      );
      expect(params.copyWith(scope: ShopwareStateScope.payment).state, 'paid');
      expect(params.copyWith(state: 'failed').state, 'failed');
    });

    test('vollständig ist er mit Verbindung und gültigem Zielstatus', () {
      const params = ShopwareTriggerParams();

      expect(params.isComplete, isFalse);
      expect(params.copyWith(connectionId: 'c1').isComplete, isTrue);
      expect(
        params
            .copyWith(
              connectionId: 'c1',
              event: ShopwareTriggerEvent.orderStatus,
              state: 'shipped',
            )
            .isComplete,
        isFalse,
        reason: 'shipped gibt es für Zahlungen nicht',
      );
    });

    test(
      'jedes Ereignis kennt seinen Namen in Shopware und seine Leserechte',
      () {
        String name(ShopwareTriggerParams params) => params.webhookEvent;

        expect(name(const ShopwareTriggerParams()), 'checkout.order.placed');
        expect(
          name(
            const ShopwareTriggerParams(
              event: ShopwareTriggerEvent.orderStatus,
              scope: ShopwareStateScope.payment,
              state: 'paid',
            ),
          ),
          'state_enter.order_transaction.state.paid',
        );
        expect(
          name(
            const ShopwareTriggerParams(
              event: ShopwareTriggerEvent.customerRegistered,
            ),
          ),
          'checkout.customer.register',
        );
        expect(
          name(
            const ShopwareTriggerParams(event: ShopwareTriggerEvent.stockLow),
          ),
          'product.written',
        );
        expect(
          name(
            const ShopwareTriggerParams(
              event: ShopwareTriggerEvent.newsletterSubscribed,
            ),
          ),
          'newsletter.confirmed',
        );
        expect(
          const ShopwareTriggerParams(
            event: ShopwareTriggerEvent.orderStatus,
          ).readPermissions,
          ['order', 'order_transaction'],
        );
      },
    );
  });

  group('Shopware-App', () {
    const params = ShopwareTriggerParams(
      event: ShopwareTriggerEvent.orderStatus,
      connectionId: 'c1',
      scope: ShopwareStateScope.delivery,
      state: 'shipped',
    );

    test('der Name taugt als Ordnername und ist je Auslöser verschieden', () {
      expect(
        shopwareAppName('a1b2-c3d4-e5f6-0000'),
        'NovooaAusloeserA1b2c3d4'.replaceFirst('A1b2', 'a1b2'),
      );
      expect(shopwareAppName('x'), 'NovooaAusloeserx');
      expect(shopwareAppName('ab/../cd'), isNot(contains('/')));
    });

    test(
      'die Adresse hängt Auslöser und Token an, ohne doppelten Schrägstrich',
      () {
        expect(
          shopwareWebhookUrl('http://novooa:8090/', 'id1', 'tok'),
          'http://novooa:8090/hooks/id1/tok',
        );
      },
    );

    test(
      'das Manifest meldet genau ein Ereignis an die Adresse des Auslösers',
      () {
        final xml = shopwareAppManifest(
          triggerId: 'id1',
          token: 'tok_en-1',
          address: 'http://novooa:8090',
          params: params,
          label: 'Lieferung: Versandt',
          description: 'Meldet „Lieferung: Versandt“ an novooa.',
        );

        expect(xml, contains('<name>NovooaAusloeserid1</name>'));
        expect(xml, contains('<label>novooa: Lieferung: Versandt</label>'));
        expect(
          xml,
          contains(
            '<webhook name="NovooaAusloeserid1Webhook" '
            'url="http://novooa:8090/hooks/id1/tok_en-1" '
            'event="state_enter.order_delivery.state.shipped"/>',
          ),
        );
        expect(xml, contains('<read>order</read>'));
        expect(xml, contains('<read>order_delivery</read>'));
        expect('<webhook '.allMatches(xml), hasLength(1));
      },
    );

    test('Sonderzeichen in der Adresse werden maskiert', () {
      final xml = shopwareAppManifest(
        triggerId: 'id1',
        token: 't',
        address: 'http://novooa/x?a=1&b="2"',
        params: params,
        label: 'A & B',
        description: 'D',
      );

      expect(
        xml,
        contains('url="http://novooa/x?a=1&amp;b=&quot;2&quot;/hooks/id1/t"'),
      );
      expect(xml, contains('<label>novooa: A &amp; B</label>'));
    });
  });

  group('EventTriggerConfig mit Shopware', () {
    const config = EventTriggerConfig(
      source: EventTriggerSource.shopware,
      params: {'event': 'stockLow', 'connectionId': 'c1', 'threshold': 4},
    );

    test('Rundlauf im Dokument samt params', () {
      final document = EventTriggerConfigMapper.toDocument(config);

      expect(document['source'], 'shopware');
      expect(document['params'], {
        'event': 'stockLow',
        'connectionId': 'c1',
        'threshold': 4,
      });
      expect(
        EventTriggerConfigMapper.fromDocument(document)?.params,
        config.params,
      );
      expect(
        EventTriggerConfigMapper.fromDocument(document)?.source,
        EventTriggerSource.shopware,
      );
    });

    test('ohne Verbindung ist der Auslöser nicht gültig', () {
      expect(config.isValid, isTrue);
      expect(
        const EventTriggerConfig(source: EventTriggerSource.shopware).isValid,
        isFalse,
      );
      expect(
        const EventTriggerConfig(
          source: EventTriggerSource.fileCreated,
        ).isValid,
        isTrue,
      );
    });

    test('die Karte nennt das Ereignis', () {
      expect(eventLabel(config), 'Shopware: Bestand höchstens 4');
    });
  });

  test(
    'der Baustein „Ereignis lesen“ braucht keine Verbindung und liefert den Datensatz',
    () {
      const spec = ShopwareActions.readEvent;
      final config = ShopwareNodeConfig.initial('readEvent');

      expect(spec.usesConnection, isFalse);
      expect(spec.fields, isEmpty);
      expect(config.primaryOutputType, NodeOutputType.json);
      expect(config.outputFields, {
        'event': NodeOutputType.string,
        'id': NodeOutputType.string,
        'receivedAt': NodeOutputType.datetime,
      });
      expect(config.toDocument(), {'action': 'readEvent', 'params': {}});
    },
  );

  group('Oberfläche', () {
    Future<ConnectionsCubit> cubit(WidgetTester tester) async {
      final repository = _ConnectionRepository();
      final connections = ConnectionsCubit(
        WatchConnections(repository),
        CreateConnection(repository),
        UpdateConnection(repository),
        DeleteConnection(repository),
        TestConnection(repository),
        GetCurrentTeamId(_Teams()),
      );
      addTearDown(connections.close);
      await connections.load();
      return connections;
    }

    testWidgets(
      'das Formular passt sich dem Ereignis an und meldet Änderungen',
      (tester) async {
        final connections = await cubit(tester);
        var value = const ShopwareTriggerParams(connectionId: 'c1');
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: connections,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return SingleChildScrollView(
                      child: ShopwareTriggerControls(
                        value: value,
                        onChanged: (next) => setState(() => value = next),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(find.byKey(const Key('shopware-trigger-scope')), findsNothing);
        expect(
          find.byKey(const Key('shopware-trigger-threshold')),
          findsNothing,
        );

        update(
          () => value = value.copyWith(event: ShopwareTriggerEvent.orderStatus),
        );
        await tester.pump();
        expect(find.byKey(const Key('shopware-trigger-scope')), findsOneWidget);
        expect(find.text('Zielstatus'), findsOneWidget);

        update(
          () => value = value.copyWith(event: ShopwareTriggerEvent.stockLow),
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('shopware-trigger-threshold')),
          '12',
        );
        expect(value.threshold, 12);

        update(
          () => value = value.copyWith(
            event: ShopwareTriggerEvent.newsletterSubscribed,
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('shopware-trigger-confirmed')));
        await tester.pump();
        expect(value.confirmedOnly, isFalse);
      },
    );

    testWidgets('der Dialog zeigt Manifest und Befehl und folgt der Adresse', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ShopwareAppDialog.show(
                  context,
                  triggerId: 'id1',
                  token: 'tok',
                  params: const ShopwareTriggerParams(connectionId: 'c1'),
                  initialAddress: 'http://localhost:8090',
                ),
                child: const Text('öffnen'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('öffnen'));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Aus dem Shopware-Container ist localhost nicht novooa.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('shopware-app-command')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('shopware-app-address')),
        'http://novooa:8090',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Aus dem Shopware-Container ist localhost nicht novooa.'),
        findsNothing,
      );
      final manifest = tester.widget<SelectableText>(
        find.byKey(const Key('shopware-app-manifest')),
      );
      expect(manifest.data, contains('url="http://novooa:8090/hooks/id1/tok"'));
      expect(manifest.data, contains('event="checkout.order.placed"'));
    });
  });
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');
}

class _ConnectionRepository implements ConnectionRepository {
  @override
  Stream<List<Connection>> watchConnections(TeamId teamId) =>
      Stream.value(const [_shop]);

  @override
  Future<Result<Connection, ConnectionFailure>> create(
    ConnectionDraft draft,
  ) async => const Success(_shop);

  @override
  Future<Result<Connection, ConnectionFailure>> update(
    String id,
    ConnectionDraft draft,
  ) async => const Success(_shop);

  @override
  Future<Result<Unit, ConnectionFailure>> delete(String id) async =>
      const Success(unit);

  @override
  Future<Result<ConnectionTestResult, ConnectionFailure>> test(
    String id, {
    String path = '',
  }) async => const Success(ConnectionTestResult(ok: true, message: 'ok'));
}
