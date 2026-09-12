from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.core.config import settings
from app.core.errors import forbidden, not_found, validation_error
from app.dependencies import get_current_user_id
from app.demo_seed import seed_demo_data, DEMO_ALEX_UID, DEMO_EMMA_UID
from app.infrastructure.mock_db import mock_chat_messages, mock_users

router = APIRouter(prefix="/demo", tags=["Demo"])
plans = {}
notifications = {}
PROMPTS = [
    "Cuối tuần này làm gì với Emma nhỉ? Budget khoảng 500K.",
    "Mình muốn làm gì đó cho Emma mà không nhớ gần đây cô ấy thích gì nữa.",
]

# Prices, images and experiences are illustrative demo fixtures.
IDEAS = [
    {"id": "pottery", "name": "Pottery Workshop", "price": 350000,
     "tags": ["Cozy", "Creative", "Photography"], "area": "Hải Châu, Đà Nẵng",
     "why": "Emma muốn thử làm gốm; không gian Cozy và hoạt động Photography hợp sở thích của cô ấy."},
    {"id": "sunset", "name": "Sunset + Cheesecake", "price": 250000,
     "tags": ["Beach", "Quiet", "Dessert"], "area": "Biển Mỹ Khê, Đà Nẵng",
     "why": "Emma thích biển, không gian yên tĩnh và cheesecake. Một buổi hẹn nhẹ nhàng trong budget."},
    {"id": "cafe", "name": "Hidden Café Date", "price": 200000,
     "tags": ["Cozy", "Quiet", "Dessert"], "area": "Hải Châu, Đà Nẵng",
     "why": "Không gian Cozy, Quiet cùng món tráng miệng Emma yêu thích, đủ thời gian trò chuyện."},
]


def demo_user(uid: str = Depends(get_current_user_id)):
    if not settings.DEMO_MODE or uid not in (DEMO_ALEX_UID, DEMO_EMMA_UID):
        raise forbidden()
    return uid


@router.get("/context")
def context(uid: str = Depends(demo_user)):
    return {"occasion": "Anniversary", "date": (datetime.now(timezone.utc) + timedelta(days=3)).date().isoformat(),
            "daysUntil": 3, "budget": 500000, "prompts": PROMPTS,
            "partner": "Emma" if uid == DEMO_ALEX_UID else "Alex"}


@router.post("/reset")
def reset(uid: str = Depends(demo_user)):
    plans.clear()
    notifications.clear()
    for user_id in (DEMO_ALEX_UID, DEMO_EMMA_UID):
        mock_chat_messages.pop(user_id, None)
    seed_demo_data()
    return {"status": "reset"}


class CreatePlan(BaseModel):
    recommendationId: str


class UpdatePlan(BaseModel):
    tulipAdded: bool | None = None
    status: str | None = None


def owned_plan(plan_id, uid):
    plan = plans.get(plan_id)
    if not plan or plan["userId"] != uid:
        raise not_found("Plan")
    return plan


@router.post("/plans")
def create_plan(req: CreatePlan, uid: str = Depends(demo_user)):
    idea = next((i for i in IDEAS if i["id"] == req.recommendationId), None)
    if not idea:
        raise not_found("Recommendation")
    base_cost = 430000 if idea["id"] == "pottery" else idea["price"]
    plan = {"id": str(uuid4()), "userId": uid, "recommendationId": idea["id"],
            "title": idea["name"], "status": "suggested", "tulipAdded": False,
            "mysteryHintEnabled": False, "baseCost": base_cost, "totalCost": base_cost,
            "timeline": ["16:00 — " + idea["name"], "18:00 — Cheesecake / Dessert", "19:00 — Walk together"],
            "breakdown": (["Workshop: 350K", "Cheesecake: 80K", "Walk: 0K"] if idea["id"] == "pottery" else [f"Trải nghiệm gồm dessert và walk: {base_cost // 1000}K"]),
            "secretSuggestion": "Emma thích Tulip 🌷. Muốn thêm một bó nhỏ không?"}
    plans[plan["id"]] = plan
    return plan


@router.patch("/plans/{plan_id}")
def update_plan(plan_id: str, req: UpdatePlan, uid: str = Depends(demo_user)):
    plan = owned_plan(plan_id, uid)
    if req.tulipAdded is not None:
        plan["tulipAdded"] = req.tulipAdded
        plan["totalCost"] = plan["baseCost"] + (50000 if req.tulipAdded else 0)
    if req.status is not None:
        if req.status != "planned":
            raise validation_error("Chỉ có thể xác nhận Planned.")
        plan["status"] = "planned"
    return plan


@router.post("/plans/{plan_id}/hint")
def send_hint(plan_id: str, uid: str = Depends(demo_user)):
    plan = owned_plan(plan_id, uid)
    if plan["status"] != "planned":
        raise validation_error("Hãy xác nhận plan trước.")
    if not plan["mysteryHintEnabled"]:
        recipient = DEMO_EMMA_UID if uid == DEMO_ALEX_UID else DEMO_ALEX_UID
        notifications[plan_id] = {"id": plan_id, "recipientUserId": recipient,
            "message": "Cuối tuần này có vẻ sẽ có một điều đáng mong chờ 👀❤️",
            "isRead": False, "createdAt": datetime.now(timezone.utc).isoformat()}
        plan["mysteryHintEnabled"] = True
    return plan


@router.get("/notifications")
def list_notifications(uid: str = Depends(demo_user)):
    return [{k: v for k, v in n.items() if k != "recipientUserId"}
            for n in reversed(list(notifications.values())) if n["recipientUserId"] == uid]


@router.patch("/notifications/{notification_id}/read")
def read_notification(notification_id: str, uid: str = Depends(demo_user)):
    n = notifications.get(notification_id)
    if not n or n["recipientUserId"] != uid:
        raise not_found("Notification")
    n["isRead"] = True
    return {"status": "read"}


def reply(message, history):
    from app.domain.schemas.chat import ChatResponse
    text = message.lower()
    if "không nhớ" in text or "thích gì" in text:
        from app.infrastructure.mock_db import mock_preferences
        from app.demo_seed import DEMO_COUPLE_ID
        memories = mock_preferences.get(DEMO_COUPLE_ID, [])
        values = "\n".join(f"• {p.type}: {p.value}" for p in memories)
        return ChatResponse(reply="Mình nhớ Emma từng nhắc vài điều nè 👀\n" + values + "\nBạn muốn chuẩn bị một món quà hay một buổi đi chơi?",
                            options=["Một món quà", "Một buổi đi chơi"])
    if "một món quà" in text:
        return ChatResponse(reply="Emma thích Tulip 🌷 và cheesecake 🍰. Bạn muốn chọn một buổi đi chơi để cùng tạo kỷ niệm không?", options=["Một buổi đi chơi"])
    if "một buổi đi chơi" in text:
        return ChatResponse(reply="Emma từng muốn thử Pottery Workshop. Cozy và Photography cũng hợp gu cô ấy. Muốn mình biến nó thành một moment không?",
                            options=["Biến thành một moment ❤️"], actions={"Biến thành một moment ❤️": "moment:pottery"})
    return ChatResponse(reply="Alex ơi, mình có 3 idea trong budget 500K: Pottery Workshop (350K), Sunset + Cheesecake (250K), Hidden Café Date (200K). Mỗi idea đều dựa trên sở thích của Emma 💕",
                        options=["Xem 3 idea", PROMPTS[1]], actions={"Xem 3 idea": "recommendations"})
