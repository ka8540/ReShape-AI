from sqlalchemy import Boolean, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class DetectedItem(Base, IdMixin, TimestampMixin):
    __tablename__ = "detected_items"

    project_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    type: Mapped[str] = mapped_column(String(64), nullable=False)
    confidence: Mapped[float] = mapped_column(Float, default=1.0, nullable=False)
    fixed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    structural: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    added_by_user: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    project = relationship("Project", back_populates="detected_items")
