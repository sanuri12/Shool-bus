import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParentTrackingScreen extends StatefulWidget {
  final String driverId;

  const ParentTrackingScreen({super.key, required this.driverId});

  @override
  State<ParentTrackingScreen> createState() => _ParentTrackingScreenState();
}

class _ParentTrackingScreenState extends State<ParentTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _setupBusStopsMarkers();
  }

  // Set up fixed bus stops markers
  void _setupBusStopsMarkers() {
    final List<Map<String, dynamic>> busStops = [
      {'name': 'Stop 1', 'lat': 37.7749, 'lng': -122.4194},
      {'name': 'Stop 2', 'lat': 37.7849, 'lng': -122.4294},
      {'name': 'Stop 3', 'lat': 37.7949, 'lng': -122.4394},
    ];

    for (var stop in busStops) {
      _markers.add(
        Marker(
          markerId: MarkerId(stop['name']),
          position: LatLng(stop['lat'], stop['lng']),
          infoWindow: InfoWindow(title: stop['name']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Bus Location', style: TextStyle(color: Colors.black)),
      ),
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'images/background.png',
            width: double.infinity,
            fit: BoxFit.cover,
            height: double.infinity,
          ),
          
          // Live tracking from Firestore
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('drivers')
                .doc(widget.driverId)
                .snapshots(),
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.yellow),
                );
              }
              
              // Handle error state
              if (snapshot.hasError) {
                _error = 'Failed to load bus location';
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
              
              // Handle no data
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'No bus location data available',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
              
              // Process data
              Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
              
              if (data == null || !data.containsKey('latitude') || !data.containsKey('longitude')) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Bus location data is incomplete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
              
              // Get bus location
              double lat = data['latitude'];
              double lng = data['longitude'];
              
              // Update bus marker
              _markers = {..._markers}; // Create a new set to trigger rebuild
              _markers.add(
                Marker(
                  markerId: const MarkerId('bus'),
                  position: LatLng(lat, lng),
                  infoWindow: const InfoWindow(title: 'School Bus'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              );
              
              // Mark as loaded
              if (_isLoading) {
                _isLoading = false;
              }
              
              // Display the map
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 15,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              );
            },
          ),
          
          // Error message overlay if needed
          if (_error.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
