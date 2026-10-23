import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/app_colors.dart';
import '../../design/app_icons.dart';
import '../../design/app_tokens.dart';
import '../../services/speech_service.dart';
import '../dialogs.dart';

/// Botón de 48 para dictar una nota: transcribe la voz al campo de texto.
class VoiceNoteButton extends StatefulWidget {
  const VoiceNoteButton({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<VoiceNoteButton> createState() => _VoiceNoteButtonState();
}

class _VoiceNoteButtonState extends State<VoiceNoteButton> {
  bool _listening = false;
  String _baseText = '';
  SpeechService? _speech;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speech = context.read<SpeechService>();
  }

  Future<void> _toggle() async {
    final speech = context.read<SpeechService>();
    if (_listening) {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final ready = await speech.ensureReady();
    if (!mounted) return;
    if (!ready) {
      AppToast.info(
        context,
        'El dictado por voz no está disponible en este teléfono. Escriba la nota a mano.',
      );
      return;
    }

    _baseText = widget.controller.text.trimRight();
    unawaited(HapticFeedback.selectionClick());
    setState(() => _listening = true);
    await speech.listen(
      onResult: (words, _) {
        final separator = _baseText.isEmpty ? '' : ' ';
        final text = '$_baseText$separator$words';
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  @override
  void dispose() {
    if (_listening) {
      // Detiene el micrófono si se sale de la pantalla mientras dicta.
      unawaited(_speech?.stop());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xs),
      child: IconButton(
        tooltip: _listening ? 'Detener dictado' : 'Dictar nota con la voz',
        onPressed: _toggle,
        style: IconButton.styleFrom(
          backgroundColor: _listening ? c.primary : Colors.transparent,
          foregroundColor: _listening ? c.onPrimary : c.primary,
          minimumSize: const Size(AppSize.touch, AppSize.touch),
        ),
        icon: Icon(_listening ? AppIcons.stop : AppIcons.microphone),
      ),
    );
  }
}
