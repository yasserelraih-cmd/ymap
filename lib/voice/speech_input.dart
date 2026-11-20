import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/app_localizations.dart';

/// يستمع لكلامك ويرجع النص (بالعربي أو الإنجليزي).
/// في آيفون (Safari) يطلب إذن الميكروفون أول مرة.
Future<String?> listenOnce(BuildContext context, {required String lang}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ListenSheet(lang: lang),
  );
}

class _ListenSheet extends StatefulWidget {
  const _ListenSheet({required this.lang});
  final String lang;

  @override
  State<_ListenSheet> createState() => _ListenSheetState();
}

class _ListenSheetState extends State<_ListenSheet> {
  final _stt = SpeechToText();
  String _text = '';
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final ok = await _stt.initialize(
        onError: (_) {
          if (mounted) setState(() => _failed = true);
        },
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && _text.isNotEmpty && mounted) {
            Navigator.of(context).pop(_text);
          }
        },
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _failed = true);
        return;
      }
      setState(() => _ready = true);
      await _stt.listen(
        listenOptions: SpeechListenOptions(
          localeId: widget.lang == 'ar' ? 'ar-SA' : 'en-US',
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
        ),
        onResult: (r) {
          if (!mounted) return;
          setState(() => _text = r.recognizedWords);
          if (r.finalResult && _text.isNotEmpty) Navigator.of(context).pop(_text);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    unawaited(_stt.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: _failed ? scheme.errorContainer : scheme.primaryContainer,
              child: Icon(_failed ? Icons.mic_off : Icons.mic,
                  size: 36,
                  color: _failed ? scheme.onErrorContainer : scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              _failed
                  ? t.voiceUnavailable
                  : (_text.isEmpty ? (_ready ? t.voiceListening : '…') : _text),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(t.voiceExample,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
