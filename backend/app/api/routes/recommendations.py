from fastapi import APIRouter, Depends
from typing import List
import uuid
from app.dependencies import get_current_user_id
from app.domain.schemas.recommendation import RecommendationRequest, RecommendationResponse, PlaceBase, Budget
from app.core.errors import validation_error

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])

@router.post("", response_model=RecommendationResponse)
def get_recommendation(req: RecommendationRequest, uid: str = Depends(get_current_user_id)):
    if not req.occasion:
        raise validation_error("Occasion is required when creating a recommendation.")
    
    # Mock AI logic fallback
    mock_place = PlaceBase(
        id=str(uuid.uuid4()),
        name="Romantic Dinner at The Deck",
        city="Da Nang",
        area="Hai Chau",
        address="123 Han River",
        placeType="Restaurant",
        budgetLevel=3,
        estimatedCost=req.budget.amount * 0.8,
        currency=req.budget.currency,
        tags=["romantic", "view", "dinner"],
        description="A beautiful restaurant by the Han river.",
        activities=["Dinner", "Walking"]
    )

    return RecommendationResponse(
        id=str(uuid.uuid4()),
        place=mock_place,
        matchTags=["romantic", "dinner"],
        estimatedCost=Budget(amount=mock_place.estimatedCost, currency=mock_place.currency),
        personalReason="Because your partner loves a romantic view of the river, this place fits perfectly.",
        secretIdea="Order the special wine early and surprise them with a bouquet of their favorite flowers.",
        suggestedActivities=["Enjoy the view", "Take photos by the river"],
        isGenerated=True
    )
