# Couple Setup & Partner Profile Contract

## 1. Overview
Hợp đồng dữ liệu và quy tắc nghiệp vụ cho tính năng **Partner Profile & Couple Space** giữa Flutter Client và Python FastAPI Backend.

## 2. Quy tắc nghiệp vụ (Business Rules)
- **Quyền sở hữu không gian (Space Membership)**:
  - Một Couple Space có tối đa 2 thành viên (`creator` và `invitee`).
  - Trạng thái Couple Space: `solo` (1 thành viên) $\rightarrow$ `connected` (2 thành viên) $\rightarrow$ `archived`.
  - Mỗi tài khoản (UID) chỉ thuộc về tối đa 1 Couple Space đang hoạt động (`activeCoupleId`).
- **Danh tính người tham gia (Participants)**:
  - Khi tạo `solo` space, hệ thống khởi tạo 2 participant record với ID cố định:
    - **Participant A**: liên kết trực tiếp với `uid` của người tạo (`role: creator`).
    - **Participant B**: placeholder cho đối phương (`role: invitee`, `linkedUserId: null`, `nickname: Partner`).
  - Khi partner chấp nhận lời mời (Accept Invite), hệ thống cập nhật `linkedUserId` của Participant B thành `uid` của partner và đổi trạng thái space sang `connected`. ID của Participant B và mọi preferences liên kết với Participant B được giữ nguyên vẹn.
- **Quyền riêng tư & Kế hoạch bất ngờ (Privacy & Surprise)**:
  - `visibility: shared`: Cả 2 thành viên trong không gian đều đọc được.
  - `visibility: private`: Chỉ người tạo (`createdByUserId == uid`) đọc được.
  - `type: Surprise`: Kế hoạch bất ngờ luôn được bảo vệ nghiêm ngặt như `private` và không bao giờ xuất hiện trong danh sách trả về cho partner.
  - Người ngoài (User C) không thuộc Couple Space: nhận lỗi `403 FORBIDDEN` khi cố gắng truy cập.

---

## 3. API Specifications

### 3.1. Users
- **`GET /v1/me`**
  - Header: `Authorization: Bearer <token>`
  - Response:
    ```json
    {
      "uid": "string",
      "activeCoupleId": "string | null"
    }
    ```

### 3.2. Couple Space
- **`POST /v1/couples?nickname={name}`**
  - Tạo solo Couple Space.
  - Response: `CoupleSpace`
- **`GET /v1/couples/current`**
  - Lấy thông tin space hiện tại của user đang đăng nhập.
  - Response: `CoupleSpace`
- **`PATCH /v1/couples/{coupleId}/participants/{participantId}`**
  - Body: `{"nickname": "string"}`
  - Quyền: Chỉ thành viên của space mới được sửa.

### 3.3. Invites
- **`POST /v1/couples/{coupleId}/invites`**
  - Tạo lời mời mới. Token dạng ngắn gọn `LV-XXXXXX`. Thời hạn 72 giờ.
  - Tự động vô hiệu hóa (revoke) lời mời cũ nếu còn pending.
  - Response: `Invite`
- **`DELETE /v1/couples/{coupleId}/invites/{inviteId}`**
  - Thu hồi lời mời.
- **`POST /v1/invites/preview`**
  - Body: `{"token": "LV-XXXXXX"}`
  - Response: `{"inviterNickname": "string", "status": "pending", "expiresAt": "ISO8601"}` (Không lộ preferences hay thông tin nhạy cảm).
- **`POST /v1/invites/accept?nickname={name}`**
  - Body: `{"token": "LV-XXXXXX"}`
  - Logic: Kiểm tra hợp lệ, liên kết UID vào Participant B, chuyển Couple Space sang `connected`.

### 3.4. Preferences
- **`GET /v1/couples/{coupleId}/preferences`**
  - Response: `List[Preference]`
  - Backend tự động lọc: Chỉ trả về các mục `shared` + các mục `private` do chính user yêu cầu tạo. Không trả về private/surprise của người khác.
- **`POST /v1/couples/{coupleId}/preferences`**
  - Body:
    ```json
    {
      "subjectParticipantId": "string",
      "type": "string",
      "value": "string",
      "visibility": "private | shared"
    }
    ```
  - Backend tự gán `createdByUserId = uid` và `source = selfDeclared | partnerObserved`.
- **`PATCH /v1/couples/{coupleId}/preferences/{preferenceId}`**
  - Cập nhật `value` hoặc `visibility`. Chỉ người tạo mới có quyền sửa.
- **`DELETE /v1/couples/{coupleId}/preferences/{preferenceId}`**
  - Xóa preference. Chỉ người tạo mới có quyền xóa.
