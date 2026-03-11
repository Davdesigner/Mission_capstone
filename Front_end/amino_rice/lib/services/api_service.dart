import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../models/scan_result.dart';
import '../models/user.dart';

class ApiService {
  // Base URL for the API
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  // Use 127.0.0.1 for iOS simulator or real device on same network
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Store auth token
  String? _authToken;

  // Set auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Get auth token
  String? getAuthToken() {
    return _authToken;
  }

  // Clear auth token (for logout)
  void clearAuthToken() {
    _authToken = null;
  }

  // Get headers with auth token
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Register a new user
  Future<Map<String, dynamic>?> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/register');
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        // Client error - try to parse JSON error message
        try {
          final error = json.decode(response.body);
          throw Exception(error['detail'] ?? 'Registration failed');
        } catch (e) {
          throw Exception('Registration failed: ${response.body}');
        }
      } else {
        // Server error
        throw Exception(
          'Server error (${response.statusCode}). Please try again later.',
        );
      }
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  /// Login user
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/login');
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: json.encode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Store the token
        if (data['access_token'] != null) {
          setAuthToken(data['access_token']);
        }
        return data;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        try {
          final error = json.decode(response.body);
          throw Exception(error['detail'] ?? 'Login failed');
        } catch (e) {
          throw Exception('Login failed: ${response.body}');
        }
      } else {
        throw Exception(
          'Server error (${response.statusCode}). Please try again later.',
        );
      }
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<User?> getProfile() async {
    try {
      final uri = Uri.parse('$baseUrl/profile');
      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      print('Profile API Status Code: ${response.statusCode}');
      print('Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed JSON data: $data');
        return User.fromJson(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error fetching profile: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update user profile
  Future<User?> updateProfile({String? fullName, String? phone}) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (fullName != null && fullName.isNotEmpty) {
        queryParams['full_name'] = fullName;
      }
      if (phone != null && phone.isNotEmpty) {
        queryParams['phone'] = phone;
      }

      final uri = Uri.parse(
        '$baseUrl/profile',
      ).replace(queryParameters: queryParams);

      print('Updating profile with params: $queryParams');

      final response = await http.put(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      print('Update profile status: ${response.statusCode}');
      print('Update profile response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  /// Upload an image and get rice quality prediction
  Future<ScanResult?> analyzeRice(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/predict');
      final request = http.MultipartRequest('POST', uri);

      // Add auth header if available
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add the image file
      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();
      final filename = imageFile.path.split('/').last;

      // Determine mime type
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeTypeData = mimeType.split('/');

      final multipartFile = http.MultipartFile(
        'file',
        imageStream,
        imageLength,
        filename: filename,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ScanResult.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error analyzing rice: $e');
      return null;
    }
  }

  /// Check if the API is reachable
  Future<bool> checkApiHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('API health check failed: $e');
      return false;
    }
  }

  /// Get analysis history (if implemented on backend)
  /// Get scan history
  Future<List<Map<String, dynamic>>?> getScanHistory({int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/scans?limit=$limit');
      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching scan history: $e');
      return null;
    }
  }

  /// Delete a scan by ID
  Future<bool> deleteScan(String scanId) async {
    try {
      final uri = Uri.parse('$baseUrl/scans/$scanId');
      final response = await http.delete(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting scan: $e');
      return false;
    }
  }

  /// Get detailed scan result by ID
  Future<ScanResult?> getScanDetails(String scanId) async {
    try {
      final uri = Uri.parse('$baseUrl/scans/$scanId');
      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ScanResult.fromJson(jsonData);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching scan details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getHistory() async {
    // Deprecated: Use getScanHistory instead
    return getScanHistory();
  }

  /// Chat with Rice Expert AI
  Future<String?> chatWithExpert(String question) async {
    try {
      final uri = Uri.parse('$baseUrl/chat');
      final response = await http.post(
        uri,
        headers: _getHeaders(includeAuth: true),
        body: json.encode({'question': question}),
      );

      print('Chat API Status Code: ${response.statusCode}');
      print('Chat API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['answer'] as String?;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error chatting with expert: $e');
      return null;
    }
  }
}
