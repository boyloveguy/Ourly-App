from fastapi import APIRouter, Query, Response
from pydantic import BaseModel
import io
import re
import httpx
try:
    import edge_tts
    HAS_EDGE_TTS = True
except ImportError:
    edge_tts = None
    HAS_EDGE_TTS = False

from gtts import gTTS

router = APIRouter(prefix="/voice", tags=["Voice & TTS"])

class TTSRequest(BaseModel):
    text: str

def clean_tts_text(text: str) -> str:
    # Remove markdown formatting, urls, bullets, and emojis
    t = re.sub(r'[*_#>`~]', '', text)
    t = re.sub(r'https?://\S+', '', t)
    t = re.sub(r'[•\-\–\—]', ' ', t)
    
    # Remove emojis & non-BMP symbols
    emoji_pattern = re.compile(r'[\U00010000-\U0010ffff]', flags=re.UNICODE)
    t = emoji_pattern.sub('', t)
    t = re.sub(r'[\u2600-\u27bf]', '', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t

@router.get("/tts")
async def generate_tts_get(text: str = Query(..., description="Text to speak in Vietnamese")):
    clean = clean_tts_text(text)
    if not clean:
        clean = "Xin chào bạn"

    # 1. Primary: Edge-TTS male neural voice (vi-VN-NamMinhNeural) speaking faster (+20%)
    try:
        c = edge_tts.Communicate(clean, voice="vi-VN-NamMinhNeural", rate="+20%")
        audio_data = b""
        async for chunk in c.stream():
            if chunk["type"] == "audio":
                audio_data += chunk["data"]
        if audio_data:
            return Response(
                content=audio_data,
                media_type="audio/mpeg",
                headers={
                    "Cache-Control": "public, max-age=86400",
                    "Content-Disposition": "inline; filename=\"tts.mp3\""
                }
            )
    except Exception:
        pass

    # 2. Fallback: gTTS
    try:
        tts = gTTS(text=clean, lang='vi')
        fp = io.BytesIO()
        tts.write_to_fp(fp)
        fp.seek(0)
        return Response(
            content=fp.getvalue(),
            media_type="audio/mpeg",
            headers={
                "Cache-Control": "public, max-age=86400",
                "Content-Disposition": "inline; filename=\"tts.mp3\""
            }
        )
    except Exception:
        pass

    # 3. Fallback: Google Translate TTS direct endpoint
    try:
        url = f"https://translate.google.com/translate_tts?ie=UTF-8&q={httpx.URL(clean)}&tl=vi&client=tw-ob"
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.get(url)
            if res.status_code == 200:
                return Response(
                    content=res.content,
                    media_type="audio/mpeg",
                    headers={
                        "Cache-Control": "public, max-age=86400",
                        "Content-Disposition": "inline; filename=\"tts.mp3\""
                    }
                )
    except Exception:
        pass

    return Response(status_code=500, content="TTS synthesis failed")

@router.post("/tts")
async def generate_tts_post(req: TTSRequest):
    return await generate_tts_get(text=req.text)

