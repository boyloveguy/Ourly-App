from fastapi import APIRouter, Depends
from typing import Optional
from datetime import datetime, timezone
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.couple import CoupleSpace, Participant, ParticipantRole, CoupleStatus, ParticipantUpdate
from app.core.errors import validation_error, not_found, forbidden
from app.infrastructure.firestore_repo import FirestoreRepo

router = APIRouter(prefix="/couples", tags=["Couples"])

@router.post("", response_model=CoupleSpace)
def create_solo_couple(
    nickname: str,
    avatar: Optional[str] = None,
    birthday: Optional[str] = None,
    uid: str = Depends(get_current_user_id)
):
    active_couple = FirestoreRepo.get_active_couple_for_user(uid)
    if active_couple and active_couple.status != CoupleStatus.archived:
        raise validation_error("User already has an active couple space.")
    
    couple_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    
    # Participant A (Creator)
    part_a = Participant(
        id=str(uuid.uuid4()),
        linkedUserId=uid,
        nickname=nickname,
        role=ParticipantRole.creator,
        createdAt=now
    )
    
    # Participant B (Placeholder)
    part_b = Participant(
        id=str(uuid.uuid4()),
        linkedUserId=None,
        nickname="Partner",
        role=ParticipantRole.invitee,
        createdAt=now
    )
    
    couple = CoupleSpace(
        id=couple_id,
        status=CoupleStatus.solo,
        participants=[part_a, part_b],
        createdAt=now,
        updatedAt=now
    )
    
    FirestoreRepo.save_couple(couple)
    
    user_updates = {
        "activeCoupleId": couple_id,
        "nickname": nickname
    }
    if avatar:
        user_updates["avatar"] = avatar
    if birthday:
        user_updates["birthday"] = birthday
    FirestoreRepo.save_or_update_user(uid, user_updates)
    
    return couple

@router.get("/current", response_model=CoupleSpace)
def get_current_couple(uid: str = Depends(get_current_user_id)):
    couple = FirestoreRepo.get_active_couple_for_user(uid)
    if not couple:
        raise not_found("CoupleSpace")
    
    return couple

@router.patch("/{coupleId}/participants/{participantId}", response_model=Participant)
def update_participant(
    coupleId: str, 
    participantId: str, 
    update_data: ParticipantUpdate, 
    uid: str = Depends(get_current_user_id)
):
    couple = FirestoreRepo.get_couple(coupleId)
    if not couple:
        raise not_found("CoupleSpace")
        
    member_uids = [p.linkedUserId for p in couple.participants if p.linkedUserId is not None]
    if uid not in member_uids:
        raise forbidden()
        
    target_part = next((p for p in couple.participants if p.id == participantId), None)
    if not target_part:
        raise not_found("Participant")
        
    if update_data.nickname is not None:
        target_part.nickname = update_data.nickname
        
    FirestoreRepo.update_couple(couple)
    return target_part
