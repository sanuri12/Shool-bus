import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationEmergencyScreen extends StatefulWidget {
  const NotificationEmergencyScreen({super.key});

  @override
  State<NotificationEmergencyScreen> createState() => _NotificationEmergencyScreenState();
}

class _NotificationEmergencyScreenState extends State<NotificationEmergencyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _parents = [];
  final List<Map<String, dynamic>> _notifications = [];
  final List<Map<String, String>> _notificationTemplates = [
    {'title': 'Delay Notice', 'message': 'The bus will be delayed by approximately 10-15 minutes today due to traffic.'},
    {'title': 'Early Arrival', 'message': 'The bus will arrive 5-10 minutes earlier than scheduled today.'},
    {'title': 'Route Change', 'message': 'The bus route has been temporarily modified due to road conditions.'},
    {'title': 'Driver Change', 'message': 'There is a substitute driver for today\'s route.'},
    {'title': 'Weather Alert', 'message': 'Due to weather conditions, please ensure your child is prepared.'},
    {'title': 'Pickup Reminder', 'message': 'Reminder: Be at the bus stop 5 minutes before pickup time.'},
  ];

  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isLoading = true;
  int? _selectedTemplateIndex;
  String _userRole = 'Parent';
  String _userId = '';
  String _userEmail = '';
  bool _canSendMessages = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchParents();
    // We'll handle notifications fetching after user details are loaded
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please sign in.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _userId = user.uid;
    _userEmail = user.email ?? '';
    
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      
      if (mounted) {
        setState(() {
          _userRole = userDoc['role'] ?? 'Parent';
          _canSendMessages = _userEmail == 'driver@gmail.com';
          _tabController = TabController(length: _canSendMessages ? 3 : 2, vsync: this);
          _isLoading = false;
        });
        
        // Fetch notifications after user details are loaded
        _fetchNotifications();
      }
    } catch (e) {
      print("❌ Error fetching user details: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchParents() async {
    try {
      QuerySnapshot parentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Parent')
          .get();
      
      if (mounted) {
        setState(() {
          _parents = parentSnapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['fullName'] ?? data['name'] ?? 'Unknown',
              'child': data['childName'] ?? 'Student',
              'phone': data['phone'] ?? 'No phone',
              'email': data['email'] ?? '',
              'selected': false
            };
          }).toList();
        });
      }
      
      print("✅ Fetched ${_parents.length} parents from database");
      
      if (_parents.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No parents found in the database')),
        );
      }
    } catch (e) {
      print("❌ Error fetching parents: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching parents: $e')),
        );
      }
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      QuerySnapshot notificationsSnapshot;
      
      // Different queries based on user role
      if (_userRole == 'Parent') {
        print("🔍 Fetching notifications for parent: $_userId");
        // For parents - fetch notifications where they are the recipient
        notificationsSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: _userId)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        print("🔍 Fetching notifications for driver");
        // For drivers - fetch all notifications they sent and ones sent to them
        notificationsSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('sender', isEqualTo: 'Driver')
            .orderBy('timestamp', descending: true)
            .get();
      }

      if (mounted) {
        setState(() {
          _notifications.clear();
          if (notificationsSnapshot.docs.isNotEmpty) {
            print("📬 Found ${notificationsSnapshot.docs.length} notifications");
            _notifications.addAll(notificationsSnapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'message': data['message'] ?? 'No message content',
                'time': data['time'] ?? '',
                'date': data['date'] ?? 'Unknown',
                'sender': data['sender'] ?? 'Unknown',
                'senderType': data['senderType'] ?? 'Unknown',
                'senderName': data['senderName'] ?? 'Unknown',
                'recipient': data['recipient'] ?? '',
                'recipientId': data['recipientId'] ?? '',
                'isRead': data['isRead'] ?? true,
                'parentId': data['parentId'] ?? '',
              };
            }).toList());
          } else {
            print("📭 No notifications found");
          }
        });
      }
    } catch (e) {
      print("❌ Error fetching notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.yellow)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text('Alerts & Emergency', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          tabs: [
            const Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
            const Tab(text: 'Emergency', icon: Icon(Icons.emergency)),
            if (_canSendMessages)
              const Tab(text: 'Send Message', icon: Icon(Icons.send)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildEmergencyTab(),
          if (_canSendMessages) _buildSendMessageTab(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    // Add refresh functionality to pull down and refresh
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: Colors.yellow,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _fetchNotifications,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(foregroundColor: Colors.yellow),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_notifications.where((n) => n['sender'] == 'Parent' && n['isRead'] == false).length}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Unread messages",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isFromParent = notification['sender'] == 'Parent';
                      return _buildNotificationTile(
                        message: notification['message'],
                        time: notification['time'],
                        date: notification['date'],
                        sender: isFromParent ? notification['senderName'] : notification['sender'],
                        senderType: notification['senderType'],
                        recipient: notification['recipient'],
                        isRead: notification['isRead'] ?? true,
                        onMarkAsRead: isFromParent && notification['isRead'] == false
                            ? () => _markAsRead(index)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['isRead'] = true;
    });
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(_notifications[index]['id'])
        .update({'isRead': true});
  }

  Widget _buildEmergencyTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Emergency Contact Options",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildEmergencyButton(
            icon: Icons.call,
            label: "Call School Office (011 2735412)",
            color: Colors.blue,
            onPressed: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: '0112735412');
              try {
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not launch phone dialer")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          _buildEmergencyButton(
            icon: Icons.local_hospital,
            label: "Medical Emergency (1990)",
            color: Colors.red,
            onPressed: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: '1990');
              try {
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not launch phone dialer")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          ),
          if (_userRole == 'Bus Driver' && _canSendMessages) ...[
            const SizedBox(height: 20),
            _buildEmergencyButton(
              icon: Icons.message,
              label: "Send Alert to Parents",
              color: Colors.orange,
              onPressed: () {
                _messageController.text = "Emergency Alert: Please check the app for updates.";
                for (var parent in _parents) {
                  parent['selected'] = true;
                }
                _tabController.animateTo(2);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSendMessageTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Notification Template',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _notificationTemplates.length,
                      itemBuilder: (context, index) {
                        final template = _notificationTemplates[index];
                        final isSelected = _selectedTemplateIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTemplateIndex = index;
                              _messageController.text = template['message']!;
                            });
                          },
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.yellow : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template['title']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black : Colors.grey.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  template['message']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.black : Colors.grey.shade700,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compose Message',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Type your message here or select a template above...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _messageController.clear();
                            _selectedTemplateIndex = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Recipients',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (var parent in _parents) {
                                  parent['selected'] = true;
                                }
                              });
                            },
                            child: const Text('Select All'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (var parent in _parents) {
                                  parent['selected'] = false;
                                }
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _parents.length,
                      itemBuilder: (context, index) {
                        final parent = _parents[index];
                        return CheckboxListTile(
                          title: Text(parent['name']),
                          subtitle: Text('Child: ${parent['child']}'),
                          secondary: CircleAvatar(
                            backgroundColor: Colors.yellow,
                            child: Text(parent['name'][0]),
                          ),
                          value: parent['selected'],
                          onChanged: (bool? value) {
                            setState(() {
                              parent['selected'] = value!;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSending ? null : () => _sendMessage(context),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    final selectedParents = _parents.where((p) => p['selected']).toList();
    if (selectedParents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    int successCount = 0;
    List<String> failedRecipients = [];

    try {
      final now = DateTime.now();
      final hours = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final time = '$hours:${now.minute.toString().padLeft(2, '0')} $period';
      final date = 'Today';
      
      // Format date in a way that sorts properly
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      for (var parent in selectedParents) {
        print("📨 Sending message to parent: ${parent['name']} (ID: ${parent['id']})");
        
        try {
          // Make sure we're setting the recipientId correctly to the parent's user ID
          String recipientId = parent['id'];
          
          // Check if the ID is valid
          if (recipientId.isEmpty) {
            print("⚠️ Invalid recipient ID for ${parent['name']}");
            failedRecipients.add(parent['name']);
            continue;
          }
          
          await FirebaseFirestore.instance.collection('notifications').add({
            'message': _messageController.text,
            'time': time,
            'date': date,
            'formattedDate': formattedDate, // Add well-formatted date for sorting
            'sender': 'Driver',
            'senderType': 'Driver',
            'senderName': 'Bus Driver',
            'recipient': parent['name'],
            'recipientId': recipientId, // Explicitly set to parent's ID
            'parentId': recipientId,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          successCount++;
        } catch (e) {
          print("❌ Error sending to ${parent['name']}: $e");
          failedRecipients.add(parent['name']);
        }
      }

      setState(() {
        _isSending = false;
      });

      // Show appropriate success/failure message
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to $successCount parents successfully'),
            backgroundColor: failedRecipients.isEmpty ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Reset form and load updated notifications
        _messageController.clear();
        for (var parent in _parents) {
          parent['selected'] = false;
        }
        _selectedTemplateIndex = null;
        _tabController.animateTo(0);
        _fetchNotifications();
      } 
      
      // If any failures occurred, show details
      if (failedRecipients.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send to: ${failedRecipients.join(", ")}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } catch (e) {
      // ...existing error handling...
    }
  }

  Widget _buildNotificationTile({
    required String message,
    String? time,
    String? date,
    String? sender,
    String? senderType,
    String? recipient,
    bool isRead = true,
    VoidCallback? onMarkAsRead,
  }) {
    final isFromParent = senderType == 'Parent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: isFromParent && !isRead ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    sender ?? 'System',
                    style: TextStyle(
                      color: isFromParent ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isFromParent && !isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '$date ${time != null ? '• $time' : ''}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          if (recipient != null) ...[
            const SizedBox(height: 4),
            Text(
              'To: $recipient',
              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          if (isFromParent && _userRole == 'Bus Driver') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRead && onMarkAsRead != null)
                  TextButton.icon(
                    onPressed: onMarkAsRead,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark as Read'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}