from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from enum import Enum

class CoupleStatus(str, Enum):
    solo = "solo"
    connected = "connected"

class ParticipantRole(str, Enum):
    creator = "creator"
    invitee = "invitee"

class ParticipantBase(BaseModel):
    nickname: str
    role: ParticipantRole

class ParticipantCreate(ParticipantBase):
    pass

class Participant(ParticipantBase):
    id: str
    linkedUserId: Optional[str] = None
    createdAt: datetime

class CoupleSpaceBase(BaseModel):
    pass

class CoupleSpace(CoupleSpaceBase):
    id: str
    status: CoupleStatus
    participants: List[Participant]
    createdAt: datetime
    updatedAt: datetime
