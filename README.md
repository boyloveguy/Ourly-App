# 🌸 Ourly App — Hướng dẫn cài đặt & chạy dự án

## 📋 Yêu cầu cài đặt trước

Trước khi bắt đầu, hãy chắc chắn máy đã cài đặt:

| Công cụ | Version tối thiểu | Link tải |
|---|---|---|
| Python | 3.10+ | https://www.python.org/downloads/ |
| Flutter SDK | 3.x | https://docs.flutter.dev/get-started/install |
| Git | Bất kỳ | https://git-scm.com/ |

---

## 🚀 Bước 1: Clone dự án về máy

```bash
git clone https://github.com/boyloveguy/Ourly-App.git
cd Ourly-App
```

---

## ⚙️ Bước 2: Cài đặt Backend

### 2.1 — Tạo Virtual Environment & cài thư viện

```bash
cd backend

# Tạo môi trường ảo
python -m venv .venv

# Kích hoạt môi trường ảo (Windows)
.venv\Scripts\activate

# Cài đặt thư viện
pip install -e .
```

### 2.2 — Cấu hình file `.env`

File `.env` **KHÔNG** được push lên Git (bảo mật). Bạn cần tạo thủ công:

```bash
# Copy file mẫu
copy .env.example .env
```

Sau đó mở file `backend\.env` và điền các giá trị thực:

```env
ENVIRONMENT=development
LOG_LEVEL=INFO

# --- Firebase (lấy từ Firebase Console) ---
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY\n-----END PRIVATE KEY-----\n"

# --- Gemini AI (lấy từ Google AI Studio) ---
AI_PROVIDER=gemini
AI_API_KEY=your-gemini-api-key
AI_MODEL=gemini-1.5-pro
AI_TIMEOUT_SECONDS=30

# --- Cloudinary (lấy từ cloudinary.com/console) ---
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

CORS_ALLOWED_ORIGINS=*
```

### 2.3 — Cấu hình Firebase Service Account

Tải file `serviceAccountKey.json` từ Firebase Console:
1. Vào **Firebase Console** → Project → ⚙️ **Project Settings**
2. Chọn tab **Service accounts**
3. Click **Generate new private key** → tải file JSON về
4. Đặt file vào: `backend/serviceAccountKey.json`

> ⚠️ File này cũng không được push lên Git — tuyệt đối giữ bí mật!

---

## 📱 Bước 3: Cài đặt Frontend

```bash
cd ..\frontend

# Cài đặt các package Flutter
flutter pub get
```

---

## ▶️ Bước 4: Chạy dự án

### Cách nhanh nhất — Dùng `start.bat` (Windows)

Double-click vào file `start.bat` ở thư mục gốc. Script này tự động mở 2 terminal:
- **Terminal 1**: Backend FastAPI
- **Terminal 2**: Frontend Flutter Web

### Cách thủ công — Mở 2 terminal riêng

**Terminal 1 (Backend):**
```bash
cd backend
.venv\Scripts\activate
python -m uvicorn app.main:app --reload
```

**Terminal 2 (Frontend):**
```bash
cd frontend
flutter run -d web-server --web-port 3000
```

### 🌐 Truy cập ứng dụng

| Dịch vụ | URL |
|---|---|
| Frontend Web | http://localhost:3000 |
| Backend API | http://localhost:8000 |
| API Docs (Swagger) | http://localhost:8000/docs |

---

## 🔑 Nơi lấy các credentials

### Firebase
1. Vào https://console.firebase.google.com
2. Chọn project → **Project Settings** → tab **Service accounts**
3. Copy **Project ID**, **Client Email**, **Private Key**

### Gemini AI API Key
1. Vào https://aistudio.google.com/app/apikey
2. Click **Create API key**

### Cloudinary
1. Vào https://cloudinary.com/console
2. Ở trang Dashboard, copy: **Cloud Name**, **API Key**, **API Secret**

---

## 🛠️ Lỗi thường gặp

| Lỗi | Giải pháp |
|---|---|
| `ModuleNotFoundError` | Chưa kích hoạt venv hoặc chưa `pip install -e .` |
| `firebase_admin` lỗi | Kiểm tra `serviceAccountKey.json` đặt đúng chỗ chưa |
| Flutter build lỗi | Chạy `flutter pub get` lại trong thư mục `frontend` |
| Port 3000/8000 bị dùng | Tắt process đang chiếm port hoặc đổi port |

---

## 📁 Cấu trúc dự án

```
Ourly-App/
├── backend/               # FastAPI backend
│   ├── app/               # Source code
│   ├── .env.example       # Mẫu file cấu hình
│   ├── pyproject.toml     # Danh sách thư viện Python
│   └── serviceAccountKey.json  ← (KHÔNG commit lên Git)
├── frontend/              # Flutter Web frontend
│   ├── lib/               # Source code Dart
│   └── pubspec.yaml       # Danh sách thư viện Flutter
└── start.bat              # Script khởi động nhanh (Windows)
```
