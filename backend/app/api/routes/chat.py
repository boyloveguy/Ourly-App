from fastapi import APIRouter, Depends
from datetime import datetime, timezone
from app.dependencies import get_current_user_id
from app.domain.schemas.chat import ChatRequest, ChatResponse, ChatHistoryResponse, ChatMessageRecord
from app.infrastructure.ai_service import AIService
from app.infrastructure.firestore_repo import FirestoreRepo

router = APIRouter(prefix="/chat", tags=["AI Chatbot"])

@router.post("", response_model=ChatResponse)
def chat_with_advisor(req: ChatRequest, uid: str = Depends(get_current_user_id)):
    now_str = datetime.now(timezone.utc).isoformat()
    # 1. Save user query to history
    FirestoreRepo.save_chat_message(uid, {
        "isUser": True,
        "text": req.message,
        "options": [],
        "createdAt": now_str,
    })

    # 2. Generate AI response
    response = AIService.generate_reply(uid=uid, message=req.message, history=req.history)

    # 3. Save assistant reply to history
    reply_time = datetime.now(timezone.utc).isoformat()
    FirestoreRepo.save_chat_message(uid, {
        "isUser": False,
        "text": response.reply,
        "options": response.options,
        "createdAt": reply_time,
    })

    return response

@router.get("/history", response_model=ChatHistoryResponse)
def get_chat_history(uid: str = Depends(get_current_user_id)):
    msgs = FirestoreRepo.get_chat_history(uid)
    records = [
        ChatMessageRecord(
            id=str(m.get("id", "")),
            isUser=bool(m.get("isUser", False)),
            text=str(m.get("text", "")),
            options=list(m.get("options") or []),
            selectedOption=m.get("selectedOption"),
            createdAt=m.get("createdAt"),
        )
        for m in msgs
    ]
    return ChatHistoryResponse(messages=records)

@router.delete("/history")
def clear_chat_history(uid: str = Depends(get_current_user_id)):
    FirestoreRepo.clear_chat_history(uid)
    return {"status": "cleared"}
