from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum

class MemoryType(str, Enum):
    favoriteFood = "favoriteFood"
    favoriteDrink = "favoriteDrink"
    favoriteFlower = "favoriteFlower"
    favoritePlace = "favoritePlace"
    hobby = "hobby"
    custom = "custom"

class PartnerMemoryBase(BaseModel):
    type: MemoryType
    value: str
    description: Optional[str] = None

class PartnerMemoryCreate(PartnerMemoryBase):
    pass

class PartnerMemory(PartnerMemoryBase):
    id: str
    createdAt: datetime
    updatedAt: datetime

class PartnerBase(BaseModel):
    name: str
    relationshipType: str = "girlfriend"
    preferences: List[str] = Field(default_factory=list, min_length=2)
    avatarUrl: Optional[str] = None

class PartnerCreate(PartnerBase):
    pass

class PartnerUpdate(BaseModel):
    name: Optional[str] = None
    relationshipType: Optional[str] = None
    preferences: Optional[List[str]] = None
    avatarUrl: Optional[str] = None

class Partner(PartnerBase):
    id: str
    createdAt: datetime
    updatedAt: datetime
