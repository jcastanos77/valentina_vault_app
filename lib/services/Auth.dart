import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/Constants.dart';

class AuthService {
  final String baseUrl = "$API_BASE_URL/api/auth";

  Future<bool> register(String name, String email, String password, int basico, int lujos, int ahorro) async {
    final url = Uri.parse("$baseUrl/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": name,
        "email": email,
        "passwordHash": password,
        "basicosPercent": basico,
        "lujosPercent": lujos,
        "ahorroPercent": ahorro,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("❌ Error en registro: ${response.body}");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    ).timeout(const Duration(seconds: 10),
      onTimeout: () {
        throw Exception("Tiempo de espera agotado");
      },);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final timeExpired = data['timeExpired'];
      print(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("jwt", token);
      await prefs.setString("timeE", timeExpired);

      return true;
    }else{
      throw Exception("Tiempo de espera agotado");
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt");
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt");
  }
}
