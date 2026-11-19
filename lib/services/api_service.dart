import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Test backend connection
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }

  // Login using MySQL through Node.js API
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login failed.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String plateNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'vehicle_type': vehicleType,
        'plate_number': plateNumber,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': data['message'] ?? 'Registration successful!',
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Registration failed.',
    };
  }

// READ: GET ALL TRIPS FOR A USER
  static Future<List<Map<String, dynamic>>> getTrips(int userID) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/$userID'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map((trip) => Map<String, dynamic>.from(trip)).toList();
      }

      return [];
    } catch (e) {
      print('Get trips error: $e');
      return [];
    }
  }

// READ: GET ALERTS FOR A SPECIFIC TRIP
  static Future<List<Map<String, dynamic>>> getTripAlerts(
    int tripID,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/trips/$tripID/alerts'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((alert) => Map<String, dynamic>.from(alert)).toList();
      }

      print('Get trip alerts failed: ${response.body}');
      return [];
    } catch (e) {
      print('Get trip alerts error: $e');
      return [];
    }
  }

// READ: GET VIDEO URL FOR A SPECIFIC TRIP
  static Future<Map<String, dynamic>?> getTripVideo(
    int tripID,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/trips/$tripID/video'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['videoURL'] == null) {
          return null;
        }

        return data;
      }

      if (response.statusCode != 404) {
        print('Get trip video failed: ${response.body}');
      }

      return null;
    } catch (e) {
      print('Get trip video error: $e');
      return null;
    }
  }

  // CREATE: ADD NEW TRIP
  static Future<Map<String, dynamic>> createTrip({
    required int userID,
    required String startTime,
    required String endTime,
    required int durationSeconds,
    required int totalAlerts,
  }) async {
    try {
      final requestBody = {
        'userID': userID,
        'startTime': startTime,
        'endTime': endTime,
        'durationSeconds': durationSeconds,
        'totalAlerts': totalAlerts,
      };

      print('CREATE TRIP REQUEST: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/trips'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('CREATE TRIP STATUS: ${response.statusCode}');
      print('CREATE TRIP RESPONSE: ${response.body}');

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 201,
        'message': data['message'] ?? 'Failed to create trip.',
        'error': data['error'] ?? '',
      };
    } catch (e) {
      print('CREATE TRIP ERROR: $e');

      return {
        'success': false,
        'message': 'Unable to connect to server.',
        'error': e.toString(),
      };
    }
  }

  // UPDATE: EDIT EXISTING TRIP
// UPDATE: EDIT TRIP TITLE ONLY
  static Future<Map<String, dynamic>> updateTripTitle({
    required int tripID,
    required String tripTitle,
  }) async {
    try {
      final requestBody = {
        'tripTitle': tripTitle.trim(),
      };

      print('UPDATE TRIP TITLE REQUEST: $requestBody');

      final response = await http
          .put(
            Uri.parse('$baseUrl/trips/$tripID/title'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('UPDATE TRIP TITLE STATUS: ${response.statusCode}');
      print('UPDATE TRIP TITLE RESPONSE: ${response.body}');

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Failed to update trip title.',
        'error': data['error'] ?? '',
      };
    } catch (e) {
      print('UPDATE TRIP TITLE ERROR: $e');

      return {
        'success': false,
        'message': 'Unable to connect to server.',
        'error': e.toString(),
      };
    }
  }

  // DELETE: REMOVE TRIP
  static Future<Map<String, dynamic>> deleteTrip(int tripID) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/trips/$tripID'),
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Failed to delete trip.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to server.',
      };
    }
  }
}
