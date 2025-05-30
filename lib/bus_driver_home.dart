import 'package:flutter/material.dart';
import 'package:school_bus_app_fresh/location.dart';
import 'package:school_bus_app_fresh/notification_emergency.dart'; // Combined page
import 'package:school_bus_app_fresh/student_parent_info.dart'; // Import the new combined screen

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  // Remove Activities from the menu items
  final List<Map<String, dynamic>> menuItems = const [
    {'icon': Icons.location_on, 'title': 'Location'},
    {'icon': Icons.notification_important, 'title': 'Alerts & Emergency'},
    {'icon': Icons.people, 'title': 'Students & Parents'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Image.asset('images/school_bus.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hi Driver!',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    String title = menuItems[index]['title'];
                    IconData icon = menuItems[index]['icon'];

                    return MenuButton(
                      icon: icon,
                      title: title,
                      onTap: () {
                        if (title == 'Location') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationScreen(),
                            ),
                          );
                        } else if (title == 'Alerts & Emergency') {  // Updated navigation
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationEmergencyScreen(),
                            ),
                          );
                        } else if (title == 'Students & Parents') { // Updated navigation
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentParentInfoScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$title feature not implemented'),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            
            // Add logout button below the grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Show confirmation dialog
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
                            // Close dialog and navigate to login screen
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Logout', 
                            style: TextStyle(color: Colors.red)),
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
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const MenuButton({super.key, required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: const EdgeInsets.all(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}