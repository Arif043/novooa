import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/run_origin.dart';
import 'package:syscat2/features/activity/infrastructure/models/run_origin_mapper.dart';
import 'package:syscat2/features/activity/presentation/widgets/run_origin_label.dart';

void main() {
  test('liest Personen und Auslöser aus der Runtime-Antwort', () {
    final origin = runOriginFrom({
      'startedBy': {'uid': 'u1', 'displayName': 'Anna'},
      'reviewedBy': null,
      'triggerType': null,
    });
    expect(origin.startedBy, 'Anna');
    expect(origin.reviewedBy, isNull);
    expect(runOriginFrom(null).isKnown, isFalse);
  });

  test('beschreibt manuelle und automatische Läufe', () {
    expect(
      runOriginLabel(const RunOrigin(startedBy: 'Anna', reviewedBy: 'Ben')),
      'gestartet von Anna · beantwortet von Ben',
    );
    expect(
      runOriginLabel(const RunOrigin(triggerType: 'schedule')),
      'Zeitplan',
    );
    expect(runOriginLabel(const RunOrigin(triggerType: 'event')), 'Auslöser');
    expect(runOriginLabel(RunOrigin.unknown), isNull);
  });
}
