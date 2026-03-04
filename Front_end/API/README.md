# AminoRice API

FastAPI backend for AminoRice - Rice Quality Assurance Application

## Features

- ✅ User Registration
- ✅ User Login with JWT Authentication
- ✅ Profile Management
- ✅ MongoDB Integration
- ✅ Password Hashing (bcrypt)
- ✅ CORS enabled for Flutter app

## API Endpoints

### Public Endpoints

#### 1. Root Endpoint

```
GET /
```

Returns API information and available endpoints.

#### 2. Register User

```
POST /register
```

**Request Body:**

```json
{
  "full_name": "John Doe",
  "email": "john.doe@example.com",
  "password": "password123",
  "phone": "+1234567890"
}
```

**Response:**

```json
{
  "id": "65f1234567890abcdef",
  "full_name": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "join_date": "March 2026",
  "created_at": "2026-03-05T10:30:00"
}
```

#### 3. Login

```
POST /login
```

**Request Body:**

```json
{
  "email": "john.doe@example.com",
  "password": "password123"
}
```

**Response:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### Protected Endpoints (Require Authentication)

#### 4. Get Profile

```
GET /profile
Authorization: Bearer <token>
```

**Response:**

```json
{
  "id": "65f1234567890abcdef",
  "full_name": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "join_date": "March 2026",
  "created_at": "2026-03-05T10:30:00"
}
```

#### 5. Update Profile

```
PUT /profile
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "full_name": "John Smith",
  "phone": "+0987654321"
}
```

#### 6. Health Check

```
GET /health
```

Returns API health status and database connection status.

## Setup Instructions

### 1. Install Python Dependencies

```bash
cd Mission_capstone/Front_end/API
pip install -r requirements.txt
```

### 2. MongoDB Connection

The API is already configured to connect to your MongoDB Atlas cluster:

- Database: `aminorice_db`
- Collection: `users`

### 3. Run the API

```bash
uvicorn app:app --reload
```

The API will be available at: `http://localhost:8000`

### 4. Access API Documentation

FastAPI provides automatic interactive documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Testing the API

### Using cURL

**Register a user:**

```bash
curl -X POST "http://localhost:8000/register" \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "email": "john.doe@example.com",
    "password": "password123",
    "phone": "+1234567890"
  }'
```

**Login:**

```bash
curl -X POST "http://localhost:8000/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "password123"
  }'
```

**Get Profile (replace TOKEN with actual token):**

```bash
curl -X GET "http://localhost:8000/profile" \
  -H "Authorization: Bearer TOKEN"
```

## Integration with Flutter

### 1. Add HTTP Package to Flutter

```yaml
dependencies:
  http: ^1.1.0
```

### 2. Example Flutter Code

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register');
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile');
    }
  }
}
```

## Security Notes

⚠️ **Important for Production:**

1. Change the `SECRET_KEY` in app.py to a secure random string
2. Update CORS origins to your specific Flutter app domain
3. Use environment variables for sensitive data
4. Enable HTTPS
5. Implement rate limiting
6. Add input validation and sanitization

## MongoDB Schema

### Users Collection

```json
{
  "_id": ObjectId,
  "full_name": "string",
  "email": "string",
  "phone": "string",
  "hashed_password": "string",
  "join_date": "string",
  "created_at": "ISO datetime string",
  "updated_at": "ISO datetime string"
}
```

## Troubleshooting

### MongoDB Connection Issues

If you get connection errors:

1. Check your internet connection
2. Verify the MongoDB connection string
3. Ensure your IP is whitelisted in MongoDB Atlas

### Port Already in Use

If port 8000 is busy, run on a different port:

```bash
uvicorn app:app --reload --port 8001
```

## License

Copyright ©2026 AminoRice
