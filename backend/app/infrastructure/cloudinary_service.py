import cloudinary
import cloudinary.uploader
from app.core.config import settings

class CloudinaryService:
    @classmethod
    def is_configured(cls) -> bool:
        return bool(
            settings.CLOUDINARY_CLOUD_NAME
            and settings.CLOUDINARY_API_KEY
            and settings.CLOUDINARY_API_SECRET
        )

    @classmethod
    def init(cls):
        if cls.is_configured():
            cloudinary.config(
                cloud_name=settings.CLOUDINARY_CLOUD_NAME,
                api_key=settings.CLOUDINARY_API_KEY,
                api_secret=settings.CLOUDINARY_API_SECRET,
                secure=True
            )

    @classmethod
    def upload_image(cls, file_bytes: bytes, user_id: str, folder: str = "ourly/avatars") -> str:
        """
        Uploads image to Cloudinary with automatic optimization (face-centered, webp/auto, 400x400)
        and returns the HTTPS secure URL.
        """
        cls.init()
        res = cloudinary.uploader.upload(
            file_bytes,
            folder=f"{folder}/{user_id}",
            transformation=[
                {
                    "width": 400,
                    "height": 400,
                    "crop": "fill",
                    "gravity": "face",
                    "quality": "auto",
                    "fetch_format": "auto"
                }
            ]
        )
        return res.get("secure_url", "")
