import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'bot',
      'text':
          '🤖 Hello! I am ResQNet AI Assistant.\n\nI can help you with:\n\n• Flood safety\n• Fire emergency\n• Earthquake steps\n• Medical emergencies\n• Shelter locations\n• Disaster preparedness\n\nHow can I assist you today?',
    }
  ];

  final Map<String, String> _responses = {
    'flood':
        '🌊 FLOOD SAFETY:\n\n1. Move to higher ground\n2. Avoid walking in moving water\n3. Disconnect electricity\n4. Carry emergency kit\n5. Call 112\n\nUse SOS in ResQNet to alert rescue teams.',
    'fire':
        '🔥 FIRE STEPS:\n\n1. Call 101\n2. Evacuate immediately\n3. Stay low to avoid smoke\n4. Do not use elevators\n\nUse SOS to notify volunteers.',
    'earthquake':
        '🏔️ EARTHQUAKE:\n\n1. DROP\n2. COVER\n3. HOLD ON\n4. Stay away from windows\n5. Expect aftershocks',
    'medical':
        '🏥 MEDICAL EMERGENCY:\n\n1. Call 108\n2. Keep patient calm\n3. Stop bleeding with pressure\n4. Do not move injured person unnecessarily',
    'shelter':
        '🏠 NEAREST SHELTERS:\n\n• Community Center\n• Government School\n• Sports Complex\n\nCheck Map tab for exact location.',
    'prepare':
        '🎒 PREPARE KIT:\n\n• Water\n• Food\n• First Aid\n• Flashlight\n• Documents\n• Power Bank',
    'volunteer':
        '🙋 To become a volunteer:\n\n1. Register as Volunteer\n2. Complete profile\n3. Accept SOS tasks\n4. Help citizens in need',
  };

  String _generateResponse(String input) {
    input = input.toLowerCase();

    if (input.contains('flood')) return _responses['flood']!;
    if (input.contains('fire')) return _responses['fire']!;
    if (input.contains('earthquake')) return _responses['earthquake']!;
    if (input.contains('medical')) return _responses['medical']!;
    if (input.contains('shelter')) return _responses['shelter']!;
    if (input.contains('prepare')) return _responses['prepare']!;
    if (input.contains('volunteer')) return _responses['volunteer']!;

    return '🤖 I can help with:\n\n• flood\n• fire\n• earthquake\n• medical\n• shelter\n• prepare\n• volunteer\n\nPlease type one of these keywords.';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _messages.add({
        'role': 'bot',
        'text': _generateResponse(text),
      });
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFD32F2F),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Text(
              "ResQNet AI",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _typingIndicator();
                }

                final msg = _messages[index];
                final isBot = msg['role'] == 'bot';

                return _messageBubble(msg['text'], isBot);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask about emergencies...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(String text, bool isBot) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isBot ? const Color(0xFF1E1E1E) : const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          "ResQNet AI is typing...",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}