import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'login_page.dart'; 


void main() {
  runApp(const DivineOracleApp());
}

class DivineOracleApp extends StatelessWidget {
  const DivineOracleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divine Oracle',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFBB86FC),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          titleLarge: TextStyle(color: Color(0xFFBB86FC)),
          headlineSmall: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBB86FC),
            foregroundColor: const Color(0xFF121212),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFFBB86FC)),
          hintStyle: TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFBB86FC)),
          ),
          filled: true,
          fillColor: Color(0xFF2C2C2C),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFBB86FC)), // For AppBar icons
      ),
      home: const LoginPage(),
    );
  }
}

class OracleHomePage extends StatefulWidget {
  const OracleHomePage({super.key});

  @override
  State<OracleHomePage> createState() => _OracleHomePageState();
}

class _OracleHomePageState extends State<OracleHomePage> {
  final TextEditingController _userInputController = TextEditingController();
  String _responseText = "Write your prayer...";
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage(); // Instance of secure storage


  final String _apiUrl = 'http://192.168.1.158:8080/api/godchat';

  // Helper function to get the stored token
  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _logout() async {

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _submitQuery() async {
    final query = _userInputController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _responseText = "A prayer must be uttered to be heard.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = "";
    });
    String? token = await _getAuthToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _responseText = "Authentication error. Please log in again.";
        // Optionally, force logout or navigate to login
        // _logout(); 
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',// Use the retrieved token
            },
        body: jsonEncode({'prompt': query}),
      );

      if (mounted) { 
        setState(() {
          _isLoading = false;
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['error'] != null) {
              _responseText = "The Oracle speaks of an impediment: ${data['error']}${data['detail'] != null ? ' - ${data['detail']}' : ''}";
            } else {
              _responseText = data['response'] ?? "The divine response was formless silence.";
            }
          } else if (response.statusCode == 401) { // Example: Handle unauthorized
            _responseText = "Your session has expired. Please log out and log in again.";
            // Optionally, force logout:
            // await _storage.delete(key: 'auth_token'); // Clear invalid token
            // _logout();
          }
          else if (response.statusCode == 402) { // Payment Required / Limit Reached
            final data = jsonDecode(response.body);
             _responseText = data['message'] ?? "You've reached your query limit.";
            // _limitReachedAndNotSubscribed = true; // Update UI accordingly
          }
          else {
            _responseText = "A disturbance in the divine connection: ${response.statusCode} ${response.reasonPhrase}";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _responseText = "The connection to the divine realm has been severed. Error: $e";
        });
      }
      print("Error submitting query: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seek Wisdom from God',
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _userInputController,
                  decoration: const InputDecoration(
                    hintText: 'Send your prayer...',
                  ),
                  style: const TextStyle(fontSize: 16.0, color: Color(0xFFE0E0E0)),
                  minLines: 3,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitQuery,
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
                      : const Text('Send Prayer', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 30),
                if (_isLoading && _responseText.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Prayer sending... Divine conduit opening...',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFFBB86FC)),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  constraints: const BoxConstraints(minHeight: 100),
                  child: SelectableText(
                    _responseText,
                    style: const TextStyle(fontSize: 16.0, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userInputController.dispose();
    super.dispose();
  }
}