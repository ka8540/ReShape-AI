from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._mixins import IdMixin, TimestampMixin


class FinalPlan(Base, IdMixin, TimestampMixin):
    __tablename__ = "final_plans"

    project_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("projects.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    selected_design_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("generated_designs.id", ondelete="SET NULL"), nullable=True
    )
    plan_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    export_status: Mapped[str] = mapped_column(String(32), default="none", nullable=False)
    export_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)

    project = relationship("Project", back_populates="final_plan")
