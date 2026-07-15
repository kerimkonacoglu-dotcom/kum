import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/voice_commands.dart';

/// Mikrofon dinleme arayüzü; algılanan metni VoiceCommands ile çalıştırır.
class VoiceSheet extends StatefulWidget {
  final VoiceCommands commands;
  const VoiceSheet({super.key, required this.commands});

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _words = '';
  String _result = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() {});
    if (_available) _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _words = '';
      _result = '';
      _listening = true;
    });
    await _speech.listen(
      localeId: 'tr_TR',
      listenFor: const Duration(seconds: 6),
      onResult: (r) async {
        setState(() => _words = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
          final res = await widget.commands.handle(r.recognizedWords);
          if (mounted) setState(() => _result = res);
        }
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _listening ? Icons.mic : Icons.mic_none,
            size: 64,
            color: _listening ? const Color(0xFF2E7BE5) : Colors.white38,
          ),
          const SizedBox(height: 16),
          Text(
            !_available
                ? 'Ses tanıma kullanılamıyor'
                : _listening
                    ? 'Dinliyorum...'
                    : 'Bitti',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_words.isNotEmpty)
            Text('"$_words"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7BE5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_result,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
          const SizedBox(height: 20),
          if (_available)
            FilledButton.icon(
              onPressed: _listening ? null : _startListening,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7BE5)),
              icon: const Icon(Icons.mic),
              label: const Text('Tekrar konuş'),
            ),
          const SizedBox(height: 8),
          Text(
            'Örnek: "sesi aç", "kanal yukarı", "menü", "23", "kapat"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
