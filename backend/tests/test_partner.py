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
