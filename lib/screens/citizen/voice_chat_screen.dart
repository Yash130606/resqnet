import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  String _recognizedText = '';
  String _aiResponse = '';
  String _statusText = 'Tap the mic to speak';

  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _history = [];

  static const String _apiKey = 'AIzaSyA8LCBsUT89yXcoDRHTth7RrgbST3DF2zY';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const String _systemPrompt =
      'You are ResQNet Voice AI, a calm and helpful emergency voice assistant. '
      'The user is speaking by voice so keep responses SHORT — 2 to 4 sentences max. '
      'Be direct, calm, and action-oriented. '
      'Help with: disaster safety, first aid, app usage, emergency contacts (call 112 in India). '
      'If someone is in immediate danger, always say: Call 112 immediately. '
      'Speak naturally — no bullet points, just clear sentences.';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSpeech();
    _initTts();
  }

  void _initAnimations() {
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusText = 'Speech error. Try again.';
          });
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _statusText = 'Tap the mic to speak again';
        });
      }
    });
  }

  Future<void> _toggleListening() async {
    // Stop speaking if tapped mid-speech
    if (_isSpeaking) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _statusText = 'Tap the mic to speak';
      });
      return;
    }

    if (_isThinking) return;

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _statusText = 'Processing...';
      });
      if (_recognizedText.isNotEmpty) {
        await _sendToAI(_recognizedText);
      } else {
        setState(() => _statusText = 'Tap the mic to speak');
      }
    } else {
      if (!_speechAvailable) {
        setState(() => _statusText = 'Microphone not available');
        return;
      }

      setState(() {
        _isListening = true;
        _recognizedText = '';
        _statusText = 'Listening...';
      });

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _recognizedText = result.recognizedWords);
          }
          if (result.finalResult && _recognizedText.isNotEmpty) {
            _speech.stop();
            setState(() {
              _isListening = false;
              _statusText = 'Processing...';
            });
            _sendToAI(_recognizedText);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_IN',
      );
    }
  }

  Future<void> _sendToAI(String text) async {
    setState(() {
      _isThinking = true;
      _statusText = 'Thinking...';
      _aiResponse = '';
    });

    _history.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ],
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt}
            ]
          },
          'contents': _history,
          'generationConfig': {
            'maxOutputTokens': 256,
            'temperature': 0.7,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        _history.add({
          'role': 'model',
          'parts': [
            {'text': reply}
          ],
        });

        if (mounted) {
          setState(() {
            _aiResponse = reply;
            _isThinking = false;
            _statusText = 'ResQNet AI is speaking...';
          });
        }

        await _tts.speak(reply);
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  void _handleError() {
    const errMsg =
        'I could not connect. If this is an emergency, please call 112 immediately.';
    if (mounted) {
      setState(() {
        _aiResponse = errMsg;
        _isThinking = false;
        _statusText = 'Connection error';
      });
    }
    _tts.speak(errMsg);
  }

  void _clearConversation() {
    _tts.stop();
    _speech.stop();
    setState(() {
      _history.clear();
      _recognizedText = '';
      _aiResponse = '';
      _statusText = 'Tap the mic to speak';
      _isSpeaking = false;
      _isThinking = false;
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Color get _orbColor {
    if (_isListening) return const Color(0xFFD32F2F);
    if (_isThinking) return const Color(0xFF1565C0);
    if (_isSpeaking) return const Color(0xFF2E7D32);
    return const Color(0xFF424242);
  }

  String get _orbEmoji {
    if (_isListening) return '🎤';
    if (_isThinking) return '🤔';
    if (_isSpeaking) return '🔊';
    return '🎤';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white54, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Voice Assistant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white38, size: 20),
            onPressed: _clearConversation,
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background radial gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 20),

              // Status chip
              _buildStatusChip(),

              const Spacer(),

              // Central orb — tap to listen
              _buildOrb(),

              const SizedBox(height: 40),

              // Text panels
              _buildTextPanel(),

              const Spacer(),

              // Quick prompts when idle
              if (!_isListening && !_isThinking && !_isSpeaking)
                _buildQuickVoicePrompts(),

              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    if (_isListening) chipColor = const Color(0xFFD32F2F);
    else if (_isThinking) chipColor = const Color(0xFF1565C0);
    else if (_isSpeaking) chipColor = const Color(0xFF2E7D32);
    else chipColor = const Color(0xFF424242);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: chipColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Opacity(
              opacity: (_isListening || _isSpeaking) ? _pulseAnim.value : 1.0,
              child: Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: chipColor, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _statusText,
            style: TextStyle(
              color: chipColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() {
    return GestureDetector(
      onTap: _toggleListening,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbit ring
            if (_isListening || _isSpeaking)
              AnimatedBuilder(
                animation: _orbitController,
                builder: (_, __) => CustomPaint(
                  size: const Size(220, 220),
                  painter: _OrbitPainter(
                    progress: _orbitController.value,
                    color: _orbColor,
                  ),
                ),
              ),

            // Expanding wave ring
            if (_isListening || _isThinking || _isSpeaking)
              AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) => Container(
                  width: 160 + 30 * _waveController.value,
                  height: 160 + 30 * _waveController.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _orbColor
                          .withOpacity(0.3 * (1 - _waveController.value)),
                      width: 2,
                    ),
                  ),
                ),
              ),

            // Inner glow ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orbColor.withOpacity(0.08),
                border: Border.all(
                  color: _orbColor.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
            ),

            // Main orb
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale:
                    (_isListening || _isSpeaking) ? _pulseAnim.value : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _orbColor.withOpacity(0.9),
                        _orbColor.withOpacity(0.5),
                      ],
                      center: const Alignment(-0.3, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _orbColor.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _isThinking
                      ? const Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Center(
                          child: Text(
                            _orbEmoji,
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPanel() {
    final showUser = _recognizedText.isNotEmpty || _isListening;
    final showAI = _aiResponse.isNotEmpty;

    if (!showUser && !showAI) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'I\'m here to help during\nemergencies. Just speak.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 15,
            height: 1.6,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (showUser)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFD32F2F).withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎤 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        _recognizedText.isEmpty
                            ? 'Listening...'
                            : _recognizedText,
                        style: TextStyle(
                          color: _recognizedText.isEmpty
                              ? Colors.white38
                              : Colors.white70,
                          fontSize: 14,
                          fontStyle: _recognizedText.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (showUser && showAI) const SizedBox(height: 10),

          if (showAI)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🤖 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        _aiResponse,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickVoicePrompts() {
    final prompts = [
      '🌊 Flood help',
      '🔥 Fire safety',
      '📞 Emergency numbers',
      '🏥 First aid',
    ];

    return Column(
      children: [
        Text(
          'or tap a quick prompt',
          style: TextStyle(
              color: Colors.white.withOpacity(0.25), fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: prompts.map((p) {
            // Strip emoji for the API call text
            final cleanText = p.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
            return GestureDetector(
              onTap: () {
                setState(() {
                  _recognizedText = p;
                });
                _sendToAI(cleanText.isEmpty ? p : cleanText);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  p,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Custom orbit ring painter
class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashCount = 24;
    const radius = 100.0;

    for (var i = 0; i < dashCount; i++) {
      final angle =
          (i / dashCount) * 2 * math.pi + progress * 2 * math.pi;
      final nextAngle =
          ((i + 0.5) / dashCount) * 2 * math.pi + progress * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        nextAngle - angle,
        false,
        paint,
      );
    }

    // Orbiting dot
    final dotAngle = progress * 2 * math.pi;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    canvas.drawCircle(
      Offset(dotX, dotY),
      4,
      Paint()..color = color.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.progress != progress || old.color != color;
}