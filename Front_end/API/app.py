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
import json
import onnxruntime as ort
import cloudinary
import cloudinary.uploader
import cloudinary.api
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# =============================================================================
#  CONFIGURATION
# =============================================================================

MONGODB_URL              = os.getenv("MONGODB_URL")
DATABASE_NAME            = os.getenv("DATABASE_NAME", "aminorice_db")
USERS_COLLECTION         = os.getenv("USERS_COLLECTION", "users")
SCANS_COLLECTION         = os.getenv("SCANS_COLLECTION", "scans")

cloudinary.config(
    cloud_name = os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key    = os.getenv("CLOUDINARY_API_KEY"),
    api_secret = os.getenv("CLOUDINARY_API_SECRET"),
)

SECRET_KEY                  = os.getenv("SECRET_KEY")
ALGORITHM                   = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 10080))

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
openai_client  = OpenAI(api_key=OPENAI_API_KEY)

# ── Model paths ───────────────────────────────────────────────────────────────
# ONNX is the only model artifact required at runtime.
ONNX_MODEL_PATH = os.getenv(
    "MODEL_PATH",
    "Saved_model/Final_Best_model.onnx"
)
GDRIVE_ONNX_ID = os.getenv("GDRIVE_ONNX_ID")

# ── Image size expected by the model ─────────────────────────────────────────
IMG_H = 640
IMG_W = 640

# ── All 16 targets in the exact order the model outputs them ─────────────────
COUNT_TARGETS = [
    'Count', 'Broken_Count', 'Long_Count', 'Medium_Count',
    'Black_Count', 'Chalky_Count', 'Red_Count', 'Yellow_Count', 'Green_Count'
]
CONTINUOUS_TARGETS = [
    'WK_Length_Average', 'WK_Width_Average', 'WK_LW_Ratio_Average',
    'Average_L', 'Average_a', 'Average_b'
]
ALL_TARGETS = COUNT_TARGETS + CONTINUOUS_TARGETS + ['comment_encoded']   # 16 total

# Rice type mapping (comment_encoded → string)
COMMENT_MAP_INV = {0: 'Paddy', 1: 'Brown', 2: 'White'}

# =============================================================================
#  FASTAPI APP
# =============================================================================

app = FastAPI(
    title       = "AminoRice API",
    description = "Rice Quality Assurance Application — powered by the trained RiceModel",
    version     = "2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins     = ["*"],
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

# =============================================================================
#  SECURITY
# =============================================================================

pwd_context    = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme  = OAuth2PasswordBearer(tokenUrl="login")

# =============================================================================
#  DATABASE
# =============================================================================

class MongoDB:
    client: AsyncIOMotorClient = None

mongodb = MongoDB()

async def get_database():
    return mongodb.client[DATABASE_NAME]

# =============================================================================
#  GLOBAL MODEL STATE
# =============================================================================

# onnx_session   : InferenceSession — runs predictions
# output_targets : ordered target names used to map ONNX output indexes
onnx_session   = None
output_targets = ALL_TARGETS.copy()


def _file_size_mb(path: str) -> float:
    try:
        return os.path.getsize(path) / (1024 * 1024)
    except Exception:
        return 0.0


def ensure_model_file(local_path: str, gdrive_file_id: Optional[str], display_name: str) -> bool:
    """
    Ensure model file exists locally, downloading from Google Drive if needed.
    """
    if os.path.exists(local_path):
        print(f"✅ {display_name} already present ({_file_size_mb(local_path):.1f} MB) → {local_path}")
        return True

    if not gdrive_file_id:
        print(f"⚠  {display_name} missing and no Google Drive ID provided")
        print(f"   Set env var for file ID to download into {local_path}")
        return False

    try:
        import gdown
    except ImportError:
        print("⚠  gdown is not installed — cannot download model files from Google Drive")
        return False

    os.makedirs(os.path.dirname(local_path) or ".", exist_ok=True)

    try:
        print(f"⬇  Downloading {display_name} from Google Drive ...")
        gdrive_url = f"https://drive.google.com/uc?id={gdrive_file_id}"
        out_path = gdown.download(url=gdrive_url, output=local_path, quiet=False, fuzzy=True)
        if out_path is None or not os.path.exists(local_path):
            print(f"❌ Failed to download {display_name}")
            return False
        print(f"✅ {display_name} downloaded ({_file_size_mb(local_path):.1f} MB) → {local_path}")
        return True
    except Exception as e:
        print(f"❌ Error downloading {display_name}: {e}")
        return False


# =============================================================================
#  STARTUP / SHUTDOWN
# =============================================================================

@app.on_event("startup")
async def startup():
    global onnx_session, output_targets

    # ── MongoDB ───────────────────────────────────────────────────────────────
    mongodb.client = AsyncIOMotorClient(MONGODB_URL)
    try:
        await mongodb.client.admin.command("ping")
        print("✅ MongoDB connected")
    except Exception as e:
        print(f"❌ MongoDB connection error: {e}")

    # ── Ensure local ONNX model file (download from Drive on first boot) ─────
    ensure_model_file(ONNX_MODEL_PATH, GDRIVE_ONNX_ID, "Final_Best_model.onnx")

    # ── ONNX model ────────────────────────────────────────────────────────────
    print(f"\nLoading ONNX model from: {ONNX_MODEL_PATH}")
    if not os.path.exists(ONNX_MODEL_PATH):
        print(f"❌ ONNX model not found at {os.path.abspath(ONNX_MODEL_PATH)}")
    else:
        try:
            # Prefer GPU if onnxruntime-gpu is installed, fall back to CPU
            providers = (
                ["CUDAExecutionProvider", "CPUExecutionProvider"]
                if "CUDAExecutionProvider" in ort.get_available_providers()
                else ["CPUExecutionProvider"]
            )
            onnx_session = ort.InferenceSession(ONNX_MODEL_PATH, providers=providers)

            # Print input / output info for debugging
            for inp in onnx_session.get_inputs():
                print(f"  Model input  : name='{inp.name}'  shape={inp.shape}  type={inp.type}")
            for out in onnx_session.get_outputs():
                print(f"  Model output : name='{out.name}'  shape={out.shape}  type={out.type}")
            print(f"✅ ONNX model loaded  (providers: {providers})")
        except Exception as e:
            print(f"❌ Failed to load ONNX model: {e}")

    # ONNX model emits 16 targets in ALL_TARGETS order.
    output_targets = ALL_TARGETS.copy()


@app.on_event("shutdown")
async def shutdown():
    mongodb.client.close()
    print("MongoDB disconnected")


# =============================================================================
#  PYDANTIC MODELS
# =============================================================================

class UserCreate(BaseModel):
    full_name : str      = Field(..., min_length=3, max_length=100)
    email     : EmailStr
    password  : str      = Field(..., min_length=6, max_length=100)
    phone     : Optional[str] = None

class UserLogin(BaseModel):
    email    : EmailStr
    password : str

class UserResponse(BaseModel):
    id        : str
    full_name : str
    email     : str
    phone     : Optional[str] = None
    join_date : str
    created_at: str

class Token(BaseModel):
    access_token : str
    token_type   : str

class TokenData(BaseModel):
    email: Optional[str] = None

class GrainCharacteristics(BaseModel):
    total_grains  : float
    broken_grains : float
    long_grains   : float
    medium_grains : float

class DefectiveGrains(BaseModel):
    black_grains    : float
    chalky_grains   : float
    red_grains      : float
    yellow_grains   : float
    green_grains    : float
    total_defective : float

class GrainMeasurements(BaseModel):
    average_length     : float
    average_width      : float
    length_width_ratio : float

class ColorCharacteristics(BaseModel):
    average_L : float
    average_a : float
    average_b : float

class RiceTypeInfo(BaseModel):
    comment_encoded : float   # raw predicted value (0 ≈ Paddy, 1 ≈ Brown, 2 ≈ White)
    rice_type       : str     # decoded label

class Conclusion(BaseModel):
    broken_grain_percentage   : float
    defective_grain_percentage: float
    overall_quality_category  : str
    quality_description       : str

class PredictionResponse(BaseModel):
    sample_information  : dict
    rice_type_info      : RiceTypeInfo
    predictions         : dict
    grain_characteristics: GrainCharacteristics
    defective_grains    : DefectiveGrains
    grain_measurements  : GrainMeasurements
    color_characteristics: ColorCharacteristics
    conclusion          : Conclusion

class ScanHistoryItem(BaseModel):
    id                : str
    image_url         : str
    quality_grade     : str
    rice_type         : str
    total_count       : float
    broken_percentage : float
    defect_percentage : float
    scanned_at        : str

class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=500)

class ChatResponse(BaseModel):
    answer    : str
    timestamp : str


# =============================================================================
#  HELPER FUNCTIONS — auth
# =============================================================================

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire    = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme)):
    exc = HTTPException(
        status_code = status.HTTP_401_UNAUTHORIZED,
        detail      = "Could not validate credentials",
        headers     = {"WWW-Authenticate": "Bearer"},
    )
    try:
        payload    = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise exc
    except JWTError:
        raise exc
    db   = await get_database()
    user = await db[USERS_COLLECTION].find_one({"email": email})
    if user is None:
        raise exc
    return user


# =============================================================================
#  HELPER FUNCTIONS — image preprocessing
#  Matches the val/inference transform used during training:
#    Resize(640, 640) → ImageNet normalize → NCHW float32
# =============================================================================

def preprocess_image(image_bytes: bytes) -> np.ndarray:
    """
    Returns float32 array of shape [1, 3, 640, 640] ready for ONNX inference.
    Preprocessing exactly mirrors the training val/TTA transform pipeline.
    """
    image = Image.open(io.BytesIO(image_bytes))
    if image.mode != "RGB":
        image = image.convert("RGB")

    # Always resize to the exact size the model was trained on
    image     = image.resize((IMG_W, IMG_H), Image.BILINEAR)
    img_array = np.array(image, dtype=np.float32) / 255.0

    # ImageNet normalisation (matches Albumentations A.Normalize default)
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std  = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    img_array = (img_array - mean) / std                   # HWC

    img_array = np.transpose(img_array, (2, 0, 1))         # CHW
    img_array = np.expand_dims(img_array, axis=0)          # NCHW [1,3,640,640]
    return img_array


def detect_comment_from_image(image_bytes: bytes) -> int:
    """
    Heuristic to guess the rice type (comment index) from the image
    before running inference — used as the 'comment' ONNX input.

    The model was trained with:
        Paddy = 0, Brown = 1, White = 2

    Strategy: use the mean brightness of the image.
      Dark image  → likely Paddy  (0)
      Mid-tone    → likely Brown  (1)
      Bright      → likely White  (2)

    You can override this with a query parameter once you know the type.
    """
    image = Image.open(io.BytesIO(image_bytes)).convert("L")   # grayscale
    brightness = np.array(image, dtype=np.float32).mean()
    if brightness < 80:
        return 0   # Paddy
    elif brightness < 160:
        return 1   # Brown
    else:
        return 2   # White


def run_onnx_inference(image_array: np.ndarray, comment_idx: int) -> np.ndarray:
    """
    Runs one forward pass through the ONNX model.
    Returns raw shape [16] normalised output.

    ONNX model inputs:
        'image'   : float32 [batch, 3, 640, 640]
        'comment' : int64   [batch]
    ONNX model output:
        'predictions' : float32 [batch, 16]
    """
    comment_array = np.array([comment_idx], dtype=np.int64)  # shape [1]
    raw = onnx_session.run(
        None,
        {
            "image"  : image_array,     # [1, 3, 640, 640]
            "comment": comment_array,   # [1]
        }
    )
    return raw[0][0]   # shape [16]


# =============================================================================
#  HELPER FUNCTIONS — post-processing
# =============================================================================

def classify_rice_quality(broken_pct: float, defect_pct: float) -> tuple:
    if broken_pct < 5 and defect_pct < 3:
        return ("Premium Quality",
                "Broken grains less than 5%. Very low defective grains. "
                "Uniform grain size and color. Excellent quality suitable for premium markets.")
    elif broken_pct < 15 and defect_pct < 8:
        return ("Good Quality",
                "Broken grains between 5% and 15%. Low defective grains. "
                "Good quality suitable for standard markets.")
    elif broken_pct < 25 and defect_pct < 15:
        return ("Medium Quality",
                "Broken grains between 15% and 25%. Moderate defects. "
                "Acceptable quality for general consumption.")
    elif broken_pct < 35 and defect_pct < 25:
        return ("Fair Quality",
                "Broken grains between 25% and 35%. High level of defects. Lower grade quality.")
    else:
        return ("Poor Quality",
                "Broken grains greater than 35% or very high defects. "
                "Irregular grain characteristics. Suitable only for processing or animal feed.")


async def upload_to_cloudinary(image_bytes: bytes, filename: str) -> str:
    try:
        result = cloudinary.uploader.upload(
            image_bytes,
            folder     = "aminorice_scans",
            public_id  = f"scan_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{filename}",
            resource_type = "image",
        )
        return result["secure_url"]
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail      = f"Error uploading image: {e}",
        )


# =============================================================================
#  ROUTES — auth / user
# =============================================================================

@app.get("/")
async def root():
    return {
        "message"  : "Welcome to AminoRice API v2",
        "version"  : "2.0.0",
        "status"   : "active",
        "model"    : "RiceModel (ConvNeXtV2-Nano, 16 targets, 640×640)",
        "endpoints": {
            "register": "/register",
            "login"   : "/login",
            "profile" : "/profile",
            "predict" : "/predict",
            "scans"   : "/scans",
            "chat"    : "/chat",
            "docs"    : "/docs",
        },
    }


@app.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user: UserCreate):
    db = await get_database()
    if await db[USERS_COLLECTION].find_one({"email": user.email}):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Email already registered")

    now       = datetime.utcnow().isoformat()
    join_date = datetime.utcnow().strftime("%B %Y")
    result    = await db[USERS_COLLECTION].insert_one({
        "full_name"      : user.full_name,
        "email"          : user.email,
        "phone"          : user.phone,
        "hashed_password": get_password_hash(user.password),
        "join_date"      : join_date,
        "created_at"     : now,
        "updated_at"     : now,
    })
    return UserResponse(id=str(result.inserted_id), full_name=user.full_name,
                        email=user.email, phone=user.phone,
                        join_date=join_date, created_at=now)


@app.post("/login", response_model=Token)
async def login(user: UserLogin):
    db      = await get_database()
    db_user = await db[USERS_COLLECTION].find_one({"email": user.email})
    if not db_user or not verify_password(user.password, db_user["hashed_password"]):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password",
                            headers={"WWW-Authenticate": "Bearer"})
    token = create_access_token(
        {"sub": user.email},
        timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": token, "token_type": "bearer"}


@app.get("/profile", response_model=UserResponse)
async def get_profile(current_user: dict = Depends(get_current_user)):
    return UserResponse(
        id=str(current_user["_id"]), full_name=current_user["full_name"],
        email=current_user["email"], phone=current_user.get("phone"),
        join_date=current_user["join_date"], created_at=current_user["created_at"],
    )


@app.put("/profile", response_model=UserResponse)
async def update_profile(
    full_name: Optional[str] = None,
    phone    : Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    db          = await get_database()
    update_data = {"updated_at": datetime.utcnow().isoformat()}
    if full_name: update_data["full_name"] = full_name
    if phone:     update_data["phone"]     = phone

    if len(update_data) > 1:
        await db[USERS_COLLECTION].update_one(
            {"_id": current_user["_id"]}, {"$set": update_data}
        )
        current_user = await db[USERS_COLLECTION].find_one({"_id": current_user["_id"]})

    return UserResponse(
        id=str(current_user["_id"]), full_name=current_user["full_name"],
        email=current_user["email"], phone=current_user.get("phone"),
        join_date=current_user["join_date"], created_at=current_user["created_at"],
    )


# =============================================================================
#  PREDICT
# =============================================================================

@app.post("/predict", response_model=PredictionResponse)
async def predict_rice_quality(
    file        : UploadFile = File(...),
    comment_hint: Optional[int] = None,   # 0=Paddy, 1=Brown, 2=White (optional override)
    current_user: dict = Depends(get_current_user),
):
    """
    Predict rice quality from an uploaded image.

    **file** — JPEG or PNG image of rice grains.

    **comment_hint** *(optional)* — rice type hint passed to the model:
    `0` = Paddy, `1` = Brown, `2` = White.
    If omitted, the API estimates it automatically from image brightness.

    Returns 16 quality indicators plus a quality summary.
    """
    if onnx_session is None:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE,
                            "Prediction model is not loaded")

    if not file.content_type.startswith("image/"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            "File must be an image (JPEG or PNG)")

    try:
        image_bytes = await file.read()

        # ── Upload to Cloudinary ──────────────────────────────────────────────
        image_url = await upload_to_cloudinary(image_bytes, file.filename or "rice_scan.png")

        # ── Determine comment index ───────────────────────────────────────────
        comment_idx = (
            comment_hint
            if comment_hint is not None and comment_hint in (0, 1, 2)
            else detect_comment_from_image(image_bytes)
        )

        # ── Preprocess image ──────────────────────────────────────────────────
        image_array = preprocess_image(image_bytes)   # [1, 3, 640, 640]

        # ── ONNX inference ────────────────────────────────────────────────────
        raw_output = run_onnx_inference(image_array, comment_idx)  # [16] normalised

        # Map raw ONNX outputs to target names.
        keys = output_targets if len(output_targets) == len(raw_output) else ALL_TARGETS[:len(raw_output)]
        preds = {keys[i]: float(raw_output[i]) for i in range(len(keys))}

        # ── Ensure non-negative counts ────────────────────────────────────────
        for t in COUNT_TARGETS:
            preds[t] = max(0.0, preds.get(t, 0.0))

        # ── Decode rice type from comment_encoded prediction ──────────────────
        comment_encoded_pred = preds.get("comment_encoded", float(comment_idx))
        rice_type_idx        = int(round(float(comment_encoded_pred)))
        rice_type_idx        = max(0, min(2, rice_type_idx))
        rice_type_label      = COMMENT_MAP_INV.get(rice_type_idx, "Unknown")

        # ── Derived percentages ───────────────────────────────────────────────
        total_count  = preds.get("Count", 0.0)
        broken_count = preds.get("Broken_Count", 0.0)
        defect_count = sum(preds.get(t, 0.0) for t in
                           ["Black_Count", "Chalky_Count", "Red_Count",
                            "Yellow_Count", "Green_Count"])

        if total_count > 0:
            broken_pct = (broken_count / total_count) * 100
            defect_pct = (defect_count / total_count) * 100
        else:
            broken_pct = defect_pct = 0.0

        quality_category, quality_description = classify_rice_quality(broken_pct, defect_pct)

        # ── Save scan to MongoDB ──────────────────────────────────────────────
        scan_timestamp = datetime.utcnow()
        sample_id      = f"RICE_{scan_timestamp.strftime('%Y%m%d_%H%M%S')}"

        scan_doc = {
            "user_id"            : str(current_user["_id"]),
            "user_email"         : current_user["email"],
            "sample_id"          : sample_id,
            "image_url"          : image_url,
            "rice_type"          : rice_type_label,
            "comment_encoded"    : comment_encoded_pred,
            **{t: preds.get(t, 0.0) for t in COUNT_TARGETS + CONTINUOUS_TARGETS},
            "broken_percentage"  : round(broken_pct, 2),
            "defect_percentage"  : round(defect_pct, 2),
            "quality_category"   : quality_category,
            "quality_description": quality_description,
            "scanned_at"         : scan_timestamp.isoformat(),
        }
        db     = await get_database()
        result = await db[SCANS_COLLECTION].insert_one(scan_doc)

        # ── Build response ────────────────────────────────────────────────────
        prediction_map = {
            key: round(float(preds.get(key, 0.0)), 6)
            for key in output_targets
            if key in preds
        }

        return PredictionResponse(
            sample_information={
                "sample_id" : sample_id,
                "scan_id"   : str(result.inserted_id),
                "image_url" : image_url,
                "scanned_at": scan_timestamp.isoformat(),
            },
            rice_type_info=RiceTypeInfo(
                comment_encoded = round(comment_encoded_pred, 3),
                rice_type       = rice_type_label,
            ),
            predictions=prediction_map,
            grain_characteristics=GrainCharacteristics(
                total_grains  = round(preds.get("Count",        0.0), 2),
                broken_grains = round(preds.get("Broken_Count", 0.0), 2),
                long_grains   = round(preds.get("Long_Count",   0.0), 2),
                medium_grains = round(preds.get("Medium_Count", 0.0), 2),
            ),
            defective_grains=DefectiveGrains(
                black_grains    = round(preds.get("Black_Count",  0.0), 2),
                chalky_grains   = round(preds.get("Chalky_Count", 0.0), 2),
                red_grains      = round(preds.get("Red_Count",    0.0), 2),
                yellow_grains   = round(preds.get("Yellow_Count", 0.0), 2),
                green_grains    = round(preds.get("Green_Count",  0.0), 2),
                total_defective = round(defect_count, 2),
            ),
            grain_measurements=GrainMeasurements(
                average_length     = round(preds.get("WK_Length_Average",   0.0), 3),
                average_width      = round(preds.get("WK_Width_Average",    0.0), 3),
                length_width_ratio = round(preds.get("WK_LW_Ratio_Average", 0.0), 3),
            ),
            color_characteristics=ColorCharacteristics(
                average_L = round(preds.get("Average_L", 0.0), 2),
                average_a = round(preds.get("Average_a", 0.0), 2),
                average_b = round(preds.get("Average_b", 0.0), 2),
            ),
            conclusion=Conclusion(
                broken_grain_percentage    = round(broken_pct, 2),
                defective_grain_percentage = round(defect_pct, 2),
                overall_quality_category   = quality_category,
                quality_description        = quality_description,
            ),
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR,
                            f"Error processing image: {e}")


# =============================================================================
#  SCAN HISTORY
# =============================================================================

@app.get("/scans", response_model=List[ScanHistoryItem])
async def get_scan_history(
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
):
    db     = await get_database()
    cursor = db[SCANS_COLLECTION].find(
        {"user_id": str(current_user["_id"])}
    ).sort("scanned_at", -1).limit(limit)

    scans = await cursor.to_list(length=limit)
    return [
        ScanHistoryItem(
            id                = str(s["_id"]),
            image_url         = s["image_url"],
            quality_grade     = s.get("quality_category", "Unknown"),
            rice_type         = s.get("rice_type", "Unknown"),
            total_count       = s.get("Count", 0.0),
            broken_percentage = s.get("broken_percentage", 0.0),
            defect_percentage = s.get("defect_percentage", 0.0),
            scanned_at        = s["scanned_at"],
        )
        for s in scans
    ]


@app.get("/scans/{scan_id}", response_model=PredictionResponse)
async def get_scan_details(
    scan_id: str,
    current_user: dict = Depends(get_current_user),
):
    db = await get_database()
    try:
        oid = ObjectId(scan_id)
    except Exception:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid scan ID format")

    scan = await db[SCANS_COLLECTION].find_one(
        {"_id": oid, "user_id": str(current_user["_id"])}
    )
    if not scan:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Scan not found")

    defect_count = sum(scan.get(t, 0.0) for t in
                       ["Black_Count", "Chalky_Count", "Red_Count",
                        "Yellow_Count", "Green_Count"])

    return PredictionResponse(
        sample_information={
            "sample_id" : scan.get("sample_id", ""),
            "scan_id"   : str(scan["_id"]),
            "image_url" : scan["image_url"],
            "scanned_at": scan["scanned_at"],
        },
        rice_type_info=RiceTypeInfo(
            comment_encoded = scan.get("comment_encoded", 0.0),
            rice_type       = scan.get("rice_type", "Unknown"),
        ),
        predictions={
            key: round(float(scan.get(key, 0.0)), 6)
            for key in output_targets
            if key in scan
        },
        grain_characteristics=GrainCharacteristics(
            total_grains  = round(scan.get("Count",        0.0), 2),
            broken_grains = round(scan.get("Broken_Count", 0.0), 2),
            long_grains   = round(scan.get("Long_Count",   0.0), 2),
            medium_grains = round(scan.get("Medium_Count", 0.0), 2),
        ),
        defective_grains=DefectiveGrains(
            black_grains    = round(scan.get("Black_Count",  0.0), 2),
            chalky_grains   = round(scan.get("Chalky_Count", 0.0), 2),
            red_grains      = round(scan.get("Red_Count",    0.0), 2),
            yellow_grains   = round(scan.get("Yellow_Count", 0.0), 2),
            green_grains    = round(scan.get("Green_Count",  0.0), 2),
            total_defective = round(defect_count, 2),
        ),
        grain_measurements=GrainMeasurements(
            average_length     = round(scan.get("WK_Length_Average",   0.0), 3),
            average_width      = round(scan.get("WK_Width_Average",    0.0), 3),
            length_width_ratio = round(scan.get("WK_LW_Ratio_Average", 0.0), 3),
        ),
        color_characteristics=ColorCharacteristics(
            average_L = round(scan.get("Average_L", 0.0), 2),
            average_a = round(scan.get("Average_a", 0.0), 2),
            average_b = round(scan.get("Average_b", 0.0), 2),
        ),
        conclusion=Conclusion(
            broken_grain_percentage    = round(scan.get("broken_percentage", 0.0), 2),
            defective_grain_percentage = round(scan.get("defect_percentage", 0.0), 2),
            overall_quality_category   = scan.get("quality_category", "Unknown"),
            quality_description        = scan.get("quality_description", ""),
        ),
    )


@app.delete("/scans/{scan_id}")
async def delete_scan(
    scan_id: str,
    current_user: dict = Depends(get_current_user),
):
    db = await get_database()
    try:
        oid = ObjectId(scan_id)
    except Exception:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid scan ID format")

    result = await db[SCANS_COLLECTION].delete_one(
        {"_id": oid, "user_id": str(current_user["_id"])}
    )
    if result.deleted_count == 0:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Scan not found")

    return {"message": "Scan deleted successfully"}


# =============================================================================
#  CHATBOT
# =============================================================================

@app.post("/chat", response_model=ChatResponse)
async def rice_expert_chat(
    chat_request: ChatRequest,
    current_user: dict = Depends(get_current_user),
):
    try:
        response = openai_client.chat.completions.create(
            model    = "gpt-4",
            messages = [
                {
                    "role"   : "system",
                    "content": (
                        "You are an expert assistant specialised in rice quality assessment. "
                        "Topics: grain measurements, broken rice, chalkiness, moisture, milling, "
                        "grading standards, varieties, cultivation, storage, nutrition, and markets. "
                        "When users share measurements, classify quality as: "
                        "Premium / Good / Medium / Fair / Poor. "
                        "If unrelated to rice, redirect politely. "
                        "IMPORTANT: reply in 60 words or fewer."
                    ),
                },
                {"role": "user", "content": chat_request.question},
            ],
            max_tokens  = 100,
            temperature = 0.7,
        )
        answer = response.choices[0].message.content
        words  = answer.split()
        if len(words) > 60:
            answer = " ".join(words[:60]) + "..."

        return ChatResponse(answer=answer, timestamp=datetime.utcnow().isoformat())

    except Exception as e:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR,
                            f"Chat error: {e}")


# =============================================================================
#  HEALTH CHECK
# =============================================================================

@app.get("/health")
async def health_check():
    try:
        await mongodb.client.admin.command("ping")
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {e}"

    return {
        "status"          : "healthy",
        "database"        : db_status,
        "onnx_model"      : "loaded" if onnx_session      is not None else "not loaded",
        "model_info"      : {
            "architecture": "ConvNeXtV2-Nano + Comment Embedding",
            "num_targets" : len(output_targets),
            "img_size"    : f"{IMG_H}×{IMG_W}",
            "targets"     : output_targets,
        },
        "timestamp"       : datetime.utcnow().isoformat(),
    }


# =============================================================================
#  Run with:  uvicorn app:app --reload
# =============================================================================