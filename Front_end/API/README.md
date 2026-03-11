# AminoRice API

FastAPI backend for AminoRice - Rice Quality Assurance Application

## Features

- ✅ User Registration
- ✅ User Login with JWT Authentication
- ✅ Profile Management
- ✅ MongoDB Integration
- ✅ Password Hashing (bcrypt)
- ✅ CORS enabled for Flutter app
- ✅ **AI-Powered Rice Quality Prediction** (MobileNetV2 CNN)
- ✅ **15 Quality Indicators from Images**
- ✅ **Cloudinary Image Storage** - Permanent cloud storage for scan images
- ✅ **Scan History & Analytics** - Track and review past predictions
- ✅ **Rice Expert Chatbot** - AI-powered Q&A using OpenAI GPT-4

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

#### 6. Predict Rice Quality from Image 🌾🤖

```
POST /predict
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

Upload a rice grain image to get quality analysis and predictions.

**Request:**

```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@rice_sample.png"
```

**Response:**

```json
{
  "sample_information": {
    "sample_id": "RICE_20260308_143022",
    "scan_id": "65f1234567890abcdef12345",
    "image_url": "https://res.cloudinary.com/dnkfri0vx/image/upload/v1234567890/aminorice_scans/scan_20260308_143022_rice.png",
    "scanned_at": "2026-03-08T14:30:22.123456"
  },
  "grain_characteristics": {
    "total_grains": 1523.45,
    "broken_grains": 123.82,
    "long_grains": 856.32,
    "medium_grains": 12.45
  },
  "defective_grains": {
    "black_grains": 34.67,
    "chalky_grains": 45.23,
    "red_grains": 23.45,
    "yellow_grains": 17.89,
    "green_grains": 12.34,
    "total_defective": 133.58
  },
  "grain_measurements": {
    "average_length": 6.45,
    "average_width": 2.13,
    "length_width_ratio": 3.028
  },
  "color_characteristics": {
    "average_L": 65.23,
    "average_a": 5.67,
    "average_b": 23.45
  },
  "conclusion": {
    "broken_grain_percentage": 8.13,
    "defective_grain_percentage": 8.77,
    "overall_quality_category": "Good Quality",
    "quality_description": "Broken grains between 5% and 15%. Low defective grains. Good quality suitable for standard markets."
  }
}
```

**Quality Indicators Explained:**

- **total_grains**: Total number of rice grains detected
- **broken_grains**: Number of broken/damaged grains
- **long_grains**: Number of long-grain rice
- **medium_grains**: Number of medium-length grains
- **black_grains**: Dark/black colored grains (defect indicator)
- **chalky_grains**: Chalky grains (quality defect affecting milling)
- **red_grains**: Red-colored grains
- **yellow_grains**: Yellow-colored grains (aging/moisture indicator)
- **green_grains**: Immature green grains
- **average_length**: Average grain length (mm)
- **average_width**: Average grain width (mm)
- **length_width_ratio**: Length-to-width ratio
- **average_L**: Average lightness (L\* color value)
- **average_a**: Red-green color axis (a\*)
- **average_b**: Yellow-blue color axis (b\*)

**Quality Classification System:**

The API classifies rice into five quality categories based on broken grain percentage and defective grain percentage:

1. **Premium Quality**
   - Broken grains: < 5%
   - Defective grains: < 3%
   - Description: Very low defective grains. Uniform grain size and color. Excellent quality suitable for premium markets.

2. **Good Quality**
   - Broken grains: 5% - 15%
   - Defective grains: < 8%
   - Description: Low defective grains. Good quality suitable for standard markets.

3. **Medium Quality**
   - Broken grains: 15% - 25%
   - Defective grains: < 15%
   - Description: Moderate defects. Acceptable quality for general consumption.

4. **Fair Quality**
   - Broken grains: 25% - 35%
   - Defective grains: < 25%
   - Description: High level of defects. Lower grade quality.

5. **Poor Quality**
   - Broken grains: > 35% or defective grains > 25%
   - Description: Very high defects. Irregular grain characteristics. Suitable only for processing or animal feed.

**Calculated Indicators:**

- **Broken Grain Percentage** = (Broken_Count / Total_Count) × 100
- **Defective Grain Percentage** = (Black + Chalky + Red + Yellow + Green) / Total_Count × 100

**Model Information:**

- Architecture: PyTorch Deep Learning Model
- Model File: `rice_quality_best.pt`
- Input: 224×224 RGB images
- Training: Labeled rice grain dataset
- Output: 15 continuous numerical predictions

#### 7. Health Check

```
GET /health
```

Returns API health status, database connection, and model loading status.

**Response:**

```json
{
  "status": "healthy",
  "database": "connected",
  "model": "loaded",
  "timestamp": "2026-03-08T12:34:56"
}
```

### Scan History Endpoints

#### 8. Get Scan History

```
GET /scans?limit=20
Authorization: Bearer <token>
```

Get user's scan history with summary information.

**Query Parameters:**

- `limit` (optional): Maximum number of scans to return (default: 20)

**Response:**

```json
[
  {
    "id": "65f1234567890abcdef12345",
    "image_url": "https://res.cloudinary.com/dnkfri0vx/image/upload/.../scan.png",
    "quality_grade": "Good",
    "total_count": 1523.45,
    "broken_percentage": 8.13,
    "defect_percentage": 12.45,
    "scanned_at": "2026-03-08T14:30:22.123456"
  },
  {
    "id": "65f1234567890abcdef12346",
    "image_url": "https://res.cloudinary.com/dnkfri0vx/image/upload/.../scan.png",
    "quality_grade": "Premium",
    "total_count": 1845.32,
    "broken_percentage": 3.21,
    "defect_percentage": 2.56,
    "scanned_at": "2026-03-07T10:15:45.789012"
  }
]
```

#### 9. Get Scan Details

```
GET /scans/{scan_id}
Authorization: Bearer <token>
```

Get complete details for a specific scan including all 15 quality indicators.

**Response:**

```json
{
  "sample_information": {
    "sample_id": "RICE_20260308_143022",
    "scan_id": "65f1234567890abcdef12345",
    "image_url": "https://res.cloudinary.com/dnkfri0vx/image/upload/.../scan.png",
    "scanned_at": "2026-03-08T14:30:22.123456"
  },
  "grain_characteristics": {
    "total_grains": 1523.45,
    "broken_grains": 123.82,
    "long_grains": 856.32,
    "medium_grains": 12.45
  },
  "defective_grains": {
    "black_grains": 34.67,
    "chalky_grains": 45.23,
    "red_grains": 23.45,
    "yellow_grains": 17.89,
    "green_grains": 12.34,
    "total_defective": 133.58
  },
  "grain_measurements": {
    "average_length": 6.45,
    "average_width": 2.13,
    "length_width_ratio": 3.028
  },
  "color_characteristics": {
    "average_L": 65.23,
    "average_a": 5.67,
    "average_b": 23.45
  },
  "conclusion": {
    "broken_grain_percentage": 8.13,
    "defective_grain_percentage": 8.77,
    "overall_quality_category": "Good Quality",
    "quality_description": "Broken grains between 5% and 15%. Low defective grains. Good quality suitable for standard markets."
  }
}
```

#### 10. Delete Scan

```
DELETE /scans/{scan_id}
Authorization: Bearer <token>
```

Delete a scan from history.

**Response:**

```json
{
  "message": "Scan deleted successfully"
}
```

### Rice Expert Chatbot

#### 11. Ask Rice Expert

```
POST /chat
Authorization: Bearer <token>
```

Ask the AI-powered Rice Expert chatbot questions about rice quality, cultivation, processing, and more.

**Request Body:**

```json
{
  "question": "What is the ideal moisture content for storing rice?"
}
```

**Response:**

```json
{
  "answer": "The ideal moisture content for storing rice is 12-14%. This level prevents mold growth, insect infestation, and maintains grain quality. Below 12% can cause grain breakage, while above 14% increases spoilage risk. Always store in cool, dry conditions.",
  "timestamp": "2026-03-11T15:30:45.123456"
}
```

**Features:**

- Expert knowledge on rice quality, cultivation, processing, storage, and grading
- Interprets measurements and provides quality assessments
- Answers limited to 60 words for quick, concise responses
- Accessible to farmers, researchers, buyers, and students

**Example Questions:**

- "What makes rice chalky?"
- "How do I improve head rice yield?"
- "What's the difference between long and medium grain rice?"
- "How is broken rice percentage calculated?"
- "What are the export quality standards for rice?"

## Setup Instructions

### 1. Install Python Dependencies

```bash
cd Mission_capstone/Front_end/API
pip install -r requirements.txt
```

### 2. Environment Variables Setup

Create a `.env` file in the API directory by copying the example:

```bash
cp .env.example .env
```

Then edit `.env` with your actual credentials:

```env
# MongoDB Configuration
MONGODB_URL=your_mongodb_connection_string
DATABASE_NAME=aminorice_db
USERS_COLLECTION=users
SCANS_COLLECTION=scans

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# JWT Configuration
SECRET_KEY=your-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key

# Model Configuration
MODEL_PATH=Saved_model/rice_quality.onnx
IMG_SIZE=224
```

**Important:** Never commit the `.env` file to version control. It's already included in `.gitignore`.

### 3. MongoDB Connection

The API connects to MongoDB Atlas using the connection string in `.env`:

- Database: `aminorice_db`
- Collections:
  - `users` - User accounts and authentication
  - `scans` - Rice quality scan history and results

### 4. Cloudinary Configuration

The API uses Cloudinary for cloud-based image storage:

- **Purpose**: Stores uploaded rice grain images permanently
- **Folder**: `aminorice_scans/`
- **Configuration**: Set credentials in `.env` file
- **URL Format**: Images are accessible via HTTPS URLs

All scan images are automatically uploaded to Cloudinary when predictions are made.

### 5. Run the API

```bash
uvicorn app:app --reload
```

The API will be available at: `http://localhost:8000`

### 6. Access API Documentation

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
