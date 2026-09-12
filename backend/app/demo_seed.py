from datetime import datetime, timezone

from app.core.security import hash_password
from app.domain.schemas.couple import (
    CoupleSpace,
    CoupleStatus,
    Participant,
    ParticipantRole,
)
from app.domain.schemas.preference import (
    Preference,
    PreferenceSource,
    PreferenceVisibility,
)
from app.infrastructure.mock_db import (
    mock_couples,
    mock_preferences,
    mock_user_couple,
    mock_users,
    mock_users_by_email,
)


DEMO_PASSWORD = "demo123"
DEMO_COUPLE_ID = "demo-couple-alex-emma"
DEMO_ALEX_UID = "demo-alex"
DEMO_EMMA_UID = "demo-emma"


def seed_demo_data() -> None:
    """Load deterministic hackathon data into the in-memory fallback store."""
    now = datetime.now(timezone.utc)
    now_str = now.isoformat()

    alex = {
        "uid": DEMO_ALEX_UID,
        "email": "alex@ourly.demo",
        "hashedPassword": hash_password(DEMO_PASSWORD),
        "nickname": "Alex",
        "activeCoupleId": DEMO_COUPLE_ID,
        "lovePoints": 630,
        "currentStreak": 29,
        "boyfriendOfTheYearUnlocked": False,
        "createdAt": now_str,
    }
    emma = {
        "uid": DEMO_EMMA_UID,
        "email": "emma@ourly.demo",
        "hashedPassword": hash_password(DEMO_PASSWORD),
        "nickname": "Emma",
        "activeCoupleId": DEMO_COUPLE_ID,
        "createdAt": now_str,
    }

    mock_users[DEMO_ALEX_UID] = alex
    mock_users[DEMO_EMMA_UID] = emma
    mock_users_by_email[alex["email"]] = alex
    mock_users_by_email[emma["email"]] = emma
    mock_user_couple[DEMO_ALEX_UID] = DEMO_COUPLE_ID
    mock_user_couple[DEMO_EMMA_UID] = DEMO_COUPLE_ID

    alex_participant = Participant(
        id="demo-participant-alex",
        linkedUserId=DEMO_ALEX_UID,
        nickname="Alex",
        role=ParticipantRole.creator,
        createdAt=now,
    )
    emma_participant = Participant(
        id="demo-participant-emma",
        linkedUserId=DEMO_EMMA_UID,
        nickname="Emma",
        role=ParticipantRole.invitee,
        createdAt=now,
    )
    mock_couples[DEMO_COUPLE_ID] = CoupleSpace(
        id=DEMO_COUPLE_ID,
        status=CoupleStatus.connected,
        participants=[alex_participant, emma_participant],
        createdAt=now,
        updatedAt=now,
    )

    seed_values = [
        ("Preference", "Romantic"),
        ("Preference", "Dessert"),
        ("Preference", "Beach"),
        ("Preference", "Cozy"),
        ("Preference", "Quiet"),
        ("Preference", "Photography"),
        ("Favorite dessert", "Cheesecake"),
        ("Favorite flower", "Tulip"),
        ("Favorite place", "Beach; Quiet places"),
        ("Favorite drink", "Matcha"),
        ("Want to try", "Pottery Workshop"),
    ]
    mock_preferences[DEMO_COUPLE_ID] = [
        Preference(
            id=f"demo-preference-{index}",
            coupleId=DEMO_COUPLE_ID,
            subjectParticipantId=emma_participant.id,
            createdByUserId=DEMO_EMMA_UID,
            source=PreferenceSource.selfDeclared,
            type=item_type,
            value=value,
            visibility=PreferenceVisibility.shared,
            createdAt=now,
            updatedAt=now,
        )
        for index, (item_type, value) in enumerate(seed_values, start=1)
    ]
