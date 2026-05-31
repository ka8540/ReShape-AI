from sqlalchemy import Boolean, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class GeneratedDesign(Base, IdMixin, TimestampMixin):
    __tablename__ = "generated_designs"

    project_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True, nullable=False
    )
    model_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    prompt_version: Mapped[str | None] = mapped_column(String(64), nullable=True)
    reference_image_key: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    output_image_key: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    layout_plan_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    generation_status: Mapped[str] = mapped_column(String(32), default="pending", nullable=False)
    error_code: Mapped[str | None] = mapped_column(String(64), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_selected: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    project = relationship("Project", back_populates="generated_designs")
    item_changes = relationship(
        "DesignItemChange", back_populates="design", cascade="all, delete-orphan"
    )
    feedback_entries = relationship(
        "Feedback", back_populates="design", cascade="all, delete-orphan"
    )
