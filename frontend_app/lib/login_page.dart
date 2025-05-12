import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 


import 'main.dart'; 
import 'registration_page.dart'; 
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;
  // Helper function to save the token
  Future<void> _saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    // Replace with your actual login API endpoint
    final String loginApiUrl = 'http://192.168.1.158:8080/api/login'; 


    try {
        final response = await http.post(
          Uri.parse(loginApiUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'username': username, 'password': password}),
        );
  
      setState(() { _isLoading = false; });

        if (!mounted) return; 

        if (response.statusCode == 200) {


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OracleHomePage()),
          );
        } else {
          setState(() { _errorMessage = "Login successful, but no token received."; });
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error connecting to server: $e';
      });
      print("Login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to God.Ai'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF121212)),
                            ),
                          )
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading ? null : () { // Disable while loading
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistrationPage()),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Register',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}