import re
import httpx
from typing import List, Optional, Dict, Any
from app.core.config import settings
from app.infrastructure.firestore_repo import FirestoreRepo
from app.domain.schemas.chat import ChatMessageItem, ChatResponse
from app.domain.schemas.couple import CoupleStatus

class AIService:
    DEMO_PREFERENCES = [
        "Romantic",
        "Dessert",
        "Beach",
        "Cozy",
        "Quiet",
        "Photography",
        "Favorite dessert: Cheesecake",
        "Favorite flower: Tulip",
        "Favorite drink: Matcha",
    ]

    @staticmethod
    def _build_context(uid: str) -> Dict[str, Any]:
        """Collect user profile, partner profile, and preferences from Firestore."""
        user_doc = FirestoreRepo.get_user(uid) or {}
        user_name = user_doc.get("nickname") or "Alex"
        user_bday = user_doc.get("birthday") or "Chưa cập nhật"
        
        couple = FirestoreRepo.get_active_couple_for_user(uid)
        partner_name = "Emma"
        partner_bday = "Chưa rõ"
        has_partner = False
        preferences_text = []
        
        if couple:
            # Find current participant and partner participant
            for p in couple.participants:
                if p.linkedUserId == uid:
                    user_name = p.nickname or user_name
                else:
                    if p.nickname and p.nickname.lower() != "partner":
                        partner_name = p.nickname
                    if p.linkedUserId is not None:
                        has_partner = True
                        p_user = FirestoreRepo.get_user(p.linkedUserId)
                        if p_user and p_user.get("birthday"):
                            partner_bday = p_user.get("birthday")
            
            # Get preferences from Firestore
            prefs = FirestoreRepo.get_preferences_for_couple(couple.id)
            for pref in prefs:
                if pref.type.lower() == "surprise":
                    if pref.createdByUserId == uid:
                        preferences_text.append(f"Kế hoạch bất ngờ đang ấp ủ: {pref.value}")
                else:
                    preferences_text.append(f"{pref.type}: {pref.value}")

        if not preferences_text:
            preferences_text = AIService.DEMO_PREFERENCES.copy()

        return {
            "userName": user_name,
            "userBirthday": user_bday,
            "hasPartner": has_partner,
            "partnerName": partner_name,
            "partnerBirthday": partner_bday,
            "preferences": preferences_text,
            "coupleStatus": couple.status.value if couple else "chưa tạo không gian",
            "occasion": "Anniversary còn 3 ngày",
            "budget": "500,000 VND",
        }

    @staticmethod
    def _build_system_prompt(context: Dict[str, Any]) -> str:
        user_name = context["userName"]
        partner_name = context["partnerName"]
        has_partner = context["hasPartner"]
        prefs = "\n- ".join(context["preferences"]) if context["preferences"] else "Chưa có thông tin cụ thể (bạn có thể hỏi người dùng thêm)"
        
        status_desc = f"Đã kết nối cùng {partner_name}" if has_partner else f"Đang ở chế độ Solo / Tìm kiếm người yêu (đối tượng quan tâm: {partner_name})"

        return f"""Bạn là "Quân sư Tình yêu Ourly" (Ourly Love Advisor) - một chuyên gia tâm lý tình cảm, cố vấn hẹn hò và quân sư tình yêu thông minh, ấm áp, sâu sắc và duyên dáng.

THÔNG TIN NGƯỜI DÙNG HIỆN TẠI (TỪ HỆ THỐNG OURLY):
- Tên người dùng: {user_name}
- Ngày sinh người dùng: {context["userBirthday"]}
- Trạng thái tình cảm: {status_desc}
- Tên người ấy / đối phương: {partner_name}
- Ngày sinh đối phương: {context["partnerBirthday"]}
- Dịp sắp tới: {context["occasion"]}
- Ngân sách: {context["budget"]}
- Các sở thích & ghi chú đã lưu trong hệ thống:
- {prefs}

NGUYÊN TẮC CỐ VẤN:
1. Xưng hô: Gọi tên "{user_name}" một cách thân mật, xưng là "mình" hoặc "Quân sư".
2. Cá nhân hóa tối đa: Luôn lồng ghép tên {user_name}, tên {partner_name}, ngày sinh và các sở thích ở trên vào câu trả lời để tạo sự gần gũi, chân thực.
3. Nếu người dùng muốn có người yêu / cưa đổ ai đó: Đưa ra chiến lược 3-4 bước thực tế (mở lời bắt chuyện, nắm bắt tâm lý, cách tạo thiện cảm, chọn thời điểm ngỏ lời).
4. Nếu người dùng hỏi về buổi hẹn hò: Gợi ý lịch trình hẹn hò chi tiết (thời gian, địa điểm, hoạt động, câu hỏi để hai bạn hiểu nhau hơn).
5. Nếu hỏi về quà tặng / bất ngờ: Gợi ý món quà tinh tế chạm đúng cảm xúc và sở thích của {partner_name}.
6. Giọng văn: Ấm áp, hài hước nhẹ nhàng, thấu hiểu, định dạng gạch đầu dòng rõ ràng và dùng emoji sinh động (💕, 🪽, ✨, 💐, 🥂, 🎁).
7. TỰ ĐỘNG ĐƯA RA CÁC NÚT TÙY CHỌN (OPTION BUTTONS):
Khi bạn hỏi lại người dùng hoặc khi bạn thấy thiếu thông tin (như gu hẹn hò, ngân sách, lý do giận dỗi, mức độ quan hệ, sở thích ăn uống...), hoặc khi cần gợi ý các hướng đi tiếp theo:
BẮT BUỘC đặt ở cuối cùng của câu trả lời cú pháp:
[OPTIONS: Lựa chọn 1 | Lựa chọn 2 | Lựa chọn 3 | Lựa chọn 4]
Ví dụ:
[OPTIONS: 🥂 Lãng mạn, ấm cúng | ☕ Quán cafe acoustic | 🍜 Ăn vặt dạo đêm | 🏕️ Dã ngoại ngoài trời]
Mỗi lựa chọn ngắn gọn từ 3 đến 6 từ kèm emoji ở đầu."""

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
        if any(k in lower for k in ["anniversary", "kỷ niệm", "500k", "500 k"]):
            return [
                "Biến thành một moment ❤️",
                "💕 Xem thêm gợi ý",
                "💵 Đổi ngân sách",
            ]
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
    def generate_reply(cls, uid: str, message: str, history: List[ChatMessageItem]) -> ChatResponse:
        if settings.DEMO_MODE and uid in ("demo-alex", "demo-emma"):
            from app.api.routes.demo import reply
            return reply(message, history)
        context = cls._build_context(uid)
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

        # 2. Smart Contextual Rule Engine fallback (using real Firestore data)
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
        prefs_str = ", ".join(ctx["preferences"]) if ctx["preferences"] else "chưa có ghi chú cụ thể"
        lower = query.lower()

        # Deterministic hackathon scenario from the demo preparation document.
        if any(k in lower for k in ["anniversary", "kỷ niệm", "500k", "500 k"]):
            return (
                f"Alex ơi, Anniversary của bạn và Emma chỉ còn 3 ngày nữa 💕\n\n"
                f"Dựa trên những điều Ourly đã ghi nhớ — Emma thích **không gian lãng mạn, yên tĩnh, gần biển**, "
                f"thích **chụp ảnh** và đặc biệt mê **cheesecake** — mình gợi ý một buổi hẹn vừa đủ trong ngân sách 500K:\n\n"
                f"• Bữa tối cozy và nhẹ nhàng\n"
                f"• Một phần cheesecake dành cho Emma\n"
                f"• Đi dạo biển lúc hoàng hôn để hai bạn có thời gian riêng\n\n"
                f"💌 Bí mật nhỏ: hãy mang theo một bó **hoa Tulip** cô ấy thích và tặng vào cuối buổi hẹn."
                f"\n\n[OPTIONS: Biến thành một moment ❤️ | 💕 Xem thêm gợi ý | 💵 Đổi ngân sách]"
            )

        # Topic: Muốn có người yêu / cưa đổ / crush
        if any(k in lower for k in ["có người yêu", "tán", "cưa", "crush", "thích một người", "làm quen", "người yêu"]):
            target = partner_name if partner_name != "Người ấy" else "người bạn đang để ý"
            return (
                f"Chào {user_name}! 💕 Quân sư hoàn toàn có thể giúp bạn!\n\n"
                f"Để chinh phục được trái tim của {target}, quân sư mách bạn lộ trình 4 bước 'chậm mà chắc' cực kỳ hiệu quả này nhé:\n\n"
                f"1. **Tạo điểm chạm tự nhiên (Tuần 1):**\n"
                f"   • Đừng vội vã tỏ tình ngay. Hãy tương tác nhẹ nhàng qua story, hỏi thăm về những điều {target} thích.\n"
                f"   • Ghi nhớ những chi tiết nhỏ (món đồ uống hay gọi, màu sắc yêu thích) để lưu vào Ourly.\n\n"
                f"2. **Buổi hẹn 'vô tình nhưng hữu ý' (Tuần 2):**\n"
                f"   • Mời {target} một buổi cafe nhẹ nhàng hoặc đi ăn món hai người cùng thích (ví dụ: một quán cafe yên tĩnh hoặc quán ăn ấm cúng).\n"
                f"   • Hãy lắng nghe 70% và chia sẻ 30%, để đối phương cảm thấy được thấu hiểu.\n\n"
                f"3. **Tạo sự rung động tinh tế:**\n"
                f"   • Một hành động ấm áp bất ngờ: che ô khi mưa, kéo ghế, hay gửi một tin nhắn nhắc nhở giữ ấm khi trời trở lạnh.\n\n"
                f"4. **Chọn thời điểm mở lòng:**\n"
                f"   • Khi cả hai đã thoải mái bên nhau, hãy thành thật chia sẻ: *'Ở cạnh bạn/em, mình luôn thấy rất bình yên và muốn được đồng hành cùng bạn/em nhiều hơn.'*\n\n"
                f"✨ {user_name} ơi, bạn đã có đối tượng cụ thể chưa? Kể thêm cho quân sư về sở thích hoặc tính cách của người ấy để mình tư vấn chi tiết hơn nhé!"
            )

        # Topic: Buổi hẹn hò
        if any(k in lower for k in ["hẹn", "cuối tuần", "đi đâu", "date", "chơi"]):
            return (
                f"✨ **Lịch trình hẹn hò ngọt ngào cho {user_name} và {partner_name}:**\n\n"
                f"Dựa trên thông tin của hai bạn ({prefs_str}), quân sư gợi ý kế hoạch lý tưởng:\n\n"
                f"1. **Chiều tà (17:30):** Cùng dạo bước ngắm hoàng hôn bên bờ sông hoặc bãi biển, tận hưởng làn gió mát và chia sẻ về những câu chuyện trong tuần.\n"
                f"2. **Tối (19:00):** Thưởng thức bữa tối ấm cúng tại một không gian riêng tư, nhẹ nhàng với các món ăn yêu thích của {partner_name}.\n"
                f"3. **Đêm (20:30):** Ghé một quán cafe acoustic nhạc nhẹ, lắng nghe giai điệu ngọt ngào trong ánh đèn vàng lãng mạn.\n\n"
                f"💡 *Gợi ý nhỏ cho {user_name}:* Hãy hỏi {partner_name}: *'Khoảnh khắc nào trong tuần này làm em/anh thấy ấm lòng nhất?'* để kéo gần khoảng cách nhé! 💕"
            )

        # Topic: Quà tặng / Kỷ niệm
        if any(k in lower for k in ["quà", "kỷ niệm", "sinh nhật", "tặng"]):
            target_bday = ctx["partnerBirthday"]
            bday_note = f" (Sắp tới ngày sinh nhật {target_bday} của {partner_name} rồi đấy!)" if target_bday != "Chưa rõ" else ""
            return (
                f"💐 **Ý tưởng quà tặng tinh tế cho {partner_name}{bday_note}:**\n\n"
                f"1. **Món quà theo gu cá nhân:** Dựa vào sở thích ({prefs_str}), hãy chọn một món đồ mà {partner_name} hay dùng hàng ngày (ly giữ nhiệt xinh xắn, nước hoa mùi gỗ nhẹ hoặc khăn choàng).\n"
                f"2. **Hộp ký ức Ourly:** In 5-10 bức ảnh đẹp nhất của hai bạn kèm lời nhắn viết tay chân thành từ trái tim của {user_name}.\n"
                f"3. **Một trải nghiệm đặc biệt:** Một buổi xem phim ngoài trời, workshop làm gốm hoặc một chuyến picnic cuối tuần.\n\n"
                f"🎁 *Bí kíp:* Sự chân thành và việc bạn nhớ được những sở thích nhỏ của {partner_name} chính là món quà đắt giá nhất!"
            )

        # Topic: Giận dỗi / Làm lành
        if any(k in lower for k in ["giận", "im lặng", "cãi nhau", "làm lành", "buồn"]):
            return (
                f"🕊️ **Quân sư chia sẻ bí kíp làm lành cùng {partner_name}:**\n\n"
                f"1. **Hạ nhiệt cảm xúc:** Đừng tranh luận 'ai đúng ai sai'. Tình cảm của {user_name} và {partner_name} quý giá hơn việc thắng thua một cuộc tranh cãi.\n"
                f"2. **Hành động quan tâm tinh tế:** Mang đến một món đồ uống yêu thích (như trà sữa ít đường hoặc món bánh ngon) kèm lời nhắn: *'Anh/em để đây cho người ấy nhé, mong người ấy bớt mệt mỏi.'*\n"
                f"3. **Chân thành mở lời:** Thử nhắn: *'Mình biết vừa rồi tụi mình chưa hiểu nhau. {user_name} rất trân trọng {partner_name} và muốn lắng nghe cảm xúc của bạn khi bạn sẵn sàng.'*\n\n"
                f"Sự dịu dàng và kiên nhẫn luôn là chìa khóa mở lối trái tim! 🌸"
            )

        # Default personalized greeting & advice
        return (
            f"💖 Chào {user_name}! Quân sư Ourly luôn sẵn sàng đồng hành cùng bạn.\n\n"
            f"Hiện tại mình đã cập nhật thông tin của bạn và {partner_name} ({prefs_str}).\n\n"
            f"Bạn có thể hỏi quân sư bất cứ điều gì:\n"
            f"• *'Cách bắt chuyện và mở lời với người ấy'* 💬\n"
            f"• *'Gợi ý lịch trình hẹn hò cuối tuần thật lãng mạn'* 🍷\n"
            f"• *'Ý tưởng quà tặng khiến người ấy bất ngờ'* 🎁\n"
            f"• *'Làm sao để người ấy hiểu mình hơn?'* 🕊️\n\n"
            f"{user_name} cứ thoải mái tâm sự nhé! 💕"
        )

    @classmethod
    def _generate_follow_ups(cls, query: str, ctx: Dict[str, Any]) -> List[str]:
        return [
            "🍷 Gợi ý buổi hẹn lãng mạn cuối tuần",
            "🎁 Ý tưởng bất ngờ làm người ấy vui",
            "💐 Gợi ý quà tặng kỷ niệm ý nghĩa",
            "💬 Cách mở lời tự nhiên khi bắt chuyện",
        ]
