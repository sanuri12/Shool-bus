import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_bus_app_fresh/absent_dates.dart';
import 'package:school_bus_app_fresh/create_profile.dart';
import 'package:school_bus_app_fresh/notification_emergency.dart';
import 'package:school_bus_app_fresh/driver_payment_info.dart';
import 'package:school_bus_app_fresh/bus_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> features = const [
    {'title': 'Track Buses', 'icon': Icons.location_on},
    {'title': 'Notifications & Emergency', 'icon': Icons.notifications_none},
    {'title': 'Driver & Payment', 'icon': Icons.account_balance_wallet},
    {'title': 'Absent dates', 'icon': Icons.close},
  ];

  final String userRole;

  const HomeScreen({super.key, this.userRole = 'Parent'});

  @override
  Widget build(BuildContext context) {
    final displayedFeatures = features;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.asset(
                'images/school_bus.png',
                width: double.infinity,
                fit: BoxFit.cover,
                height: 200,
              ),
              Positioned(
                top: 20,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.account_circle,
                    size: 40,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: displayedFeatures.length,
              itemBuilder: (context, index) {
                final feature = displayedFeatures[index];
                return ElevatedButton(
                  onPressed: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please sign in to continue')),
                      );
                      Navigator.pushReplacementNamed(context, '/login');
                      return;
                    }

                    if (feature['title'] == 'Absent dates') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendancePage(),
                        ),
                      );
                    } else if (feature['title'] == 'Track Buses') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusSelectionScreen(),
                        ),
                      );
                    } else if (feature['title'] == 'Driver & Payment') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverPaymentInfoScreen(),
                        ),
                      );
                    } else if (feature['title'] == 'Notifications & Emergency') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationEmergencyScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${feature['title']} is not implemented yet'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(feature['icon'], size: 30),
                      const SizedBox(height: 8),
                      Text(
                        feature['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}