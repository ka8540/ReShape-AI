from sqlalchemy import Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class ExtractedFrame(Base, IdMixin, TimestampMixin):
    __tablename__ = "extracted_frames"

    media_asset_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("media_assets.id", ondelete="CASCADE"), index=True, nullable=False
    )
    frame_index: Mapped[int] = mapped_column(Integer, nullable=False)
    timestamp_seconds: Mapped[float] = mapped_column(Float, nullable=False)
    storage_key: Mapped[str] = mapped_column(String(1024), nullable=False)

    media_asset = relationship("MediaAsset", back_populates="frames")
