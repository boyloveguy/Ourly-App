from fastapi import APIRouter, Depends
from typing import List
from datetime import datetime, timezone
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.partner import Partner, PartnerCreate, PartnerUpdate, PartnerMemory, PartnerMemoryCreate
from app.core.errors import validation_error, not_found

router = APIRouter(prefix="/partners", tags=["Partners"])

# In-memory mock DB for demo
mock_partners = {}
mock_memories = {}

@router.post("", response_model=Partner)
def create_partner(partner_in: PartnerCreate, uid: str = Depends(get_current_user_id)):
    if len(partner_in.preferences) < 2:
        raise validation_error("Minimum 2 preferences are required for recommendation flow.")
    
    partner_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    partner = Partner(
        id=partner_id,
        createdAt=now,
        updatedAt=now,
        **partner_in.model_dump()
    )
    if uid not in mock_partners:
        mock_partners[uid] = []
    mock_partners[uid].append(partner)
    return partner

@router.get("", response_model=List[Partner])
def get_partners(uid: str = Depends(get_current_user_id)):
    return mock_partners.get(uid, [])

@router.post("/{partner_id}/memories", response_model=PartnerMemory)
def create_memory(partner_id: str, memory_in: PartnerMemoryCreate, uid: str = Depends(get_current_user_id)):
    # Verify partner ownership
    user_partners = mock_partners.get(uid, [])
    if not any(p.id == partner_id for p in user_partners):
        raise not_found("Partner")

    memory_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    memory = PartnerMemory(
        id=memory_id,
        createdAt=now,
        updatedAt=now,
        **memory_in.model_dump()
    )
    
    if partner_id not in mock_memories:
        mock_memories[partner_id] = []
    mock_memories[partner_id].append(memory)
    return memory

@router.get("/{partner_id}/memories", response_model=List[PartnerMemory])
def get_memories(partner_id: str, uid: str = Depends(get_current_user_id)):
    user_partners = mock_partners.get(uid, [])
    if not any(p.id == partner_id for p in user_partners):
        raise not_found("Partner")
    return mock_memories.get(partner_id, [])
