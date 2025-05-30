import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _absenceDates = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Map<String, dynamic>>> _absenceEvents = {};

  // Format date for display
  final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to manage attendance';
          _isLoading = false;
        });
        return;
      }

      // Fetch children associated with this parent
      final QuerySnapshot childSnapshot = await _firestore
          .collection('students')
          .where('parentId', isEqualTo: user.uid)
          .get();

      final List<Map<String, dynamic>> childrenList = childSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown',
                'status': 'present', // Default status
              })
          .toList();

      // Fetch existing absence records
      final QuerySnapshot absenceSnapshot = await _firestore
          .collection('absences')
          .where('parentId', isEqualTo: user.uid)
          .get();

      final List<Map<String, dynamic>> absenceList = absenceSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            DateTime date;
            // Handle both Timestamp and String formats for the date field
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
              'reason': data['reason'] ?? '',
            };
          })
          .toList();

      // Build absence events for calendar
      Map<DateTime, List<Map<String, dynamic>>> events = {};
      for (var absence in absenceList) {
        final date = absence['date'] as DateTime;
        final eventDate = DateTime(date.year, date.month, date.day);
        if (events[eventDate] == null) {
          events[eventDate] = [];
        }
        events[eventDate]!.add(absence);
      }

      setState(() {
        _children = childrenList;
        _absenceDates = absenceList;
        _absenceEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markAbsence({
    required String studentId,
    required String studentName,
    required DateTime date,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if this absence already exists
      final existingAbsence = _absenceDates.firstWhere(
        (absence) =>
            absence['studentId'] == studentId &&
            absence['date'].year == date.year &&
            absence['date'].month == date.month &&
            absence['date'].day == date.day,
        orElse: () => <String, dynamic>{},
      );

      if (existingAbsence.isNotEmpty) {
        // Update existing absence
        await _firestore.collection('absences').doc(existingAbsence['id']).update({
          'reason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          existingAbsence['reason'] = reason;
        });
      } else {
        // Create new absence
        final docRef = await _firestore.collection('absences').add({
          'date': Timestamp.fromDate(date),
          'studentId': studentId,
          'studentName': studentName,
          'parentId': user.uid,
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final newAbsence = {
          'id': docRef.id,
          'date': date,
          'studentId': studentId,
          'studentName': studentName,
          'reason': reason,
        };

        setState(() {
          _absenceDates.add(newAbsence);
          final eventDate = DateTime(date.year, date.month, date.day);
          if (_absenceEvents[eventDate] == null) {
            _absenceEvents[eventDate] = [];
          }
          _absenceEvents[eventDate]!.add(newAbsence);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absence recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording absence: $e')),
      );
    }
  }

  Future<void> _removeAbsence(String absenceId) async {
    try {
      await _firestore.collection('absences').doc(absenceId).delete();

      setState(() {
        final absence = _absenceDates.firstWhere((a) => a['id'] == absenceId);
        _absenceDates.removeWhere((a) => a['id'] == absenceId);
        final eventDate = DateTime(
          absence['date'].year,
          absence['date'].month,
          absence['date'].day,
        );
        _absenceEvents[eventDate]?.removeWhere((a) => a['id'] == absenceId);
        if (_absenceEvents[eventDate]?.isEmpty ?? false) {
          _absenceEvents.remove(eventDate);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absence removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing absence: $e')),
      );
    }
  }

  void _showAbsenceDialog(String studentId, String studentName) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark $studentName Absent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_dateFormat.format(_selectedDay!)}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for absence (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              _markAbsence(
                studentId: studentId,
                studentName: studentName,
                date: _selectedDay!,
                reason: reasonController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm Absence'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text(
          'Manage Attendance',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : Stack(
                  children: [
                    SizedBox.expand(
                      child: Image.asset('images/background.png', fit: BoxFit.cover),
                    ),
                    Container(color: Colors.black.withOpacity(0.3)),
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCalendarSection(),
                            const SizedBox(height: 24),
                            _buildChildrenSection(),
                            const SizedBox(height: 24),
                            _buildUpcomingAbsencesSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCalendarSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date to Mark Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return _absenceEvents[DateTime(day.year, day.month, day.day)] ?? [];
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.yellow.shade200,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.yellow.shade700,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  color: Colors.yellow.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenSection() {
    if (_children.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No children found in your account'),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Selected Date: ${_dateFormat.format(_selectedDay!)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(_children.length, (index) {
              final child = _children[index];
              final isAbsent = _absenceDates.any((absence) =>
                  absence['studentId'] == child['id'] &&
                  absence['date'].year == _selectedDay!.year &&
                  absence['date'].month == _selectedDay!.month &&
                  absence['date'].day == _selectedDay!.day);

              final absence = isAbsent
                  ? _absenceDates.firstWhere((absence) =>
                      absence['studentId'] == child['id'] &&
                      absence['date'].year == _selectedDay!.year &&
                      absence['date'].month == _selectedDay!.month &&
                      absence['date'].day == _selectedDay!.day)
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAbsent ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAbsent ? Colors.red : Colors.green,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          child['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAbsent ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAbsent ? 'Absent' : 'Present',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isAbsent && absence != null && absence['reason'] != null && absence['reason'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${absence['reason']}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        isAbsent
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Mark as Present'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _removeAbsence(absence!['id']);
                                },
                              )
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Mark as Absent'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  _showAbsenceDialog(child['id'], child['name']);
                                },
                              ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAbsencesSection() {
    final upcomingAbsences = _absenceDates
        .where((absence) => absence['date'].isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .toList();

    upcomingAbsences.sort((a, b) => a['date'].compareTo(b['date']));

    if (upcomingAbsences.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No upcoming absences'),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Absences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(upcomingAbsences.length, (index) {
              final absence = upcomingAbsences[index];
              return ListTile(
                title: Text(absence['studentName']),
                subtitle: Text('Date: ${_dateFormat.format(absence['date'])}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeAbsence(absence['id']),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}