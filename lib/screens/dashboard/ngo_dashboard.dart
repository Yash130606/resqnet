import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'ngo_profile_screen.dart';
import 'ngo_map_screen.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  String? ngoId;
  int _bottomIndex = 0;
  int _currentTab = 1; // Default Dispatch Tab

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'water':
        return Icons.water_drop;
      case 'medical':
        return Icons.medical_services;
      case 'blanket':
        return Icons.bed;
      case 'tent':
        return Icons.house;
      case 'truck':
        return Icons.local_shipping;
      case 'food_bank':
        return Icons.food_bank;
      default:
        return Icons.inventory;
    }
  }

  final List<Map<String, dynamic>> _inventory = [
    {
      'item': 'Food Packets',
      'quantity': 500,
      'unit': 'packs',
      'icon': 'fastfood'
    },
    {
      'item': 'Water Bottles',
      'quantity': 1000,
      'unit': 'bottles',
      'icon': 'water'
    },
    {'item': 'Medical Kits', 'quantity': 50, 'unit': 'kits', 'icon': 'medical'},
    {'item': 'Blankets', 'quantity': 200, 'unit': 'pieces', 'icon': 'blanket'},
    {'item': 'Tents', 'quantity': 30, 'unit': 'units', 'icon': 'tent'},
  ];

  Future<void> _loadNgoInventory() async {
    if (ngoId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('ngo_inventory')
        .where('ngoId', isEqualTo: ngoId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      _inventory.add({
        'item': data['item'],
        'quantity': data['quantity'],
        'unit': data['unit'],
        'icon': data['icon'] ?? 'inventory',
        'docId': doc.id,
        'isFirestore': true,
      });
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ngoId = FirebaseAuth.instance.currentUser?.uid;
    _loadNgoInventory();
  }

  void _showAddInventoryDialog() {
    String selectedIcon = 'inventory';
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Inventory Item"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Item Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: "Unit (e.g. packs, bottles)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: "Select Icon",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'inventory', child: Text("Default")),
                    DropdownMenuItem(value: 'fastfood', child: Text("Food")),
                    DropdownMenuItem(value: 'water', child: Text("Water")),
                    DropdownMenuItem(value: 'medical', child: Text("Medical")),
                    DropdownMenuItem(value: 'blanket', child: Text("Blanket")),
                    DropdownMenuItem(value: 'tent', child: Text("Tent")),
                    DropdownMenuItem(value: 'truck', child: Text("Transport")),
                    DropdownMenuItem(
                        value: 'food_bank', child: Text("Food Bank")),
                  ],
                  onChanged: (value) {
                    selectedIcon = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    quantityController.text.isEmpty ||
                    unitController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                final newItem = {
                  'ngoId': ngoId,
                  'item': nameController.text.trim(),
                  'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
                  'unit': unitController.text.trim(),
                  'icon': selectedIcon,
                  'createdAt': FieldValue.serverTimestamp(),
                };

                final docRef = await FirebaseFirestore.instance
                    .collection('ngo_inventory')
                    .add(newItem);

                setState(() {
                  _inventory.add({
                    'item': newItem['item'],
                    'quantity': newItem['quantity'],
                    'unit': newItem['unit'],
                    'docId': docRef.id,
                    'isFirestore': true,
                  });
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  final Color primaryRed = const Color(0xFFD32F2F);
  final Color bgColor = const Color(0xFF121212);

  // ================= AUTO ASSIGN =================

  Map<String, int> _getAutoAssignment(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return {
          'Food Packets': 100,
          'Water Bottles': 200,
          'Medical Kits': 10,
          'Blankets': 50,
          'Tents': 10
        };
      case 'fire':
        return {
          'Food Packets': 50,
          'Water Bottles': 100,
          'Medical Kits': 15,
          'Blankets': 30,
          'Tents': 5
        };
      case 'medical':
        return {
          'Food Packets': 20,
          'Water Bottles': 50,
          'Medical Kits': 20
        };
      case 'earthquake':
        return {
          'Food Packets': 150,
          'Water Bottles': 300,
          'Medical Kits': 20,
          'Blankets': 80,
          'Tents': 20
        };
      default:
        return {
          'Food Packets': 30,
          'Water Bottles': 60,
          'Medical Kits': 5,
        };
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  int _severityPriority(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return 1;
      case 'HIGH':
        return 2;
      case 'MEDIUM':
        return 3;
      default:
        return 4;
    }
  }

  // ================= DEDUCT INVENTORY =================

  Future<void> _deductInventory(Map<String, int> assignment) async {
    setState(() {
      for (final entry in assignment.entries) {
        final itemName = entry.key;
        final deductQty = entry.value;

        final index =
            _inventory.indexWhere((i) => i['item'] == itemName);
        if (index != -1) {
          final current = _inventory[index]['quantity'] as int;
          _inventory[index]['quantity'] =
              (current - deductQty).clamp(0, current);
        }
      }
    });
  }

  // ================= CONFIRM DISPATCH DIALOG =================

  void _showDispatchConfirmDialog({
    required String docId,
    required String collectionName,
    required String type,
    required String location,
    required String priority,
  }) {
    final assignment = _getAutoAssignment(type);

    // Check stock availability
    final List<String> insufficientItems = [];
    for (final entry in assignment.entries) {
      final index = _inventory.indexWhere((i) => i['item'] == entry.key);
      if (index != -1) {
        if ((_inventory[index]['quantity'] as int) < entry.value) {
          insufficientItems.add(entry.key);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: [
              Icon(Icons.local_shipping, color: primaryRed),
              const SizedBox(width: 8),
              const Text(
                "Confirm Dispatch",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Emergency: $type",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Location: $location",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Resources to be dispatched:",
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...assignment.entries.map((entry) {
                  final isLow = insufficientItems.contains(entry.key);
                  final index =
                      _inventory.indexWhere((i) => i['item'] == entry.key);
                  final available =
                      index != -1 ? _inventory[index]['quantity'] as int : 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLow
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isLow ? Colors.red : Colors.green,
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: isLow ? Colors.red : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Dispatch: ${entry.value}",
                              style: TextStyle(
                                color: isLow ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Available: $available",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (insufficientItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Low stock for: ${insufficientItems.join(', ')}. Will dispatch available quantity.",
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);

                // Deduct from local inventory
                await _deductInventory(assignment);

                // Mark as assigned in Firestore
                await FirebaseFirestore.instance
                    .collection(collectionName)
                    .doc(docId)
                    .update({
                  'status': 'assigned',
                  'assignedAt': FieldValue.serverTimestamp(),
                  'dispatchedResources': assignment,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text("Resources dispatched successfully!"),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("DISPATCH NOW"),
            ),
          ],
        );
      },
    );
  }

  // ================= MAIN BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NGO Dashboard 🏢",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Manage & dispatch relief resources",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        currentIndex: _bottomIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping), label: "Dispatch"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // ================= TABS =================

  Widget _topTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tabButton("Inventory", 0, Icons.inventory),
          const SizedBox(width: 8),
          _tabButton("Dispatch", 1, Icons.local_shipping),
          const SizedBox(width: 8),
          _tabButton("History", 2, Icons.history),
        ],
      ),
    );
  }

  Widget _buildSelectedScreen() {
    switch (_bottomIndex) {
      case 0:
        return Column(
          children: [
            const SizedBox(height: 15),
            _topTabs(),
            const SizedBox(height: 10),
            Expanded(
              child: _currentTab == 0
                  ? _inventoryTab()
                  : _currentTab == 1
                      ? _dispatchTab()
                      : _historyTab(),
            )
          ],
        );
      case 1:
        return const NgoMapScreen();
      case 2:
        return _dispatchTab();
      case 3:
        return const NgoProfileScreen();
      default:
        return Container();
    }
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final selected = _currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD32F2F) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 15, color: selected ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================= DISPATCH TAB =================

  Widget _dispatchTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, emergencySnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sos_reports')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, sosSnapshot) {
            if (emergencySnapshot.hasError) {
              return Center(
                  child:
                      Text("Emergency Error: ${emergencySnapshot.error}"));
            }
            if (sosSnapshot.hasError) {
              return Center(
                  child: Text("SOS Error: ${sosSnapshot.error}"));
            }
            if (!emergencySnapshot.hasData || !sosSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final emergencyDocs = emergencySnapshot.data!.docs;
            final sosDocs = sosSnapshot.data!.docs;
            final allDocs = [...emergencyDocs, ...sosDocs];

            if (allDocs.isEmpty) {
              return const Center(
                child: Text(
                  "No pending emergency cases",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: allDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bool isSOS = data.containsKey('phone');

                final String type = isSOS
                    ? (data['emergencyType'] ?? 'Unknown').toString()
                    : (data['type'] ?? 'Unknown').toString();

                final String description = isSOS
                    ? (data['emergencyDescription'] ?? '').toString()
                    : (data['description'] ?? '').toString();

                final String location = isSOS
                    ? "📞 ${data['phone'] ?? ''}"
                    : (data['locationName'] ??
                            data['location'] ??
                            'Unknown Location')
                        .toString();

                final String priority = isSOS
                    ? (data['priority'] ?? 'normal')
                        .toString()
                        .toUpperCase()
                    : (data['severity'] ?? 'LOW')
                        .toString()
                        .toUpperCase();

                final color =
                    priority == "HIGH" || priority == "CRITICAL"
                        ? Colors.red
                        : Colors.orange;

                final collectionName =
                    isSOS ? 'sos_reports' : 'emergency_requests';

                // Get predefined assignment for this emergency type
                final assignment = _getAutoAssignment(type);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Icon(Icons.crisis_alert, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Text(
                        location,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),

                      // Description
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ── Predefined Supplies Section ──
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white24, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.inventory_2_outlined,
                                    color: Colors.white54, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  "Suggested Supplies",
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: assignment.entries.map((entry) {
                                final idx = _inventory.indexWhere(
                                    (i) => i['item'] == entry.key);
                                final available = idx != -1
                                    ? _inventory[idx]['quantity'] as int
                                    : 0;
                                final isLow = available < entry.value;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLow
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: isLow
                                            ? Colors.red.withOpacity(0.5)
                                            : Colors.green.withOpacity(0.5),
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    "${entry.key}: ${entry.value}${isLow ? ' ⚠️' : ''}",
                                    style: TextStyle(
                                      color:
                                          isLow ? Colors.red : Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Dispatch Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _showDispatchConfirmDialog(
                              docId: doc.id,
                              collectionName: collectionName,
                              type: type,
                              location: location,
                              priority: priority,
                            );
                          },
                          icon: const Icon(Icons.local_shipping, size: 16),
                          label: const Text(
                            "CONFIRM DISPATCH",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ================= INVENTORY TAB =================

  Widget _inventoryTab() {
    final totalItems =
        _inventory.fold(0, (sum, item) => sum + (item['quantity'] as int));
    final lowStock =
        _inventory.where((i) => (i['quantity'] as int) < 50).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Stats Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border.all(color: const Color(0xFFD32F2F)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Resources",
                    style: TextStyle(color: Colors.white)),
                Text(
                  totalItems.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (lowStock > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    "$lowStock item(s) running low!",
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          const Text(
            "Current Inventory",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white),
          ),

          const SizedBox(height: 15),

          ..._inventory.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLow = (item['quantity'] as int) < 50;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
                border: isLow ? Border.all(color: Colors.orange) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getIconFromString(item['icon']),
                                color: primaryRed),
                            const SizedBox(width: 8),
                            Text(
                              item['item'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        Text(
                          "${item['quantity']} ${item['unit']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_inventory[index]['quantity'] > 0) {
                          _inventory[index]['quantity']--;
                        }
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _inventory[index]['quantity']++;
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.green),
                  ),
                  IconButton(
                    onPressed: () async {
                      final item = _inventory[index];
                      if (item['isFirestore'] == true) {
                        await FirebaseFirestore.instance
                            .collection('ngo_inventory')
                            .doc(item['docId'])
                            .delete();
                      }
                      setState(() {
                        _inventory.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F)),
              onPressed: _showAddInventoryDialog,
              icon: const Icon(Icons.add),
              label: const Text(
                "ADD INVENTORY ITEM",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(255, 255, 255, 1)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ================= HISTORY TAB =================

  Widget _historyTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_requests')
          .where('status', isEqualTo: 'assigned')
          .snapshots(),
      builder: (context, emergencySnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sos_reports')
              .where('status', isEqualTo: 'assigned')
              .snapshots(),
          builder: (context, sosSnapshot) {
            if (!emergencySnapshot.hasData || !sosSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final emergencyDocs = emergencySnapshot.data!.docs;
            final sosDocs = sosSnapshot.data!.docs;
            final allDocs = [...emergencyDocs, ...sosDocs];

            if (allDocs.isEmpty) {
              return const Center(
                child: Text(
                  "No dispatch history yet",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: allDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bool isSOS = data.containsKey('phone');

                final String type = isSOS
                    ? (data['emergencyType'] ?? 'Unknown').toString()
                    : (data['type'] ?? 'Unknown').toString();

                final String location = isSOS
                    ? "📞 ${data['phone'] ?? ''}"
                    : (data['locationName'] ??
                            data['location'] ??
                            'Unknown Location')
                        .toString();

                final String priority = isSOS
                    ? (data['priority'] ?? 'normal')
                        .toString()
                        .toUpperCase()
                    : (data['severity'] ?? 'LOW').toString().toUpperCase();

                final Timestamp? assignedAt = data['assignedAt'];
                String timeText = "Time not available";
                if (assignedAt != null) {
                  final date = assignedAt.toDate();
                  timeText =
                      "${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                }

                final color =
                    priority == "HIGH" || priority == "CRITICAL"
                        ? Colors.red
                        : Colors.green;

                // Show dispatched resources if saved
                final Map<String, dynamic>? dispatchedResources =
                    data['dispatchedResources'] != null
                        ? Map<String, dynamic>.from(
                            data['dispatchedResources'])
                        : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping,
                              color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("📍 $location",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("🕒 $timeText",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),

                      // Show dispatched resources if available
                      if (dispatchedResources != null &&
                          dispatchedResources.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white24, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Dispatched Resources:",
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: dispatchedResources.entries
                                    .map((e) => Text(
                                          "${e.key}: ${e.value}",
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 11),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Resources Dispatched ✓",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}