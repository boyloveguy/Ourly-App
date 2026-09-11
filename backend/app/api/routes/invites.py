from fastapi import APIRouter, Depends, Query
from datetime import datetime, timezone, timedelta
import uuid
import secrets
from app.dependencies import get_current_user_id
from app.domain.schemas.invite import Invite, InviteStatus, InvitePreviewResponse, AcceptInviteRequest
from app.domain.schemas.couple import CoupleStatus, ParticipantRole
from app.core.errors import validation_error, not_found, forbidden
from app.infrastructure.firestore_repo import FirestoreRepo

router = APIRouter(tags=["Invites"])

def get_couple_for_user(uid: str):
    couple = FirestoreRepo.get_active_couple_for_user(uid)
    if not couple:
        raise not_found("CoupleSpace")
    return couple

@router.post("/couples/{coupleId}/invites", response_model=Invite)
def create_invite(coupleId: str, uid: str = Depends(get_current_user_id)):
    couple = get_couple_for_user(uid)
    if couple.id != coupleId:
        raise forbidden()
        
    if couple.status == CoupleStatus.connected:
        raise validation_error("Couple space is already full.")

    # Revoke old pending invites for this couple
    FirestoreRepo.revoke_pending_invites_for_couple(coupleId)

    # Generate readable 4-char code like LV-8K2M
    chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    rand_part = "".join(secrets.choice(chars) for _ in range(4))
    token = f"LV-{rand_part}"
    now = datetime.now(timezone.utc)
    
    invite = Invite(
        id=str(uuid.uuid4()),
        coupleId=coupleId,
        tokenHash=token,
        status=InviteStatus.pending,
        expiresAt=now + timedelta(hours=72),
        createdAt=now
    )
    FirestoreRepo.save_invite(invite)
    return invite

@router.delete("/couples/{coupleId}/invites/{inviteId}")
def revoke_invite(coupleId: str, inviteId: str, uid: str = Depends(get_current_user_id)):
    couple = get_couple_for_user(uid)
    if couple.id != coupleId:
        raise forbidden()
        
    inv = FirestoreRepo.get_invite(inviteId)
    if not inv or inv.coupleId != coupleId:
        raise not_found("Invite")
        
    inv.status = InviteStatus.revoked
    FirestoreRepo.update_invite(inv)
    return {"status": "ok"}

@router.post("/invites/preview", response_model=InvitePreviewResponse)
def preview_invite(req: AcceptInviteRequest, uid: str = Depends(get_current_user_id)):
    inv = FirestoreRepo.get_invite_by_token(req.token)
    if not inv:
        raise validation_error("Invalid invite code.")
    
    couple = FirestoreRepo.get_couple(inv.coupleId)
    creator = next((p for p in couple.participants if p.role == ParticipantRole.creator), None) if couple else None
    
    return InvitePreviewResponse(
        inviterNickname=creator.nickname if creator else "Someone",
        status=inv.status,
        expiresAt=inv.expiresAt
    )

@router.post("/invites/accept")
def accept_invite(
    req: AcceptInviteRequest, 
    nickname: str, 
    archive_solo: bool = Query(False),
    uid: str = Depends(get_current_user_id)
):
    inv = FirestoreRepo.get_invite_by_token(req.token)
    if not inv:
        raise validation_error("Invalid invite code.")
        
    couple = FirestoreRepo.get_couple(inv.coupleId)
    if not couple:
        raise not_found("CoupleSpace")

    # Prevent creator from accepting their own invite
    creator = next((p for p in couple.participants if p.role == ParticipantRole.creator), None)
    if creator and creator.linkedUserId == uid:
        raise validation_error("You cannot accept your own invite.")

    # Idempotent retry: if same user already accepted this invite
    if inv.status == InviteStatus.accepted:
        existing_part = next((p for p in couple.participants if p.linkedUserId == uid), None)
        if existing_part:
            return {"status": "success", "coupleId": couple.id}
        raise validation_error("Invite has already been used.")

    # Check if user already has an active space
    current_couple = FirestoreRepo.get_active_couple_for_user(uid)
    if current_couple:
        if current_couple.status == CoupleStatus.solo and archive_solo:
            # Archive solo space
            current_couple.status = CoupleStatus.archived
            FirestoreRepo.update_couple(current_couple)
        else:
            raise validation_error("You already belong to an active couple space.")
        
    if inv.status != InviteStatus.pending or inv.expiresAt < datetime.now(timezone.utc):
        raise validation_error("Invite is no longer valid or has expired.")
        
    # Ensure not full
    if couple.status == CoupleStatus.connected:
        raise validation_error("Space is already full.")
        
    # Link placeholder participant B
    placeholder = next((p for p in couple.participants if p.linkedUserId is None), None)
    if not placeholder:
        raise validation_error("No available participant slot.")

    placeholder.linkedUserId = uid
    placeholder.nickname = nickname
    
    couple.status = CoupleStatus.connected
    FirestoreRepo.update_couple(couple)
    
    inv.status = InviteStatus.accepted
    FirestoreRepo.update_invite(inv)
    
    FirestoreRepo.set_user_active_couple(uid, couple.id)
    FirestoreRepo.save_or_update_user(uid, {"nickname": nickname, "activeCoupleId": couple.id})
    
    return {"status": "success", "coupleId": couple.id}
