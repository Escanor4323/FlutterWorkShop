import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../chat_screen.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

Color blendColors(Color color1, Color color2) {
  int redPart = ((color1.red + color2.red) / 2).round();
  int greenPart = ((color1.green + color2.green) / 2).round();
  int bluePart = ((color1.blue + color2.blue) / 2).round();
  return Color.fromRGBO(redPart, greenPart, bluePart, 1); // 1 is full opacity
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed! Wrong email or Password?')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blendColors(const Color(0xFFFFFFFF), const Color(0xFFA61717)).withOpacity(0.65),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50, // Adjust the radius for desired size
                    backgroundImage: AssetImage('assets/Icon.png'),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Log In',
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(hintText: 'Username Email'),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(hintText: 'Password'),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFA61717).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Log in!'),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()), // <-- Navigate to RegisterScreen
                          );
                        },
                        child: const Text('Register?'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle forgot password
                          print("Forgot Password button pressed"); // Replace with your desired action
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
