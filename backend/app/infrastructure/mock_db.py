# Simple in-memory DB for demo purposes
mock_couples = {}      # coupleId -> CoupleSpace
mock_user_couple = {}  # uid -> coupleId (active)
mock_invites = {}      # inviteId -> Invite
mock_preferences = {}  # coupleId -> List[Preference]
mock_users = {}        # uid -> Dict
mock_users_by_email = {}  # email -> Dict
mock_chat_messages = {}   # uid -> List[Dict]
