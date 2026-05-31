from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class DesignItemChange(Base, IdMixin, TimestampMixin):
    __tablename__ = "design_item_changes"

    design_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("generated_designs.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    detected_item_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("detected_items.id", ondelete="SET NULL"), nullable=True
    )
    change_type: Mapped[str] = mapped_column(String(32), nullable=False)  # move | rotate | swap
    change_payload_json: Mapped[str | None] = mapped_column(Text, nullable=True)

    design = relationship("GeneratedDesign", back_populates="item_changes")
