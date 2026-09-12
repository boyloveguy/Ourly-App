from fastapi import APIRouter, Depends
from typing import List

from app.dependencies import get_current_user_id
from app.domain.schemas.recommendation import (
    Budget,
    PlaceBase,
    RecommendationRequest,
    RecommendationResponse,
)
from app.core.errors import validation_error

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


MOCK_RECOMMENDATIONS = [
    {
        "place": {
            "id": "da-nang-son-tra-marina",
            "name": "Bữa tối hoàng hôn tại Sơn Trà Marina",
            "city": "Đà Nẵng",
            "area": "Sơn Trà",
            "address": "Hồ Xanh, Thọ Quang, Sơn Trà, Đà Nẵng",
            "imageUrl": "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80",
            "placeType": "Experience",
            "budgetLevel": 2,
            "estimatedCost": 480000,
            "tags": ["romantic", "quiet", "dessert", "beach"],
            "description": "Một buổi tối ấm cúng, có món tráng miệng và kết thúc bằng chuyến đi dạo bên biển.",
            "activities": ["Ăn tối", "Ăn cheesecake", "Đi dạo biển"],
            "openingHours": "08:00 - 22:00",
        },
        "matchTags": ["romantic", "quiet", "dessert", "beach"],
        "personalReason": "Emma thích không gian lãng mạn, yên tĩnh, gần biển và đặc biệt thích cheesecake.",
        "secretIdea": "Mang theo một bó hoa Tulip cô ấy thích và tặng vào lúc hoàng hôn 💌",
        "suggestedActivities": ["Ăn tối trong không gian ấm cúng", "Thưởng thức cheesecake", "Đi dạo biển lúc hoàng hôn"],
    },
    {
        "place": {
            "id": "da-nang-wonderlust-cheesecake-date",
            "name": "Cheesecake date tại Wonderlust",
            "city": "Đà Nẵng",
            "area": "Hải Châu",
            "address": "Hải Châu, Đà Nẵng",
            "imageUrl": "https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=1200&q=80",
            "placeType": "Cafe",
            "budgetLevel": 1,
            "estimatedCost": 320000,
            "tags": ["cozy", "photography", "dessert", "quiet"],
            "description": "Một buổi cafe nhẹ nhàng tập trung vào cheesecake, trò chuyện và chụp ảnh cùng nhau.",
            "activities": ["Uống cafe", "Ăn cheesecake", "Chụp ảnh"],
            "openingHours": "08:00 - 22:00",
        },
        "matchTags": ["cozy", "photography", "dessert"],
        "personalReason": "Emma thích cheesecake, không gian cozy và những nơi có góc chụp ảnh đẹp.",
        "secretIdea": "Nhờ quán viết một lời chúc Anniversary nhỏ cạnh phần cheesecake của Emma.",
        "suggestedActivities": ["Chọn góc ngồi yên tĩnh", "Cùng ăn cheesecake", "Chụp một bộ ảnh kỷ niệm"],
    },
    {
        "place": {
            "id": "da-nang-my-khe-sunset-picnic",
            "name": "Picnic hoàng hôn tại biển Mỹ Khê",
            "city": "Đà Nẵng",
            "area": "Sơn Trà",
            "address": "Bãi biển Mỹ Khê, Võ Nguyên Giáp, Sơn Trà, Đà Nẵng",
            "imageUrl": "https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&q=80",
            "placeType": "Activity",
            "budgetLevel": 2,
            "estimatedCost": 450000,
            "tags": ["beach", "romantic", "photography", "outdoor"],
            "description": "Một buổi picnic riêng tư bên biển với đồ ăn nhẹ, hoa và thời gian ngắm hoàng hôn.",
            "activities": ["Picnic", "Ngắm hoàng hôn", "Chụp ảnh", "Đi dạo biển"],
            "openingHours": "16:30 - 20:30",
        },
        "matchTags": ["beach", "romantic", "photography"],
        "personalReason": "Emma thích biển, sự lãng mạn và chụp ảnh nên một buổi picnic hoàng hôn sẽ rất hợp với cô ấy.",
        "secretIdea": "Đặt hoa Tulip cạnh tấm ảnh đẹp nhất của hai bạn trước khi Emma đến.",
        "suggestedActivities": ["Chuẩn bị picnic nhỏ", "Chụp ảnh lúc hoàng hôn", "Đi dạo yên tĩnh trên bãi biển"],
    },
]


@router.post("", response_model=List[RecommendationResponse])
def get_recommendations(req: RecommendationRequest, uid: str = Depends(get_current_user_id)):
    if not req.occasion:
        raise validation_error("Occasion is required when creating a recommendation.")

    from app.core.config import settings
    if settings.DEMO_MODE:
        from app.api.routes.demo import IDEAS
        return [RecommendationResponse(
            id=i["id"], place=PlaceBase(id=i["id"], name=i["name"], city="Đà Nẵng",
                area=i["area"], address=i["area"], imageUrl="assets/images/heart_3d.png",
                placeType="Activity" if i["id"] != "cafe" else "Cafe", budgetLevel=1,
                estimatedCost=i["price"], tags=i["tags"], description=i["why"]),
            matchTags=[t for t in i["tags"] if t != "Creative"],
            estimatedCost=Budget(amount=i["price"]), personalReason=i["why"],
            secretIdea="Emma thích Tulip. Bạn có thể chọn thêm vào plan.",
            suggestedActivities=[i["name"], "Cheesecake", "Walk together"], isGenerated=False)
            for i in IDEAS if i["id"] not in (req.excludedPlaceIds or [])]

    excluded_ids = set(req.excludedPlaceIds or [])
    recommendations = []

    for item in MOCK_RECOMMENDATIONS:
        place_data = item["place"]
        if place_data["id"] in excluded_ids:
            continue

        place = PlaceBase(**place_data, currency=req.budget.currency)
        recommendations.append(
            RecommendationResponse(
                id=f"recommendation-{place.id}",
                place=place,
                matchTags=item["matchTags"],
                estimatedCost=Budget(
                    amount=place.estimatedCost,
                    currency=req.budget.currency,
                ),
                personalReason=item["personalReason"],
                secretIdea=item["secretIdea"],
                suggestedActivities=item["suggestedActivities"],
                isGenerated=False,
            )
        )

    return recommendations
