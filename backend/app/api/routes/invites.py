from fastapi import APIRouter, Depends
from datetime import datetime, timezone, timedelta
import uuid
import secrets
from app.dependencies import get_current_user_id
from app.domain.schemas.invite import Invite, InviteStatus, InvitePreviewResponse, AcceptInviteRequest
from app.domain.schemas.couple import CoupleStatus
from app.core.errors import validation_error, not_found, AppException
from app.infrastructure.mock_db import mock_couples, mock_user_couple, mock_invites

router = APIRouter(tags=["Invites"])

def get_couple_for_user(uid: str):
    cid = mock_user_couple.get(uid)
    if not cid or cid not in mock_couples:
        raise not_found("CoupleSpace")
    return mock_couples[cid]

@router.post("/couples/{coupleId}/invites", response_model=Invite)
def create_invite(coupleId: str, uid: str = Depends(get_current_user_id)):
    couple = get_couple_for_user(uid)
    if couple.id != coupleId:
        raise validation_error("Not authorized to create invite for this space.")
        
    if couple.status == CoupleStatus.connected:
        raise validation_error("Couple space is already full.")

    # Check for existing pending invite
    for inv in mock_invites.values():
        if inv.coupleId == coupleId and inv.status == InviteStatus.pending:
            if inv.expiresAt > datetime.now(timezone.utc):
                # Revoke old invite
                inv.status = InviteStatus.revoked

    token = f"LV-{secrets.token_hex(4).upper()}" # Example: LV-8K2M9X
    
    invite = Invite(
        id=str(uuid.uuid4()),
        coupleId=coupleId,
        tokenHash=token, # In real app, we hash it. Here we store plain for demo.
        status=InviteStatus.pending,
        expiresAt=datetime.now(timezone.utc) + timedelta(hours=72),
        createdAt=datetime.now(timezone.utc)
    )
    mock_invites[invite.id] = invite
    return invite

@router.delete("/couples/{coupleId}/invites/{inviteId}")
def revoke_invite(coupleId: str, inviteId: str, uid: str = Depends(get_current_user_id)):
    couple = get_couple_for_user(uid)
    if couple.id != coupleId:
        raise validation_error("Not authorized.")
        
    inv = mock_invites.get(inviteId)
    if not inv or inv.coupleId != coupleId:
        raise not_found("Invite")
        
    inv.status = InviteStatus.revoked
    return {"status": "ok"}

@router.post("/invites/preview", response_model=InvitePreviewResponse)
def preview_invite(req: AcceptInviteRequest, uid: str = Depends(get_current_user_id)):
    inv = next((i for i in mock_invites.values() if i.tokenHash == req.token), None)
    if not inv:
        raise validation_error("Invalid invite code.")
    
    couple = mock_couples.get(inv.coupleId)
    creator = next((p for p in couple.participants if p.linkedUserId is not None), None)
    
    return InvitePreviewResponse(
        inviterNickname=creator.nickname if creator else "Someone",
        status=inv.status,
        expiresAt=inv.expiresAt
    )

@router.post("/invites/accept")
def accept_invite(req: AcceptInviteRequest, nickname: str, uid: str = Depends(get_current_user_id)):
    if uid in mock_user_couple:
        raise validation_error("You already belong to a couple space.")
        
    inv = next((i for i in mock_invites.values() if i.tokenHash == req.token), None)
    if not inv:
        raise validation_error("Invalid invite code.")
        
    if inv.status != InviteStatus.pending or inv.expiresAt < datetime.now(timezone.utc):
        raise validation_error("Invite is no longer valid or has expired.")
        
    couple = mock_couples.get(inv.coupleId)
    
    # Ensure not full
    if couple.status == CoupleStatus.connected:
        raise validation_error("Space is already full.")
        
    # Link placeholder
    placeholder = next(p for p in couple.participants if p.linkedUserId is None)
    placeholder.linkedUserId = uid
    placeholder.nickname = nickname
    
    couple.status = CoupleStatus.connected
    inv.status = InviteStatus.accepted
    mock_user_couple[uid] = couple.id
    
    return {"status": "success", "coupleId": couple.id}
