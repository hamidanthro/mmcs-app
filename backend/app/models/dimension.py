import uuid

from sqlalchemy.dialects.postgresql import UUID

from app.extensions import db


class Dimension(db.Model):
    __tablename__ = "dimension"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tenant_id = db.Column(UUID(as_uuid=True), nullable=False, index=True)
    code = db.Column(db.String(64), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)

    __table_args__ = (db.UniqueConstraint("tenant_id", "code", name="uq_dimension_tenant_code"),)
