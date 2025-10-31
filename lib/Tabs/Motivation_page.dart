import 'dart:ui';
import 'package:flutter/material.dart';
import '../Utils/ui_helpers.dart';
import '../services/ApiService.dart';
import '../services/Auth.dart';
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
  final _apiService = ApiService();
  final _authService = AuthService();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    String? token = await _authService.getToken();
    try {
      final data = await _apiService.loadFeed(token!);
      print(data);
      setState(() => _posts = data);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    if (_controller.text.trim().isEmpty) return;

    String? token = await _authService.getToken();
    try {
      await _apiService.postMessageMotivationale(_controller.text, token!);
      _controller.clear();
      await _loadFeed();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _openComments(String postId, String userName, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CommentsPage(postId: postId, userName: userName, content: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF667EEA);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Comunidad Motivacional',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _loadFeed,
                color: primary,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return GestureDetector(
                      onTap:(){
                        _openComments(post['id'],post['userName'],post['content']);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withOpacity(0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                post['userName'] ?? "Usuario",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // ✍️ Contenido del post
                              Text(
                                post['content'] ?? "",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),


                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.comment_outlined, size: 16, color: Colors.white54),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${post['commentCount'] ?? 0} comentarios",
                                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    formatShortDate(post['createdAt']) ?? "",
                                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                  },
                ),
              ),

              /// Campo para escribir post motivacional
            Positioned(
              left: 16,
              right: 16,
              bottom: 85,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                constraints: BoxConstraints(
                  minWidth: 56,
                  maxWidth: _isExpanded ? MediaQuery.of(context).size.width - 32 : 56,
                ),
                height: 56,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    // Fondo glass animado
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_isExpanded ? 0.15 : 0.25),
                        borderRadius: BorderRadius.circular(_isExpanded ? 20 : 28),
                        border: Border.all(
                            color: Colors.white.withOpacity(_isExpanded ? 0.2 : 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_isExpanded ? 20 : 28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: _isExpanded ? 16 : 0,
                                vertical: _isExpanded ? 6 : 0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isExpanded
                                  ? Row(
                                key: const ValueKey("expanded"),
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        hintText:
                                        'Comparte algo motivacional...',
                                        hintStyle:
                                        TextStyle(color: Colors.white70),
                                        border: InputBorder.none,
                                      ),
                                      autofocus: true,
                                      onSubmitted: (_) {
                                        _createPost();
                                        setState(() => _isExpanded = false);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send_rounded,
                                        color: Colors.white, size: 26),
                                    onPressed: () {

                                      setState(() => _isExpanded = false);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: Colors.white70, size: 24),
                                    onPressed: () =>
                                        setState(() => _isExpanded = false),
                                  ),
                                ],
                              )
                                  : IconButton(
                                key: const ValueKey("button"),
                                icon: const Icon(Icons.edit,
                                    color: Colors.white, size: 28),
                                onPressed: () =>
                                    setState(() => _isExpanded = true),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            ],
          ),
        ),
      ),
    );
  }
}
