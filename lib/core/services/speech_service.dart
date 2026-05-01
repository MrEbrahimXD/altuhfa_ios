// TODO: re-enable when test feature is restored
// import 'package:speech_to_text/speech_to_text.dart';

/// Stub — speech recognition disabled while test feature is hidden.
class SpeechService {
  static final SpeechService _instance = SpeechService._();
  factory SpeechService() => _instance;
  SpeechService._();

  bool get isAvailable => false;
  bool get isListening => false;

  Future<bool> init() async => false;

  Future<void> startListening({
    required void Function(String text) onResult,
  }) async {}

  Future<void> stopListening() async {}
}
