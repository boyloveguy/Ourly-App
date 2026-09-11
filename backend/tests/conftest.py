import os
# Set test environment flag before app imports
os.environ["TESTING"] = "1"

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.dependencies import get_current_user_id

def override_get_current_user_id():
    return "test-uid-123"

@pytest.fixture
def client():
    app.dependency_overrides[get_current_user_id] = override_get_current_user_id
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()
