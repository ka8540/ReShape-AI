from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class PreferenceSet(Base, IdMixin, TimestampMixin):
    __tablename__ = "preference_sets"

    project_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("projects.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    primary_goal: Mapped[str | None] = mapped_column(String(80), nullable=True)
    style: Mapped[str | None] = mapped_column(String(80), nullable=True)
    constraints_json: Mapped[str | None] = mapped_column(Text, nullable=True)

    project = relationship("Project", back_populates="preference_set")
