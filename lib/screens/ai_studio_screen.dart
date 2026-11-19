import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Legacy route name retained for compatibility. This is a local writing
/// template, not an AI/music service. No provider key or network call belongs
/// in this client; a future service needs a reviewed server-side boundary.
class AiStudioScreen extends StatefulWidget {
  const AiStudioScreen({super.key});

  @override
  State<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends State<AiStudioScreen> {
  final _prompt = TextEditingController();
  String _lastInput = '';
  String? _reflection;
  String? _notice;
  bool _copying = false;

  static const _ideas = [
    ('A busy day', 'Letting go of a busy day'),
    ('Before sleep', 'Making room for rest'),
    ('A fresh start', 'Taking one small step today'),
    ('A quiet pause', 'Noticing the present moment'),
  ];

  @override
  void initState() {
    super.initState();
    _prompt.addListener(_edited);
  }

  void _edited() {
    if (_lastInput == _prompt.text) return;
    _lastInput = _prompt.text;
    setState(() {
      _reflection = null;
      _notice = null;
    });
  }

  void _createReflection() {
    final subject = _prompt.text.trim();
    if (subject.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _notice = null;
      _reflection =
          '''A quiet reflection: $subject

If it feels comfortable, settle into a position that supports you. Let your breathing find its own easy pace. You can keep your eyes open, change position or stop whenever you need to.

Bring this intention to mind: "$subject". Notice what is here without needing to solve it all at once. If your attention wanders, gently return to the feeling of your feet or the surface supporting you.

When you are ready, notice something around you and choose one small, kind next step. There is no perfect way to take a quiet pause.''';
    });
  }

  Future<void> _copyReflection() async {
    final text = _reflection;
    if (text == null || _copying) return;
    setState(() => _copying = true);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted && text == _reflection) {
        setState(
          () => _notice =
              'Text copied. Save it somewhere private if you want to keep it.',
        );
      }
    } catch (_) {
      if (mounted && text == _reflection) {
        setState(() => _notice = 'Clipboard access failed. Nothing was saved.');
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  void dispose() {
    _prompt.removeListener(_edited);
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF061722),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Reflection studio'),
        backgroundColor: Color(0xF0061722),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Make room for a quiet thought',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Use an on-device writing template for a short pause. This is not AI or music generation. '
                'The app does not upload your prompt or save this text automatically.',
                style: TextStyle(color: Color(0xFFBCD0DC), height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'What would you like to reflect on?',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                key: const ValueKey('reflection-prompt'),
                controller: _prompt,
                placeholder: 'A feeling, an intention, or a small moment…',
                minLines: 3,
                maxLines: 5,
                maxLength: 400,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(color: CupertinoColors.white),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A3B),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final idea in _ideas)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: const Color(0xFF173A43),
                      onPressed: () => _prompt.text = idea.$2,
                      child: Text(
                        idea.$1,
                        style: const TextStyle(
                          color: Color(0xFF9CF0DA),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                key: const ValueKey('create-reflection'),
                onPressed: _prompt.text.trim().isEmpty
                    ? null
                    : _createReflection,
                child: const Text(
                  'Create reflection from template',
                  textAlign: TextAlign.center,
                ),
              ),
              if (_reflection != null) ...[
                const SizedBox(height: 28),
                const Text(
                  'YOUR TEMPLATE REFLECTION',
                  style: TextStyle(
                    color: Color(0xFF9CF0DA),
                    fontSize: 12,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _reflection!,
                  key: const ValueKey('reflection-output'),
                  style: const TextStyle(
                    color: Color(0xFFE3F1F5),
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  key: const ValueKey('copy-reflection'),
                  onPressed: _copying ? null : _copyReflection,
                  child: _copying
                      ? const CupertinoActivityIndicator()
                      : const Text('Copy text'),
                ),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _notice!,
                    key: const ValueKey('reflection-notice'),
                    style: const TextStyle(
                      color: Color(0xFFBCD0DC),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (_prompt.text.isNotEmpty)
                CupertinoButton(
                  key: const ValueKey('clear-reflection'),
                  onPressed: _prompt.clear,
                  child: const Text('Clear this reflection'),
                ),
              const SizedBox(height: 24),
              const Text(
                'Leaving this screen discards the draft. Copying is optional; other apps may be able '
                'to read your clipboard. This general wellbeing exercise is not medical care.',
                style: TextStyle(
                  color: Color(0xFF9BB4C4),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
