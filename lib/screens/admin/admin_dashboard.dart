import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'broadcast_screen.dart';
import 'ai_assistant_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedFilter = 'All';
  int _selectedIndex = 0;
  int _currentTab = 0;

  String _adminEmail = '';
  bool _isVerified = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _checking = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = (doc.data() ?? {})['role'] ?? '';
      if (mounted) {
        setState(() {
          _adminEmail = user.email ?? '';
          _isVerified = role == 'Admin';
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _log(String action, String detail) async {
    try {
      await FirebaseFirestore.instance.collection('admin_logs').add({
        'action': action,
        'detail': detail,
        'adminEmail': _adminEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFD32F2F))),
      );
    }

    if (!_isVerified) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.red, size: 72),
                const SizedBox(height: 20),
                const Text('Access Denied',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Admin accounts only',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted)
                      Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F)),
                  icon: const Icon(Icons.logout),
                  label: const Text('Back to Login'),
                ),
              ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E1E1E),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
        icon: const Icon(Icons.smart_toy, color: Color(0xFFD32F2F)),
        label: const Text('AI Help', style: TextStyle(color: Colors.white)),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Control Center',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(_adminEmail,
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: const Row(children: [
              Icon(Icons.circle, color: Colors.red, size: 7),
              SizedBox(width: 4),
              Text('LIVE',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          IconButton(
            icon:
                const Icon(Icons.broadcast_on_personal, color: Colors.orange),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BroadcastScreen())),
            tooltip: 'Broadcast',
          ),
          IconButton(
            icon: Stack(children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F), shape: BoxShape.circle),
                ),
              ),
            ]),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const NotificationScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E1E1E),
            height: 46,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                _tabChip('Dashboard', 0, Icons.dashboard),
                _tabChip('Cases', 1, Icons.sos),
                _tabChip('NGOs', 2, Icons.business),
                _tabChip('Volunteers', 3, Icons.people),
                _tabChip('Resources', 4, Icons.inventory),
                _tabChip('Analytics', 5, Icons.bar_chart),
                _tabChip('Audit Log', 6, Icons.security),
              ]),
            ),
          ),
          Expanded(child: _buildCurrentTab()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MapScreen()));
          } else if (index == 3) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Volunteers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index, IconData icon) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD32F2F)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return _dashboardTab();
      case 1:
        return _casesTab();
      case 2:
        return _ngoTab();
      case 3:
        return _volunteersTab();
      case 4:
        return _resourcesTab();
      case 5:
        return _analyticsTab();
      case 6:
        return _auditLogTab();
      default:
        return _dashboardTab();
    }
  }

  // ════════════════════════════════════════
  // TAB 0 — DASHBOARD (both collections)
  // ════════════════════════════════════════
  Widget _dashboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('sos_reports').snapshots(),
      builder: (context, sosSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('emergency_requests')
              .snapshots(),
          builder: (context, erSnap) {
            final sosDocs = sosSnap.data?.docs ?? [];
            final erDocs = erSnap.data?.docs ?? [];
            final allDocs = [...sosDocs, ...erDocs];

            final total = allDocs.length;
            final pending =
                allDocs.where((d) => d['status'] == 'pending').length;
            final active =
                allDocs.where((d) => d['status'] == 'in_progress').length;
            final pendingConfirm = allDocs
                .where((d) => d['status'] == 'pending_confirmation')
                .length;
            final resolved =
                allDocs.where((d) => d['status'] == 'resolved').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Broadcast banner
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('broadcasts')
                        .where('active', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty)
                        return const SizedBox();
                      final data = snap.data!.docs.first.data()
                          as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.broadcast_on_personal,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('📢 Active: ${data['message']}',
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 12)),
                          ),
                        ]),
                      );
                    },
                  ),

                  // ── Pending confirmation alert banner ──
                  if (pendingConfirm > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.purple.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.hourglass_empty,
                            color: Colors.purple, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⏳ $pendingConfirm case(s) waiting for citizen confirmation',
                            style: const TextStyle(
                                color: Colors.purple, fontSize: 12),
                          ),
                        ),
                      ]),
                    ),

                  // 5 stat cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    children: [
                      _gridStatCard(
                          'Total', '$total', Icons.sos, Colors.red),
                      _gridStatCard('Pending', '$pending',
                          Icons.pending_actions, Colors.orange),
                      _gridStatCard('Active', '$active',
                          Icons.local_fire_department, Colors.blue),
                      _gridStatCard('Awaiting Confirm', '$pendingConfirm',
                          Icons.hourglass_empty, Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Full-width resolved card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$resolved',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const Text('Resolved',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ]),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Quick actions
                  Row(children: [
                    Expanded(
                        child: _quickAction(
                            'Broadcast',
                            Icons.broadcast_on_personal,
                            Colors.orange,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const BroadcastScreen())))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _quickAction(
                            'Map',
                            Icons.map,
                            Colors.blue,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MapScreen())))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _quickAction(
                            'Analytics',
                            Icons.bar_chart,
                            Colors.purple,
                            () => setState(() => _currentTab = 5))),
                  ]),

                  const SizedBox(height: 24),

                  const Text('All Emergency Requests',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'pending',
                        'in_progress',
                        'pending_confirmation',
                        'resolved'
                      ].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        final label = filter == 'All'
                            ? 'All ($total)'
                            : filter == 'pending'
                                ? 'Pending ($pending)'
                                : filter == 'in_progress'
                                    ? 'Active ($active)'
                                    : filter == 'pending_confirmation'
                                        ? 'Awaiting ($pendingConfirm)'
                                        : 'Resolved ($resolved)';
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = filter),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Combined list
                  ..._buildFilteredCards(allDocs),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildFilteredCards(List<QueryDocumentSnapshot> allDocs) {
    List<QueryDocumentSnapshot> filtered = allDocs;
    if (_selectedFilter != 'All') {
      filtered = allDocs
          .where((d) => d['status'] == _selectedFilter)
          .toList();
    }

    if (filtered.isEmpty) {
      return [
        _emptyCard('No $_selectedFilter requests', Icons.sos)
      ];
    }

    return filtered.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Detect which collection this came from
      final source = data.containsKey('phone') ? 'sos_reports' : 'emergency_requests';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _requestCard(doc.id, data, source),
      );
    }).toList();
  }

  // ════════════════════════════════════════
  // TAB 1 — CASES (both collections)
  // ════════════════════════════════════════
  Widget _casesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('sos_reports').snapshots(),
      builder: (context, sosSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('emergency_requests')
              .snapshots(),
          builder: (context, erSnap) {
            final sosDocs = (sosSnap.data?.docs ?? []).map((d) {
              final data = d.data() as Map<String, dynamic>;
              data['_source'] = 'sos_reports';
              data['_docId'] = d.id;
              return data;
            }).toList();

            final erDocs = (erSnap.data?.docs ?? []).map((d) {
              final data = d.data() as Map<String, dynamic>;
              data['_source'] = 'emergency_requests';
              data['_docId'] = d.id;
              return data;
            }).toList();

            final allItems = [...sosDocs, ...erDocs];

            List<Map<String, dynamic>> filtered = allItems;
            if (_selectedFilter != 'All') {
              filtered = allItems
                  .where((d) => d['status'] == _selectedFilter)
                  .toList();
            }

            return Column(
              children: [
                Container(
                  color: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'pending',
                        'in_progress',
                        'pending_confirmation',
                        'resolved'
                      ].map((f) {
                        final isSelected = _selectedFilter == f;
                        final label = f == 'All'
                            ? 'All'
                            : f == 'in_progress'
                                ? 'Active'
                                : f == 'pending_confirmation'
                                    ? 'Awaiting Confirm'
                                    : f[0].toUpperCase() + f.substring(1);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('No cases found',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final data = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _requestCard(
                                data['_docId'] as String,
                                data,
                                data['_source'] as String,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════
  // TAB 2 — NGOs
  // ════════════════════════════════════════
  Widget _ngoTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'NGO')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _statCard('Total NGOs', '${docs.length}', Icons.business,
                    Colors.blue),
                const SizedBox(width: 12),
                _statCard('Active', '${docs.length}', Icons.check_circle,
                    Colors.green),
              ]),
              const SizedBox(height: 20),
              const Text('Registered NGOs',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                _emptyCard('No NGOs registered yet', Icons.business)
              else
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.15),
                            child: Text(
                              (data['name'] ?? 'N')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'NGO',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(data['email'] ?? '-',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Active',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('ngo_inventory')
                              .doc(doc.id)
                              .snapshots(),
                          builder: (context, invSnap) {
                            if (!invSnap.hasData || !invSnap.data!.exists) {
                              return const Text('No inventory data',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12));
                            }
                            final invData = invSnap.data!.data()
                                as Map<String, dynamic>;
                            final items =
                                List<Map<String, dynamic>>.from(
                                    invData['inventory'] ?? []);
                            final totalItems = items.fold(
                                0,
                                (sum, item) =>
                                    sum + (item['quantity'] as int? ?? 0));
                            return Row(children: [
                              const Icon(Icons.inventory,
                                  color: Colors.grey, size: 13),
                              const SizedBox(width: 4),
                              Text('Inventory: $totalItems items',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ]);
                          },
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('dispatches')
                              .where('ngoId', isEqualTo: doc.id)
                              .snapshots(),
                          builder: (context, dispSnap) {
                            final count =
                                dispSnap.data?.docs.length ?? 0;
                            return Row(children: [
                              const Icon(Icons.local_shipping,
                                  color: Colors.green, size: 13),
                              const SizedBox(width: 4),
                              Text('$count dispatches made',
                                  style: const TextStyle(
                                      color: Colors.green, fontSize: 12)),
                            ]);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════
  // TAB 3 — VOLUNTEERS
  // ════════════════════════════════════════
  Widget _volunteersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Volunteer')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _statCard('Total', '${docs.length}', Icons.people,
                    Colors.purple),
                const SizedBox(width: 12),
                _statCard('Online', '${docs.length}', Icons.circle,
                    Colors.green),
              ]),
              const SizedBox(height: 20),
              const Text('Volunteer Directory',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                _emptyCard('No volunteers registered', Icons.people)
              else
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sos_reports')
                        .where('assignedTo', isEqualTo: doc.id)
                        .where('status', whereIn: [
                      'in_progress',
                      'pending_confirmation'
                    ]).snapshots(),
                    builder: (context, taskSnap) {
                      final tasks =
                          taskSnap.data?.docs.length ?? 0;
                      final isBusy = tasks > 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.purple.withOpacity(0.15),
                            child: Text(
                              (data['name'] ?? 'V')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'Volunteer',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(data['email'] ?? '-',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                                if (isBusy)
                                  Text('$tasks active task(s)',
                                      style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11)),
                                Builder(builder: (_) {
                                  final skills = List<String>.from(
                                      data['skills'] ?? []);
                                  if (skills.isEmpty) {
                                    return const Text('No skills set',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11));
                                  }
                                  return Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: skills
                                        .map((s) => Container(
                                              margin: const EdgeInsets.only(
                                                  top: 4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6),
                                                border: Border.all(
                                                    color: Colors.purple
                                                        .withOpacity(0.3)),
                                              ),
                                              child: Text(s,
                                                  style: const TextStyle(
                                                      color: Colors.purple,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ))
                                        .toList(),
                                  );
                                }),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isBusy
                                      ? Colors.orange
                                      : Colors.green)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(isBusy ? 'Busy' : 'Free',
                                style: TextStyle(
                                    color: isBusy
                                        ? Colors.orange
                                        : Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      );
                    },
                  );
                }).toList(),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════
  // TAB 4 — RESOURCES
  // ════════════════════════════════════════
  Widget _resourcesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ngo_inventory')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        Map<String, int> totalResources = {
          'Food Packets': 0,
          'Water Bottles': 0,
          'Medical Kits': 0,
          'Blankets': 0,
          'Tents': 0,
        };
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items =
              List<Map<String, dynamic>>.from(data['inventory'] ?? []);
          for (var item in items) {
            final name = item['item'] as String? ?? '';
            final qty = item['quantity'] as int? ?? 0;
            if (totalResources.containsKey(name)) {
              totalResources[name] = totalResources[name]! + qty;
            }
          }
        }

        final resourceIcons = {
          'Food Packets': Icons.fastfood,
          'Water Bottles': Icons.water_drop,
          'Medical Kits': Icons.medical_services,
          'Blankets': Icons.airline_seat_flat,
          'Tents': Icons.house,
        };
        final resourceColors = {
          'Food Packets': Colors.orange,
          'Water Bottles': Colors.blue,
          'Medical Kits': Colors.red,
          'Blankets': Colors.purple,
          'Tents': Colors.green,
        };

        final criticalCount =
            totalResources.values.where((v) => v < 50).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (criticalCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                        '⚠️ $criticalCount resource(s) critically low!',
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                      'Aggregated from ${docs.length} NGO${docs.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.blue, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('Total Resource Intelligence',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...totalResources.entries.map((entry) {
                final isLow = entry.value < 50;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: isLow
                        ? Border.all(color: Colors.red.withOpacity(0.4))
                        : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: (resourceColors[entry.key] ?? Colors.grey)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                          resourceIcons[entry.key] ?? Icons.inventory,
                          color:
                              resourceColors[entry.key] ?? Colors.grey,
                          size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            if (isLow) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Text('LOW',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  (entry.value / 1000).clamp(0.0, 1.0),
                              backgroundColor:
                                  const Color(0xFF2A2A2A),
                              color: isLow
                                  ? Colors.red
                                  : resourceColors[entry.key] ??
                                      Colors.green,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${entry.value}',
                        style: TextStyle(
                            color:
                                isLow ? Colors.red : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ]),
                );
              }).toList(),
              const SizedBox(height: 20),
              const Text('Recent Dispatches',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('dispatches')
                    .snapshots(),
                builder: (context, dispSnap) {
                  final dispDocs = dispSnap.data?.docs ?? [];
                  if (dispDocs.isEmpty)
                    return _emptyCard(
                        'No dispatches yet', Icons.local_shipping);
                  return Column(
                    children: dispDocs.take(5).map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      final items =
                          List<Map<String, dynamic>>.from(
                              data['items'] ?? []);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.local_shipping,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${data['emergencyType']} → ${data['location']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                Text('${items.length} item type(s)',
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Sent',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════
  // TAB 5 — ANALYTICS
  // ════════════════════════════════════════
  Widget _analyticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_reports')
          .snapshots(),
      builder: (context, sosSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('emergency_requests')
              .snapshots(),
          builder: (context, erSnap) {
            final docs = [
              ...(sosSnap.data?.docs ?? []),
              ...(erSnap.data?.docs ?? [])
            ];
            final total = docs.length;
            final pending =
                docs.where((d) => d['status'] == 'pending').length;
            final active =
                docs.where((d) => d['status'] == 'in_progress').length;
            final waitingConfirm = docs
                .where((d) => d['status'] == 'pending_confirmation')
                .length;
            final resolved =
                docs.where((d) => d['status'] == 'resolved').length;

            Map<String, int> typeCounts = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? data['emergencyType'] ?? 'Other';
              typeCounts[type] = (typeCounts[type] ?? 0) + 1;
            }

            final resRate = total > 0
                ? ((resolved / total) * 100).toStringAsFixed(0)
                : '0';
            final pendRate = total > 0
                ? ((pending / total) * 100).toStringAsFixed(0)
                : '0';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Key Metrics',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _bigMetric(
                        'Resolution\nRate', '$resRate%', Colors.green),
                    const SizedBox(width: 10),
                    _bigMetric(
                        'Pending\nRate', '$pendRate%', Colors.orange),
                    const SizedBox(width: 10),
                    _bigMetric('Total\nCases', '$total', Colors.red),
                  ]),
                  const SizedBox(height: 24),
                  const Text('Emergency Type Breakdown',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (typeCounts.isEmpty)
                    _emptyCard('No data yet', Icons.bar_chart)
                  else
                    ...typeCounts.entries.map((entry) {
                      final percent =
                          total > 0 ? entry.value / total : 0.0;
                      final colors = {
                        'Flood': Colors.blue,
                        'Fire': Colors.red,
                        'Medical': Colors.green,
                        'Earthquake': Colors.orange,
                        'Other': Colors.grey,
                      };
                      final color =
                          colors[entry.key] ?? Colors.purple;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(entry.key,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('${entry.value} case(s)',
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold)),
                              ]),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor:
                                      const Color(0xFF2A2A2A),
                                  color: color,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '${(percent * 100).toStringAsFixed(0)}% of all cases',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ]),
                      );
                    }).toList(),
                  const SizedBox(height: 20),
                  const Text('Status Overview',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      _statusBar('Pending', pending, total, Colors.orange),
                      const SizedBox(height: 12),
                      _statusBar('Active', active, total, Colors.blue),
                      const SizedBox(height: 12),
                      _statusBar('Awaiting', waitingConfirm, total,
                          Colors.purple),
                      const SizedBox(height: 12),
                      _statusBar(
                          'Resolved', resolved, total, Colors.green),
                    ]),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════
  // TAB 6 — AUDIT LOG
  // ════════════════════════════════════════
  Widget _auditLogTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_logs')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1A1A1A),
            child: Row(children: [
              const Icon(Icons.security, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text('${docs.length} admin actions recorded',
                  style:
                      const TextStyle(color: Colors.green, fontSize: 13)),
              const Spacer(),
              const Text('Tamper-proof log',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
          Expanded(
            child: docs.isEmpty
                ? _emptyCard(
                    'No actions logged yet\nAssign or resolve a case to start',
                    Icons.history)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d =
                          docs[i].data() as Map<String, dynamic>;
                      final ts = d['timestamp'];
                      String timeStr = '-';
                      if (ts is Timestamp) {
                        final dt = ts.toDate();
                        timeStr =
                            '${dt.day}/${dt.month}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.15)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.admin_panel_settings,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(d['action'] ?? '-',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text(d['detail'] ?? '-',
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11)),
                                Text(d['adminEmail'] ?? '-',
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10)),
                              ])),
                          Text(timeStr,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 10)),
                        ]),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }

  // ════════════════════════════════════════
  // REQUEST CARD — handles all statuses including pending_confirmation
  // ════════════════════════════════════════
  Widget _requestCard(
      String docId, Map<String, dynamic> data, String source) {
    Color statusColor;
    String statusLabel;
    final status = data['status'] ?? 'pending';

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'Pending';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusLabel = 'In Progress';
        break;
      case 'pending_confirmation':
        statusColor = Colors.purple;
        statusLabel = '⏳ Citizen Confirming';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusLabel = '✓ Resolved';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    final collectionName = source == 'sos_reports'
        ? 'sos_reports'
        : 'emergency_requests';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: status == 'pending_confirmation'
            ? Border.all(color: Colors.purple.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.emergency,
                  color: Color(0xFFD32F2F), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['type'] ?? data['emergencyType'] ?? 'Emergency',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // Citizen confirmation notice
          if (status == 'pending_confirmation') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.hourglass_empty,
                    color: Colors.purple, size: 15),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Volunteer marked complete. Waiting for citizen to confirm resolution.',
                    style:
                        TextStyle(color: Colors.purple, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 10),

          // Email/phone
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['userEmail'] ?? data['phone'] ?? 'Public SOS',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: Colors.grey, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['locationName'] ??
                      data['location'] ??
                      'Location unavailable',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // People + volunteers
          Builder(builder: (_) {
            final int peopleCount = data['peopleCount'] ?? 0;
            final int volunteersNeeded = data['volunteersNeeded'] ?? 0;
            final String type =
                (data['type'] ?? data['emergencyType'] ?? '')
                    .toLowerCase();

            final Map<String, List<String>> skillMap = {
              'flood': ['Rescue', 'Logistics'],
              'fire': ['Rescue', 'Medical'],
              'earthquake': ['Rescue', 'Medical', 'Shelter Setup'],
              'medical': ['Medical'],
            };
            final List<String> requiredSkills = skillMap[type] ?? [];

            if (peopleCount == 0 && volunteersNeeded == 0)
              return const SizedBox();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (peopleCount > 0) ...[
                    _adminBadge(
                        Icons.people,
                        '$peopleCount ${peopleCount == 1 ? "person" : "people"}',
                        Colors.amber),
                    const SizedBox(width: 8),
                  ],
                  if (volunteersNeeded > 0)
                    _adminBadge(Icons.volunteer_activism,
                        '$volunteersNeeded vol. needed', Colors.cyan),
                ]),
                if (requiredSkills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.psychology,
                        color: Colors.purple, size: 13),
                    const SizedBox(width: 5),
                    Text('Needs: ${requiredSkills.join(", ")}',
                        style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
                const SizedBox(height: 8),
              ],
            );
          }),

          // Action buttons
          Row(
            children: [
              // Assign button (only when pending)
              if (status == 'pending')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection(collectionName)
                          .doc(docId)
                          .update({'status': 'in_progress'});
                      await _log('ASSIGN',
                          data['type'] ?? data['emergencyType'] ?? '');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text('Volunteer Assigned!'),
                        backgroundColor: Colors.green,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F)),
                    child: const Text('ASSIGN VOLUNTEER',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),

              // In progress → admin can force resolve
              if (status == 'in_progress') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection(collectionName)
                          .doc(docId)
                          .update({'status': 'resolved'});
                      await _log('FORCE RESOLVE',
                          data['type'] ?? data['emergencyType'] ?? '');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text('Marked Resolved!'),
                        backgroundColor: Colors.green,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text('MARK RESOLVED',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],

              // Pending confirmation → admin can force resolve or re-open
              if (status == 'pending_confirmation') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection(collectionName)
                          .doc(docId)
                          .update({
                        'status': 'resolved',
                        'adminForceResolved': true,
                      });
                      await _log('ADMIN FORCE RESOLVED',
                          data['type'] ?? data['emergencyType'] ?? '');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text('Admin marked as resolved!'),
                        backgroundColor: Colors.green,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text('CONFIRM RESOLVED',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection(collectionName)
                          .doc(docId)
                          .update({'status': 'in_progress'});
                      await _log('REOPEN',
                          data['type'] ?? data['emergencyType'] ?? '');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text('Case reopened.'),
                        backgroundColor: Colors.orange,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('REOPEN',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],

              // Already resolved
              if (status == 'resolved')
                Expanded(
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800),
                    child: const Text('RESOLVED ✓',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _gridStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _quickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _bigMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _statusBar(
      String label, int count, int total, Color color) {
    final percent = total > 0 ? count / total : 0.0;
    return Row(children: [
      SizedBox(
          width: 70,
          child: Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: const Color(0xFF2A2A2A),
            color: color,
            minHeight: 8,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('$count',
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _adminBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _emptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Column(children: [
          Icon(icon, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}