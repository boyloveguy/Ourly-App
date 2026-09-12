import re
import uuid
from typing import Optional
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from fastapi import APIRouter

from app.core.security import hash_password, verify_password
from app.core.errors import bad_request, unauthenticated, AppException
from app.infrastructure.firestore_repo import FirestoreRepo
from app.api.routes.users import UserProfileResponse

router = APIRouter(prefix="/auth", tags=["Auth"])

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")

class RegisterRequest(BaseModel):
    email: str = Field(..., description="User's email address")
    password: str = Field(..., min_length=6, description="User password, minimum 6 characters")
    nickname: Optional[str] = Field(None, description="Optional user display name")
    gender: Optional[str] = Field(None, description="Optional user gender ('male', 'female', 'other')")

class LoginRequest(BaseModel):
    email: str = Field(..., description="User's email address")
    password: str = Field(..., description="User password")

class AuthResponse(BaseModel):
    token: str
    user: UserProfileResponse

@router.post("/register", response_model=AuthResponse, status_code=201)
def register(req: RegisterRequest):
    norm_email = req.email.strip().lower()
    
    # 1. Validate email format
    if not EMAIL_REGEX.match(norm_email):
        raise bad_request("Địa chỉ email không đúng định dạng.")
        
    # 2. Validate password length
    if len(req.password) < 6:
        raise bad_request("Mật khẩu phải có ít nhất 6 ký tự.")
        
    # 3. Check for existing user with this email
    existing_user = FirestoreRepo.get_user_by_email(norm_email)
    if existing_user:
        raise AppException(
            status_code=400,
            code="EMAIL_ALREADY_EXISTS",
            detail="Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.",
        )
        
    # 4. Create new user with hashed password
    uid = f"user-{uuid.uuid4().hex[:12]}"
    now_str = datetime.now(timezone.utc).isoformat()
    clean_nickname = req.nickname.strip() if req.nickname and req.nickname.strip() else norm_email.split("@")[0].capitalize()
    
    hashed_pw = hash_password(req.password)
    
    user_data = {
        "uid": uid,
        "email": norm_email,
        "hashedPassword": hashed_pw,
        "nickname": clean_nickname,
        "gender": req.gender,
        "activeCoupleId": None,
        "createdAt": now_str,
    }
    
    saved = FirestoreRepo.save_or_update_user(uid, user_data)
    
    user_profile = UserProfileResponse(
        uid=uid,
        email=saved.get("email"),
        nickname=saved.get("nickname"),
        birthday=saved.get("birthday"),
        avatar=saved.get("avatar"),
        gender=saved.get("gender"),
        datingStartDate=saved.get("datingStartDate"),
        activeCoupleId=saved.get("activeCoupleId"),
        createdAt=saved.get("createdAt"),
    )
    
    return AuthResponse(token=uid, user=user_profile)

@router.post("/login", response_model=AuthResponse)
def login(req: LoginRequest):
    norm_email = req.email.strip().lower()
    
    # 1. Basic validation
    if not norm_email or not req.password:
        raise AppException(
            status_code=401,
            code="INVALID_CREDENTIALS",
            detail="Email hoặc mật khẩu không chính xác.",
        )
        
    # 2. Look up user by email
    user = FirestoreRepo.get_user_by_email(norm_email)
    if not user:
        raise AppException(
            status_code=401,
            code="INVALID_CREDENTIALS",
            detail="Email hoặc mật khẩu không chính xác.",
        )
        
    # 3. Check hashed password
    stored_hash = user.get("hashedPassword")
    if not stored_hash or not verify_password(req.password, stored_hash):
        raise AppException(
            status_code=401,
            code="INVALID_CREDENTIALS",
            detail="Email hoặc mật khẩu không chính xác.",
        )
        
    uid = user["uid"]
    user_profile = UserProfileResponse(
        uid=uid,
        email=user.get("email"),
        nickname=user.get("nickname"),
        birthday=user.get("birthday"),
        avatar=user.get("avatar"),
        gender=user.get("gender"),
        datingStartDate=user.get("datingStartDate"),
        activeCoupleId=user.get("activeCoupleId"),
        createdAt=user.get("createdAt"),
    )
    
    return AuthResponse(token=uid, user=user_profile)
