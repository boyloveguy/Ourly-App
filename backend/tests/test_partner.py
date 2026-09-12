def test_create_partner(client):
    response = client.post(
        "/v1/partners",
        json={
            "name": "Jane Doe",
            "relationshipType": "wife",
            "preferences": ["reading", "traveling", "food"]
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Jane Doe"
    assert data["id"] is not None

def test_create_partner_validation_error(client):
    response = client.post(
        "/v1/partners",
        json={
            "name": "Jane Doe",
            "relationshipType": "wife",
            "preferences": ["reading"] # Need at least 2
        }
    )
    assert response.status_code == 422 # Pydantic validation error or custom error

def test_invite_full_flow_with_solo_user(client):
    from app.main import app
    from app.dependencies import get_current_user_id

    # 1. User A creates solo space and creates invite
    app.dependency_overrides[get_current_user_id] = lambda: "user-a-creator"
    space_a = client.post("/v1/couples", params={"nickname": "Bé Chó"}).json()
    inv_a = client.post(f"/v1/couples/{space_a['id']}/invites").json()
    token = inv_a["tokenHash"]
    assert token.startswith("LV-")

    # Calling create_invite again returns the SAME active token
    inv_a2 = client.post(f"/v1/couples/{space_a['id']}/invites").json()
    assert inv_a2["tokenHash"] == token

    # 2. User B creates their own solo space (Step 1 onboarding)
    app.dependency_overrides[get_current_user_id] = lambda: "user-b-invitee"
    space_b = client.post("/v1/couples", params={"nickname": "Bé Mèo"}).json()
    assert space_b["status"] == "solo"

    # 3. User B enters lowercase or raw code: e.g. lv-xxxx or full url
    # Preview invite
    preview = client.post("/v1/invites/preview", json={"token": token.lower()})
    assert preview.status_code == 200
    assert preview.json()["inviterNickname"] == "Bé Chó"

    # 4. User B accepts invite (with default archive_solo=True)
    res_accept = client.post("/v1/invites/accept", params={"nickname": "Bé Mèo"}, json={"token": token.lower()})
    assert res_accept.status_code == 200
    assert res_accept.json()["status"] == "success"
    assert res_accept.json()["coupleId"] == space_a["id"]

    # 5. User B current couple is now connected space A
    res_curr_b = client.get("/v1/couples/current")
    assert res_curr_b.status_code == 200
    assert res_curr_b.json()["status"] == "connected"
    assert res_curr_b.json()["id"] == space_a["id"]

    # 7. User A unlinks partner
    res_unlink = client.post(f"/v1/couples/{space_a['id']}/unlink")
    assert res_unlink.status_code == 200
    unlink_data = res_unlink.json()
    assert unlink_data["status"] == "solo"
    # Invitee participant link is removed
    for p in unlink_data["participants"]:
        if p["role"] == "invitee":
            assert p["linkedUserId"] is None

    # User B is no longer linked to space A
    app.dependency_overrides[get_current_user_id] = lambda: "user-b-invitee"
    res_curr_b_after = client.get("/v1/couples/current")
    # User B does not have active space A
    if res_curr_b_after.status_code == 200 and res_curr_b_after.json():
        assert res_curr_b_after.json()["id"] != space_a["id"]

    app.dependency_overrides.clear()

