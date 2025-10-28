import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String userName;
  final String content;

  const CommentsPage({
    super.key,
    required this.postId,
    required this.userName,
    required this.content,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = false;
  final String baseUrl = 'http://localhost:8080/api/motivation';

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/comments/${widget.postId}'));
      if (response.statusCode == 200) {
        setState(() => _comments = jsonDecode(response.body));
      } else {
        debugPrint('Error loading comments: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_controller.text.trim().isEmpty) return;
    final token = await _getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$baseUrl/comment/${widget.postId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({'content': _controller.text}),
    );

    if (response.statusCode == 200) {
      _controller.clear();
      _loadComments();
    } else {
      debugPrint('Error adding comment: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.content),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(comment['userName'] ?? 'Usuario'),
                    subtitle: Text(comment['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
