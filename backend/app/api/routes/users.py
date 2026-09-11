from fastapi import APIRouter, Depends
from typing import Optional
from pydantic import BaseModel
from app.dependencies import get_current_user_id
from app.infrastructure.mock_db import mock_user_couple

router = APIRouter(tags=["Users"])

class UserProfileResponse(BaseModel):
    uid: str
    activeCoupleId: Optional[str] = None

@router.get("/me", response_model=UserProfileResponse)
def get_me(uid: str = Depends(get_current_user_id)):
    couple_id = mock_user_couple.get(uid)
    return UserProfileResponse(uid=uid, activeCoupleId=couple_id)
