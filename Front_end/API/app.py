from fastapi import FastAPI, HTTPException, Depends, status, File, UploadFile
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
import os
import numpy as np
from PIL import Image
import io
import onnxruntime as ort
import cloudinary
import cloudinary.uploader
import cloudinary.api
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# ==================== Configuration ====================

# MongoDB Configuration
MONGODB_URL = os.getenv("MONGODB_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "aminorice_db")
USERS_COLLECTION = os.getenv("USERS_COLLECTION", "users")
SCANS_COLLECTION = os.getenv("SCANS_COLLECTION", "scans")

# Cloudinary Configuration
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET")
)

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 10080))  # 7 days

# OpenAI Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
openai_client = OpenAI(api_key=OPENAI_API_KEY)

# Model Configuration
MODEL_PATH = os.getenv("MODEL_PATH", "Saved_model/rice_quality.onnx")
IMG_SIZE = int(os.getenv("IMG_SIZE", 224))
TARGET_COLUMNS = [
    'Count', 'Broken_Count', 'Long_Count', 'Medium_Count',
    'Black_Count', 'Chalky_Count', 'Red_Count', 'Yellow_Count',
    'Green_Count', 'WK_Length_Average', 'WK_Width_Average',
    'WK_LW_Ratio_Average', 'Average_L', 'Average_a', 'Average_b'
]

# ==================== FastAPI App ====================

app = FastAPI(
    title="AminoRice API",
    description="API for AminoRice - Rice Quality Assurance Application",
    version="1.0.0"
)

# CORS Configuration - Allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== Security ====================

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# ==================== Database Connection ====================

class MongoDB:
    client: AsyncIOMotorClient = None
    
mongodb = MongoDB()

# Global model variable
model = None

async def get_database():
    return mongodb.client[DATABASE_NAME]

@app.on_event("startup")
async def startup_db_client():
    global model
    # Connect to MongoDB
    mongodb.client = AsyncIOMotorClient(MONGODB_URL)
    try:
        # Test the connection
        await mongodb.client.admin.command('ping')
        print("Successfully connected to MongoDB!")
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
    
    # Load ML Model
    print(f"Attempting to load model from: {MODEL_PATH}")
    print(f"Current working directory: {os.getcwd()}")
    print(f"Model file exists: {os.path.exists(MODEL_PATH)}")
    
    try:
        if not os.path.exists(MODEL_PATH):
            print(f"ERROR: Model file not found at {MODEL_PATH}")
            print(f"Please ensure the model file exists at: {os.path.abspath(MODEL_PATH)}")
        else:
            print("Loading ONNX model...")
            model = ort.InferenceSession(MODEL_PATH, providers=['CPUExecutionProvider'])
            print("Successfully loaded rice quality prediction model!")
            print(f"Model inputs: {model.get_inputs()[0].name}, shape: {model.get_inputs()[0].shape}")
            print(f"Model outputs: {len(model.get_outputs())} output(s)")
    except Exception as e:
        print(f"Error loading model: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        print("API will continue without prediction capabilities")

@app.on_event("shutdown")
async def shutdown_db_client():
    mongodb.client.close()
    print("Disconnected from MongoDB")

# ==================== Models ====================

class UserCreate(BaseModel):
    full_name: str = Field(..., min_length=3, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=100)
    phone: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: str
    full_name: str
    email: str
    phone: Optional[str] = None
    join_date: str
    created_at: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class UserInDB(BaseModel):
    id: str
    full_name: str
    email: str
    phone: Optional[str] = None
    hashed_password: str
    join_date: str
    created_at: str
    updated_at: str

class GrainCharacteristics(BaseModel):
    total_grains: float
    broken_grains: float
    long_grains: float
    medium_grains: float

class DefectiveGrains(BaseModel):
    black_grains: float
    chalky_grains: float
    red_grains: float
    yellow_grains: float
    green_grains: float
    total_defective: float

class GrainMeasurements(BaseModel):
    average_length: float
    average_width: float
    length_width_ratio: float

class ColorCharacteristics(BaseModel):
    average_L: float
    average_a: float
    average_b: float

class Conclusion(BaseModel):
    broken_grain_percentage: float
    defective_grain_percentage: float
    overall_quality_category: str
    quality_description: str

class PredictionResponse(BaseModel):
    sample_information: dict
    grain_characteristics: GrainCharacteristics
    defective_grains: DefectiveGrains
    grain_measurements: GrainMeasurements
    color_characteristics: ColorCharacteristics
    conclusion: Conclusion

class ScanHistoryItem(BaseModel):
    id: str
    image_url: str
    quality_grade: str
    total_count: float
    broken_percentage: float
    defect_percentage: float
    scanned_at: str

class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=500)

class ChatResponse(BaseModel):
    answer: str
    timestamp: str

# ==================== Helper Functions ====================

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    
    db = await get_database()
    user = await db[USERS_COLLECTION].find_one({"email": token_data.email})
    if user is None:
        raise credentials_exception
    return user

# ==================== API Routes ====================

@app.get("/")
async def root():
    return {
        "message": "Welcome to AminoRice API",
        "version": "1.0.0",
        "status": "active",
        "endpoints": {
            "register": "/register",
            "login": "/login",
            "profile": "/profile",
            "docs": "/docs"
        }
    }

@app.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user: UserCreate):
    """
    Register a new user
    
    - **full_name**: User's full name (minimum 3 characters)
    - **email**: Valid email address
    - **password**: Password (minimum 6 characters)
    - **phone**: Optional phone number
    """
    db = await get_database()
    
    # Check if user already exists
    existing_user = await db[USERS_COLLECTION].find_one({"email": user.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    now = datetime.utcnow().isoformat()
    join_date = datetime.utcnow().strftime("%B %Y")
    
    user_dict = {
        "full_name": user.full_name,
        "email": user.email,
        "phone": user.phone,
        "hashed_password": get_password_hash(user.password),
        "join_date": join_date,
        "created_at": now,
        "updated_at": now
    }
    
    result = await db[USERS_COLLECTION].insert_one(user_dict)
    
    # Return user data without password
    return UserResponse(
        id=str(result.inserted_id),
        full_name=user.full_name,
        email=user.email,
        phone=user.phone,
        join_date=join_date,
        created_at=now
    )

@app.post("/login", response_model=Token)
async def login(user: UserLogin):
    """
    Login with email and password
    
    - **email**: User's email address
    - **password**: User's password
    
    Returns an access token for authentication
    """
    db = await get_database()
    
    # Find user by email
    db_user = await db[USERS_COLLECTION].find_one({"email": user.email})
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password
    if not verify_password(user.password, db_user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/profile", response_model=UserResponse)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """
    Get current user's profile information
    
    Requires authentication token in header:
    Authorization: Bearer <token>
    """
    return UserResponse(
        id=str(current_user["_id"]),
        full_name=current_user["full_name"],
        email=current_user["email"],
        phone=current_user.get("phone"),
        join_date=current_user["join_date"],
        created_at=current_user["created_at"]
    )

@app.put("/profile", response_model=UserResponse)
async def update_profile(
    full_name: Optional[str] = None,
    phone: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Update user profile information
    
    - **full_name**: New full name (optional)
    - **phone**: New phone number (optional)
    
    Requires authentication token
    """
    db = await get_database()
    
    update_data = {"updated_at": datetime.utcnow().isoformat()}
    
    if full_name:
        update_data["full_name"] = full_name
    if phone:
        update_data["phone"] = phone
    
    if len(update_data) > 1:  # More than just updated_at
        await db[USERS_COLLECTION].update_one(
            {"_id": current_user["_id"]},
            {"$set": update_data}
        )
        
        # Get updated user
        updated_user = await db[USERS_COLLECTION].find_one({"_id": current_user["_id"]})
        
        return UserResponse(
            id=str(updated_user["_id"]),
            full_name=updated_user["full_name"],
            email=updated_user["email"],
            phone=updated_user.get("phone"),
            join_date=updated_user["join_date"],
            created_at=updated_user["created_at"]
        )
    
    # No changes, return current user
    return UserResponse(
        id=str(current_user["_id"]),
        full_name=current_user["full_name"],
        email=current_user["email"],
        phone=current_user.get("phone"),
        join_date=current_user["join_date"],
        created_at=current_user["created_at"]
    )

# ==================== Helper Functions for Prediction ====================

async def upload_to_cloudinary(image_bytes: bytes, filename: str) -> str:
    """
    Upload image to Cloudinary and return the URL
    """
    try:
        # Upload image to Cloudinary
        upload_result = cloudinary.uploader.upload(
            image_bytes,
            folder="aminorice_scans",
            public_id=f"scan_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{filename}",
            resource_type="image"
        )
        return upload_result['secure_url']
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading image to cloud storage: {str(e)}"
        )

def preprocess_image(image_bytes: bytes) -> np.ndarray:
    """
    Preprocess image for ONNX model prediction
    - Resize to 224x224
    - Normalize using ImageNet statistics
    - Convert to NCHW format (batch, channels, height, width)
    """
    # Load image from bytes
    image = Image.open(io.BytesIO(image_bytes))
    
    # Convert to RGB if necessary
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize
    image = image.resize((IMG_SIZE, IMG_SIZE))
    
    # Convert to numpy array and normalize to [0, 1]
    img_array = np.array(image).astype(np.float32) / 255.0
    
    # Apply ImageNet normalization
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    img_array = (img_array - mean) / std
    
    # Convert from HWC to CHW format
    img_array = np.transpose(img_array, (2, 0, 1))
    
    # Add batch dimension: (1, 3, 224, 224)
    img_array = np.expand_dims(img_array, axis=0)
    
    return img_array

def classify_rice_quality(broken_pct: float, defect_pct: float) -> tuple:
    """
    Classify rice quality based on detailed rules:
    - Premium Quality: <5% broken, very low defects
    - Good Quality: 5-15% broken, low defects
    - Medium Quality: 15-25% broken, moderate defects
    - Fair Quality: 25-35% broken, high defects
    - Poor Quality: >35% broken, very high defects
    """
    if broken_pct < 5 and defect_pct < 3:
        return "Premium Quality", "Broken grains less than 5%. Very low defective grains. Uniform grain size and color. Excellent quality suitable for premium markets."
    elif broken_pct < 15 and defect_pct < 8:
        return "Good Quality", "Broken grains between 5% and 15%. Low defective grains. Good quality suitable for standard markets."
    elif broken_pct < 25 and defect_pct < 15:
        return "Medium Quality", "Broken grains between 15% and 25%. Moderate defects. Acceptable quality for general consumption."
    elif broken_pct < 35 and defect_pct < 25:
        return "Fair Quality", "Broken grains between 25% and 35%. High level of defects. Lower grade quality."
    else:
        return "Poor Quality", "Broken grains greater than 35% or very high defects. Irregular grain characteristics. Suitable only for processing or animal feed."

# ==================== Prediction Endpoint ====================

@app.post("/predict", response_model=PredictionResponse)
async def predict_rice_quality(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """
    Predict rice quality from uploaded image
    
    - **file**: Image file (JPEG, PNG) of rice grains
    
    Returns 15 quality indicators and a quality summary
    
    Requires authentication token
    """
    # Check if model is loaded
    if model is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Prediction model is not available"
        )
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image (JPEG, PNG)"
        )
    
    try:
        # Read image bytes
        image_bytes = await file.read()
        
        # Upload image to Cloudinary
        image_url = await upload_to_cloudinary(image_bytes, file.filename or "rice_scan.png")
        
        # Preprocess image for prediction
        processed_image = preprocess_image(image_bytes)
        
        # Make prediction with ONNX
        input_name = model.get_inputs()[0].name
        raw_predictions = model.run(None, {input_name: processed_image})
        
        # Convert predictions to numpy array
        predictions_array = raw_predictions[0][0]
        predictions_dict = {
            TARGET_COLUMNS[i]: float(predictions_array[i])
            for i in range(len(TARGET_COLUMNS))
        }
        
        # Ensure non-negative values for counts
        for key in predictions_dict:
            if 'Count' in key:
                predictions_dict[key] = max(0, predictions_dict[key])
        
        # Calculate derived indicators
        total_count = predictions_dict['Count']
        broken_count = predictions_dict['Broken_Count']
        
        # Calculate defective grains total
        defect_count = (
            predictions_dict['Black_Count'] + 
            predictions_dict['Chalky_Count'] + 
            predictions_dict['Red_Count'] + 
            predictions_dict['Yellow_Count'] + 
            predictions_dict['Green_Count']
        )
        
        # Calculate percentages
        if total_count > 0:
            broken_pct = (broken_count / total_count) * 100
            defect_pct = (defect_count / total_count) * 100
        else:
            broken_pct = 0
            defect_pct = 0
        
        # Classify rice quality
        quality_category, quality_description = classify_rice_quality(broken_pct, defect_pct)
        
        # Generate unique sample ID
        scan_timestamp = datetime.utcnow()
        sample_id = f"RICE_{scan_timestamp.strftime('%Y%m%d_%H%M%S')}"
        
        # Save scan to database
        db = await get_database()
        
        scan_document = {
            "user_id": str(current_user["_id"]),
            "user_email": current_user["email"],
            "sample_id": sample_id,
            "image_url": image_url,
            **predictions_dict,
            "broken_percentage": round(broken_pct, 2),
            "defect_percentage": round(defect_pct, 2),
            "quality_category": quality_category,
            "quality_description": quality_description,
            "scanned_at": scan_timestamp.isoformat()
        }
        
        result = await db[SCANS_COLLECTION].insert_one(scan_document)
        
        # Structure the response
        response = PredictionResponse(
            sample_information={
                "sample_id": sample_id,
                "scan_id": str(result.inserted_id),
                "image_url": image_url,
                "scanned_at": scan_timestamp.isoformat()
            },
            grain_characteristics=GrainCharacteristics(
                total_grains=round(predictions_dict['Count'], 2),
                broken_grains=round(predictions_dict['Broken_Count'], 2),
                long_grains=round(predictions_dict['Long_Count'], 2),
                medium_grains=round(predictions_dict['Medium_Count'], 2)
            ),
            defective_grains=DefectiveGrains(
                black_grains=round(predictions_dict['Black_Count'], 2),
                chalky_grains=round(predictions_dict['Chalky_Count'], 2),
                red_grains=round(predictions_dict['Red_Count'], 2),
                yellow_grains=round(predictions_dict['Yellow_Count'], 2),
                green_grains=round(predictions_dict['Green_Count'], 2),
                total_defective=round(defect_count, 2)
            ),
            grain_measurements=GrainMeasurements(
                average_length=round(predictions_dict['WK_Length_Average'], 3),
                average_width=round(predictions_dict['WK_Width_Average'], 3),
                length_width_ratio=round(predictions_dict['WK_LW_Ratio_Average'], 3)
            ),
            color_characteristics=ColorCharacteristics(
                average_L=round(predictions_dict['Average_L'], 2),
                average_a=round(predictions_dict['Average_a'], 2),
                average_b=round(predictions_dict['Average_b'], 2)
            ),
            conclusion=Conclusion(
                broken_grain_percentage=round(broken_pct, 2),
                defective_grain_percentage=round(defect_pct, 2),
                overall_quality_category=quality_category,
                quality_description=quality_description
            )
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing image: {str(e)}"
        )

@app.get("/scans", response_model=List[ScanHistoryItem])
async def get_scan_history(
    limit: int = 20,
    current_user: dict = Depends(get_current_user)
):
    """
    Get user's scan history
    
    - **limit**: Maximum number of scans to return (default: 20)
    
    Returns list of previous scans with image URLs and quality summaries
    
    Requires authentication token
    """
    db = await get_database()
    
    # Get user's scans, sorted by most recent first
    cursor = db[SCANS_COLLECTION].find(
        {"user_id": str(current_user["_id"])}
    ).sort("scanned_at", -1).limit(limit)
    
    scans = await cursor.to_list(length=limit)
    
    # Format response
    scan_history = []
    for scan in scans:
        scan_history.append(ScanHistoryItem(
            id=str(scan["_id"]),
            image_url=scan["image_url"],
            quality_grade=scan.get("quality_category", "Unknown"),
            total_count=scan["Count"],
            broken_percentage=scan.get("broken_percentage", 0),
            defect_percentage=scan.get("defect_percentage", 0),
            scanned_at=scan["scanned_at"]
        ))
    
    return scan_history

@app.get("/scans/{scan_id}", response_model=PredictionResponse)
async def get_scan_details(
    scan_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get detailed information about a specific scan
    
    - **scan_id**: The ID of the scan
    
    Returns complete prediction results and quality analysis
    
    Requires authentication token
    """
    db = await get_database()
    
    # Validate scan_id format
    try:
        scan_object_id = ObjectId(scan_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid scan ID format"
        )
    
    # Get scan from database
    scan = await db[SCANS_COLLECTION].find_one({
        "_id": scan_object_id,
        "user_id": str(current_user["_id"])
    })
    
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )
    
    # Calculate defect count
    defect_count = (
        scan.get('Black_Count', 0) + 
        scan.get('Chalky_Count', 0) + 
        scan.get('Red_Count', 0) + 
        scan.get('Yellow_Count', 0) + 
        scan.get('Green_Count', 0)
    )
    
    # Return scan details in new format
    return PredictionResponse(
        sample_information={
            "sample_id": scan.get("sample_id", f"RICE_{scan['scanned_at'][:10]}"),
            "scan_id": str(scan["_id"]),
            "image_url": scan["image_url"],
            "scanned_at": scan["scanned_at"]
        },
        grain_characteristics=GrainCharacteristics(
            total_grains=round(scan["Count"], 2),
            broken_grains=round(scan["Broken_Count"], 2),
            long_grains=round(scan["Long_Count"], 2),
            medium_grains=round(scan["Medium_Count"], 2)
        ),
        defective_grains=DefectiveGrains(
            black_grains=round(scan["Black_Count"], 2),
            chalky_grains=round(scan["Chalky_Count"], 2),
            red_grains=round(scan["Red_Count"], 2),
            yellow_grains=round(scan["Yellow_Count"], 2),
            green_grains=round(scan["Green_Count"], 2),
            total_defective=round(defect_count, 2)
        ),
        grain_measurements=GrainMeasurements(
            average_length=round(scan["WK_Length_Average"], 3),
            average_width=round(scan["WK_Width_Average"], 3),
            length_width_ratio=round(scan["WK_LW_Ratio_Average"], 3)
        ),
        color_characteristics=ColorCharacteristics(
            average_L=round(scan["Average_L"], 2),
            average_a=round(scan["Average_a"], 2),
            average_b=round(scan["Average_b"], 2)
        ),
        conclusion=Conclusion(
            broken_grain_percentage=round(scan.get("broken_percentage", 0), 2),
            defective_grain_percentage=round(scan.get("defect_percentage", 0), 2),
            overall_quality_category=scan.get("quality_category", "Unknown"),
            quality_description=scan.get("quality_description", "Quality information not available")
        )
    )

@app.delete("/scans/{scan_id}")
async def delete_scan(
    scan_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a scan from history
    
    - **scan_id**: The ID of the scan to delete
    
    Requires authentication token
    """
    db = await get_database()
    
    # Validate scan_id format
    try:
        scan_object_id = ObjectId(scan_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid scan ID format"
        )
    
    # Delete scan
    result = await db[SCANS_COLLECTION].delete_one({
        "_id": scan_object_id,
        "user_id": str(current_user["_id"])
    })
    
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )
    
    return {"message": "Scan deleted successfully"}

# ==================== Rice Expert Chatbot ====================

@app.post("/chat", response_model=ChatResponse)
async def rice_expert_chat(
    chat_request: ChatRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Ask the Rice Expert chatbot a question
    
    - **question**: Your question about rice quality, cultivation, processing, etc.
    
    Returns an expert answer (maximum 60 words)
    
    Requires authentication token
    """
    try:
        response = openai_client.chat.completions.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": """You are an expert assistant specialized in rice.

Your purpose is to help users understand everything related to rice, including:

- Rice quality assessment
- Grain measurements (length, width, shape)
- Broken rice percentage
- Chalkiness
- Moisture content
- Milling quality and head rice yield
- Rice grading standards
- Rice varieties and characteristics
- Rice cultivation and harvesting
- Storage and processing
- Nutrition and cooking quality
- Market and export quality standards

When users provide measurements or characteristics, interpret them and explain the likely rice quality level such as:
Premium Quality
Good Quality
Medium Quality
Fair Quality
Poor Quality

Explain information clearly so farmers, researchers, buyers, and students can understand.

If the user asks something unrelated to rice or agriculture, politely guide the conversation back to rice-related topics.

IMPORTANT: Your response must not exceed 60 words. Be concise and direct."""
                },
                {
                    "role": "user",
                    "content": chat_request.question
                }
            ],
            max_tokens=100,
            temperature=0.7
        )
        
        answer = response.choices[0].message.content
        
        # Ensure answer doesn't exceed 60 words
        words = answer.split()
        if len(words) > 60:
            answer = ' '.join(words[:60]) + '...'
        
        return ChatResponse(
            answer=answer,
            timestamp=datetime.utcnow().isoformat()
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing chat request: {str(e)}"
        )

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        db = await get_database()
        await mongodb.client.admin.command('ping')
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    model_status = "loaded" if model is not None else "not loaded"
    
    return {
        "status": "healthy",
        "database": db_status,
        "model": model_status,
        "timestamp": datetime.utcnow().isoformat()
    }

# ==================== Run with: uvicorn app:app --reload ====================
