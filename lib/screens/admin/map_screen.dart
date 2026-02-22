import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _disasters = [
    {
      'title': 'Flood Emergency',
      'location': 'Sector 4, Near River',
      'lat': 18.5204,
      'lng': 73.8567,
      'color': Colors.blue,
      'icon': Icons.water,
    },
    {
      'title': 'Fire Emergency',
      'location': 'Market Area',
      'lat': 18.5304,
      'lng': 73.8467,
      'color': Colors.red,
      'icon': Icons.local_fire_department,
    },
    {
      'title': 'Medical Emergency',
      'location': 'Hospital Road',
      'lat': 18.5104,
      'lng': 73.8667,
      'color': Colors.green,
      'icon': Icons.medical_services,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _currentLocation = const LatLng(18.5204, 73.8567);
      } else {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentLocation =
            LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      _currentLocation = const LatLng(18.5204, 73.8567);
    }

    setState(() => _isLoading = false);

    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Disaster Map",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD32F2F),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _currentLocation ?? const LatLng(18.5204, 73.8567),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.resqnet.app",
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ..._disasters.map(
                          (d) => Marker(
                            point: LatLng(d['lat'], d['lng']),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor:
                                        const Color(0xFF1E1E1E),
                                    title: Text(
                                      d['title'],
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                    content: Text(
                                      d['location'],
                                      style: const TextStyle(
                                          color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                              child: Icon(
                                d['icon'],
                                color: d['color'],
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFFD32F2F),
                    onPressed: _getLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }
}