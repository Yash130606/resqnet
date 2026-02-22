import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ReportEmergencyScreen extends StatefulWidget {
  const ReportEmergencyScreen({super.key});

  @override
  State<ReportEmergencyScreen> createState() => _ReportEmergencyScreenState();
}

class _ReportEmergencyScreenState extends State<ReportEmergencyScreen> {
  String selectedType = "Flood";

  final TextEditingController descriptionController = TextEditingController();

  // ✅ NEW: People count controller
  final TextEditingController peopleController =
      TextEditingController(text: "1");

  double? latitude;
  double? longitude;

  String locationName = "Fetching location...";

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    peopleController.dispose();
    super.dispose();
  }

  Future<void> fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationName = "Location disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          locationName = "Permission denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      latitude = position.latitude;
      longitude = position.longitude;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude!, longitude!);

      setState(() {
        locationName =
            "${placemarks.first.locality ?? ''}, ${placemarks.first.administrativeArea ?? ''}";
      });
    } catch (e) {
      setState(() {
        locationName = "Location unavailable";
      });
    }
  }

  // ✅ NEW: Helper to determine recommended volunteers based on people count
  int _recommendedVolunteers(int peopleCount) {
    if (peopleCount <= 1) return 1;
    if (peopleCount <= 5) return 2;
    if (peopleCount <= 10) return 3;
    if (peopleCount <= 20) return 5;
    return (peopleCount / 4).ceil().clamp(5, 10);
  }

  Future<void> submitRequest() async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location not available"),
        ),
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter description"),
        ),
      );
      return;
    }

    // ✅ NEW: Validate people count
    int peopleCount = int.tryParse(peopleController.text.trim()) ?? 1;
    if (peopleCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Number of people must be at least 1"),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;

    // ✅ NEW: Calculate recommended volunteers
    int volunteersNeeded = _recommendedVolunteers(peopleCount);

    await FirebaseFirestore.instance.collection("emergency_requests").add({
      "userId": user?.uid,
      "userEmail": user?.email,
      "type": selectedType,
      "description": descriptionController.text.trim(),
      "latitude": latitude,
      "longitude": longitude,
      "locationName": locationName,
      "status": "pending",
      // ✅ NEW fields stored in Firestore
      "peopleCount": peopleCount,
      "volunteersNeeded": volunteersNeeded,
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() => isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NEW: Live compute recommended volunteers for display
    int peopleCount = int.tryParse(peopleController.text) ?? 1;
    int recommended = _recommendedVolunteers(peopleCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Emergency"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Emergency Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "Flood", child: Text("Flood")),
                DropdownMenuItem(value: "Fire", child: Text("Fire")),
                DropdownMenuItem(
                    value: "Earthquake", child: Text("Earthquake")),
                DropdownMenuItem(value: "Medical", child: Text("Medical")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              "Your Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(locationName),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ✅ NEW: Number of People section
            const Text(
              "Number of People Affected",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                // Decrement button
                _circleButton(
                  icon: Icons.remove,
                  onTap: () {
                    int current = int.tryParse(peopleController.text) ?? 1;
                    if (current > 1) {
                      setState(() {
                        peopleController.text = (current - 1).toString();
                      });
                    }
                  },
                ),

                const SizedBox(width: 12),

                // Text field in the center
                Expanded(
                  child: TextField(
                    controller: peopleController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(width: 12),

                // Increment button
                _circleButton(
                  icon: Icons.add,
                  onTap: () {
                    int current = int.tryParse(peopleController.text) ?? 1;
                    setState(() {
                      peopleController.text = (current + 1).toString();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ NEW: Live volunteer recommendation badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Estimated volunteers needed: $recommended",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describe your emergency situation...",
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: isSubmitting ? null : submitRequest,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Emergency",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Helper widget for +/- buttons
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
