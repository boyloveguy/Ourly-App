from fastapi import APIRouter, Depends, Request
from typing import Optional
from pydantic import BaseModel
from datetime import datetime, timezone
from app.dependencies import get_current_user_id
from app.infrastructure.firestore_repo import FirestoreRepo

router = APIRouter(tags=["Users"])

class UserProfileResponse(BaseModel):
    uid: str
    email: Optional[str] = None
    nickname: Optional[str] = None
    birthday: Optional[str] = None
    avatar: Optional[str] = None
    gender: Optional[str] = None
    datingStartDate: Optional[str] = None
    activeCoupleId: Optional[str] = None
    createdAt: Optional[str] = None

class UserProfileUpdate(BaseModel):
    nickname: Optional[str] = None
    birthday: Optional[str] = None
    avatar: Optional[str] = None
    gender: Optional[str] = None
    datingStartDate: Optional[str] = None
    email: Optional[str] = None

@router.get("/users/me", response_model=UserProfileResponse)
@router.get("/me", response_model=UserProfileResponse)
def get_me(uid: str = Depends(get_current_user_id)):
    user_doc = FirestoreRepo.get_user(uid)
    if not user_doc:
        # Default name extraction for simulated or new tokens
        prefix = uid.replace("user-a-", "").replace("user-b-", "").replace("user-", "")
        default_name = prefix.capitalize() if prefix else "User"
        default_email = f"{prefix}@example.com" if prefix else None
        
        user_doc = FirestoreRepo.save_or_update_user(uid, {
            "uid": uid,
            "email": default_email,
            "nickname": default_name,
            "activeCoupleId": None,
            "createdAt": datetime.now(timezone.utc).isoformat()
        })
        
    return UserProfileResponse(
        uid=uid,
        email=user_doc.get("email"),
        nickname=user_doc.get("nickname"),
        birthday=user_doc.get("birthday"),
        avatar=user_doc.get("avatar"),
        gender=user_doc.get("gender"),
        datingStartDate=user_doc.get("datingStartDate"),
        activeCoupleId=user_doc.get("activeCoupleId"),
        createdAt=user_doc.get("createdAt")
    )

@router.patch("/users/me", response_model=UserProfileResponse)
@router.put("/users/me", response_model=UserProfileResponse)
@router.patch("/me", response_model=UserProfileResponse)
@router.put("/me", response_model=UserProfileResponse)
def update_me(update_data: UserProfileUpdate, uid: str = Depends(get_current_user_id)):
    saved = FirestoreRepo.save_or_update_user(uid, update_data.model_dump(exclude_unset=True))
    return UserProfileResponse(
        uid=uid,
        email=saved.get("email"),
        nickname=saved.get("nickname"),
        birthday=saved.get("birthday"),
        avatar=saved.get("avatar"),
        gender=saved.get("gender"),
        datingStartDate=saved.get("datingStartDate"),
        activeCoupleId=saved.get("activeCoupleId"),
        createdAt=saved.get("createdAt")
    )

class AvatarUploadResponse(BaseModel):
    avatar_url: str
    message: str

@router.post("/users/avatar", response_model=AvatarUploadResponse)
@router.post("/avatar", response_model=AvatarUploadResponse)
async def upload_user_avatar(
    request: Request,
    uid: str = Depends(get_current_user_id)
):
    from app.infrastructure.cloudinary_service import CloudinaryService
    import base64

    content: Optional[bytes] = None
    content_type = request.headers.get("content-type", "")

    if "multipart/form-data" in content_type:
        form = await request.form()
        uploaded_file = form.get("file")
        if uploaded_file and hasattr(uploaded_file, "read"):
            content = await uploaded_file.read()
    else:
        try:
            body = await request.json()
            if isinstance(body, dict) and "data" in body:
                raw_b64 = str(body["data"])
                if "base64," in raw_b64:
                    raw_b64 = raw_b64.split("base64,")[1]
                content = base64.b64decode(raw_b64)
        except Exception as e:
            print("[Avatar Upload] JSON parsing error:", e)

    if not content:
        return AvatarUploadResponse(avatar_url="", message="No valid image provided")

    # If Cloudinary is configured, upload and get URL
    if CloudinaryService.is_configured():
        try:
            avatar_url = CloudinaryService.upload_image(content, user_id=uid)
            FirestoreRepo.save_or_update_user(uid, {"avatar": avatar_url})
            return AvatarUploadResponse(avatar_url=avatar_url, message="Uploaded to Cloudinary successfully")
        except Exception as e:
            print(f"[Cloudinary] Upload error: {e}")

    # Fallback if Cloudinary is not configured or fails
    b64_str = base64.b64encode(content).decode("utf-8")
    fallback_url = f"data:image/jpeg;base64,{b64_str}"
    FirestoreRepo.save_or_update_user(uid, {"avatar": fallback_url})
    return AvatarUploadResponse(
        avatar_url=fallback_url,
        message="Saved locally (Cloudinary credentials not yet configured in .env)"
    )
