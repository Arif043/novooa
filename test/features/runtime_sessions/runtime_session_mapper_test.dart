import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/session_device.dart';
import 'package:syscat2/features/runtime_sessions/infrastructure/mappers/runtime_session_mapper.dart';

void main() {
  test('liest Sitzungen samt Gerät und übergeht unvollständige', () {
    final sessions = RuntimeSessionMapper.sessionsFrom({
      'items': [
        {
          'id': 's1',
          'current': true,
          'createdAt': '2026-10-01T00:00:00.000Z',
          'lastUsedAt': '2026-10-02T00:00:00.000Z',
          'device': {'app': 'novooa', 'os': 'macos', 'browser': 'Chrome'},
        },
        {
          'id': 's2',
          'createdAt': '2026-10-01T00:00:00.000Z',
          'lastUsedAt': '2026-10-01T00:00:00.000Z',
          'device': {'app': '', 'os': 'beos', 'browser': null},
        },
        {'id': 'ohne-zeiten'},
      ],
    });

    expect(sessions.map((session) => session.id.value), ['s1', 's2']);
    expect(sessions.first.isCurrent, isTrue);
    expect(
      sessions.first.device,
      const SessionDevice(app: 'novooa', os: DeviceOs.macos, browser: 'Chrome'),
    );
    expect(sessions.last.isCurrent, isFalse);
    expect(sessions.last.device.os, DeviceOs.unknown);
    expect(sessions.last.device.isKnown, isFalse);
  });

  test('eine Antwort ohne Liste ergibt keine Sitzungen', () {
    expect(RuntimeSessionMapper.sessionsFrom({}), isEmpty);
  });
}
