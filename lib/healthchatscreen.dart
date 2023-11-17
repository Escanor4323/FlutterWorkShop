import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:firebase_database/firebase_database.dart';

import 'HomeEntrance/health.dart';
import 'HomeEntrance/login.dart';
import 'calendar.dart';
import 'chatmessage.dart';
import 'threedots.dart';

class HealthChatScreen extends StatefulWidget {
  const HealthChatScreen({Key? key}) : super(key: key);

  @override
  State<HealthChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<HealthChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = []; // Assuming ChatMessage is a class you have defined elsewhere
  final List<Map<String, String>> _chatHistory = [];
  final _databaseReference = FirebaseDatabase.instance.ref();

  late OpenAI? chatGPT; // Assuming OpenAI is a class you have defined elsewhere
  bool _isImageSearch = false;
  bool _isTyping = false;
  Map<String, dynamic>? userHealthData; // To store user's health data

  // Variables for event creation flow
  bool _isCreatingEvent = false;
  DateTime? _eventDate;


  void _startHealthChat() {
    // Check if health data exists
    if (userHealthData != null) {
      // You might want to format your health data here or prepare it for displaying in a message

      // Create a message about the user's health based on the retrieved data
      String healthMessage = "Let's talk about your health! Here's what I found: ${userHealthData.toString()}"; // Customize this message

      // Add the health message to the chat
      ChatMessage message = ChatMessage(
        text: healthMessage,
        sender: "Bachicha",
        isImage: false,
      );

      setState(() {
        _messages.insert(0, message); // Inserting message at the start of the list
      });

      // You can continue the conversation here or prompt the user for more interactions
    } else {
      // Handle the case when health data is null
      // This might be because the data doesn't exist in the database or it couldn't be retrieved
      ChatMessage message = const ChatMessage(
        text: "I'm sorry, I couldn't find any health data. Can you provide more information?",
        sender: "Bachicha",
        isImage: false,
      );

      setState(() {
        _messages.insert(0, message);
      });
    }
  }


  @override
  void initState() {
    super.initState();
    chatGPT = OpenAI.instance.build(
      token: dotenv.env["API_KEY"],
      baseOption: HttpSetup(receiveTimeout: 60000), // Assuming HttpSetup is a class you have defined or imported
    );
    _fetchHealthData(); // Fetch health data on initialization
  }

  Future<void> _fetchHealthData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid; // Getting current user's ID
    DatabaseReference healthDataRef = _databaseReference.child('health_data').child(userId);

    healthDataRef.once().then((DatabaseEvent event) {
      // Notice here we're using DatabaseEvent, not DataSnapshot
      DataSnapshot snapshot = event.snapshot; // And here we get the snapshot from the event

      setState(() {
        userHealthData = snapshot.value as Map<String, dynamic>?; // Ensure proper type casting here
      });
      if (userHealthData != null) {
        _startHealthChat(); // Start a chat about the user's health
      }
    });
  }

  @override
  void dispose() {
    chatGPT?.close();
    chatGPT?.genImgClose();
    super.dispose();
  }

  String formatChatHistory(List<Map<String, String>> chatHistory) {
    List<String> formattedMessages = [];
    for (int index = 0; index < chatHistory.length; index++) {
      String sender = chatHistory[index]['user'] ?? 'User';
      String message = chatHistory[index]['content'] ?? '';
      formattedMessages.add("Instead of bot write Bachicha, previous responses: $sender: $message");
    }
    return formattedMessages.join('\n');
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "user",
      isImage: false,
    );
    _chatHistory.add({'role': 'user', 'content': _controller.text});

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    _controller.clear();

    // Handle event creation dialogue
    if (_isCreatingEvent) {
      if (_eventDate == null) {
        _eventDate = DateTime.tryParse(message.text); // assuming the user enters a valid date string
        if (_eventDate != null) {
          insertNewData("With what description?");
          return;
        } else {
          insertNewData("I couldn't understand the date. Please provide it in the format YYYY-MM-DD.");
          _resetEventCreation();
          return;
        }
      } else {
        String eventDescription = message.text;
        await _saveEventToDatabase(_eventDate!, eventDescription); // Save to Firebase Realtime Database
        insertNewData("Your event on $_eventDate with description '$eventDescription' has been created! Please check your calendar.");
        _resetEventCreation();
        return;
      }
    }

    // Check if the user wants to create an event
    if (message.text.toLowerCase().contains("create an event in my calendar")) {
      _isCreatingEvent = true;
      insertNewData("Yes, on what date?");
      return;
    }

    if (_isImageSearch) {
      final request = GenerateImage(message.text, 1, size: "256x256");
      final response = await chatGPT!.generateImage(request);
      Vx.log(response!.data!.last!.url!);
      insertNewData(response.data!.last!.url!, isImage: true);
    } else {
      final formattedChatHistory = formatChatHistory(_chatHistory);
      final request = CompleteText(prompt: formattedChatHistory, model: kTranslateModelV3);
      final response = await chatGPT!.onCompleteText(request: request);
      Vx.log(response!.choices[0].text);
      _chatHistory.add({'role': 'Bachicha', 'content': response.choices[0].text});
      insertNewData(response.choices[0].text, isImage: false);
    }
  }

  Future<void> _saveEventToDatabase(DateTime date, String description) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String? eventKey = _databaseReference.child("events").push().key;

    var eventData = {
      "userId": userId,
      "date": date.toIso8601String(),
      "description": description
    };

    _databaseReference.child("events").child(eventKey!).set(eventData);
  }

  void _resetEventCreation() {
    _isCreatingEvent = false;
    _eventDate = null;
  }

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "Bachicha",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (value) => _sendMessage(),
            decoration: const InputDecoration.collapsed(
                hintText: "Question/Functionality?"),
          ),
        ),
        ButtonBar(
          children: [
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                _isImageSearch = false;
                _sendMessage();
              },
            ),
          ],
        ),
      ],
    ).px16();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA61717).withOpacity(0.8),
        title: const Text("Wiener Dog"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ListView(
              shrinkWrap: true,  // ensures the ListView only takes up necessary space
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.red,
                  ),
                  child: Text('Functionalities'),
                ),
                ListTile(
                  title: const Text('Calendar'),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CalendarScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Health'),
                  leading: const Icon(Icons.local_hospital),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HealthSection()),
                    );
                  },
                ),
              ],
            ),
            ListTile(
              title: const Text('Log out'),
              leading: const Icon(Icons.exit_to_app),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: Vx.m8,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatMessage(
                    text: _messages[index].text,
                    sender: _messages[index].sender,
                    isImage: _messages[index].isImage,
                  );
                },
              ),
            ),
            if (_isTyping) const ThreeDots(),
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }
}
