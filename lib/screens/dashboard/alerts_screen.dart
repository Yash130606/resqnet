import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Live Alerts",
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('disasters')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No alerts available.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              String title = data['title'] ?? "Alert";
              String location = data['locationName'] ?? "Unknown";
              String severity = data['severity'] ?? "low";
              String status = data['status'] ?? "";
              String description = data['description'] ?? "";

              Timestamp? timestamp = data['createdAt'];
              String formattedTime = "";

              if (timestamp != null) {
                DateTime date = timestamp.toDate();
                formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(date);
              }

              Color severityColor = Colors.red;

              if (severity.toLowerCase() == "medium") {
                severityColor = Colors.orange;
              } else if (severity.toLowerCase() == "low") {
                severityColor = Colors.green;
              }

              IconData alertIcon = Icons.warning;

              if (title.toLowerCase().contains("flood")) {
                alertIcon = Icons.water;
              } else if (title.toLowerCase().contains("cyclone") ||
                  title.toLowerCase().contains("storm")) {
                alertIcon = Icons.air;
              } else if (title.toLowerCase().contains("fire")) {
                alertIcon = Icons.local_fire_department;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: severityColor.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(alertIcon, color: severityColor, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "$title – $location",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: Text(
                                title,
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Location: $location",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    "Severity: $severity",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    "Status: $status",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    description,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "Close",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          "View Details",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
