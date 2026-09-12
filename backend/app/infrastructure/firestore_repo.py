import os
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone

from app.infrastructure.firebase import get_db
from app.infrastructure.mock_db import (
    mock_couples,
    mock_user_couple,
    mock_invites,
    mock_preferences,
    mock_users,
    mock_users_by_email,
    mock_chat_messages,
)
from app.domain.schemas.couple import CoupleSpace, CoupleStatus, Participant
from app.domain.schemas.invite import Invite, InviteStatus
from app.domain.schemas.preference import Preference, PreferenceVisibility

def is_firestore_enabled() -> bool:
    """Return True if Firestore should be used (not in mock unit-test mode)."""
    from app.core.config import settings
    if settings.DEMO_MODE or os.getenv("TESTING") == "1":
        return False
    return get_db() is not None

class FirestoreRepo:
    # -------------------------------------------------------------
    # USERS
    # -------------------------------------------------------------
    @staticmethod
    def get_user(uid: str) -> Optional[Dict[str, Any]]:
        if is_firestore_enabled():
            try:
                db = get_db()
                doc = db.collection("users").document(uid).get()
                if doc.exists:
                    return doc.to_dict()
            except Exception as e:
                print(f"[FirestoreRepo] Error reading user {uid}: {e}")
        
        # Fallback
        if uid in mock_users:
            return mock_users[uid]
        cid = mock_user_couple.get(uid)
        return {"uid": uid, "activeCoupleId": cid}

    @staticmethod
    def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
        norm_email = email.strip().lower()
        if is_firestore_enabled():
            try:
                db = get_db()
                docs = list(db.collection("users").where("email", "==", norm_email).limit(1).stream())
                if docs:
                    return docs[0].to_dict()
            except Exception as e:
                print(f"[FirestoreRepo] Error finding user by email {norm_email}: {e}")

        # Fallback from mock
        if norm_email in mock_users_by_email:
            return mock_users_by_email[norm_email]
        for u in mock_users.values():
            if u.get("email", "").lower() == norm_email:
                return u
        return None

    @staticmethod
    def save_or_update_user(uid: str, data: Dict[str, Any]) -> Dict[str, Any]:
        now_str = datetime.now(timezone.utc).isoformat()
        clean_data = {k: v for k, v in data.items() if v is not None}
        clean_data["uid"] = uid
        clean_data["updatedAt"] = now_str
        
        if is_firestore_enabled():
            try:
                db = get_db()
                ref = db.collection("users").document(uid)
                existing = ref.get()
                if not existing.exists:
                    clean_data["createdAt"] = clean_data.get("createdAt") or now_str
                    ref.set(clean_data)
                else:
                    ref.set(clean_data, merge=True)
            except Exception as e:
                print(f"[FirestoreRepo] Error saving user {uid}: {e}")
                
        # Sync mock
        existing_mock = mock_users.get(uid, {})
        existing_mock.update(clean_data)
        mock_users[uid] = existing_mock
        if "email" in clean_data and clean_data["email"]:
            mock_users_by_email[clean_data["email"].strip().lower()] = existing_mock

        if "activeCoupleId" in clean_data:
            if clean_data["activeCoupleId"]:
                mock_user_couple[uid] = clean_data["activeCoupleId"]
            elif uid in mock_user_couple:
                del mock_user_couple[uid]

        # Sync participant nickname in couple space if changed
        if "nickname" in clean_data and clean_data["nickname"]:
            couple_id = clean_data.get("activeCoupleId") or FirestoreRepo.get_user_active_couple_id(uid)
            if couple_id:
                couple = FirestoreRepo.get_couple(couple_id)
                if couple:
                    changed = False
                    for p in couple.participants:
                        if p.linkedUserId == uid:
                            p.nickname = clean_data["nickname"]
                            changed = True
                    if changed:
                        FirestoreRepo.save_couple(couple)
                
        return clean_data

    @staticmethod
    def set_user_active_couple(uid: str, couple_id: Optional[str]):
        FirestoreRepo.save_or_update_user(uid, {"activeCoupleId": couple_id})

    @staticmethod
    def get_user_active_couple_id(uid: str) -> Optional[str]:
        user = FirestoreRepo.get_user(uid)
        if user and user.get("activeCoupleId"):
            return user.get("activeCoupleId")
        return mock_user_couple.get(uid)

    # -------------------------------------------------------------
    # COUPLES
    # -------------------------------------------------------------
    @staticmethod
    def save_couple(couple: CoupleSpace) -> CoupleSpace:
        couple_data = couple.model_dump(mode="json")
        if is_firestore_enabled():
            try:
                db = get_db()
                db.collection("couples").document(couple.id).set(couple_data)
            except Exception as e:
                print(f"[FirestoreRepo] Error saving couple {couple.id}: {e}")
                
        mock_couples[couple.id] = couple
        return couple

    @staticmethod
    def get_couple(couple_id: str) -> Optional[CoupleSpace]:
        if is_firestore_enabled():
            try:
                db = get_db()
                doc = db.collection("couples").document(couple_id).get()
                if doc.exists:
                    return CoupleSpace(**doc.to_dict())
            except Exception as e:
                print(f"[FirestoreRepo] Error reading couple {couple_id}: {e}")
                
        return mock_couples.get(couple_id)

    @staticmethod
    def update_couple(couple: CoupleSpace) -> CoupleSpace:
        couple.updatedAt = datetime.now(timezone.utc)
        return FirestoreRepo.save_couple(couple)

    @staticmethod
    def get_active_couple_for_user(uid: str) -> Optional[CoupleSpace]:
        cid = FirestoreRepo.get_user_active_couple_id(uid)
        if cid:
            c = FirestoreRepo.get_couple(cid)
            if c and c.status != CoupleStatus.archived:
                return c

        # Scan active couples if activeCoupleId was not set yet
        if is_firestore_enabled():
            try:
                db = get_db()
                # Query couples collection
                docs = db.collection("couples").stream()
                for doc in docs:
                    data = doc.to_dict()
                    parts = data.get("participants", [])
                    if any(p.get("linkedUserId") == uid for p in parts):
                        if data.get("status") in [CoupleStatus.solo.value, CoupleStatus.connected.value]:
                            couple = CoupleSpace(**data)
                            FirestoreRepo.set_user_active_couple(uid, couple.id)
                            return couple
            except Exception as e:
                print(f"[FirestoreRepo] Error scanning couples for {uid}: {e}")

        # Mock fallback
        mock_cid = mock_user_couple.get(uid)
        if mock_cid and mock_cid in mock_couples:
            return mock_couples[mock_cid]
            
        return None

    # -------------------------------------------------------------
    # INVITES
    # -------------------------------------------------------------
    @staticmethod
    def save_invite(invite: Invite) -> Invite:
        inv_data = invite.model_dump(mode="json")
        if is_firestore_enabled():
            try:
                db = get_db()
                db.collection("invites").document(invite.id).set(inv_data)
            except Exception as e:
                print(f"[FirestoreRepo] Error saving invite {invite.id}: {e}")
                
        mock_invites[invite.id] = invite
        return invite

    @staticmethod
    def get_invite(invite_id: str) -> Optional[Invite]:
        if is_firestore_enabled():
            try:
                db = get_db()
                doc = db.collection("invites").document(invite_id).get()
                if doc.exists:
                    return Invite(**doc.to_dict())
            except Exception as e:
                print(f"[FirestoreRepo] Error reading invite {invite_id}: {e}")
                
        return mock_invites.get(invite_id)

    @staticmethod
    def get_invite_by_token(token: str) -> Optional[Invite]:
        if is_firestore_enabled():
            try:
                db = get_db()
                docs = db.collection("invites").where("tokenHash", "==", token).limit(1).get()
                for doc in docs:
                    return Invite(**doc.to_dict())
            except Exception as e:
                print(f"[FirestoreRepo] Error reading invite by token {token}: {e}")
                
        return next((i for i in mock_invites.values() if i.tokenHash == token), None)

    @staticmethod
    def revoke_pending_invites_for_couple(couple_id: str):
        if is_firestore_enabled():
            try:
                db = get_db()
                docs = db.collection("invites").where("coupleId", "==", couple_id).where("status", "==", InviteStatus.pending.value).get()
                for doc in docs:
                    doc.reference.update({"status": InviteStatus.revoked.value})
            except Exception as e:
                print(f"[FirestoreRepo] Error revoking pending invites: {e}")
                
        for inv in mock_invites.values():
            if inv.coupleId == couple_id and inv.status == InviteStatus.pending:
                inv.status = InviteStatus.revoked

    @staticmethod
    def update_invite(invite: Invite) -> Invite:
        return FirestoreRepo.save_invite(invite)

    # -------------------------------------------------------------
    # PREFERENCES
    # -------------------------------------------------------------
    @staticmethod
    def save_preference(pref: Preference) -> Preference:
        pref_data = pref.model_dump(mode="json")
        if is_firestore_enabled():
            try:
                db = get_db()
                db.collection("preferences").document(pref.id).set(pref_data)
            except Exception as e:
                print(f"[FirestoreRepo] Error saving preference {pref.id}: {e}")
                
        if pref.coupleId not in mock_preferences:
            mock_preferences[pref.coupleId] = []
        # Replace or append
        existing = next((i for i, p in enumerate(mock_preferences[pref.coupleId]) if p.id == pref.id), None)
        if existing is not None:
            mock_preferences[pref.coupleId][existing] = pref
        else:
            mock_preferences[pref.coupleId].append(pref)
            
        return pref

    @staticmethod
    def get_preferences_for_couple(couple_id: str) -> List[Preference]:
        if is_firestore_enabled():
            try:
                db = get_db()
                docs = db.collection("preferences").where("coupleId", "==", couple_id).get()
                if docs:
                    return [Preference(**d.to_dict()) for d in docs]
            except Exception as e:
                print(f"[FirestoreRepo] Error reading preferences for {couple_id}: {e}")
                
        return mock_preferences.get(couple_id, [])

    @staticmethod
    def get_preference(couple_id: str, pref_id: str) -> Optional[Preference]:
        if is_firestore_enabled():
            try:
                db = get_db()
                doc = db.collection("preferences").document(pref_id).get()
                if doc.exists:
                    data = doc.to_dict()
                    if data.get("coupleId") == couple_id:
                        return Preference(**data)
            except Exception as e:
                print(f"[FirestoreRepo] Error reading preference {pref_id}: {e}")
                
        prefs = mock_preferences.get(couple_id, [])
        return next((p for p in prefs if p.id == pref_id), None)

    @staticmethod
    def update_preference(pref: Preference) -> Preference:
        pref.updatedAt = datetime.now(timezone.utc)
        return FirestoreRepo.save_preference(pref)

    @staticmethod
    def delete_preference(couple_id: str, pref_id: str) -> bool:
        if is_firestore_enabled():
            try:
                db = get_db()
                db.collection("preferences").document(pref_id).delete()
            except Exception as e:
                print(f"[FirestoreRepo] Error deleting preference {pref_id}: {e}")
                
        prefs = mock_preferences.get(couple_id, [])
        mock_preferences[couple_id] = [p for p in prefs if p.id != pref_id]
        return True

    # -------------------------------------------------------------
    # CHAT HISTORY
    # -------------------------------------------------------------
    @staticmethod
    def save_chat_message(uid: str, msg_data: Dict[str, Any]) -> Dict[str, Any]:
        msg_id = msg_data.get("id") or f"msg-{int(datetime.now(timezone.utc).timestamp() * 1000)}"
        msg_data["id"] = msg_id
        msg_data["uid"] = uid
        if "createdAt" not in msg_data:
            msg_data["createdAt"] = datetime.now(timezone.utc).isoformat()

        if is_firestore_enabled():
            try:
                db = get_db()
                db.collection("users").document(uid).collection("chat_messages").document(msg_id).set(msg_data)
            except Exception as e:
                print(f"[FirestoreRepo] Error saving chat message {msg_id}: {e}")

        if uid not in mock_chat_messages:
            mock_chat_messages[uid] = []
        mock_chat_messages[uid].append(msg_data)
        return msg_data

    @staticmethod
    def get_chat_history(uid: str, limit: int = 100) -> List[Dict[str, Any]]:
        if is_firestore_enabled():
            try:
                db = get_db()
                docs = (
                    db.collection("users")
                    .document(uid)
                    .collection("chat_messages")
                    .order_by("createdAt")
                    .limit(limit)
                    .get()
                )
                if docs:
                    return [d.to_dict() for d in docs]
            except Exception as e:
                print(f"[FirestoreRepo] Error reading chat history for {uid}: {e}")

        return mock_chat_messages.get(uid, [])

    @staticmethod
    def clear_chat_history(uid: str) -> bool:
        if is_firestore_enabled():
            try:
                db = get_db()
                docs = db.collection("users").document(uid).collection("chat_messages").get()
                for d in docs:
                    d.reference.delete()
            except Exception as e:
                print(f"[FirestoreRepo] Error clearing chat history for {uid}: {e}")

        mock_chat_messages[uid] = []
        return True
