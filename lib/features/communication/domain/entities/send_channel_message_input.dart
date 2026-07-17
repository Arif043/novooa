class SendChannelMessageInput {
  const SendChannelMessageInput({
    required this.channelId,
    required this.to,
    required this.body,
  });

  final String channelId;
  final String to;
  final String body;

  bool get isValid {
    return channelId.trim().isNotEmpty &&
        to.trim().isNotEmpty &&
        body.trim().isNotEmpty;
  }
}
