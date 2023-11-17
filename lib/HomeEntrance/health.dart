
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../chat_screen.dart';
import '../healthchatscreen.dart';
import 'login.dart';

class HealthSection extends StatefulWidget {
  @override
  _HealthSectionState createState() => _HealthSectionState();
}

class _HealthSectionState extends State<HealthSection> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('health_data');

  String? weight;
  String? height;
  String? gender;

  @override
  void initState() {
    super.initState();
    _checkHealthData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkHealthData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            // Navigate to ChatScreen
            Navigator.pushReplacementNamed(context, '/chatScreen');
            return SizedBox.shrink();  // Return an empty widget after navigation
          } else {
            // Display Health form
            return _buildHealthForm(context);
          }
        } else {
          // Display loading indicator while waiting for data
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildHealthForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Pops and goes back to chat screen
        ),
        title: Text("Health"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.favorite, color: Colors.pink, size: 50),
            SizedBox(height: 20),
            Text("Please fill out this form"),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Weight",
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your weight';
                      }
                      return null;
                    },
                    onSaved: (value) => weight = value,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Height",
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your height';
                      }
                      return null;
                    },
                    onSaved: (value) => height = value,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Gender",
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your gender';
                      }
                      return null;
                    },
                    onSaved: (value) => gender = value,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text("Continue"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkHealthData() async {
    // Fetching health data from Firebase
    DatabaseEvent event = await _database.once(); // This might return a DatabaseEvent

    // Check if the event has data (you should replace 'dataKey' with the actual key you want to check)
    if (event.snapshot.hasChild('health_data')) {
      return true;  // Data exists
    }
    return false;  // Data doesn't exist
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Save data to Firebase
      _database.push().set({
        'weight': weight,
        'height': height,
        'gender': gender,
      }).then((_) {
        // After saving the data, navigate to ChatScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HealthChatScreen()),
        );
      });
    }
  }
}

