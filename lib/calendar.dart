import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Map<String, dynamic>> _upcomingEvents = [];
  DateTime _selectedDate = DateTime.now();
  final _auth = FirebaseAuth.instance;
  final _databaseReference = FirebaseDatabase.instance.reference();
  final _eventController = TextEditingController();
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _retrieveEventsFromFirebase();
  }

  Future<void> _retrieveEventsFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DataSnapshot snapshot = (await _databaseReference.child('events').once()).snapshot;
        Map<dynamic, dynamic>? data = snapshot.value as Map?;
        if (data != null) {
          data.forEach((key, value) {
            if (value['userId'] == user.uid) { // Only consider events created by the current user
              DateTime date = DateTime.parse(value['date']);
              String description = value['description'];
              if (_events[date] == null) _events[date] = [];
              _events[date]!.add(description);
            }
          });
          _upcomingEvents = data.entries
              .where((e) => e.value['userId'] == user.uid) // Only consider events created by the current user
              .map((e) => {'date': DateTime.parse(e.value['date']), 'description': e.value['description']})
              .toList();
          _upcomingEvents.sort((a, b) => a['date'].compareTo(b['date']));
        }
        setState(() {});  // Refresh the UI after fetching events
      }
    } catch (e) {
      print(e);
    }
  }



  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      _selectedDate = day;
    });
  }

  Future<void> _saveEventToFirebase(DateTime date, String description) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String dateString = date.toIso8601String().split('T')[0];
        if (_events[date] == null) _events[date] = [];
        _events[date]!.add(description);
        await _databaseReference.child('events/${user.uid}').push().set({
          'date': dateString,
          'description': description,
          'userId': user.uid
        });
        setState(() {}); // Refresh the UI after adding the event
      }
    } catch (e) {
      print(e);
    }
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Event Description'),
          content: TextField(
            controller: _eventController,
            decoration: InputDecoration(hintText: 'Event Description'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _saveEventToFirebase(_selectedDate, _eventController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wiener Dog",
          textAlign: TextAlign.center,
        ),
      ),
      body: Column(
        children: [
          content(),
          ElevatedButton(
            onPressed: _showAddEventDialog,
            child: Text('Create a new Event'),
          ),
          if (_upcomingEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Nothing to show',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Upcoming Events:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ..._upcomingEvents.map((event) {
                  return ListTile(
                    title: Text(event['description']),
                    subtitle: Text((event['date'] as DateTime).toString().split(" ")[0]),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget content() {
    return Column(
      children: [
        TableCalendar(
          locale: 'en_US',
          availableGestures: AvailableGestures.all,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          onDaySelected: _onDaySelected,
          focusedDay: _selectedDate,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 1, 1),
          eventLoader: (day) {
            return _events[day] ?? [];
          },
        ),
        Text("Selected day: ${_selectedDate.toString().split(" ")[0]}"),
      ],
    );
  }
}
