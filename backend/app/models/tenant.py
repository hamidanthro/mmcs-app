import uuid
from sqlalchemy.dialects.postgresql import UUID
from app.extensions import db


class Tenant(db.Model):
    __tablename__ = "tenant"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code = db.Column(db.String(64), unique=True, nullable=False, index=True)
    name = db.Column(db.String(255), nullable=False)
