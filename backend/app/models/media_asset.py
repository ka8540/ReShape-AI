from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class MediaAsset(Base, IdMixin, TimestampMixin):
    __tablename__ = "media_assets"

    project_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True, nullable=False
    )
    media_kind: Mapped[str] = mapped_column(String(16), nullable=False)  # image | video
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    mime_type: Mapped[str] = mapped_column(String(100), nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, nullable=False)
    storage_key: Mapped[str] = mapped_column(String(1024), nullable=False)
    upload_status: Mapped[str] = mapped_column(String(32), default="pending", nullable=False)

    project = relationship("Project", back_populates="media_assets")
    frames = relationship(
        "ExtractedFrame", back_populates="media_asset", cascade="all, delete-orphan"
    )
