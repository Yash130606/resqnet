import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class SosReportScreen extends StatefulWidget {
  const SosReportScreen({super.key});

  @override
  State<SosReportScreen> createState() => _SosReportScreenState();
}

class _SosReportScreenState extends State<SosReportScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otherEmergencyController =
      TextEditingController();
  final TextEditingController otherDisasterController = TextEditingController();

  String? selectedEmergencyType;
  String? selectedDisasterType;
  bool isSending = false;

  final List<String> emergencyTypes = [
    "Medical",
    "Trapped",
    "Food & Water",
    "Shelter",
    "Other"
  ];

  final List<String> disasterTypes = [
    "Flood",
    "Earthquake",
    "Fire",
    "Cyclone",
    "Landslide",
    "Unknown"
  ];

  // ✅ Send SMS via TextBelt (1 free SMS per day for demo)
  Future<void> sendSms(String phone, String message) async {
    final url = Uri.parse('https://textbelt.com/text');

    try {
      final response = await http.post(
        url,
        body: {
          'phone': '+91$phone',
          'message': message,
          'key': 'textbelt', // free key — 1 SMS per day
        },
      );

      print('📱 SMS Status: ${response.statusCode}');
      print('📱 SMS Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ SMS sent successfully');
      } else {
        print('❌ SMS failed: ${response.body}');
      }
    } catch (e) {
      print('❌ SMS Exception: $e');
    }
  }

  Future<void> sendSOS() async {
    if (phoneController.text.isEmpty || selectedEmergencyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete required fields")),
      );
      return;
    }

    if (selectedEmergencyType == "Other" &&
        otherEmergencyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe the emergency")),
      );
      return;
    }

    if (selectedDisasterType != null &&
        selectedDisasterType == "Unknown" &&
        otherDisasterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe the disaster")),
      );
      return;
    }

    try {
      setState(() => isSending = true);

      final phone = phoneController.text.trim().replaceAll(' ', '');

      // ✅ Step 1: Save to Firestore
      await FirebaseFirestore.instance.collection("sos_reports").add({
        "phone": phone,
        "emergencyType": selectedEmergencyType,
        "emergencyDescription": selectedEmergencyType == "Other"
            ? otherEmergencyController.text.trim()
            : "",
        "disasterType": selectedDisasterType ?? "",
        "disasterDescription": selectedDisasterType == "Unknown"
            ? otherDisasterController.text.trim()
            : "",
        "priority": selectedEmergencyType == "Medical" ? "high" : "normal",
        "timestamp": FieldValue.serverTimestamp(),
        "status": "pending",
        "source": "no_login_user"
      });

      // ✅ Step 2: Send SMS via TextBelt
      await sendSms(
        phone,
        'ResQNet SOS Received! '
        'Emergency: $selectedEmergencyType. '
        'Disaster: ${selectedDisasterType ?? "Unknown"}. '
        'Authorities alerted. Stay safe!',
      );

      // ✅ Step 3: Show success dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "SOS Sent Successfully 🚨",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Help request received.\nSMS confirmation sent to your number.\nAuthorities are reviewing your case.\nStay safe. We will contact you soon.",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              child: const Text("OK", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      );
    } catch (e) {
      print("🔥 ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Widget buildOptionGrid(
      List<String> options, String? selected, Function(String) onSelect) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final bool isSelected = selected == option;
        return GestureDetector(
          onTap: () => setState(() => onSelect(option)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: isSelected ? Colors.red : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.red : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Emergency SOS",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // 🔴 Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Quick Emergency Report\nNo login required",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 📱 Mobile Number
            const Text(
              "Mobile Number *",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              maxLength: 10,
              decoration: InputDecoration(
                hintText: "Enter 10-digit mobile number",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixText: "+91  ",
                prefixStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                counterStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🚨 Emergency Type
            const Text(
              "Select Emergency Type *",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            buildOptionGrid(
              emergencyTypes,
              selectedEmergencyType,
              (val) => selectedEmergencyType = val,
            ),

            if (selectedEmergencyType == "Other") ...[
              const SizedBox(height: 15),
              TextField(
                controller: otherEmergencyController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Describe Emergency",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 25),

            // 🌪️ Disaster Type
            const Text(
              "Select Disaster Type (Optional)",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            buildOptionGrid(
              disasterTypes,
              selectedDisasterType,
              (val) => selectedDisasterType = val,
            ),

            if (selectedDisasterType == "Unknown") ...[
              const SizedBox(height: 15),
              TextField(
                controller: otherDisasterController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Describe Disaster",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 35),

            // 🔴 SEND SOS BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isSending ? null : sendSOS,
              child: isSending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Sending SOS...",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sos, size: 24),
                        SizedBox(width: 10),
                        Text(
                          "SEND SOS",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                "An SMS confirmation will be sent to your number",
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
