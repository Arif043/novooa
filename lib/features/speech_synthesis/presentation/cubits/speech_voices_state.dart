import 'package:equatable/equatable.dart';

import '../../domain/entities/speech_voice.dart';

enum SpeechVoicesStatus { loading, ready, failure }

class SpeechVoicesState extends Equatable {
  const SpeechVoicesState({
    this.status = SpeechVoicesStatus.loading,
    this.voices,
    this.message,
  });

  final SpeechVoicesStatus status;
  final SpeechVoiceList? voices;
  final String? message;

  @override
  List<Object?> get props => [status, voices, message];
}
