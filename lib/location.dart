import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String? _locationLink;
  bool _isLoading = true;
  bool _isSharing = false;
  final Set<Marker> _markers = {};
  String _driverId = 'unknown_driver';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _verifyAuthentication();
    _checkLocationPermission();
    Future.delayed(Duration(milliseconds: 500), _fetchBusStops);
  }

  void _verifyAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _driverId = user.uid;
      });
      print("✅ Driver UID: $_driverId");
      print("✅ Driver Email: ${user.email}");
    } else {
      print("❌ ERROR: No authenticated user found!");
      setState(() {
        _errorMessage = 'Authentication error: Not signed in';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error: Not signed in'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable GPS.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable in settings.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _startLocationTracking();
    } catch (e) {
      print("❌ ERROR getting location: $e");
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _startLocationTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }

        _updateLocationInFirestore(position);
      }
    }, onError: (e) {
      print("❌ ERROR tracking location: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error tracking location: $e';
        });
      }
    });
  }

  Future<void> _refreshLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      _updateLocationInFirestore(position);
    } catch (e) {
      print("❌ ERROR refreshing location: $e");
      setState(() {
        _errorMessage = 'Error refreshing location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBusStops() async {
    try {
      QuerySnapshot stopsSnapshot = await FirebaseFirestore.instance.collection('bus_stops').get();

      if (stopsSnapshot.docs.isEmpty) {
        print("ℹ️ No bus stops in Firestore, using default stops");
        final List<Map<String, dynamic>> defaultStops = [
          {'name': 'Stop 1', 'latitude': 37.7749, 'longitude': -122.4194},
          {'name': 'Stop 2', 'latitude': 37.7849, 'longitude': -122.4294},
          {'name': 'Stop 3', 'latitude': 37.7949, 'longitude': -122.4394},
        ];

        for (var stop in defaultStops) {
          _markers.add(
            Marker(
              markerId: MarkerId(stop['name']),
              position: LatLng(stop['latitude'], stop['longitude']),
              infoWindow: InfoWindow(title: stop['name']),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }
      } else {
        for (var doc in stopsSnapshot.docs) {
          var stop = doc.data() as Map<String, dynamic>;
          // Check for null or invalid latitude/longitude
          if (stop['latitude'] == null || stop['longitude'] == null) {
            print("⚠️ Skipping bus stop ${doc.id}: Missing latitude or longitude");
            continue;
          }
          double latitude = (stop['latitude'] as num?)?.toDouble() ?? 0.0;
          double longitude = (stop['longitude'] as num?)?.toDouble() ?? 0.0;
          if (latitude == 0.0 || longitude == 0.0) {
            print("⚠️ Skipping bus stop ${doc.id}: Invalid coordinates ($latitude, $longitude)");
            continue;
          }
          _markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: stop['name'] ?? 'Unknown Stop'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      print("❌ ERROR fetching bus stops: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading bus stops: $e';
        });
      }
    }
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    try {
      if (_driverId == 'unknown_driver') {
        print("❌ ERROR: Cannot update location - Not properly authenticated!");
        return;
      }

      print("📍 Updating location for driver: $_driverId");
      print("📍 Location: ${position.latitude}, ${position.longitude}");

      await FirebaseFirestore.instance.collection('drivers').doc(_driverId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Location updated successfully");
    } catch (e) {
      print("❌ ERROR updating Firestore: $e");
      setState(() {
        _errorMessage = 'Error updating location in database: $e';
      });
    }
  }

  Future<void> _shareLocation() async {
    setState(() {
      _isSharing = true;
      _errorMessage = '';
    });

    try {
      if (_driverId == 'unknown_driver') {
        throw Exception('Not properly authenticated');
      }

      print("🔗 Sharing location for driver: $_driverId");

      String link = "https://schoolbusapp.com/track/$_driverId";

      // Fetch nearby bus stops
      List<String> nearbyStops = [];
      QuerySnapshot stopsSnapshot = await FirebaseFirestore.instance.collection('bus_stops').get();
      for (var doc in stopsSnapshot.docs) {
        var stop = doc.data() as Map<String, dynamic>;
        // Check for null or invalid latitude/longitude
        if (stop['latitude'] == null || stop['longitude'] == null) {
          print("⚠️ Skipping bus stop ${doc.id}: Missing latitude or longitude");
          continue;
        }
        double stopLat = (stop['latitude'] as num?)?.toDouble() ?? 0.0;
        double stopLng = (stop['longitude'] as num?)?.toDouble() ?? 0.0;
        if (stopLat == 0.0 || stopLng == 0.0) {
          print("⚠️ Skipping bus stop ${doc.id}: Invalid coordinates ($stopLat, $stopLng)");
          continue;
        }
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          stopLat,
          stopLng,
        );
        if (distance < 1000) {
          nearbyStops.add(stop['name'] ?? 'Unknown Stop');
        }
      }

      String message = "Bus location shared: $link\nNearby Stops: ${nearbyStops.isNotEmpty ? nearbyStops.join(', ') : 'None'}";

      // Store the driver's information for in-app tracking
      Map<String, dynamic> driverInfo = {
        'driverId': _driverId,
        'link': link,
        'isActive': true,
        'busName': 'School Bus',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('shared_locations').doc(_driverId).set(driverInfo);

      // Notify all parents
      QuerySnapshot parentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Parent')
          .get();
      final now = DateTime.now();
      final hours = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final time = '$hours:${now.minute.toString().padLeft(2, '0')} $period';
      final date = 'Today';

      for (var parent in parentsSnapshot.docs) {
        var parentData = parent.data() as Map<String, dynamic>;
        await FirebaseFirestore.instance.collection('notifications').add({
          'message': message,
          'time': time,
          'date': date,
          'sender': 'Driver',
          'senderType': 'Driver',
          'senderName': 'Bus Driver',
          'recipient': parentData['fullName'] ?? 'Parent',
          'recipientId': parent.id,
          'parentId': parent.id,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _locationLink = link;
      });

      print("✅ Location shared successfully");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Location shared with ${parentsSnapshot.docs.length} parents'),
                Text('Parents can now track this bus in the app',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        );
      }

      try {
        await launchUrl(Uri.parse(link));
      } catch (e) {
        print('❌ Could not launch URL: $e');
      }
    } catch (e) {
      print("❌ ERROR sharing location: $e");
      setState(() {
        _errorMessage = 'Error sharing location: $e';
      });
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  Future<void> _stopSharing() async {
    try {
      await FirebaseFirestore.instance.collection('shared_locations').doc(_driverId).update({
        'isActive': false,
      });

      setState(() {
        _locationLink = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location sharing stopped')),
      );
    } catch (e) {
      print("❌ ERROR stopping location sharing: $e");
      setState(() {
        _errorMessage = 'Error stopping location sharing: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Driver Location', style: TextStyle(color: Colors.black)),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
          ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.yellow),
                  SizedBox(height: 16),
                  Text("Loading location...", style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
          if (!_isLoading && _currentPosition == null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      "Could not get your location",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage.isNotEmpty ? _errorMessage : "Please check your GPS settings and permissions",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshLocation,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          if (!_isLoading && _currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: {
                ..._markers,
                Marker(
                  markerId: const MarkerId('driver'),
                  position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  infoWindow: const InfoWindow(title: 'Current Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          if (!_isLoading && _currentPosition != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Share Your Location with Parents",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    if (_locationLink != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationLink!,
                                style: const TextStyle(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _refreshLocation,
                          icon: const Icon(Icons.refresh),
                          label: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Refresh"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                        _locationLink == null
                            ? ElevatedButton.icon(
                                onPressed: _isSharing ? null : _shareLocation,
                                icon: const Icon(Icons.share_location),
                                label: _isSharing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text("Share"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                              )
                            : ElevatedButton.icon(
                                onPressed: _stopSharing,
                                icon: const Icon(Icons.location_off),
                                label: const Text("Stop Sharing"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              child: const Icon(Icons.bug_report, color: Colors.black),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("UID: $_driverId"),
                        if (_currentPosition != null)
                          Text("Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}"),
                        Text("Markers: ${_markers.length}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}