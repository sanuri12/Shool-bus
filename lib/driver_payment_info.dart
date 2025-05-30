import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverPaymentInfoScreen extends StatefulWidget {
  const DriverPaymentInfoScreen({super.key});

  @override
  State<DriverPaymentInfoScreen> createState() => _DriverPaymentInfoScreenState();
}

class _DriverPaymentInfoScreenState extends State<DriverPaymentInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingDrivers = true;
  bool _isProcessingPayment = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _drivers = [];
  final TextEditingController _cardholderNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final double monthlyFee = 120.00;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDrivers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _fetchDrivers() async {
    try {
      setState(() {
        _isLoadingDrivers = true;
        _errorMessage = '';
      });

      QuerySnapshot driversSnapshot = await FirebaseFirestore.instance.collection('drivers').get();

      // Log the raw data for debugging
      for (var doc in driversSnapshot.docs) {
        print("Driver Document ID: ${doc.id}, Data: ${doc.data()}");
      }

      // Map the data to the _drivers list
      List<Map<String, dynamic>> fetchedDrivers = driversSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        // Handle incorrect field names with colons
        var name = data['name:']?.toString() ?? data['name']?.toString() ?? 'Unknown Driver';
        var phone = data['phone:']?.toString() ?? data['phone']?.toString() ?? 'N/A';
        var bus = data['bus:']?.toString() ?? data['bus']?.toString() ?? 'Unknown Bus';
        var ratingValue = data['rating:'] ?? data['rating'];
        double rating = 0.0;
        // Handle rating as either a number or a string
        if (ratingValue is num) {
          rating = ratingValue.toDouble();
        } else if (ratingValue is String) {
          rating = double.tryParse(ratingValue) ?? 0.0;
        }
        return {
          'name': name,
          'phone': phone,
          'bus': bus,
          'rating': rating,
        };
      }).toList();

      setState(() {
        _drivers = fetchedDrivers;
        _isLoadingDrivers = false;
      });

      // Log the mapped data for confirmation
      print("Mapped Drivers: $_drivers");
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading drivers: $e';
        _isLoadingDrivers = false;
      });
      print("Error fetching drivers: $e");
    }
  }

  Future<void> _processPayment() async {
    if (_cardholderNameController.text.trim().isEmpty ||
        _cardNumberController.text.trim().isEmpty ||
        _expiryDateController.text.trim().isEmpty ||
        _cvvController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all payment details')),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated. Please sign in.');
      }

      await FirebaseFirestore.instance.collection('payments').doc(user.uid).set({
        'userId': user.uid,
        'cardholderName': _cardholderNameController.text.trim(),
        'cardNumber': '**** **** **** ${_cardNumberController.text.trim().substring(_cardNumberController.text.length - 4)}',
        'expiryDate': _expiryDateController.text.trim(),
        'cvv': '***',
        'amount': monthlyFee,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment processed successfully'), backgroundColor: Colors.green),
      );

      _cardholderNameController.clear();
      _cardNumberController.clear();
      _expiryDateController.clear();
      _cvvController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing payment: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text('Driver & Payment', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: 'Bus Drivers', icon: Icon(Icons.person_outline)),
            Tab(text: 'Payment', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDriversTab(),
          _buildPaymentTab(),
        ],
      ),
    );
  }

  Widget _buildDriversTab() {
    if (_isLoadingDrivers) {
      return const Center(child: CircularProgressIndicator(color: Colors.yellow));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDrivers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_drivers.isEmpty) {
      return const Center(child: Text('No drivers available', style: TextStyle(color: Colors.white)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.yellow,
                        radius: 25,
                        child: Icon(Icons.person, color: Colors.black, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              driver['bus'],
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${driver['rating']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.call,
                        label: 'Call',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${driver['name']}...')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.message,
                        label: 'Message',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Messaging ${driver['name']}...')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.info_outline,
                        label: 'Details',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Viewing ${driver['name']} details...')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: "Cardholder Name",
                  controller: _cardholderNameController,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: "Card Number",
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: "Expiry Date (MM/YY)",
                        controller: _expiryDateController,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        label: "CVV",
                        controller: _cvvController,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Fee:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '\$${monthlyFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${monthlyFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isProcessingPayment ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                  ),
                  child: _isProcessingPayment
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}