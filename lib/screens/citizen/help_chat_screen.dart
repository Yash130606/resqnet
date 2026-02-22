import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HelpChatScreen extends StatefulWidget {
  const HelpChatScreen({super.key});

  @override
  State<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends State<HelpChatScreen> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();

  String conversationState = ""; // Used to track context
  Future<String> getAIResponse(String userMessage) async {
    const apiKey = "AIzaSyCiVVwLB65g1QMnkt_qPeNEzbO1RrxjXlc";

    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "You are an emergency disaster safety assistant. Answer clearly and briefly: $userMessage"
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "Sorry, I couldn’t process that right now.";
    }
  }

  @override
  void initState() {
    super.initState();

    messages.add({
      "text": "🛡️ Welcome to ResQNet AI Assistant.\nHow can I help you today?",
      "isUser": false,
    });
  }

  void sendMessage(String text, {bool isUser = true}) {
    setState(() {
      messages.add({
        "text": text,
        "isUser": isUser,
      });
    });
  }

  void handleUserInput(String input) {
    sendMessage(input, isUser: true);

    String lowerInput = input.toLowerCase();
    String response = "";

    // ===== DIRECTION CONFIRMATION FLOW =====
    if (conversationState == "awaiting_direction_confirmation") {
      if (lowerInput == "yes") {
        response =
            "🧭 Opening directions to nearest shelter...\n(Integration with map coming next step)";
      } else {
        response = "Okay. Let me know if you need anything else.";
      }

      conversationState = "";
    }

    // ===== NORMAL FLOW =====
    else if (lowerInput.contains("find shelter")) {
      response = "🏠 Nearest shelter is 2.1 km away.\nDo you want directions?";
      conversationState = "awaiting_direction_confirmation";
    } else if (lowerInput.contains("emergency contacts")) {
      response =
          "📞 Emergency Numbers:\nPolice: 100\nAmbulance: 108\nFire: 101";
    } else if (lowerInput.contains("i am injured")) {
      response = "🚑 Stay calm. Apply pressure to bleeding and avoid movement.";
    } else if (lowerInput.contains("i am trapped")) {
      response =
          "🆘 Try to stay visible and conserve battery. Help is being notified.";
    } else if (lowerInput.contains("what disaster is active")) {
      response = "⚠ Currently: Flood Alert (High Severity) in your area.";
    } else if (lowerInput.contains("safety instructions")) {
      response = "🛡 Follow official alerts and avoid unsafe areas.";
    } else if (lowerInput.contains("medical help")) {
      response = "🚑 Nearest hospital is 3 km away.";
    } else if (lowerInput.contains("food help")) {
      response = "🍲 Relief camp nearby is providing food supplies.";
    } else if (lowerInput.contains("water help")) {
      response = "💧 Clean water distribution available at relief center.";
    } else if (lowerInput.contains("power outage")) {
      response = "🔌 Power restoration team has been notified for your area.";
    } else {
      response = "";
    }

    Future.delayed(const Duration(milliseconds: 400), () async {
      if (response.isNotEmpty) {
        sendMessage(response, isUser: false);
      } else {
        sendMessage("🤖 Thinking...", isUser: false);

        String aiReply = await getAIResponse(input);

        setState(() {
          messages.removeLast(); // remove "Thinking..."
        });

        sendMessage(aiReply, isUser: false);
      }
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help Assistant"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                return Align(
                  alignment: message["isUser"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          message["isUser"] ? Colors.red : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["text"],
                      style: TextStyle(
                        color: message["isUser"] ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ===== 10+ PREDEFINED BUTTONS =====
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                suggestionButton("Find Shelter"),
                suggestionButton("Emergency Contacts"),
                suggestionButton("I am injured"),
                suggestionButton("I am trapped"),
                suggestionButton("What disaster is active near me?"),
                suggestionButton("Safety Instructions"),
                suggestionButton("Need medical help"),
                suggestionButton("Need food help"),
                suggestionButton("Need water help"),
                suggestionButton("Power outage issue"),
              ],
            ),
          ),

          // Text Field
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.red),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      handleUserInput(_controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget suggestionButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          handleUserInput(text);
        },
      ),
    );
  }
}
