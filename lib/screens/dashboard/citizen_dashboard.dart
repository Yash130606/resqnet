import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../dashboard/alerts_screen.dart';
import 'report_emergency_screen.dart';
import '../citizen/help_chat_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard>
    with TickerProviderStateMixin {
  int currentIndex = 0;
  final Map<String, bool> _expandedStates = {};

  final MapController _mapController = MapController();

  // ✅ FIX 3: Default center set to Pune (where your Firestore data is)
  LatLng defaultCenter = const LatLng(18.5074, 73.8077);

  LatLng? userLocation;
  String locationText = "Fetching location...";
  String userName = "User";

  // 🔴 Disaster markers
  List<Marker> disasterMarkers = [];

  // 🟢 Safe zone markers
  List<Marker> safeZoneMarkers = [];

  // 🟡 Relief camp markers
  List<Marker> reliefCampMarkers = [];

  late AnimationController rotateController;
  late AnimationController shakeController;
  late AnimationController pulseController;
  late AnimationController waveController;

  Future<void> loadDisasters() async {
    FirebaseFirestore.instance
        .collection('disasters')
        .where('status', isEqualTo: "active")
        .snapshots()
        .listen((snapshot) {
      // ✅ FIX: Check mounted before setState
      if (!mounted) return;

      print("Disaster docs count: ${snapshot.docs.length}");

      disasterMarkers = snapshot.docs.map((doc) {
        final data = doc.data();

        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();

        print("Disaster at: $lat , $lng");

        return Marker(
          width: 40,
          height: 40,
          point: LatLng(lat, lng),
          child: const Icon(Icons.warning, color: Colors.red, size: 35),
        );
      }).toList();

      setState(() {});
    });
  }

  Future<void> loadReliefCamps() async {
    FirebaseFirestore.instance
        .collection('relief_camps')
        .snapshots()
        .listen((snapshot) {
      // ✅ FIX: Check mounted before setState
      if (!mounted) return;

      print("Relief camps count: ${snapshot.docs.length}");

      reliefCampMarkers = snapshot.docs.map((doc) {
        final data = doc.data();

        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();

        return Marker(
          width: 40,
          height: 40,
          point: LatLng(lat, lng),
          child: const Icon(Icons.home, color: Colors.orange, size: 35),
        );
      }).toList();

      setState(() {});
    });
  }

  Future<void> loadSafeZones() async {
    FirebaseFirestore.instance
        .collection('safe_zones')
        .snapshots()
        .listen((snapshot) {
      // ✅ FIX: Check mounted before setState
      if (!mounted) return;

      print("Safe zones count: ${snapshot.docs.length}");

      safeZoneMarkers = snapshot.docs.map((doc) {
        final data = doc.data();

        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();

        return Marker(
          width: 40,
          height: 40,
          point: LatLng(lat, lng),
          child: const Icon(Icons.shield, color: Colors.green, size: 35),
        );
      }).toList();

      setState(() {});
    });
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        userName = doc['name'] ?? "User";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getLocationSafely();
    fetchUserName();
    loadDisasters();
    loadReliefCamps();
    loadSafeZones();

    rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    rotateController.dispose();
    shakeController.dispose();
    pulseController.dispose();
    waveController.dispose();
    super.dispose();
  }

  Future<void> getLocationSafely() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      LatLng current = LatLng(position.latitude, position.longitude);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks.first;

      if (!mounted) return;

      setState(() {
        userLocation = current;
        locationText =
            "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
      });

      // ✅ FIX 2: Wrap mapController.move in addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(current, 15);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          locationText = "Location Error";
        });
      }
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Citizen Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(Icons.support_agent),
        label: const Text("Help"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HelpChatScreen(),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            );
          } else {
            setState(() => currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Requests"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          _homeScreen(userName),
          _buildMyRequestsScreen(),
          const SizedBox(),
          _profileScreen(user?.email ?? "User"),
        ],
      ),
    );
  }

  Widget _homeScreen(String name) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 Greeting
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, $name 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 🚨 SOS Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportEmergencyScreen(),
                ),
              );
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "REPORT EMERGENCY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Quick Stats (Live)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('disasters').snapshots(),
            builder: (context, disasterSnapshot) {
              if (disasterSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              int high = 0;
              int medium = 0;

              if (disasterSnapshot.hasData) {
                for (var doc in disasterSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final severity =
                      (data['severity'] ?? '').toString().toLowerCase();

                  if (severity == "high") {
                    high++;
                  } else if (severity == "medium") {
                    medium++;
                  }
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('safe_zones')
                    .snapshots(),
                builder: (context, safeSnapshot) {
                  int safeZones =
                      safeSnapshot.hasData ? safeSnapshot.data!.docs.length : 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('relief_camps')
                        .snapshots(),
                    builder: (context, campSnapshot) {
                      int camps = campSnapshot.hasData
                          ? campSnapshot.data!.docs.length
                          : 0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              _statusCard("Active Disasters", high, Colors.red),
                              const SizedBox(width: 10),
                              _statusCard(
                                  "Medium Alerts", medium, Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _statusCard(
                                  "Safe Zones", safeZones, Colors.green),
                              const SizedBox(width: 10),
                              _statusCard("Relief Camps", camps, Colors.blue),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 25),

          const Text(
            "My Request Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('emergency_requests')
                .where(
                  'userId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                )
                .snapshots(),
            builder: (context, snapshot) {
              int pending = 0;
              int assigned = 0;
              int inProgress = 0;
              int resolved = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final status = doc['status'].toString().toLowerCase();

                  if (status == "pending") {
                    pending++;
                  } else if (status == "assigned") {
                    assigned++;
                  } else if (status == "in progress") {
                    inProgress++;
                  } else if (status == "resolved") {
                    resolved++;
                  }
                }
              }

              return Column(
                children: [
                  Row(
                    children: [
                      _statusCard("Pending", pending, Colors.orange),
                      const SizedBox(width: 10),
                      _statusCard("Assigned", assigned, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statusCard("In Progress", inProgress, Colors.purple),
                      const SizedBox(width: 10),
                      _statusCard("Resolved", resolved, Colors.green),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 25),

          const Text(
            "Live Disaster Map",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Map Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Row(children: [
                Icon(Icons.warning, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Text("Disaster",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              Row(children: [
                Icon(Icons.shield, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text("Safe Zone",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              Row(children: [
                Icon(Icons.home, color: Colors.orange, size: 16),
                SizedBox(width: 4),
                Text("Relief Camp",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              Row(children: [
                Icon(Icons.location_on, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text("You", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
                // ✅ FIX 1: Use initialCenter and initialZoom (not deprecated center/zoom)
                options: MapOptions(
                  initialCenter: defaultCenter,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.resqnetpro',
                  ),
                  MarkerLayer(
                    markers: [
                      if (userLocation != null)
                        Marker(
                          point: userLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ...disasterMarkers,
                      ...safeZoneMarkers,
                      ...reliefCampMarkers,
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "🛡️ Disaster Safety Awareness",
            style: TextStyle(
              fontSize: 18,
              color: Color.fromARGB(255, 255, 255, 255),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _buildSafetyAwarenessSection(),

          const Text(
            "Disaster News",
            style: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 310,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _newsCard(
                  title: "Heavy Rainfall Warning",
                  location: "Pune",
                  time: "2 hours ago",
                  description:
                      "IMD has issued heavy rainfall warning for Pune district.",
                ),
                _newsCard(
                  title: "Flood Alert Issued",
                  location: "Mumbai",
                  time: "5 hours ago",
                  description:
                      "Water levels rising in low-lying areas near coastal region.",
                ),
                _newsCard(
                  title: "Fire Safety Advisory",
                  location: "Nagpur",
                  time: "Yesterday",
                  description:
                      "Authorities advise caution due to rising industrial incidents.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsCard({
    required String title,
    required String location,
    required String time,
    required String description,
  }) {
    String lowerTitle = title.toLowerCase();

    String imageUrl;

    if (lowerTitle.contains("rain")) {
      imageUrl =
          "https://upload.wikimedia.org/wikipedia/commons/5/55/Rain_in_India.jpg";
    } else if (lowerTitle.contains("flood")) {
      imageUrl =
          "https://upload.wikimedia.org/wikipedia/commons/3/3c/Flood_in_Bangladesh.jpg";
    } else if (lowerTitle.contains("fire")) {
      imageUrl =
          "https://upload.wikimedia.org/wikipedia/commons/5/5e/Forest_fire.jpg";
    } else {
      imageUrl =
          "https://upload.wikimedia.org/wikipedia/commons/6/6e/Natural_disaster_damage.jpg";
    }

    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                imageUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 130,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  );
                },
              )),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "📍 $location • $time",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Read More",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsScreen() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_requests')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No requests submitted yet"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final type = data['type'] ?? "Unknown";
            final status = data['status'] ?? "pending";
            final location = data['locationName'] ?? "";
            final description = data['description'] ?? "";
            final distance = data['assignedDistance'];

            String normalizedStatus = status.toString().toLowerCase().trim();

            Color statusColor;

            switch (normalizedStatus) {
              case "pending":
                statusColor = Colors.orange;
                break;
              case "assigned":
                statusColor = Colors.blue;
                break;
              case "in progress":
                statusColor = Colors.purple;
                break;
              case "resolved":
                statusColor = Colors.green;
                break;
              default:
                statusColor = Colors.grey;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (distance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me,
                                color: Colors.blue, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "Volunteer is ${distance.toStringAsFixed(2)} km away",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _safetyCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> tips,
  }) {
    bool isExpanded = _expandedStates[title] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _buildAnimatedIcon(title, icon, color),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: isExpanded ? 0.5 : 0,
              child: const Icon(Icons.expand_more),
            ),
            onTap: () {
              setState(() {
                _expandedStates[title] = !isExpanded;
              });
            },
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tips
                    .map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• "),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(String title, IconData icon, Color color) {
    if (title.contains("Flood")) {
      return AnimatedBuilder(
        animation: waveController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 6 * waveController.value),
            child: Icon(icon,
                color: const Color.fromARGB(255, 32, 225, 255), size: 28),
          );
        },
      );
    } else if (title.contains("Fire")) {
      return AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + 0.2 * pulseController.value,
            child: Icon(icon,
                color: const Color.fromARGB(255, 255, 182, 13), size: 28),
          );
        },
      );
    } else if (title.contains("Earthquake")) {
      return AnimatedBuilder(
        animation: shakeController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(4 * (shakeController.value - 0.5), 0),
            child: Icon(icon,
                color: const Color.fromARGB(255, 95, 12, 12), size: 28),
          );
        },
      );
    } else {
      return AnimatedBuilder(
        animation: rotateController,
        builder: (context, child) {
          return Transform.rotate(
            angle: rotateController.value * 6.3,
            child: Icon(icon,
                color: const Color.fromARGB(255, 22, 255, 80), size: 28),
          );
        },
      );
    }
  }

  Widget _buildSafetyAwarenessSection() {
    return Column(
      children: [
        _safetyCard(
          icon: Icons.water_drop,
          title: "Flood Safety",
          color: Colors.blue,
          tips: [
            "Stay indoors and avoid flooded areas.",
            "Move to higher ground immediately.",
            "Do not walk or drive through flood water.",
          ],
        ),
        const SizedBox(height: 12),
        _safetyCard(
          icon: Icons.local_fire_department,
          title: "Fire Safety",
          color: Colors.red,
          tips: [
            "Do not use elevators during fire.",
            "Stay low to avoid smoke inhalation.",
            "Call emergency services immediately.",
          ],
        ),
        const SizedBox(height: 12),
        _safetyCard(
          icon: Icons.public,
          title: "Earthquake Safety",
          color: Colors.orange,
          tips: [
            "Drop, Cover, and Hold On.",
            "Stay away from windows.",
            "Move to open area after shaking stops.",
          ],
        ),
        const SizedBox(height: 12),
        _safetyCard(
          icon: Icons.medical_services,
          title: "Medical Emergency",
          color: Colors.green,
          tips: [
            "Call emergency services immediately.",
            "Provide first aid if trained.",
            "Keep the person calm and still.",
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _profileScreen(String email) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        String name = data?['name'] ?? "User";
        String role = data?['role'] ?? "Citizen";
        String emergencyContact = data?['emergencyContact'] ?? "Not Set";

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFD32F2F).withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "U",
                  style: const TextStyle(
                    fontSize: 40,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Chip(
                label: Text(
                  role,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFF1E1E1E),
                side: const BorderSide(color: Color(0xFFD32F2F)),
              ),
              const SizedBox(height: 25),
              _profileTile(
                icon: Icons.phone,
                title: "Emergency Contact",
                value: emergencyContact,
                onTap: () => _editEmergencyContact(emergencyContact),
              ),
              _profileTile(
                icon: Icons.edit,
                title: "Edit Name",
                value: "Update your name",
                onTap: () => _editName(name),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: logout,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD32F2F)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _editName(String currentName) async {
    TextEditingController controller = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({
                "name": controller.text.trim(),
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editEmergencyContact(String currentContact) async {
    TextEditingController controller =
        TextEditingController(text: currentContact);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Contact"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration:
              const InputDecoration(labelText: "Enter emergency contact"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({
                "emergencyContact": controller.text.trim(),
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
