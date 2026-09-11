from fastapi.testclient import TestClient
from app.main import app
from app.dependencies import get_current_user_id

client = TestClient(app)

print("=== STARTING COUPLE SPACE E2E FLOW ===")

# --- Step 1: User A creates solo space ---
app.dependency_overrides[get_current_user_id] = lambda: "userA-123"

resp = client.post("/v1/couples", params={"nickname": "User A"})
couple_a = resp.json()
print(f"User A created Solo Space: {couple_a['id']}")
part_a_id = couple_a['participants'][0]['id']
part_b_id = couple_a['participants'][1]['id']

# User A adds a private preference for User B
client.post(f"/v1/couples/{couple_a['id']}/preferences", json={
    "subjectParticipantId": part_b_id,
    "type": "Drink",
    "value": "Matcha",
    "visibility": "private"
})
print("User A added private preference: Matcha")

# User A creates Invite
resp = client.post(f"/v1/couples/{couple_a['id']}/invites")
invite = resp.json()
invite_token = invite['tokenHash']
print(f"User A created Invite Token: {invite_token}")

# --- Step 2: User B accepts invite ---
app.dependency_overrides[get_current_user_id] = lambda: "userB-456"

# User B previews invite
resp = client.post("/v1/invites/preview", json={"token": invite_token})
print(f"User B previews invite: {resp.json()}")

# User B accepts invite
resp = client.post("/v1/invites/accept", params={"nickname": "User B"}, json={"token": invite_token})
print(f"User B accepts invite: {resp.json()}")

# User B checks current couple space
resp = client.get("/v1/couples/current")
couple_b = resp.json()
print(f"User B sees connected space with participants: {[p['nickname'] for p in couple_b['participants']]}")

# User B tries to read preferences (Should be empty because A's pref was private)
resp = client.get(f"/v1/couples/{couple_b['id']}/preferences")
print(f"User B sees preferences: {resp.json()} (Expected: Empty list)")

print("=== E2E FLOW SUCCESS ===")
app.dependency_overrides.clear()
