def test_get_recommendation(client):
    response = client.post(
        "/v1/recommendations",
        json={
            "partnerId": "some-partner-id",
            "occasion": "Anniversary",
            "budget": {
                "amount": 1000000,
                "currency": "VND"
            }
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["place"]["name"] == "Romantic Dinner at The Deck"
    assert data["personalReason"] is not None
