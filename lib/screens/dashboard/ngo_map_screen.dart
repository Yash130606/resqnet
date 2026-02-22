import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class NgoMapScreen extends StatefulWidget {
  const NgoMapScreen({super.key});

  @override
  State<NgoMapScreen> createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends State<NgoMapScreen> {
  final MapController _mapController = MapController();

  final LatLng defaultCenter = const LatLng(21.1458, 79.0882);

  LatLng? ngoLocation;

  List<Marker> disasterMarkers = [];
  List<Marker> safeZoneMarkers = [];
  List<Marker> reliefMarkers = [];
  List<Marker> dispatchMarkers = [];

  final Color primaryRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _getNgoLocation();
    _loadDisasters();
    _loadSafeZones();
    _loadReliefCamps();
    _loadDispatchLocations();
  }

  // ================= NGO LIVE LOCATION =================

  Future<void> _getNgoLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    ngoLocation = LatLng(position.latitude, position.longitude);

    _mapController.move(ngoLocation!, 14);

    setState(() {});
  }

  // ================= FIRESTORE LOADERS =================

  void _loadDisasters() {
    FirebaseFirestore.instance
        .collection('disasters')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      disasterMarkers = snapshot.docs.map((doc) {
        final data = doc.data();
        return _buildMarker(
          LatLng(data['latitude'], data['longitude']),
          Icons.warning,
          Colors.red,
        );
      }).toList();

      setState(() {});
    });
  }

  void _loadSafeZones() {
    FirebaseFirestore.instance
        .collection('safe_zones')
        .snapshots()
        .listen((snapshot) {
      safeZoneMarkers = snapshot.docs.map((doc) {
        final data = doc.data();
        return _buildMarker(
          LatLng(data['latitude'], data['longitude']),
          Icons.shield,
          Colors.green,
        );
      }).toList();

      setState(() {});
    });
  }

  void _loadReliefCamps() {
    FirebaseFirestore.instance
        .collection('relief_camps')
        .snapshots()
        .listen((snapshot) {
      reliefMarkers = snapshot.docs.map((doc) {
        final data = doc.data();
        return _buildMarker(
          LatLng(data['latitude'], data['longitude']),
          Icons.home,
          Colors.orange,
        );
      }).toList();

      setState(() {});
    });
  }

  void _loadDispatchLocations() {
    FirebaseFirestore.instance
        .collection('emergency_requests')
        .where('status', whereIn: ['pending', 'assigned'])
        .snapshots()
        .listen((snapshot) {
          dispatchMarkers = snapshot.docs.map((doc) {
            final data = doc.data();
            return _buildMarker(
              LatLng(data['latitude'], data['longitude']),
              Icons.local_shipping,
              Colors.purple,
            );
          }).toList();

          setState(() {});
        });
  }

  // ================= CUSTOM MARKER =================

  Marker _buildMarker(LatLng point, IconData icon, Color color) {
    return Marker(
      point: point,
      width: 45,
      height: 45,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "NGO Live Command Map",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: defaultCenter,
          initialZoom: 13,
        ),
        children: [
          // 🌍 LIGHT MAP TILE (NOT BLACK)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.resqnetpro',
          ),

          MarkerLayer(
            markers: [
              // NGO Location
              if (ngoLocation != null)
                Marker(
                  point: ngoLocation!,
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryRed, width: 3),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFD32F2F),
                      size: 28,
                    ),
                  ),
                ),

              ...disasterMarkers,
              ...safeZoneMarkers,
              ...reliefMarkers,
              ...dispatchMarkers,
            ],
          ),
        ],
      ),
    );
  }
}
