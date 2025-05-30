import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentParentInfoScreen extends StatefulWidget {
  const StudentParentInfoScreen({super.key});

  @override
  State<StudentParentInfoScreen> createState() => _StudentParentInfoScreenState();
}

class _StudentParentInfoScreenState extends State<StudentParentInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _parents = [];
  String _errorMessage = '';
  int _totalStudents = 0;
  int _presentToday = 0;
  int _absentToday = 0;
  double _attendancePercentage = 0.0;
  final DateFormat _dateFormat = DateFormat('EEEE, MMM d');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<Map<String, dynamic>> _loadDataStream() {
    return Stream<Map<String, dynamic>>.fromFuture(_loadData());
  }

  Future<Map<String, dynamic>> _loadData() async {
    try {
      // Load all students
      final QuerySnapshot studentsSnapshot = await _firestore.collection('students').get();
      final students = studentsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown',
                'parentId': (doc.data() as Map<String, dynamic>)['parentId'] ?? '',
              })
          .toList();

      // Load all parents
      final QuerySnapshot parentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Parent')
          .get();

      final parents = parentsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['fullName'] ?? data['name'] ?? 'Unknown',
          'phone': data['phone']?.toString() ?? 'No phone',
          'email': data['email']?.toString() ?? 'No email',
          'address': data['address']?.toString() ?? 'No address',
          'notes': data['notes']?.toString() ?? '',
          'lastLogin': data['lastLogin'] != null
              ? (data['lastLogin'] is Timestamp
                  ? (data['lastLogin'] as Timestamp).toDate()
                  : DateTime.tryParse(data['lastLogin'].toString()))
              : null,
        };
      }).toList();

      // Load today's absences
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final QuerySnapshot absencesSnapshot = await _firestore.collection('absences').get();

      final absences = absencesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime date;
        if (data['date'] is Timestamp) {
          date = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          date = DateTime.parse(data['date'] as String);
        } else {
          throw Exception('Invalid date format for absence ${doc.id}');
        }
        return {
          'id': doc.id,
          'date': date,
          'studentId': data['studentId'],
          'studentName': data['studentName'],
          'parentId': data['parentId'],
          'reason': data['reason']?.toString() ?? '',
          'isToday': date.year == today.year && date.month == today.month && date.day == today.day,
        };
      }).toList();

      // Calculate statistics
      final totalStudents = students.length;
      final absentToday = absences.where((absence) => absence['isToday']).length;
      final presentToday = totalStudents - absentToday;
      final attendancePercentage = totalStudents > 0 ? (presentToday / totalStudents) * 100 : 0;

      return {
        'students': students,
        'parents': parents,
        'absences': absences,
        'totalStudents': totalStudents,
        'presentToday': presentToday,
        'absentToday': absentToday,
        'attendancePercentage': attendancePercentage,
      };
    } catch (e) {
      throw Exception('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text('Students & Parents', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: 'Student Count', icon: Icon(Icons.people)),
            Tab(text: 'Parent Details', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _loadDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.yellow));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          _students = data['students'];
          _parents = data['parents'];
          final absences = data['absences'];
          _totalStudents = data['totalStudents'];
          _presentToday = data['presentToday'];
          _absentToday = data['absentToday'];
          _attendancePercentage = data['attendancePercentage'];

          return Stack(
            children: [
              SizedBox.expand(
                child: Image.asset('images/background.png', fit: BoxFit.cover),
              ),
              Container(color: Colors.black.withOpacity(0.3)),
              TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentCountTab(absences),
                  _buildParentDetailsTab(absences),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentCountTab(List<Map<String, dynamic>> absences) {
    final DateTime now = DateTime.now();
    final todayAbsences = absences.where((absence) => absence['isToday']).toList();
    final futureAbsences = absences
        .where((absence) => absence['date'].isAfter(DateTime(now.year, now.month, now.day)))
        .toList();

    futureAbsences.sort((a, b) => a['date'].compareTo(b['date']));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCountCard('Total Students', '$_totalStudents', Colors.blue),
            _buildCountCard('Present Today', '$_presentToday', Colors.green),
            _buildCountCard('Absent Today', '$_absentToday', Colors.red),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Percentage',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _totalStudents > 0 ? _presentToday / _totalStudents : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_attendancePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            if (todayAbsences.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Absent Today',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...todayAbsences.map((absence) {
                        return ListTile(
                          title: Text(absence['studentName']),
                          subtitle: Text(absence['reason'].isEmpty
                              ? 'No reason provided'
                              : 'Reason: ${absence['reason']}'),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            if (futureAbsences.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Planned Absences',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...futureAbsences.map((absence) {
                        return ListTile(
                          title: Text(absence['studentName']),
                          subtitle: Text(
                              '${_dateFormat.format(absence['date'])}${absence['reason'].isNotEmpty ? '\nReason: ${absence['reason']}' : ''}'),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.event_busy, color: Colors.white),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParentDetailsTab(List<Map<String, dynamic>> absences) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _parents.length,
        itemBuilder: (context, index) {
          final parent = _parents[index];
          final children = _students.where((child) => child['parentId'] == parent['id']).toList();
          final String phoneDisplay = parent['phone'] != 'No phone' ? parent['phone'] : 'Not provided';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.yellow,
                    radius: 25,
                    child: Text(
                      parent['name'][0],
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    parent['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              phoneDisplay,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: parent['phone'] == 'No phone' ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              parent['email'],
                              style: TextStyle(
                                color: parent['email'] == 'No email' ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Children: ${children.length}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (parent['phone'] != 'No phone')
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green, size: 28),
                          tooltip: 'Call ${parent['name']}',
                          onPressed: () async {
                            final phoneNumber = parent['phone'];
                            final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                            try {
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(phoneUri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Could not launch phone dialer")),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            }
                          },
                        ),
                      if (parent['phone'] != 'No phone')
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue, size: 24),
                          tooltip: 'Message ${parent['name']}',
                          onPressed: () async {
                            final phoneNumber = parent['phone'];
                            final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
                            try {
                              if (await canLaunchUrl(smsUri)) {
                                await launchUrl(smsUri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Could not launch messaging app")),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            }
                          },
                        ),
                    ],
                  ),
                ),
                if (children.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text(
                          'Children:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...children.map((child) {
                          final childAbsences = absences.where((absence) => absence['studentId'] == child['id']).toList();
                          final absentToday = childAbsences.any((absence) => absence['isToday'] == true);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: absentToday ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: absentToday ? Colors.red.shade300 : Colors.green.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.child_care,
                                  color: absentToday ? Colors.red : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        absentToday ? 'Absent today' : 'Present today',
                                        style: TextStyle(
                                          color: absentToday ? Colors.red : Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Total absences: ${childAbsences.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountCard(String title, String count, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  count,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}