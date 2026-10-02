import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_save_notice.dart';
import 'package:syscat2/features/task_builder/domain/services/task_save_notice_bus.dart';

void main() {
  late TaskSaveNoticeBus bus;
  late List<TaskSaveNotice> received;

  setUp(() {
    bus = TaskSaveNoticeBus();
    received = [];
    bus.notices.listen(received.add);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('meldet Warnungen und lässt unveränderte nicht wiederkehren', () async {
    bus.announceWarnings('a', ['Schleife A → B']);
    bus.announceWarnings('a', ['Schleife A → B']);
    await settle();

    expect(received.map((notice) => notice.message), ['Schleife A → B']);
    expect(received.single.isRejection, isFalse);
  });

  test('meldet erneut, sobald sich die Warnungen ändern', () async {
    bus.announceWarnings('a', ['eins']);
    bus.announceWarnings('a', ['eins', 'zwei']);
    await settle();

    expect(received.map((notice) => notice.message), ['eins', 'eins', 'zwei']);
  });

  test('ein sauberes Speichern setzt die Erinnerung zurück', () async {
    bus.announceWarnings('a', ['eins']);
    bus.clear('a');
    bus.announceWarnings('a', ['eins']);
    await settle();

    expect(received, hasLength(2));
  });

  test(
    'Ablehnungen sind als solche markiert und je Aufgabe getrennt',
    () async {
      bus.announceRejection('a', 'Selbstschleife');
      bus.announceRejection('a', 'Selbstschleife');
      bus.announceRejection('b', 'Selbstschleife');
      await settle();

      expect(received.map((notice) => notice.taskId), ['a', 'b']);
      expect(received.every((notice) => notice.isRejection), isTrue);
    },
  );
}
