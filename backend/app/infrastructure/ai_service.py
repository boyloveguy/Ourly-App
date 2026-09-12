import re
import httpx
from typing import List, Optional, Dict, Any
from app.core.config import settings
from app.infrastructure.firestore_repo import FirestoreRepo
from app.domain.schemas.chat import ChatMessageItem, ChatResponse
from app.domain.schemas.couple import CoupleStatus

from datetime import datetime

class AIService:
    @staticmethod
    def _calculate_days_together(dating_str: Optional[str]) -> tuple[str, Optional[int]]:
        if not dating_str:
            return "Chưa cập nhật ngày bắt đầu", None
        for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%Y/%m/%d"):
            try:
                d = datetime.strptime(dating_str[:10], fmt)
                now = datetime.now()
                days = (now - d).days
                if days >= 0:
                    return f"{dating_str} ({days} ngày bên nhau)", days
                else:
                    return dating_str, None
            except Exception:
                pass
        return dating_str, None

    @staticmethod
    def _build_context(uid: str, client_context: Optional[dict] = None) -> Dict[str, Any]:
        """Collect user profile, partner profile, dating date, moods, and preferences from Firestore & client."""
        client_ctx = client_context or {}
        user_doc = FirestoreRepo.get_user(uid) or {}
        
        user_name = client_ctx.get("userNickname") or user_doc.get("nickname") or "Bạn"
        user_bday = user_doc.get("birthday") or "Chưa cập nhật"
        user_dating_start = client_ctx.get("datingStartDate") or user_doc.get("datingStartDate")
        user_mood = client_ctx.get("userMood") or user_doc.get("todayMood") or "Thư thái, bình yên"
        user_hobbies = user_doc.get("interests") or user_doc.get("hobbies") or []
        
        couple = FirestoreRepo.get_active_couple_for_user(uid)
        partner_name = client_ctx.get("partnerNickname") or "Người ấy"
        partner_bday = "Chưa rõ"
        partner_mood = client_ctx.get("partnerMood") or "Chưa cập nhật hôm nay"
        partner_hobbies = []
        has_partner = False
        preferences_text = []
        
        if couple:
            # Find current participant and partner participant
            for p in couple.participants:
                if p.linkedUserId == uid:
                    user_name = p.nickname or user_name
                else:
                    partner_name = p.nickname or partner_name
                    if p.linkedUserId is not None:
                        has_partner = True
                        p_user = FirestoreRepo.get_user(p.linkedUserId)
                        if p_user:
                            if p_user.get("birthday"):
                                partner_bday = p_user.get("birthday")
                            if p_user.get("todayMood") and partner_mood == "Chưa cập nhật hôm nay":
                                partner_mood = p_user.get("todayMood")
                            if p_user.get("interests"):
                                partner_hobbies = p_user.get("interests")
                            if not user_dating_start and p_user.get("datingStartDate"):
                                user_dating_start = p_user.get("datingStartDate")
            
            # Get preferences from Firestore
            prefs = FirestoreRepo.get_preferences_for_couple(couple.id)
            for pref in prefs:
                if pref.type.lower() == "surprise":
                    if pref.createdByUserId == uid:
                        preferences_text.append(f"Kế hoạch bất ngờ đang ấp ủ: {pref.value}")
                else:
                    preferences_text.append(f"{pref.type}: {pref.value}")

        # If client passed partner info directly
        if client_ctx.get("hasPartner") is True:
            has_partner = True
        if client_ctx.get("partnerName"):
            partner_name = client_ctx.get("partnerName")

        dating_desc, days_count = AIService._calculate_days_together(user_dating_start)

        return {
            "userName": user_name,
            "userBirthday": user_bday,
            "userMood": user_mood,
            "userHobbies": user_hobbies,
            "hasPartner": has_partner,
            "partnerName": partner_name,
            "partnerBirthday": partner_bday,
            "partnerMood": partner_mood,
            "partnerHobbies": partner_hobbies,
            "datingStartDate": user_dating_start,
            "datingDescription": dating_desc,
            "daysTogether": days_count,
            "preferences": preferences_text,
            "coupleStatus": couple.status.value if couple else ("connected" if has_partner else "chưa tạo không gian"),
        }

    @staticmethod
    def _build_system_prompt(context: Dict[str, Any]) -> str:
        user_name = context["userName"]
        partner_name = context["partnerName"]
        has_partner = context["hasPartner"]
        user_mood = context["userMood"]
        partner_mood = context["partnerMood"]
        user_hobbies = ", ".join(context["userHobbies"]) if context["userHobbies"] else "Chưa chia sẻ"
        partner_hobbies = ", ".join(context["partnerHobbies"]) if context["partnerHobbies"] else "Chưa chia sẻ"
        prefs = "\n- ".join(context["preferences"]) if context["preferences"] else "Chưa có ghi chú đặc biệt"
        dating_info = context["datingDescription"]
        
        status_desc = f"Đã kết nối cùng {partner_name}" if has_partner else f"Đang ở chế độ Solo / Tìm kiếm người yêu (đối tượng quan tâm: {partner_name})"

        return f"""Bạn là "Quân sư Tình yêu Ourly" (Ourly Love Advisor) - một chuyên gia tâm lý tình cảm, cố vấn hẹn hò và quân sư tình yêu thông minh, ấm áp, sâu sắc, duyên dáng và thấu hiểu.

HỒ SƠ CẶP ĐÔI TỪ HỆ THỐNG OURLY:
- Người dùng hiện tại ({user_name}):
  + Sinh nhật: {context["userBirthday"]}
  + Tâm trạng hôm nay: {user_mood}
  + Sở thích: {user_hobbies}
- Người ấy / Đối phương ({partner_name}):
  + Sinh nhật: {context["partnerBirthday"]}
  + Tâm trạng hôm nay: {partner_mood}
  + Sở thích: {partner_hobbies}
- Trạng thái mối quan hệ: {status_desc}
- Cột mốc tình cảm: {dating_info}
- Các sở thích & ghi chú đã lưu trong không gian chung:
- {prefs}

NGUYÊN TẮC CỐ VẤN CHÍNH XÁC & CÁ NHÂN HÓA CAO ĐỘ:
1. Xưng hô: Gọi tên "{user_name}" một cách thân mật, xưng là "mình" hoặc "Quân sư". Luôn nhắc đến "{partner_name}" đúng vị thế mối quan hệ.
2. Thấu hiểu tâm trạng (Daily Mood):
   - Nếu {partner_name} đang mệt mỏi, áp lực, buồn hoặc ốm: Ưu tiên khuyên {user_name} dịu dàng an ủi, chuẩn bị đồ uống ấm, không tranh cãi, tạo không gian thư giãn cho người ấy.
   - Nếu {partner_name} vui vẻ, ngọt ngào: Gợi ý các hoạt động bất ngờ, hẹn hò sôi động, gắn kết lãng mạn.
3. Tận dụng thời gian bên nhau ({dating_info}): Nhắc khéo về chặng đường hai bạn đã đi qua để tạo chiều sâu cảm xúc.
4. Tận dụng sở thích cá nhân ({partner_hobbies}, {prefs}): Khi gợi ý quán ăn, quà tặng, hoạt động hẹn hò, phải bám sát sở thích của {partner_name}.
5. Giọng văn: Nam tính, năng động, ấm áp, dí dỏm, khích lệ và tinh tế. Dùng gạch đầu dòng rõ ràng và emoji sinh động (💕, 🪽, ✨, 💐, 🥂, 🎁).
6. TỰ ĐỘNG ĐƯA RA CÁC NÚT TÙY CHỌN (OPTION BUTTONS):
BẮT BUỘC đặt ở cuối cùng của câu trả lời cú pháp:
[OPTIONS: Lựa chọn 1 | Lựa chọn 2 | Lựa chọn 3 | Lựa chọn 4]
Mỗi lựa chọn ngắn gọn từ 3 đến 6 từ kèm emoji ở đầu.

GIỚI HẠN PHẠM VI TRẢ LỜI (QUAN TRỌNG):
Bạn CHỈ được tư vấn về các chủ đề thuộc phạm vi ứng dụng Ourly:
  ✅ ĐƯỢC phép: Tình yêu, hẹn hò, lên kế hoạch hẹn hò, quà tặng, kỷ niệm, làm lành, thấu hiểu cảm xúc, gắn kết cặp đôi, tán tỉnh, tâm sự chuyện tình cảm.
  ❌ KHÔNG được phép: Lập trình, toán học, tin tức, thể thao (lịch thi đấu, kết quả bóng đá, v.v.), nấu ăn công thức chi tiết, kinh doanh, tài chính, y tế, pháp lý, và bất kỳ chủ đề nào không liên quan đến tình cảm & hẹn hò.

Khi người dùng hỏi ngoài phạm vi, hãy từ chối lịch sự và hài hước theo mẫu này:
"Ối {user_name} ơi, Quân sư Tình yêu chỉ thành thạo chuyện trái tim thôi nhé! 😄💕 Câu hỏi về [tóm tắt chủ đề] thì quân sư xin thua, nhưng nếu bạn muốn [gợi ý chủ đề liên quan đến tình yêu] thì quân sư sẵn sàng hỗ trợ ngay!"
Sau đó BẮT BUỘC thêm [OPTIONS] với 4 lựa chọn liên quan đến tình yêu."""


    @staticmethod
    def _extract_options_and_clean_reply(raw_text: str) -> tuple[str, List[str]]:
        """Extract [OPTIONS: opt1 | opt2 | opt3] from AI reply and return clean text and options."""
        options = []
        pattern = r"\[OPTIONS:\s*([^\]]+)\]"
        match = re.search(pattern, raw_text, re.IGNORECASE)
        if match:
            options_str = match.group(1)
            options = [opt.strip() for opt in options_str.split("|") if opt.strip()]
            clean_reply = re.sub(pattern, "", raw_text, flags=re.IGNORECASE).strip()
            return clean_reply, options
        return raw_text.strip(), options

    @classmethod
    def _generate_smart_options(cls, query: str, ctx: Dict[str, Any]) -> List[str]:
        """Generate relevant option buttons based on conversation topic."""
        lower = query.lower()
        if any(k in lower for k in ["hẹn", "cuối tuần", "đi đâu", "date", "chơi", "ăn gì"]):
            return [
                "🥂 Lãng mạn, ấm cúng",
                "☕ Quán cafe acoustic",
                "🍜 Ăn vặt dạo phố về đêm",
                "🏕️ Dã ngoại ngoài trời",
            ]
        if any(k in lower for k in ["quà", "kỷ niệm", "sinh nhật", "tặng", "bất ngờ"]):
            return [
                "🎁 Quà sinh nhật ý nghĩa",
                "💐 Kỷ niệm ngày yêu",
                "💝 Món quà bất ngờ nhỏ",
                "💵 Ngân sách dưới 500k",
                "💎 Ngân sách 500k - 1.5tr",
            ]
        if any(k in lower for k in ["có người yêu", "tán", "cưa", "crush", "làm quen", "thích"]):
            return [
                "👀 Mới quen, chưa nói chuyện",
                "💬 Đang nhắn tin làm quen",
                "☕ Đã từng đi cafe riêng",
                "🤝 Bạn thân muốn tiến tới",
            ]
        if any(k in lower for k in ["giận", "im lặng", "cãi nhau", "làm lành", "buồn", "dỗi"]):
            return [
                "📱 Người ấy im lặng không nhắn",
                "⚡ Cãi nhau vì bất đồng quan điểm",
                "⏰ Quên lịch hẹn / kỷ niệm",
                "🥺 Giận dỗi vu vơ",
            ]
        return [
            "🍷 Lên lịch hẹn hò lãng mạn",
            "🎁 Gợi ý quà tặng người ấy",
            "💬 Cách mở lời tự nhiên",
            "💕 Bí kíp gắn kết tình cảm",
        ]

    @classmethod
    def generate_reply(
        cls,
        uid: str,
        message: str,
        history: List[ChatMessageItem],
        client_context: Optional[dict] = None
    ) -> ChatResponse:
        context = cls._build_context(uid, client_context)
        system_prompt = cls._build_system_prompt(context)
        
        # 1. If AI_API_KEY is configured, call Gemini API
        if settings.AI_API_KEY and settings.AI_API_KEY.strip():
            try:
                raw_reply = cls._call_gemini_api(system_prompt, message, history)
                if raw_reply:
                    reply, options = cls._extract_options_and_clean_reply(raw_reply)
                    if not options:
                        options = cls._generate_smart_options(message, context)
                    follow_ups = cls._generate_follow_ups(message, context)
                    return ChatResponse(reply=reply, suggestedFollowUps=follow_ups, options=options)
            except Exception as e:
                print(f"[AIService] Gemini API error: {e}, falling back to smart engine")

        # 2. Smart Contextual Rule Engine fallback (using real Firestore & client data)
        raw_reply = cls._generate_smart_fallback(message, context)
        reply, options = cls._extract_options_and_clean_reply(raw_reply)
        if not options:
            options = cls._generate_smart_options(message, context)
        follow_ups = cls._generate_follow_ups(message, context)
        return ChatResponse(reply=reply, suggestedFollowUps=follow_ups, options=options)

    @classmethod
    def _call_gemini_api(cls, system_prompt: str, message: str, history: List[ChatMessageItem]) -> Optional[str]:
        candidate_models = [settings.AI_MODEL or "gemini-3.5-flash-lite", "gemini-3.5-flash-lite", "gemini-3.1-flash-lite", "gemini-3.5-flash"]
        seen = set()
        models_to_try = [m for m in candidate_models if not (m in seen or seen.add(m))]

        contents = []
        for h in history[-6:]:  # Keep last 6 context turns
            role = "user" if h.role == "user" else "model"
            contents.append({"role": role, "parts": [{"text": h.content}]})
            
        contents.append({"role": "user", "parts": [{"text": message}]})

        payload = {
            "system_instruction": {
                "parts": [{"text": system_prompt}]
            },
            "contents": contents,
            "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 1000
            }
        }

        headers = {
            "Content-Type": "application/json",
            "X-goog-api-key": settings.AI_API_KEY
        }

        with httpx.Client(timeout=float(settings.AI_TIMEOUT_SECONDS)) as client:
            for model_name in models_to_try:
                try:
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
                    resp = client.post(url, headers=headers, json=payload)
                    if resp.status_code == 200:
                        data = resp.json()
                        candidates = data.get("candidates", [])
                        if candidates:
                            parts = candidates[0].get("content", {}).get("parts", [])
                            if parts:
                                return parts[0].get("text")
                    else:
                        print(f"[AIService] Model {model_name} returned {resp.status_code}: {resp.text[:100]}, trying next...")
                except Exception as e:
                    print(f"[AIService] Error with model {model_name}: {e}")
        return None

    @classmethod
    def _generate_smart_fallback(cls, query: str, ctx: Dict[str, Any]) -> str:
        user_name = ctx["userName"]
        partner_name = ctx["partnerName"]
        has_partner = ctx["hasPartner"]
        user_mood = ctx.get("userMood", "bình thường")
        partner_mood = ctx.get("partnerMood", "chưa cập nhật")
        dating_desc = ctx.get("datingDescription", "")
        days_together = ctx.get("daysTogether")
        partner_hobbies = ", ".join(ctx.get("partnerHobbies") or []) or "ẩm thực & cafe"
        prefs_str = ", ".join(ctx["preferences"]) if ctx["preferences"] else "chưa có ghi chú cụ thể"
        lower = query.lower()

        # Mood care alert if partner is not feeling well
        mood_hint = ""
        if any(w in str(partner_mood).lower() for w in ["mệt", "áp lực", "buồn", "ốm", "stress"]):
            mood_hint = f"\n\n⚠️ *Lưu ý tâm trạng:* Hôm nay {partner_name} đang cảm thấy *{partner_mood}*. {user_name} nhớ trò chuyện nhẹ nhàng, chuẩn bị một món ấm nóng hoặc gửi lời hỏi thăm ấm áp nhé! 💕"
        elif any(w in str(partner_mood).lower() for w in ["vui", "ngọt ngào", "hào hứng", "yêu"]):
            mood_hint = f"\n\n✨ *Điểm cộng hôm nay:* Hôm nay {partner_name} đang trong tâm trạng rất *{partner_mood}*. Đây là cơ hội vàng để {user_name} hẹn hò hoặc tạo bất ngờ đấy!"

        # Topic: Muốn có người yêu / cưa đổ / crush
        if any(k in lower for k in ["có người yêu", "tán", "cưa", "crush", "thích một người", "làm quen", "người yêu"]):
            target = partner_name if partner_name != "Người ấy" else "người bạn đang để ý"
            return (
                f"Chào {user_name}! 💕 Quân sư hoàn toàn có thể giúp bạn!\n\n"
                f"Để chinh phục được trái tim của {target}, quân sư mách bạn lộ trình 4 bước 'chậm mà chắc' cực kỳ hiệu quả này nhé:\n\n"
                f"1. **Tạo điểm chạm tự nhiên (Tuần 1):**\n"
                f"   • Đừng vội vã tỏ tình ngay. Hãy tương tác nhẹ nhàng qua story, hỏi thăm về những điều {target} thích.\n"
                f"   • Ghi nhớ những chi tiết nhỏ ({partner_hobbies}) để lưu vào Ourly.\n\n"
                f"2. **Buổi hẹn 'vô tình nhưng hữu ý' (Tuần 2):**\n"
                f"   • Mời {target} một buổi cafe nhẹ nhàng hoặc đi ăn món hai người cùng thích.\n"
                f"   • Hãy lắng nghe 70% và chia sẻ 30%, để đối phương cảm thấy được thấu hiểu.\n\n"
                f"3. **Tạo sự rung động tinh tế:**\n"
                f"   • Một hành động ấm áp bất ngờ: che ô khi mưa, kéo ghế, hay gửi một tin nhắn nhắc nhở giữ ấm khi trời trở lạnh.\n\n"
                f"4. **Chọn thời điểm mở lòng:**\n"
                f"   • Khi cả hai đã thoải mái bên nhau, hãy thành thật chia sẻ: *'Ở cạnh {target}, mình luôn thấy rất bình yên và muốn được đồng hành cùng bạn nhiều hơn.'*\n\n"
                f"✨ {user_name} ơi, hãy kể thêm cho quân sư về phản ứng của {target} nhé!"
                f"{mood_hint}"
            )

        # Topic: Buổi hẹn hò
        if any(k in lower for k in ["hẹn", "cuối tuần", "đi đâu", "date", "chơi", "ăn"]):
            days_str = f" sau {days_together} ngày bên nhau" if days_together else ""
            return (
                f"✨ **Lịch trình hẹn hò ngọt ngào cho {user_name} và {partner_name}{days_str}:**\n\n"
                f"Dựa trên gu của hai bạn (Sở thích: {partner_hobbies}; Ghi chú: {prefs_str}), quân sư gợi ý kế hoạch lý tưởng:\n\n"
                f"1. **Chiều tà (17:30):** Cùng dạo bước ngắm hoàng hôn, tận hưởng làn gió mát và chia sẻ về những câu chuyện trong tuần.\n"
                f"2. **Tối (19:00):** Thưởng thức bữa tối ấm cúng tại một không gian riêng tư, thưởng thức các món ăn hợp khẩu vị của {partner_name}.\n"
                f"3. **Đêm (20:30):** Ghé một quán cafe acoustic nhạc nhẹ, nhâm nhi đồ uống yêu thích trong ánh đèn vàng lãng mạn.\n\n"
                f"💡 *Gợi ý nhỏ cho {user_name}:* Hãy hỏi {partner_name}: *'Khoảnh khắc nào trong tuần này làm em/anh thấy ấm lòng nhất?'* để hai bạn gắn kết sâu sắc hơn!"
                f"{mood_hint}"
            )

        # Topic: Quà tặng / Kỷ niệm
        if any(k in lower for k in ["quà", "kỷ niệm", "sinh nhật", "tặng"]):
            target_bday = ctx["partnerBirthday"]
            bday_note = f" (Sắp tới ngày sinh nhật {target_bday} của {partner_name} rồi đấy!)" if target_bday != "Chưa rõ" else ""
            return (
                f"💐 **Ý tưởng quà tặng tinh tế cho {partner_name}{bday_note}:**\n\n"
                f"1. **Món quà theo gu cá nhân:** Dựa vào sở thích ({partner_hobbies}), hãy chọn một món đồ mà {partner_name} hay dùng hàng ngày (ly giữ nhiệt xinh xắn, nước hoa thơm dịu hoặc món đồ handmade).\n"
                f"2. **Hộp ký ức Ourly:** In 5-10 bức ảnh đẹp nhất của hai bạn kèm lời nhắn viết tay chân thành từ trái tim của {user_name}.\n"
                f"3. **Một trải nghiệm đặc biệt:** Một buổi xem phim ngoài trời, workshop làm gốm hoặc một chuyến picnic cuối tuần.\n\n"
                f"🎁 *Bí kíp:* Sự chân thành và việc bạn nhớ được những sở thích nhỏ của {partner_name} chính là món quà đắt giá nhất!"
                f"{mood_hint}"
            )

        # Topic: Giận dỗi / Làm lành
        if any(k in lower for k in ["giận", "im lặng", "cãi nhau", "làm lành", "buồn", "dỗi"]):
            return (
                f"🕊️ **Quân sư chia sẻ bí kíp làm lành cùng {partner_name}:**\n\n"
                f"1. **Hạ nhiệt cảm xúc:** Đừng tranh luận 'ai đúng ai sai'. Mối quan hệ của {user_name} và {partner_name} quý giá hơn việc thắng thua một cuộc tranh luận.\n"
                f"2. **Hành động quan tâm tinh tế:** Mang đến một món đồ uống yêu thích (như trà sữa ít đường hoặc đồ ăn nóng) kèm lời nhắn: *'Mình để đây cho người ấy nhé, mong người ấy bớt mệt mỏi.'*\n"
                f"3. **Chân thành mở lời:** Thử nhắn: *'Mình biết vừa rồi tụi mình chưa hiểu nhau. {user_name} rất trân trọng {partner_name} và muốn lắng nghe cảm xúc của bạn khi bạn sẵn sàng.'*\n\n"
                f"Sự dịu dàng và chân thành luôn là chiếc chìa khóa mở lối trái tim! 🌸"
                f"{mood_hint}"
            )

        # Default personalized greeting & advice
        days_str = f" Hai bạn đã đồng hành được **{days_together} ngày** tuyệt đẹp!" if days_together else ""
        return (
            f"💖 Chào {user_name}! Quân sư Ourly luôn sẵn sàng đồng hành cùng bạn.{days_str}\n\n"
            f"Hiện tại quân sư đã nắm rõ thông tin của bạn và {partner_name} (Sở thích: {partner_hobbies}).\n\n"
            f"Bạn có thể hỏi quân sư bất cứ điều gì:\n"
            f"• *'Cách mở lời bắt chuyện tự nhiên với {partner_name}'* 💬\n"
            f"• *'Gợi ý lịch trình hẹn hò cuối tuần thật lãng mạn'* 🍷\n"
            f"• *'Ý tưởng quà tặng khiến {partner_name} bất ngờ'* 🎁\n"
            f"• *'Cách quan tâm khi {partner_name} mệt mỏi'* 🕊️\n\n"
            f"{user_name} cứ thoải mái chia sẻ với quân sư nhé! 💕"
            f"{mood_hint}"
        )

    @classmethod
    def _generate_follow_ups(cls, query: str, ctx: Dict[str, Any]) -> List[str]:
        return [
            "🍷 Gợi ý buổi hẹn lãng mạn cuối tuần",
            "🎁 Ý tưởng bất ngờ làm người ấy vui",
            "💐 Gợi ý quà tặng kỷ niệm ý nghĩa",
            "💬 Cách mở lời tự nhiên khi bắt chuyện",
        ]
