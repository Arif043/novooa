import 'package:equatable/equatable.dart';

class NotificationDeviceToken extends Equatable {
  const NotificationDeviceToken({
    required this.userId,
    required this.token,
    required this.platform,
  });

  final String userId;
  final String token;
  final String platform;

  @override
  List<Object?> get props => [userId, token, platform];
}
