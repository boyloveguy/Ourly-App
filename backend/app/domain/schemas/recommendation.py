from pydantic import BaseModel, Field
from typing import List, Optional

class Budget(BaseModel):
    amount: float = Field(gt=0)
    currency: str = "VND"

class RecommendationRequest(BaseModel):
    partnerId: str
    occasion: str
    budget: Budget
    context: Optional[str] = None
    excludedPlaceIds: Optional[List[str]] = None

class PlaceBase(BaseModel):
    id: str
    name: str
    city: str
    area: str
    address: str
    imageUrl: Optional[str] = None
    placeType: str
    budgetLevel: int
    estimatedCost: float
    currency: str = "VND"
    tags: List[str] = Field(default_factory=list)
    description: str
    activities: List[str] = Field(default_factory=list)
    openingHours: Optional[str] = None
    active: bool = True

class RecommendationResponse(BaseModel):
    id: str
    place: PlaceBase
    matchTags: List[str]
    estimatedCost: Budget
    personalReason: str
    secretIdea: str
    suggestedActivities: List[str]
    isGenerated: bool = True
