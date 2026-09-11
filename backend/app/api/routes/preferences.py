from fastapi import APIRouter, Depends
from typing import List
from datetime import datetime, timezone
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.preference import Preference, PreferenceCreate, PreferenceUpdate, PreferenceVisibility, PreferenceSource
from app.core.errors import validation_error, not_found, AppException
from app.infrastructure.mock_db import mock_couples, mock_user_couple, mock_preferences

router = APIRouter(tags=["Preferences"])

def get_couple_for_user(uid: str):
    cid = mock_user_couple.get(uid)
    if not cid or cid not in mock_couples:
        raise not_found("CoupleSpace")
    return mock_couples[cid]

@router.post("/couples/{coupleId}/preferences", response_model=Preference)
def create_preference(coupleId: str, pref_in: PreferenceCreate, uid: str = Depends(get_current_user_id)):
    couple = get_couple_for_user(uid)
    if couple.id != coupleId:
        raise validation_error("Not authorized.")
        
    subject = next((p for p in couple.participants if p.id == pref_in.subjectParticipantId), None)
    if not subject:
        raise validation_error("Invalid subject participant.")
        
    source = PreferenceSource.selfDeclared if subject.linkedUserId == uid else PreferenceSource.partnerObserved
    
    now = datetime.now(timezone.utc)
    pref = Preference(
        id=str(uuid.uuid4()),
        createdByUserId=uid,
        source=source,
        createdAt=now,
        updatedAt=now,
        **pref_in.model_dump()
    )
    
    if coupleId not in mock_preferences:
        mock_preferences[coupleId] = []
    mock_preferences[coupleId].append(pref)
    
    return pref

@router.get("/couples/{coupleId}/preferences", response_model=List[Preference])
def get_preferences(coupleId: str, uid: str = Depends(get_current_user_id)):
    couple = get_couple_for_user(uid)
    if couple.id != coupleId:
        raise validation_error("Not authorized.")
        
    prefs = mock_preferences.get(coupleId, [])
    # Filter based on visibility
    result = []
    for p in prefs:
        if p.visibility == PreferenceVisibility.shared:
            result.append(p)
        elif p.visibility == PreferenceVisibility.private and p.createdByUserId == uid:
            result.append(p)
            
    return result
