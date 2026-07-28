typedef FcmPushClickCallback = void Function(Map<String, dynamic> data);

class FcmPushClickBridge {
  const FcmPushClickBridge();

  void start(FcmPushClickCallback onPushClick) {}
}
