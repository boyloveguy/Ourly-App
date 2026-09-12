from fastapi import APIRouter, Depends
from typing import List
from datetime import datetime, timezone, timedelta
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.date_plan import DatePlan, DatePlanCreate, DatePlanUpdate, CompleteMomentRequest, CompleteMomentResponse, PlanStatus
from app.core.errors import not_found, validation_error
from app.infrastructure.mock_db import mock_users

router = APIRouter(prefix="/date-plans", tags=["Date Plans"])

mock_plans = {}


def build_demo_plan(uid: str) -> DatePlan:
    now = datetime.now(timezone.utc)
    return DatePlan(
        id="demo-anniversary-perfect-moment",
        userId=uid,
        recommendationId="recommendation-da-nang-son-tra-marina",
        placeId="da-nang-son-tra-marina",
        occasion="Anniversary",
        timeline=[
            "18:00 — Dinner tại không gian cozy, romantic",
            "19:15 — Dessert: Cheesecake Emma yêu thích",
            "20:00 — Beach Walk yên tĩnh lúc hoàng hôn",
        ],
        estimatedDuration="2.5–3 giờ",
        estimatedCost={"amount": 480000, "currency": "VND"},
        secretIdea="Mang theo hoa Tulip cô ấy thích 💌",
        plannedTime=now + timedelta(days=3),
        status=PlanStatus.suggested,
        createdAt=now,
        updatedAt=now,
    )

@router.post("", response_model=DatePlan)
def create_date_plan(plan_in: DatePlanCreate, uid: str = Depends(get_current_user_id)):
    plan_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    plan = DatePlan(
        id=plan_id,
        userId=uid,
        status=PlanStatus.suggested,
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
    if uid not in mock_plans or not mock_plans[uid]:
        mock_plans[uid] = [build_demo_plan(uid)]
    return mock_plans.get(uid, [])


@router.patch("/{plan_id}", response_model=DatePlan)
def update_plan(plan_id: str, update: DatePlanUpdate, uid: str = Depends(get_current_user_id)):
    user_plans = mock_plans.get(uid, [])
    plan = next((p for p in user_plans if p.id == plan_id), None)
    if not plan:
        raise not_found("DatePlan")

    if update.status is not None:
        plan.status = update.status
    if update.plannedTime is not None:
        plan.plannedTime = update.plannedTime
    plan.updatedAt = datetime.now(timezone.utc)
    return plan

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

    user_state = mock_users.setdefault(uid, {"uid": uid})
    user_state["lovePoints"] = 680
    user_state["currentStreak"] = 30
    user_state["boyfriendOfTheYearUnlocked"] = True
    if req.feedback is not None:
        user_state["lastMomentFeedback"] = req.feedback.value
    
    return CompleteMomentResponse(
        planId=plan_id,
        lovePointsEarned=50,
        totalLovePoints=680,
        currentStreak=30,
        milestoneReached="Boyfriend of the Year unlocked!"
    )
