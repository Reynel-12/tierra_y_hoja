import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Dictado por voz a texto (nota de voz transcribible).
///
/// Funciona sin internet si el teléfono tiene descargado el paquete de voz
/// en español. Si no está disponible, la vista avisa y se escribe a mano.
class SpeechService {
  SpeechService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  bool _available = false;
  String? _localeId;
  VoidCallback? _onDone;

  bool get isListening => _speech.isListening;

  /// Prepara el reconocedor. Devuelve `false` si el teléfono no lo soporta.
  Future<bool> ensureReady() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: (error) {
          debugPrint('Dictado: ${error.errorMsg}');
          _finish();
        },
      );
      if (_available) _localeId = await _spanishLocale();
    } catch (e) {
      debugPrint('Dictado no disponible: $e');
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  /// Empieza a escuchar. [onResult] recibe el texto reconocido.
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    VoidCallback? onDone,
  }) async {
    _onDone = onDone;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) =>
          onResult(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
    _finish();
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _finish();
    }
  }

  void _finish() {
    final callback = _onDone;
    _onDone = null;
    callback?.call();
  }

  Future<String?> _spanishLocale() async {
    final locales = await _speech.locales();
    const preferred = ['es_HN', 'es-HN', 'es_419', 'es-419', 'es_MX', 'es-MX'];
    for (final id in preferred) {
      for (final locale in locales) {
        if (locale.localeId == id) return locale.localeId;
      }
    }
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('es')) {
        return locale.localeId;
      }
    }
    return null;
  }
}
