from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class PreferenceSource(str, Enum):
    selfDeclared = "selfDeclared"
    partnerObserved = "partnerObserved"

class PreferenceVisibility(str, Enum):
    private = "private"
    shared = "shared"

class PreferenceBase(BaseModel):
    subjectParticipantId: str
    type: str
    value: str
    visibility: PreferenceVisibility = PreferenceVisibility.private

class PreferenceCreate(PreferenceBase):
    pass

class PreferenceUpdate(BaseModel):
    value: Optional[str] = None
    visibility: Optional[PreferenceVisibility] = None

class Preference(PreferenceBase):
    id: str
    createdByUserId: str
    source: PreferenceSource
    createdAt: datetime
    updatedAt: datetime
