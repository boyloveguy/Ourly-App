from fastapi import APIRouter, Depends
from typing import List
from datetime import datetime, timezone
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.date_plan import DatePlan, DatePlanCreate, DatePlanUpdate, CompleteMomentRequest, CompleteMomentResponse, PlanStatus
from app.core.errors import not_found, validation_error

router = APIRouter(prefix="/date-plans", tags=["Date Plans"])

mock_plans = {}

@router.post("", response_model=DatePlan)
def create_date_plan(plan_in: DatePlanCreate, uid: str = Depends(get_current_user_id)):
    plan_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    plan = DatePlan(
        id=plan_id,
        userId=uid,
        status=PlanStatus.draft,
        createdAt=now,
        updatedAt=now,
        **plan_in.model_dump()
    )
    if uid not in mock_plans:
        mock_plans[uid] = []
    mock_plans[uid].append(plan)
    return plan

@router.get("", response_model=List[DatePlan])
def get_date_plans(uid: str = Depends(get_current_user_id)):
    return mock_plans.get(uid, [])

@router.patch("/{plan_id}/complete", response_model=CompleteMomentResponse)
def complete_plan(plan_id: str, req: CompleteMomentRequest, uid: str = Depends(get_current_user_id)):
    user_plans = mock_plans.get(uid, [])
    plan = next((p for p in user_plans if p.id == plan_id), None)
    
    if not plan:
        raise not_found("DatePlan")
        
    if plan.status == PlanStatus.completed:
        raise validation_error("PLAN_ALREADY_COMPLETED", {"planId": plan_id})
        
    plan.status = PlanStatus.completed
    plan.updatedAt = datetime.now(timezone.utc)
    
    return CompleteMomentResponse(
        planId=plan_id,
        lovePointsEarned=50,
        totalLovePoints=150,
        currentStreak=3,
        milestoneReached="3-day Streak! Keep the love glowing."
    )
