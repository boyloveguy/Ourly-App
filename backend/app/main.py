from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.errors import AppException, ErrorResponse
from app.infrastructure.firebase import init_firebase
from app.api.routes import health, users, couples, invites, preferences

# Init Firebase
init_firebase()

app = FastAPI(
    title="Love Advisor API",
    version="0.1.0",
    description="Backend for the Love Advisor Flutter Application"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in settings.CORS_ALLOWED_ORIGINS.split(",")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.detail, "details": exc.details}}
    )

app.include_router(health.router)
app.include_router(users.router, prefix="/v1")
app.include_router(couples.router, prefix="/v1")
app.include_router(invites.router, prefix="/v1")
app.include_router(preferences.router, prefix="/v1")
