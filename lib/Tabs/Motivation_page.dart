import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Comments_page.dart';

class MotivationPage extends StatefulWidget {
  const MotivationPage({super.key});

  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage> {
  List<dynamic> _posts = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final String baseUrl = 'http://localhost:8080/api/motivation'; // Cambia según tu backend

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/feed'));
      if (response.statusCode == 200) {
        setState(() {
          _posts = jsonDecode(response.body);
        });
      } else {
        debugPrint('Error loading feed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (_controller.text.trim().isEmpty) return;

    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/post'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({'content': _controller.text}),
    );

    if (response.statusCode == 200) {
      _controller.clear();
      _loadFeed();
    } else {
      debugPrint('Error creating post: ${response.body}');
    }
  }

  void _openComments(String postId, String userName, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(postId: postId, userName: userName, content: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad Motivacional'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Escribe algo motivacional...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _createPost,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._posts.map((post) => Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  post['userName'] ?? 'Usuario',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(post['content'] ?? ''),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () => _openComments(
                    post['id'],
                    post['userName'],
                    post['content'],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
