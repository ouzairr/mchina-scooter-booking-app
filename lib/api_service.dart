import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend URL. Defaults to the Android emulator's alias for localhost.
  // Override at build time: flutter run --dart-define=API_BASE_URL=http://localhost:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // Send OTP
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber, {bool isLogin = false}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/send-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone_number': phoneNumber, 'is_login': isLogin}),
  );
  return jsonDecode(response.body);
}

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber, 'code': code}),
    );
    return jsonDecode(response.body);
  }

  // Save token locally
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Delete token on logout
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
 static Future<Map<String, dynamic>> updateProfile(String name) async {
  final token = await getToken();
  final response = await http.put(
    Uri.parse('$baseUrl/users/update-profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'name': name}),
  );
  // Save name locally
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_name', name);
  return jsonDecode(response.body);
}
static Future<Map<String, dynamic>> addPayment(String last4, String brand) async {
  final token = await getToken();
  final response = await http.post(
    Uri.parse('$baseUrl/users/add-payment'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'last4': last4, 'card_brand': brand}),
  );
  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>?> getPayment() async {
  final token = await getToken();
  final response = await http.get(
    Uri.parse('$baseUrl/users/payment'),
    headers: {'Authorization': 'Bearer $token'},
  );
  final data = jsonDecode(response.body);
  return data;
}
}
