from fastapi import APIRouter, Depends
from datetime import datetime, timezone
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.couple import CoupleSpace, Participant, ParticipantRole, CoupleStatus
from app.core.errors import validation_error, not_found
from app.infrastructure.mock_db import mock_couples, mock_user_couple

router = APIRouter(prefix="/couples", tags=["Couples"])

@router.post("", response_model=CoupleSpace)
def create_solo_couple(nickname: str, uid: str = Depends(get_current_user_id)):
    if uid in mock_user_couple:
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
    
    mock_couples[couple_id] = couple
    mock_user_couple[uid] = couple_id
    
    return couple

@router.get("/current", response_model=CoupleSpace)
def get_current_couple(uid: str = Depends(get_current_user_id)):
    couple_id = mock_user_couple.get(uid)
    if not couple_id or couple_id not in mock_couples:
        raise not_found("CoupleSpace")
    
    return mock_couples[couple_id]
