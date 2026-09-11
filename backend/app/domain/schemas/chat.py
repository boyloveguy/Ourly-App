from pydantic import BaseModel, Field
from typing import List, Optional

class ChatMessageItem(BaseModel):
    role: str = Field(..., description="user or assistant")
    content: str

class ChatRequest(BaseModel):
    message: str
    history: List[ChatMessageItem] = Field(default_factory=list)

class ChatResponse(BaseModel):
    reply: str
    suggestedFollowUps: List[str] = Field(default_factory=list)
    options: List[str] = Field(default_factory=list, description="Interactive option buttons for user when AI needs more info or clarification")

class ChatMessageRecord(BaseModel):
    id: str
    isUser: bool
    text: str
    options: List[str] = Field(default_factory=list)
    selectedOption: Optional[str] = None
    createdAt: Optional[str] = None

class ChatHistoryResponse(BaseModel):
    messages: List[ChatMessageRecord] = Field(default_factory=list)
