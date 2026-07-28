Map<String, dynamic>? fcmPushClickData(Object? payload) {
  if (payload is! Map) return null;
  final data = payload['data'];
  if (data is! Map) return null;
  final runId = data['runId'];
  if (runId is! String) return null;
  return {'runId': runId};
}
