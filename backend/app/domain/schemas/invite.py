from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class InviteStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    declined = "declined"
    revoked = "revoked"
    expired = "expired"

class InviteBase(BaseModel):
    pass

class InviteCreate(InviteBase):
    pass

class Invite(InviteBase):
    id: str
    coupleId: str
    tokenHash: str
    status: InviteStatus
    expiresAt: datetime
    createdAt: datetime

class InvitePreviewResponse(BaseModel):
    inviterNickname: str
    status: InviteStatus
    expiresAt: datetime

class AcceptInviteRequest(BaseModel):
    token: str
