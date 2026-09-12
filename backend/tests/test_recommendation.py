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
    assert isinstance(data, list)
    assert len(data) == 3
    assert data[0]["place"]["city"] == "Đà Nẵng"
    assert data[0]["place"]["name"] == "Pottery Workshop"
    assert all(item["estimatedCost"]["amount"] <= 500000 for item in data)
    assert all(item["personalReason"] for item in data)


def test_get_recommendation_excludes_places(client):
    response = client.post(
        "/v1/recommendations",
        json={
            "partnerId": "some-partner-id",
            "occasion": "Date Night",
            "budget": {
                "amount": 1000000,
                "currency": "VND"
            },
            "excludedPlaceIds": ["pottery"]
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert all(item["place"]["id"] != "pottery" for item in data)
