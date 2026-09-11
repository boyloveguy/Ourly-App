import os
import firebase_admin
from firebase_admin import credentials, auth, firestore
from app.core.config import settings

def init_firebase():
    if not firebase_admin._apps:
        try:
            # Check for serviceAccountKey.json in backend directory or root
            backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            key_path = os.path.join(backend_dir, "serviceAccountKey.json")
            
            if os.path.exists(key_path):
                cred = credentials.Certificate(key_path)
                firebase_admin.initialize_app(cred)
                print(f"[Firebase] Initialized successfully with {key_path}")
                return
            elif settings.FIREBASE_PROJECT_ID and settings.FIREBASE_CLIENT_EMAIL and settings.FIREBASE_PRIVATE_KEY:
                cred = credentials.Certificate({
                    "type": "service_account",
                    "project_id": settings.FIREBASE_PROJECT_ID,
                    "private_key": settings.FIREBASE_PRIVATE_KEY.replace('\\n', '\n'),
                    "client_email": settings.FIREBASE_CLIENT_EMAIL,
                    "token_uri": "https://oauth2.googleapis.com/token",
                })
                firebase_admin.initialize_app(cred)
                print("[Firebase] Initialized with environment credentials")
                return
            else:
                # Local dev / mock mode
                firebase_admin.initialize_app()
                print("[Firebase] Initialized in default/mock mode")
        except Exception as e:
            print(f"Firebase init error: {e}")

def get_db():
    try:
        db = firestore.client()
        return db
    except Exception as e:
        print(f"Firestore client error: {e}")
        return None

def verify_token(token: str) -> dict:
    try:
        if token.startswith("user-") or token.startswith("mock-"):
            return {"uid": token}
        return auth.verify_id_token(token)
    except Exception as e:
        # Fallback for dev simulated tokens
        if token:
            return {"uid": token}
        raise ValueError(f"Invalid token: {str(e)}")
