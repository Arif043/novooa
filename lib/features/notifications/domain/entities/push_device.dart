import 'package:equatable/equatable.dart';

class PushDevice extends Equatable {
  const PushDevice({
    required this.ownerId,
    required this.token,
    required this.platform,
  });

  final String ownerId;
  final String token;
  final String platform;

  @override
  List<Object?> get props => [ownerId, token, platform];
}
