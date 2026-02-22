import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ReportEmergencyScreen extends StatefulWidget {
  const ReportEmergencyScreen({super.key});

  @override
  State<ReportEmergencyScreen> createState() =>
      _ReportEmergencyScreenState();
}

class _ReportEmergencyScreenState
    extends State<ReportEmergencyScreen> {

  String selectedType = "Flood";

  final TextEditingController descriptionController =
      TextEditingController();

  double? latitude;
  double? longitude;

  String locationName = "Fetching location...";

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationName = "Location disabled";
        });
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        setState(() {
          locationName = "Permission denied";
        });
        return;
      }

      Position position =
          await Geolocator.getCurrentPosition(
              desiredAccuracy:
                  LocationAccuracy.high);

      latitude = position.latitude;
      longitude = position.longitude;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
              latitude!, longitude!);

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

    setState(() => isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
        .collection("emergency_requests")
        .add({
      "userId": user?.uid,
      "userEmail": user?.email,
      "type": selectedType,
      "description":
          descriptionController.text.trim(),
      "latitude": latitude,
      "longitude": longitude,
      "locationName": locationName,
      "status": "pending",
      "createdAt":
          FieldValue.serverTimestamp(),
    });

    setState(() => isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Emergency"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              "Emergency Type",
              style: TextStyle(
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedType,
              items: const [
                DropdownMenuItem(
                    value: "Flood",
                    child: Text("Flood")),
                DropdownMenuItem(
                    value: "Fire",
                    child: Text("Fire")),
                DropdownMenuItem(
                    value: "Earthquake",
                    child: Text("Earthquake")),
                DropdownMenuItem(
                    value: "Medical",
                    child: Text("Medical")),
                DropdownMenuItem(
                    value: "Other",
                    child: Text("Other")),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(Icons.location_on,
                    color: Colors.red),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(locationName),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              "Description",
              style: TextStyle(
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    "Describe your emergency situation...",
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(
                          vertical: 15),
                ),
                onPressed:
                    isSubmitting ? null : submitRequest,
                child: isSubmitting
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text(
                        "Submit Emergency",
                        style: TextStyle(
                            fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}