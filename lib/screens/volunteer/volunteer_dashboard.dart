import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  int _currentTab = 0;
  String _userName = 'Volunteer';
  bool _isAvailable = true;
  bool _isLoading = true;
  final List<String> _mySkills = [];
  final List<String> _allSkills = [
    'Medical',
    'Rescue',
    'Logistics',
    'Food Distribution',
    'Shelter Setup'
  ];
  final user = FirebaseAuth.instance.currentUser;

  // Dummy nearby volunteers for UI display
  final List<Map<String, dynamic>> _nearbyVolunteers = [
    {
      'name': 'Rahul Sharma',
      'skill': 'Medical',
      'distance': '1.2 km',
      'status': 'Online',
      'color': Colors.green
    },
    {
      'name': 'Priya Patel',
      'skill': 'Rescue',
      'distance': '2.5 km',
      'status': 'Online',
      'color': Colors.green
    },
    {
      'name': 'Amit Singh',
      'skill': 'Logistics',
      'distance': '3.8 km',
      'status': 'Busy',
      'color': Colors.orange
    },
    {
      'name': 'Sneha Desai',
      'skill': 'Medical',
      'distance': '5.1 km',
      'status': 'Online',
      'color': Colors.green
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVolunteerData();
    _saveMyLocation(); // ← Save location on app open
  }

  // ── SAVE LOCATION TO FIRESTORE ─────────────────────
  Future<void> _saveMyLocation() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'location': {
          'lat': 18.5204, // Change per volunteer for demo
          'lng': 73.8567,
        },
        'availability': true,
      });
    } catch (e) {
      // If update fails (new user), use set with merge
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'location': {'lat': 18.5204, 'lng': 73.8567},
        'availability': true,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _loadVolunteerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      setState(() {
        _userName = doc['name'] ?? 'Volunteer';
        _isAvailable = doc['availability'] ?? true;
        final saved = List<String>.from(doc['skills'] ?? []);
        _mySkills.addAll(saved);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'availability': value});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value ? '✅ You are now Online' : '⚫ You are now Offline'),
      backgroundColor: value ? Colors.green : Colors.grey,
    ));
  }

  Future<void> _acceptTask(
    String docId,
    String type,
    String location,
    String source,
  ) async {
    try {
      final collectionName =
          source == "sos" ? "sos_reports" : "emergency_requests";

      final docSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .get();

      final data = docSnapshot.data() as Map<String, dynamic>;

      double distance = 0;

      // 🔥 Only calculate distance if lat/lng exist
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        final double citizenLat = data['latitude'];
        final double citizenLng = data['longitude'];

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        final volunteerLocation = userDoc['location'];

        final double volunteerLat = volunteerLocation['lat'];
        final double volunteerLng = volunteerLocation['lng'];

        distance = Geolocator.distanceBetween(
              citizenLat,
              citizenLng,
              volunteerLat,
              volunteerLng,
            ) /
            1000;
      }

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .update({
        'assignedTo': user!.uid,
        'assignedName': _userName,
        'status': 'in_progress',
        'acceptedAt': FieldValue.serverTimestamp(),
        'assignedDistance': distance,
        'source': source,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task Accepted Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _currentTab = 0);
    } catch (e) {
      print("ACCEPT ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error accepting task: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markCompleted(
    String docId,
    String type,
    String location,
    String source,
  ) async {
    final collectionName =
        source == "sos" ? "sos_reports" : "emergency_requests";

    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(docId)
        .update({
      'status': 'pending_confirmation',
      'completedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked complete! Waiting for confirmation.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _updateSkills() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'skills': _mySkills});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: Color(0xFFD32F2F), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $_userName 👋',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Text('Volunteer',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isAvailable ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  color: _isAvailable ? Colors.green : Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _isAvailable,
                  onChanged: _toggleAvailability,
                  activeColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : Column(
              children: [
                Container(
                  color: const Color(0xFF1E1E1E),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _tabButton('My Tasks', 0, Icons.assignment_ind),
                      const SizedBox(width: 8),
                      _tabButton('Available', 1, Icons.sos),
                      const SizedBox(width: 8),
                      _tabButton('Nearby', 2, Icons.people),
                      const SizedBox(width: 8),
                      _tabButton('Profile', 3, Icons.person),
                    ],
                  ),
                ),
                Expanded(
                  child: _currentTab == 0
                      ? _myTasksTab()
                      : _currentTab == 1
                          ? _availableTab()
                          : _currentTab == 2
                              ? _nearbyTab()
                              : _profileTab(),
                ),
              ],
            ),
    );
  }

  // ─── TAB 1: MY TASKS ──────────────────────────────
// ─── TAB 1: MY TASKS (FIXED VERSION) ─────────────────────────────
  Widget _myTasksTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_reports')
          .where('assignedTo', isEqualTo: user!.uid)
          .where('status',
              whereIn: ['in_progress', 'pending_confirmation']).snapshots(),
      builder: (context, sosSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('emergency_requests')
              .where('assignedTo', isEqualTo: user!.uid)
              .where('status',
                  whereIn: ['in_progress', 'pending_confirmation']).snapshots(),
          builder: (context, emergencySnapshot) {
            if (sosSnapshot.connectionState == ConnectionState.waiting ||
                emergencySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD32F2F),
                ),
              );
            }

            if (!sosSnapshot.hasData || !emergencySnapshot.hasData) {
              return _emptyState(
                icon: Icons.error_outline,
                title: "Error Loading Tasks",
                subtitle: "Please try again",
                color: Colors.red,
              );
            }

            final allDocs = [
              ...sosSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['source'] = 'sos';
                return {"id": doc.id, "data": data};
              }),
              ...emergencySnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['source'] = 'emergency';
                return {"id": doc.id, "data": data};
              }),
            ];

            if (allDocs.isEmpty) {
              return _emptyState(
                icon: Icons.assignment_outlined,
                title: 'No Active Tasks',
                subtitle: 'Accept tasks from Available tab',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allDocs.length,
              itemBuilder: (context, index) {
                final item = allDocs[index];
                return _myTaskCard(
                  item["id"] as String,
                  item["data"] as Map<String, dynamic>,
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── TAB 2: AVAILABLE SOS ─────────────────────────
  Widget _availableTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_reports')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, sosSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('emergency_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, emergencySnapshot) {
            if (!sosSnapshot.hasData || !emergencySnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final sosDocs = sosSnapshot.data!.docs;
            final emergencyDocs = emergencySnapshot.data!.docs;

            // 🔥 Merge both lists
            final allDocs = [
              ...sosDocs.map((d) => {"doc": d, "source": "sos"}),
              ...emergencyDocs.map((d) => {"doc": d, "source": "emergency"}),
            ];

            if (allDocs.isEmpty) {
              return const Center(
                child: Text(
                  "No Pending Requests",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: allDocs.map((item) {
                final doc = item["doc"] as QueryDocumentSnapshot;
                final String source = item["source"] as String;

                final data = doc.data() as Map<String, dynamic>;

                return _availableTaskCard(
                  doc.id,
                  data,
                  source,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ─── TAB 3: NEARBY VOLUNTEERS ─────────────────────
  Widget _nearbyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.people, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Volunteers near your location — sorted by distance',
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Your location card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_pin_circle,
                      color: Color(0xFFD32F2F), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You — $_userName',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const Text('📍 Pune, Maharashtra',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        'Skills: ${_mySkills.isEmpty ? "None selected" : _mySkills.join(", ")}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('● YOU',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text('Nearby Volunteers',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Auto-assignment picks nearest with matching skills',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),

          // Dummy nearby volunteers
          ..._nearbyVolunteers.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: (v['color'] as Color).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Colors.amber.withOpacity(0.2)
                          : const Color(0xFF2A2A2A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${i + 1}',
                        style: TextStyle(
                          color: i == 0 ? Colors.amber : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Volunteer info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(v['name'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            if (i == 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('NEAREST',
                                    style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: (v['color'] as Color), size: 12),
                            const SizedBox(width: 4),
                            Text(v['skill'],
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on,
                                color: Colors.grey, size: 12),
                            const SizedBox(width: 4),
                            Text(v['distance'],
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (v['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      v['status'],
                      style: TextStyle(
                          color: v['color'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // How auto assign works
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple, size: 18),
                    SizedBox(width: 8),
                    Text('How Smart Assignment Works',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                _stepRow(
                    '1', 'Citizen submits SOS with GPS location', Colors.blue),
                _stepRow(
                    '2', 'System scans all online volunteers', Colors.orange),
                _stepRow('3', 'Filters by required skill (Medical/Rescue etc)',
                    Colors.green),
                _stepRow('4', 'Calculates distance using Haversine formula',
                    Colors.purple),
                _stepRow('5', 'Nearest skilled volunteer gets auto-assigned',
                    Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 4: PROFILE ───────────────────────────────
  Widget _profileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFFD32F2F), size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(user?.email ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('Volunteer',
                                style: TextStyle(
                                    color: Colors.blue, fontSize: 11)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isAvailable
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _isAvailable ? '● Online' : '● Offline',
                              style: TextStyle(
                                  color:
                                      _isAvailable ? Colors.green : Colors.grey,
                                  fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Location card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved Location',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text('Pune, Maharashtra',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('18.5204° N, 73.8567° E',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Saved ✓',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('My Skills',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Select skills to get matched with right emergencies',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),

          ..._allSkills.map((skill) {
            final hasSkill = _mySkills.contains(skill);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: hasSkill
                    ? Border.all(
                        color: const Color(0xFFD32F2F).withOpacity(0.5))
                    : null,
              ),
              child: CheckboxListTile(
                title: Text(skill,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(_skillDescription(skill),
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                secondary: Icon(_skillIcon(skill),
                    color: hasSkill ? const Color(0xFFD32F2F) : Colors.grey),
                value: hasSkill,
                activeColor: const Color(0xFFD32F2F),
                onChanged: (value) {
                  setState(() {
                    if (value == true)
                      _mySkills.add(skill);
                    else
                      _mySkills.remove(skill);
                  });
                  _updateSkills();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(value == true
                        ? '$skill skill added!'
                        : '$skill skill removed'),
                    backgroundColor: value == true ? Colors.green : Colors.grey,
                    duration: const Duration(seconds: 1),
                  ));
                },
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                context.go('/login');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARDS ────────────────────────────────────────
  Widget _myTaskCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'in_progress';
    final isPending = status == 'pending_confirmation';
    final distance = data['assignedDistance'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.5)
              : Colors.blue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emergency,
                    color: Color(0xFFD32F2F), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(data['type'] ?? 'Emergency',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPending ? '⏳ Awaiting Confirm' : '🔵 In Progress',
                  style: TextStyle(
                      color: isPending ? Colors.orange : Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (distance != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.near_me, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'You were ${(distance as num).toStringAsFixed(1)} km away — nearest volunteer!',
                    style: const TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ),
            ),
          Row(children: [
            const Icon(Icons.location_on, color: Colors.grey, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                data['location'] ??
                    data['locationName'] ??
                    data['phone'] ??
                    '-',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ]),
          if (data['description'] != null &&
              data['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.notes, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(data['description'],
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12))),
            ]),
          ],
          const SizedBox(height: 12),
          isPending
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty,
                          color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text('Waiting for Admin Confirmation',
                          style: TextStyle(color: Colors.orange, fontSize: 13)),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markCompleted(
                      docId,
                      data['type'] ?? '',
                      data['location'] ?? '',
                      data['source'] ?? 'sos',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('MARK AS COMPLETED',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _availableTaskCard(
      String docId, Map<String, dynamic> data, String source) {
    Color typeColor = const Color(0xFFD32F2F);
    IconData typeIcon = Icons.warning;
    final bool isSOS = source == "sos";

    final Color sourceColor = isSOS ? Colors.red : Colors.blue;

    final String sourceLabel =
        isSOS ? "🆘 SOS (No Login)" : "⚡ Emergency (Logged In)";
    switch ((data['type'] ?? '').toLowerCase()) {
      case 'flood':
        typeColor = Colors.blue;
        typeIcon = Icons.water;
        break;
      case 'fire':
        typeColor = Colors.deepOrange;
        typeIcon = Icons.local_fire_department;
        break;
      case 'medical':
        typeColor = Colors.red;
        typeIcon = Icons.medical_services;
        break;
      case 'earthquake':
        typeColor = Colors.brown;
        typeIcon = Icons.landscape;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['type'] ?? 'Emergency',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const Text('Needs Volunteer',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('🆘 Pending',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Row(children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(data['location'] ?? '-',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13))),
                ]),
                if (data['description'] != null &&
                    data['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.notes, color: Colors.grey, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(data['description'],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12))),
                  ]),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person_outline,
                      color: Colors.grey, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    data['citizenEmail'] ??
                        data['userEmail'] ??
                        data['phone'] ??
                        'Public SOS',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAvailable
                  ? () => _acceptTask(
                        docId,
                        data['type'] ?? '',
                        data['location'] ?? '',
                        source,
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAvailable
                    ? const Color(0xFFD32F2F)
                    : Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(_isAvailable ? Icons.volunteer_activism : Icons.block,
                  size: 18),
              label: Text(
                _isAvailable ? 'ACCEPT & RESPOND' : 'GO ONLINE TO ACCEPT',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────
  Widget _stepRow(String step, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Center(
                child: Text(step,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFFD32F2F) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle,
      Color color = Colors.grey}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 56),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _skillDescription(String skill) {
    switch (skill) {
      case 'Medical':
        return 'First aid, CPR, emergency medical care';
      case 'Rescue':
        return 'Search & rescue, trapped person extraction';
      case 'Logistics':
        return 'Supply transport and coordination';
      case 'Food Distribution':
        return 'Managing and distributing food/water';
      case 'Shelter Setup':
        return 'Setting up temporary shelters and tents';
      default:
        return '';
    }
  }

  IconData _skillIcon(String skill) {
    switch (skill) {
      case 'Medical':
        return Icons.medical_services;
      case 'Rescue':
        return Icons.run_circle;
      case 'Logistics':
        return Icons.local_shipping;
      case 'Food Distribution':
        return Icons.fastfood;
      case 'Shelter Setup':
        return Icons.house;
      default:
        return Icons.star;
    }
  }
}
// ```

// ---

// ## ✅ What's New
// ```
// 🆕 _saveMyLocation() called in initState
//    → Saves lat/lng to Firestore on every login
//    → Uses merge so it won't overwrite other fields

// 🆕 NEARBY TAB (replaced History)
//    → Shows 4 dummy nearby volunteers
//    → Ranked #1 #2 #3 #4 by distance
//    → NEAREST badge on #1
//    → Color coded Online/Busy status
//    → "How Smart Assignment Works" explainer

// 🆕 MY TASKS shows distance badge
//    → "You were X km away — nearest volunteer!"

// 🆕 Location card in Profile + My Tasks tab
//    → Shows saved coordinates
