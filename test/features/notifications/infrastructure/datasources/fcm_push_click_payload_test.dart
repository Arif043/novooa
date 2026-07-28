import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/notifications/infrastructure/datasources/fcm_push_click_payload.dart';

void main() {
  test('extracts the run ID from an FCM notification click payload', () {
    final data = fcmPushClickData({
      'data': {'runId': 'run-1', 'taskId': 'task-1'},
    });

    expect(data, {'runId': 'run-1'});
  });

  test('rejects payloads without a run ID', () {
    expect(
      fcmPushClickData({
        'data': {'taskId': 'task-1'},
      }),
      isNull,
    );
  });
}
