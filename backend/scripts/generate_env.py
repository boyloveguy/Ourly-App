import json
import os

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
key_file = os.path.join(backend_dir, "serviceAccountKey.json")
env_file = os.path.join(backend_dir, ".env")

with open(key_file, "r", encoding="utf-8") as f:
    key_data = json.load(f)

proj_id = key_data.get("project_id", "")
client_email = key_data.get("client_email", "")
pk = key_data.get("private_key", "").replace("\n", "\\n")

env_content = f"""ENVIRONMENT=development
LOG_LEVEL=INFO

FIREBASE_PROJECT_ID={proj_id}
FIREBASE_CLIENT_EMAIL={client_email}
FIREBASE_PRIVATE_KEY="{pk}"

AI_PROVIDER=gemini
AI_API_KEY=
AI_MODEL=gemini-1.5-pro
AI_TIMEOUT_SECONDS=30

CORS_ALLOWED_ORIGINS=*
"""

with open(env_file, "w", encoding="utf-8") as f:
    f.write(env_content)

print(f"Created {env_file} successfully for project {proj_id}")
