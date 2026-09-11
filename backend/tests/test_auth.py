import pytest
from fastapi.testclient import TestClient
from app.infrastructure.mock_db import mock_users, mock_users_by_email

def test_register_success(client: TestClient):
    mock_users.clear()
    mock_users_by_email.clear()
    
    payload = {
        "email": "lover1@ourly.app",
        "password": "password123",
        "nickname": "Anh Yêu",
    }
    res = client.post("/v1/auth/register", json=payload)
    assert res.status_code == 201
    data = res.json()
    assert "token" in data
    assert data["token"].startswith("user-")
    assert data["user"]["email"] == "lover1@ourly.app"
    assert data["user"]["nickname"] == "Anh Yêu"

def test_register_invalid_email(client: TestClient):
    payload = {
        "email": "invalid-email-without-at",
        "password": "password123",
    }
    res = client.post("/v1/auth/register", json=payload)
    assert res.status_code == 400

def test_register_short_password(client: TestClient):
    payload = {
        "email": "short@ourly.app",
        "password": "123",
    }
    res = client.post("/v1/auth/register", json=payload)
    assert res.status_code == 400 or res.status_code == 422

def test_register_duplicate_email(client: TestClient):
    payload = {
        "email": "dup@ourly.app",
        "password": "securepassword",
    }
    res1 = client.post("/v1/auth/register", json=payload)
    assert res1.status_code == 201
    
    res2 = client.post("/v1/auth/register", json=payload)
    assert res2.status_code == 400
    assert res2.json()["error"]["code"] == "EMAIL_ALREADY_EXISTS"

def test_login_success(client: TestClient):
    email = "login_test@ourly.app"
    password = "correct_password"
    
    # Register first
    client.post("/v1/auth/register", json={
        "email": email,
        "password": password,
        "nickname": "Bé Cưng",
    })
    
    # Login
    res = client.post("/v1/auth/login", json={
        "email": email,
        "password": password,
    })
    assert res.status_code == 200
    data = res.json()
    assert "token" in data
    assert data["user"]["email"] == email
    assert data["user"]["nickname"] == "Bé Cưng"

def test_login_wrong_password(client: TestClient):
    email = "wrong_pw@ourly.app"
    client.post("/v1/auth/register", json={
        "email": email,
        "password": "realpassword",
    })
    
    res = client.post("/v1/auth/login", json={
        "email": email,
        "password": "WRONG_PASSWORD",
    })
    assert res.status_code == 401
    assert "Email hoặc mật khẩu không chính xác" in res.json()["error"]["message"]

def test_login_nonexistent_email(client: TestClient):
    res = client.post("/v1/auth/login", json={
        "email": "never_registered@ourly.app",
        "password": "anypassword",
    })
    assert res.status_code == 401
    assert "Email hoặc mật khẩu không chính xác" in res.json()["error"]["message"]

def test_upload_avatar_json(client: TestClient):
    # Register & get token
    reg = client.post("/v1/auth/register", json={
        "email": "avatar_user@ourly.app",
        "password": "password123",
        "nickname": "Avatar Test",
    })
    token = reg.json()["token"]

    # Upload avatar with base64 data
    res = client.post(
        "/v1/users/avatar",
        headers={"Authorization": f"Bearer {token}"},
        json={"data": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="}
    )
    assert res.status_code == 200
    data = res.json()
    assert "avatar_url" in data
    assert len(data["avatar_url"]) > 0

    # Verify user profile has updated avatar
    me_res = client.get("/v1/users/me", headers={"Authorization": f"Bearer {token}"})
    assert me_res.status_code == 200
    assert me_res.json()["avatar"] == data["avatar_url"]
