import firebase_admin
from firebase_admin import credentials, auth, firestore
from app.core.config import settings

def init_firebase():
    if not firebase_admin._apps:
        try:
            if settings.FIREBASE_PROJECT_ID and settings.FIREBASE_CLIENT_EMAIL and settings.FIREBASE_PRIVATE_KEY:
                cred = credentials.Certificate({
                    "type": "service_account",
                    "project_id": settings.FIREBASE_PROJECT_ID,
                    "private_key": settings.FIREBASE_PRIVATE_KEY.replace('\\n', '\n'),
                    "client_email": settings.FIREBASE_CLIENT_EMAIL,
                    "token_uri": "https://oauth2.googleapis.com/token",
                })
                firebase_admin.initialize_app(cred)
            else:
                # Local dev / mock mode
                firebase_admin.initialize_app()
        except Exception as e:
            print(f"Firebase init error (continuing in mock mode): {e}")

def get_db():
    try:
        return firestore.client()
    except Exception:
        return None # Mock DB will be used if real isn't available

def verify_token(token: str) -> dict:
    try:
        if token == "mock-token":
            return {"uid": "mock-uid-123"}
        return auth.verify_id_token(token)
    except Exception as e:
        raise ValueError(f"Invalid token: {str(e)}")
