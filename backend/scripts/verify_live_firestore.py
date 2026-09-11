import os
import sys
# Ensure UTF-8 output on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

if "TESTING" in os.environ:
    del os.environ["TESTING"]

from datetime import datetime, timezone, timedelta
import uuid
from app.infrastructure.firebase import init_firebase, get_db
from app.infrastructure.firestore_repo import FirestoreRepo
from app.domain.schemas.couple import CoupleSpace, Participant, CoupleStatus, ParticipantRole
from app.domain.schemas.invite import Invite, InviteStatus
from app.domain.schemas.preference import Preference, PreferenceVisibility, PreferenceSource

def run_live_firestore_verification():
    print("=== STARTING LIVE FIRESTORE VERIFICATION ===")
    init_firebase()
    db = get_db()
    if not db:
        raise RuntimeError("Could not connect to Firestore!")
    print(f"[OK] Connected to Firestore project: {db.project}")

    test_uid = f"test-user-{uuid.uuid4().hex[:8]}"
    test_couple_id = f"couple-{uuid.uuid4().hex[:8]}"
    test_invite_id = f"inv-{uuid.uuid4().hex[:8]}"
    test_pref_id = f"pref-{uuid.uuid4().hex[:8]}"
    test_token = f"LV-TEST"

    try:
        # 1. Test Users Collection
        print("\n1. Testing Users Collection...")
        user_data = {
            "uid": test_uid,
            "email": "minh@gmail.com",
            "nickname": "Minh",
            "birthday": "15/08/2000",
            "avatar": "cat",
            "activeCoupleId": test_couple_id,
            "createdAt": datetime.now(timezone.utc).isoformat()
        }
        saved_user = FirestoreRepo.save_or_update_user(test_uid, user_data)
        read_user = FirestoreRepo.get_user(test_uid)
        assert read_user is not None, "Failed to read user from Firestore"
        assert read_user.get("nickname") == "Minh"
        assert read_user.get("birthday") == "15/08/2000"
        print(f"[OK] User document created and verified: {read_user['nickname']}")

        # 2. Test Couples Collection
        print("\n2. Testing Couples Collection...")
        now = datetime.now(timezone.utc)
        part_a = Participant(
            id=f"part-a-{test_uid}",
            linkedUserId=test_uid,
            nickname="Minh",
            role=ParticipantRole.creator,
            createdAt=now
        )
        part_b = Participant(
            id="part-b-placeholder",
            linkedUserId=None,
            nickname="Partner",
            role=ParticipantRole.invitee,
            createdAt=now
        )
        couple = CoupleSpace(
            id=test_couple_id,
            status=CoupleStatus.solo,
            participants=[part_a, part_b],
            createdAt=now,
            updatedAt=now
        )
        FirestoreRepo.save_couple(couple)
        read_couple = FirestoreRepo.get_couple(test_couple_id)
        assert read_couple is not None, "Failed to read couple from Firestore"
        assert read_couple.status == CoupleStatus.solo
        assert len(read_couple.participants) == 2
        print(f"[OK] Couple document created and verified: {read_couple.id} (status: {read_couple.status.value})")

        # 3. Test Invites Collection
        print("\n3. Testing Invites Collection...")
        invite = Invite(
            id=test_invite_id,
            coupleId=test_couple_id,
            tokenHash=test_token,
            status=InviteStatus.pending,
            expiresAt=now + timedelta(hours=72),
            createdAt=now
        )
        FirestoreRepo.save_invite(invite)
        found_invite = FirestoreRepo.get_invite_by_token(test_token)
        assert found_invite is not None, "Failed to query invite by token from Firestore"
        assert found_invite.id == test_invite_id
        print(f"[OK] Invite document created and queried by token: {found_invite.tokenHash}")

        # 4. Test Preferences Collection (including Surprise)
        print("\n4. Testing Preferences Collection...")
        pref = Preference(
            id=test_pref_id,
            coupleId=test_couple_id,
            subjectParticipantId=part_b.id,
            createdByUserId=test_uid,
            source=PreferenceSource.partnerObserved,
            type="Surprise",
            value="Sunset picnic with red roses",
            visibility=PreferenceVisibility.private,
            createdAt=now,
            updatedAt=now
        )
        FirestoreRepo.save_preference(pref)
        read_pref = FirestoreRepo.get_preference(test_couple_id, test_pref_id)
        assert read_pref is not None, "Failed to read preference from Firestore"
        assert read_pref.value == "Sunset picnic with red roses"
        assert read_pref.type == "Surprise"
        print(f"[OK] Preference document created: {read_pref.type} - {read_pref.value}")

        print("\n=== ALL LIVE FIRESTORE CRUD OPERATIONS PASSED SUCCESSFULLY! ===")

    finally:
        print("\nCleaning up test documents from Firestore...")
        try:
            db.collection("users").document(test_uid).delete()
            db.collection("couples").document(test_couple_id).delete()
            db.collection("invites").document(test_invite_id).delete()
            db.collection("preferences").document(test_pref_id).delete()
            print("[OK] Test documents cleaned up cleanly.")
        except Exception as e:
            print(f"[WARN] Cleanup note: {e}")

if __name__ == "__main__":
    run_live_firestore_verification()
