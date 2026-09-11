import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.dependencies import get_current_user_id
from app.infrastructure.mock_db import mock_couples, mock_user_couple, mock_invites, mock_preferences

@pytest.fixture(autouse=True)
def clean_db():
    mock_couples.clear()
    mock_user_couple.clear()
    mock_invites.clear()
    mock_preferences.clear()
    yield

def test_full_partner_profile_and_surprise_flow():
    client = TestClient(app)

    # 1. User A (Minh) creates solo space
    app.dependency_overrides[get_current_user_id] = lambda: "user-a-minh"
    resp = client.post("/v1/couples", params={"nickname": "Minh"})
    assert resp.status_code == 200, resp.text
    space_a = resp.json()
    assert space_a["status"] == "solo"
    assert len(space_a["participants"]) == 2
    part_a = space_a["participants"][0]
    part_b = space_a["participants"][1]
    assert part_a["linkedUserId"] == "user-a-minh"
    assert part_b["linkedUserId"] is None

    # 2. Minh adds preferences: 1 shared, 1 private, 1 surprise
    # Shared
    resp_shared = client.post(f"/v1/couples/{space_a['id']}/preferences", json={
        "subjectParticipantId": part_b["id"],
        "type": "Food",
        "value": "Cozy cafés",
        "visibility": "shared"
    })
    assert resp_shared.status_code == 200
    shared_pref = resp_shared.json()

    # Private
    resp_private = client.post(f"/v1/couples/{space_a['id']}/preferences", json={
        "subjectParticipantId": part_b["id"],
        "type": "Drink",
        "value": "Matcha with oat milk",
        "visibility": "private"
    })
    assert resp_private.status_code == 200

    # Surprise
    resp_surprise = client.post(f"/v1/couples/{space_a['id']}/preferences", json={
        "subjectParticipantId": part_b["id"],
        "type": "Surprise",
        "value": "Sunset dinner at the beach with tulips",
        "visibility": "private"
    })
    assert resp_surprise.status_code == 200

    # Minh reads preferences -> should see all 3
    resp_minh_prefs = client.get(f"/v1/couples/{space_a['id']}/preferences")
    assert resp_minh_prefs.status_code == 200
    assert len(resp_minh_prefs.json()) == 3

    # 3. Minh creates invite
    resp_invite = client.post(f"/v1/couples/{space_a['id']}/invites")
    assert resp_invite.status_code == 200
    invite_data = resp_invite.json()
    token = invite_data["tokenHash"]
    assert token.startswith("LV-")

    # 4. User B (Emma) previews invite
    app.dependency_overrides[get_current_user_id] = lambda: "user-b-emma"
    resp_preview = client.post("/v1/invites/preview", json={"token": token})
    assert resp_preview.status_code == 200
    assert resp_preview.json()["inviterNickname"] == "Minh"
    assert resp_preview.json()["status"] == "pending"

    # 5. Emma accepts invite
    resp_accept = client.post("/v1/invites/accept", params={"nickname": "Emma"}, json={"token": token})
    assert resp_accept.status_code == 200
    assert resp_accept.json()["status"] == "success"

    # Verify space is now connected
    resp_current = client.get("/v1/couples/current")
    assert resp_current.status_code == 200
    connected_space = resp_current.json()
    assert connected_space["status"] == "connected"
    part_b_linked = next(p for p in connected_space["participants"] if p["id"] == part_b["id"])
    assert part_b_linked["linkedUserId"] == "user-b-emma"
    assert part_b_linked["nickname"] == "Emma"

    # 6. Emma reads preferences: MUST ONLY SEE SHARED (no private, NO surprise!)
    resp_emma_prefs = client.get(f"/v1/couples/{space_a['id']}/preferences")
    assert resp_emma_prefs.status_code == 200
    emma_visible = resp_emma_prefs.json()
    assert len(emma_visible) == 1
    assert emma_visible[0]["value"] == "Cozy cafés"
    assert emma_visible[0]["visibility"] == "shared"

    # 7. Emma cannot modify Minh's preference
    resp_mod = client.patch(
        f"/v1/couples/{space_a['id']}/preferences/{shared_pref['id']}",
        json={"value": "No cafes"}
    )
    assert resp_mod.status_code == 403

    # 8. Emma adds her own shared preference
    resp_emma_new = client.post(f"/v1/couples/{space_a['id']}/preferences", json={
        "subjectParticipantId": part_a["id"],
        "type": "Food",
        "value": "Sushi",
        "visibility": "shared"
    })
    assert resp_emma_new.status_code == 200

    # 9. User C (Outsider) is strictly blocked
    app.dependency_overrides[get_current_user_id] = lambda: "user-c-stranger"
    resp_c_prefs = client.get(f"/v1/couples/{space_a['id']}/preferences")
    assert resp_c_prefs.status_code == 403

    resp_c_part = client.patch(
        f"/v1/couples/{space_a['id']}/participants/{part_a['id']}",
        json={"nickname": "Hacked"}
    )
    assert resp_c_part.status_code == 403

    # 10. Minh cannot accept his own invite
    app.dependency_overrides[get_current_user_id] = lambda: "user-a-minh"
    resp_self_accept = client.post("/v1/invites/accept", params={"nickname": "Minh2"}, json={"token": token})
    assert resp_self_accept.status_code == 400

    app.dependency_overrides.clear()
