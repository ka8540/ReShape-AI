from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class Feedback(Base, IdMixin, TimestampMixin):
    __tablename__ = "feedback_entries"

    design_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("generated_designs.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sentiment: Mapped[str | None] = mapped_column(String(16), nullable=True)
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)

    design = relationship("GeneratedDesign", back_populates="feedback_entries")
