from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from enum import Enum
from app.domain.schemas.recommendation import Budget

class PlanStatus(str, Enum):
    suggested = "suggested"
    draft = "draft"
    planned = "planned"
    completed = "completed"
    cancelled = "cancelled"

class FeedbackEnum(str, Enum):
    excited = "excited"
    happy = "happy"
    loved = "loved"

class DatePlanBase(BaseModel):
    recommendationId: str
    placeId: str
    occasion: str
    timeline: List[str]
    estimatedDuration: str
    estimatedCost: Budget
    secretIdea: str
    plannedTime: Optional[datetime] = None

class DatePlanCreate(DatePlanBase):
    pass

class DatePlanUpdate(BaseModel):
    status: Optional[PlanStatus] = None
    plannedTime: Optional[datetime] = None

class CompleteMomentRequest(BaseModel):
    feedback: Optional[FeedbackEnum] = None
    notes: Optional[str] = None

class CompleteMomentResponse(BaseModel):
    planId: str
    lovePointsEarned: int
    totalLovePoints: int
    currentStreak: int
    milestoneReached: Optional[str] = None

class DatePlan(DatePlanBase):
    id: str
    userId: str
    status: PlanStatus
    createdAt: datetime
    updatedAt: datetime
