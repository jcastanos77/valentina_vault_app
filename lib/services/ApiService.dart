import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/Constants.dart';

class ApiService {
  final String baseUrl = "$API_BASE_URL/transactions";
  final String baseUrlUsers = "$API_BASE_URL/users";
  final String baseUrlSaving = "$API_BASE_URL/savings";
  final String baseUrlStats= "$API_BASE_URL/stats";
  final String baseUrlMotivation = "$API_BASE_URL/motivation";
  final String baseUrlNotifications = "$API_BASE_URL/notifications";
  final String baseUrlSummary = "$API_BASE_URL/monthly-summary";

  Future<void> addIncome(double amount, String description,String token) async {
    final url = Uri.parse("$baseUrl/income");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "amount": amount,
        "description": description,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      print("Ingreso agregado correctamente ✅");
    } else {
      throw Exception("Error al agregar ingreso: ${response.body}");
    }
  }

  Future<void> addExpense(double amount, String description, String category, String token) async {
    final url = Uri.parse("$baseUrl/expense");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "category": category,
        "amount": amount,
        "description": description,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      print("Gasto agregado correctamente ✅");
    } else {
      throw Exception("Error al agregar Gasto: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getMonthlySummary(String token) async {
    final url = Uri.parse("$baseUrl/monthlySummary");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener resumen: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getExpensesPorcentages(String token) async {
    final url = Uri.parse("$baseUrl/expenses/percentages");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener percentages: ${response.body}");
    }
  }

  Future<void> addDirectSaving(String token, double amount, String id) async {
    final url = Uri.parse("$baseUrl/saving/$id");

    try {
      print("try response");
      final response = await http
          .post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "amount": amount,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print("✅ Direct saving added: ${response.body}");
      } else {
        print("❌ Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("⚠️ Exception: $e");
    }
  }

  Future<Map<String, dynamic>> getTotalSavings(String token) async {
    final url = Uri.parse("$baseUrl/totalSaving");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10)); // ⏳ timeout

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener ahorro total: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getRules(String token) async {
    final url = Uri.parse("$baseUrlUsers/rules");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10)); // ⏳ timeout
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener ahorro total: ${response.body}");
    }
  }

  Future<List<dynamic>> getGoals(String token) async {
    final url = Uri.parse("$baseUrlSaving/goals");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    ).timeout(const Duration(seconds: 10)); // ⏳ timeout
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener ahorro total: ${response.body}");
    }
  }

  Future<void> addGoal(String name, double amountGoal,String token) async {
    final url = Uri.parse("$baseUrlSaving/add");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "targetAmount": amountGoal,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      print("Meta creada correctamente");
    } else {
      throw Exception("Error al agregar ingreso: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getMonthlyStats(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrlStats/transactionStats"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al obtener estadísticas mensuales");
    }
  }

  Future<bool> deleteSavingsGoal(String token, String goalId) async {
    final url = Uri.parse('$baseUrlSaving/deleteGoal/$goalId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Error deleting goal: ${response.body}');
      return false;
    }
  }

  Future<List<dynamic>> loadFeed(String token) async {
      final url = Uri.parse('$baseUrlMotivation/feed');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Error al obtener mensajes");
      }
  }

  Future<void> postMessageMotivationale(String post, String token) async {
    final url = Uri.parse("$baseUrlMotivation/post");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({'content': post}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      print("Comentario creado");
    } else {
      throw Exception("Error al agregar comentario: ${response.body}");
    }
  }

  Future<List<dynamic>> loadComments(String token, String postId) async {
    final url = Uri.parse('$baseUrlMotivation/comments/${postId}');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener mensajes");
    }
  }

  Future<void> postComment(String comment, String postId,String token) async {
    final url = Uri.parse("$baseUrlMotivation/comment/${postId}");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({'content': comment}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      print("Comentario creado");
    } else {
      throw Exception("Error al agregar comentario: ${response.body}");
    }
  }

  Future<void> resetSummaries(String token) async {

    final response = await http.post(
      Uri.parse('$baseUrlSummary/resetSummaries'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("se resetearion valores");
    } else {
      throw Exception("Error al hacer reset: ${response.body}");
    }

  }


  Future<void> markNotificationAsRead(String notificationId, token) async {

    await http.post(
      Uri.parse('$baseUrlNotifications/mark-read/$notificationId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<List<dynamic>> loadNotifications(String token) async {

    final response = await http.get(
      Uri.parse('$baseUrlNotifications/unread'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error traer notifiaciones: ${response.body}");
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt");
  }
}
