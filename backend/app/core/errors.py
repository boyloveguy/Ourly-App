from fastapi import HTTPException
from pydantic import BaseModel
from typing import Any, Dict, Optional

class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[Dict[str, Any]] = {}

class ErrorResponse(BaseModel):
    error: ErrorDetail

class AppException(HTTPException):
    def __init__(self, status_code: int, code: str, message: str = "", details: Dict[str, Any] = None, detail: str = None):
        msg = detail or message
        super().__init__(status_code=status_code, detail=msg)
        self.code = code
        self.details = details or {}

def unauthenticated():
    return AppException(401, "UNAUTHENTICATED", "Authentication required")

def forbidden():
    return AppException(403, "FORBIDDEN", "You don't have permission to perform this action")

def validation_error(message: str, details: dict = None):
    return AppException(400, "VALIDATION_ERROR", message, details)

def bad_request(message: str, code: str = "BAD_REQUEST", details: dict = None):
    return AppException(400, code, message, details)

def not_found(resource: str):
    return AppException(404, f"{resource.upper()}_NOT_FOUND", f"{resource} not found")
