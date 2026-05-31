from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class Project(Base, IdMixin, TimestampMixin):
    __tablename__ = "projects"

    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    room: Mapped[str | None] = mapped_column(String(80), nullable=True)
    mode: Mapped[str] = mapped_column(String(32), default="reshuffle", nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="draft", nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    owner = relationship("User", back_populates="projects")
    media_assets = relationship(
        "MediaAsset", back_populates="project", cascade="all, delete-orphan"
    )
    detected_items = relationship(
        "DetectedItem", back_populates="project", cascade="all, delete-orphan"
    )
    preference_set = relationship(
        "PreferenceSet", back_populates="project", uselist=False, cascade="all, delete-orphan"
    )
    generated_designs = relationship(
        "GeneratedDesign", back_populates="project", cascade="all, delete-orphan"
    )
    final_plan = relationship(
        "FinalPlan", back_populates="project", uselist=False, cascade="all, delete-orphan"
    )
