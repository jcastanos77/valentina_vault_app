import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/ApiService.dart';
import '../services/Auth.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _apiService = ApiService();
  final _authService = AuthService();
  List<dynamic> _ranking = [];

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    String? token = await _authService.getToken();
    try {
      final data = await _apiService.getWeeklyRanking(token!);
      //setState(() => _ranking = data);
    } catch (e) {
      debugPrint("Error loading ranking: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e3c72),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("🏆 Ranking Semanal"),
        centerTitle: true,
      ),
      body: _ranking.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ranking.length,
        itemBuilder: (context, index) {
          final user = _ranking[index];
          final isTop3 = index < 3;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isTop3
                    ? [Colors.amberAccent, Colors.orangeAccent]
                    : [Colors.white12, Colors.white10],
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                isTop3 ? Colors.amberAccent : Colors.grey.shade700,
                radius: 26,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              title: Text(
                user['userName'] ?? 'Usuario',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '🔥 Racha: ${user['currentStreak']} días',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: isTop3
                  ? Lottie.asset('assets/animations/fire.json', width: 40)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
