from fastapi import APIRouter, Query, Response
from pydantic import BaseModel
import io
import re
import httpx
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
def generate_tts_get(text: str = Query(..., description="Text to speak in Vietnamese")):
    clean = clean_tts_text(text)
    if not clean:
        clean = "Xin chào bạn"

    try:
        # Standard Vietnamese voice generation
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
        # High-res fallback via Google Translate TTS
        try:
            url = f"https://translate.google.com/translate_tts?ie=UTF-8&q={httpx.URL(clean)}&tl=vi&client=tw-ob"
            with httpx.Client(timeout=10.0) as client:
                res = client.get(url)
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
def generate_tts_post(req: TTSRequest):
    return generate_tts_get(text=req.text)
