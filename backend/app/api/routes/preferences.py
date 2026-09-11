from fastapi import APIRouter, Depends
from typing import List
from datetime import datetime, timezone
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.preference import Preference, PreferenceCreate, PreferenceUpdate, PreferenceVisibility, PreferenceSource
from app.core.errors import validation_error, not_found, forbidden
from app.infrastructure.firestore_repo import FirestoreRepo

router = APIRouter(tags=["Preferences"])

def get_couple_for_user(coupleId: str, uid: str):
    couple = FirestoreRepo.get_couple(coupleId)
    if not couple:
        raise not_found("CoupleSpace")
    member_uids = [p.linkedUserId for p in couple.participants if p.linkedUserId is not None]
    if uid not in member_uids:
        raise forbidden()
    return couple

@router.post("/couples/{coupleId}/preferences", response_model=Preference)
def create_preference(coupleId: str, pref_in: PreferenceCreate, uid: str = Depends(get_current_user_id)):
    couple = get_couple_for_user(coupleId, uid)
        
    subject = next((p for p in couple.participants if p.id == pref_in.subjectParticipantId), None)
    if not subject:
        raise validation_error("Invalid subject participant.")
        
    source = PreferenceSource.selfDeclared if subject.linkedUserId == uid else PreferenceSource.partnerObserved
    
    # Surprise is always strictly private to the creator
    visibility = pref_in.visibility
    if pref_in.type.lower() == "surprise":
        visibility = PreferenceVisibility.private

    now = datetime.now(timezone.utc)
    pref_data = pref_in.model_dump()
    pref_data["visibility"] = visibility

    pref = Preference(
        id=str(uuid.uuid4()),
        coupleId=coupleId,
        createdByUserId=uid,
        source=source,
        createdAt=now,
        updatedAt=now,
        **pref_data
    )
    
    FirestoreRepo.save_preference(pref)
    return pref

@router.get("/couples/{coupleId}/preferences", response_model=List[Preference])
def get_preferences(coupleId: str, uid: str = Depends(get_current_user_id)):
    # Check that current user is a participant of the couple space
    get_couple_for_user(coupleId, uid)
        
    prefs = FirestoreRepo.get_preferences_for_couple(coupleId)
    
    # Filter based on visibility & surprise protection
    result = []
    for p in prefs:
        # Surprise is always private to creator, partner CANNOT see it!
        if p.type.lower() == "surprise":
            if p.createdByUserId == uid:
                result.append(p)
            continue

        if p.visibility == PreferenceVisibility.shared:
            result.append(p)
        elif p.visibility == PreferenceVisibility.private and p.createdByUserId == uid:
            result.append(p)
            
    return result

@router.patch("/couples/{coupleId}/preferences/{preferenceId}", response_model=Preference)
def update_preference(
    coupleId: str,
    preferenceId: str,
    pref_update: PreferenceUpdate,
    uid: str = Depends(get_current_user_id)
):
    get_couple_for_user(coupleId, uid)
    
    pref = FirestoreRepo.get_preference(coupleId, preferenceId)
    if not pref:
        raise not_found("Preference")
        
    # Only creator can update
    if pref.createdByUserId != uid:
        raise forbidden()
        
    if pref_update.value is not None:
        pref.value = pref_update.value
    if pref_update.visibility is not None:
        # Cannot make surprise shared
        if pref.type.lower() == "surprise" and pref_update.visibility == PreferenceVisibility.shared:
            raise validation_error("Surprise items must remain private.")
        pref.visibility = pref_update.visibility
        
    FirestoreRepo.update_preference(pref)
    return pref

@router.delete("/couples/{coupleId}/preferences/{preferenceId}")
def delete_preference(
    coupleId: str,
    preferenceId: str,
    uid: str = Depends(get_current_user_id)
):
    get_couple_for_user(coupleId, uid)
    
    pref = FirestoreRepo.get_preference(coupleId, preferenceId)
    if not pref:
        raise not_found("Preference")
        
    # Only creator can delete
    if pref.createdByUserId != uid:
        raise forbidden()
        
    FirestoreRepo.delete_preference(coupleId, preferenceId)
    return {"status": "deleted", "id": preferenceId}
