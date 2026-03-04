from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
import os

# ==================== Configuration ====================

# MongoDB Configuration
MONGODB_URL = "mongodb+srv://aminostore_db_user:yGwj1LCERsQn34hH@amino01.obxcvq3.mongodb.net/?appName=Amino01"
DATABASE_NAME = "aminorice_db"
USERS_COLLECTION = "users"

# JWT Configuration
SECRET_KEY = "your-secret-key-change-this-in-production-2026-aminorice-app"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

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

async def get_database():
    return mongodb.client[DATABASE_NAME]

@app.on_event("startup")
async def startup_db_client():
    mongodb.client = AsyncIOMotorClient(MONGODB_URL)
    try:
        # Test the connection
        await mongodb.client.admin.command('ping')
        print("Successfully connected to MongoDB!")
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")

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

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        db = await get_database()
        await mongodb.client.admin.command('ping')
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    return {
        "status": "healthy",
        "database": db_status,
        "timestamp": datetime.utcnow().isoformat()
    }

# ==================== Run with: uvicorn app:app --reload ====================
