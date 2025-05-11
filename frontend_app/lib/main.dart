import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode and jsonEncode
import 'login_page.dart'; // Import the new login page
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

  // IMPORTANT: Replace with your backend URL
  // If running Flask locally and testing on Android emulator: 'http://10.0.2.2:8080/api/godchat'
  // If running Flask locally and testing on iOS simulator: 'http://localhost:8080/api/godchat'
  // If backend is deployed: 'https://your-deployed-api-url.com/api/godchat'
  final String _apiUrl = 'http://192.168.1.158:8080/api/godchat'; 

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
      _responseText = ""; // Clear previous response
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'prompt': query}),
      );

      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _isLoading = false;
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['error'] != null) {
              _responseText = "The Oracle speaks of an impediment: ${data['error']}${data['detail'] != null ? ' - ${data['detail']}' : ''}";
            } else {
              _responseText = data['response'] ?? "The divine response was formless silence.";
            }
          } else {
            _responseText = "A disturbance in the divine connection: ${response.statusCode} ${response.reasonPhrase}";
            // You might want to parse response.body for more error details if the server sends them
            // For example: final errorBody = jsonDecode(response.body); _responseText += "\nDetail: ${errorBody['error']}";
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
            fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily, // Example for custom font if set
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        centerTitle: true,
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
                    // border: OutlineInputBorder(), // Handled by theme
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
                if (_isLoading && _responseText.isEmpty) // Show loading text only if response area is empty
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