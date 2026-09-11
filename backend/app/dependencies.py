from fastapi import Depends, Header, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.infrastructure.firebase import verify_token
from app.core.errors import unauthenticated

security = HTTPBearer(auto_error=False)

def get_current_user_id(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    if not credentials:
        raise unauthenticated()
    
    token = credentials.credentials
    try:
        decoded_token = verify_token(token)
        return decoded_token.get("uid")
    except Exception:
        raise unauthenticated()
