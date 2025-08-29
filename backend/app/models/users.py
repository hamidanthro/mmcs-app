import uuid

from sqlalchemy.dialects.postgresql import UUID

from app.extensions import db


class User(db.Model):
    __tablename__ = "user"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = db.Column(db.String(320), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=True)  # filled later when we add auth
    is_active = db.Column(db.Boolean, nullable=False, default=True)


class Role(db.Model):
    __tablename__ = "role"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = db.Column(db.String(64), unique=True, nullable=False)  # owner, admin, steward, viewer


class TenantUser(db.Model):
    __tablename__ = "tenant_user"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tenant_id = db.Column(UUID(as_uuid=True), nullable=False, index=True)
    user_id = db.Column(UUID(as_uuid=True), nullable=False, index=True)
    role_id = db.Column(UUID(as_uuid=True), nullable=False, index=True)

    __table_args__ = (db.UniqueConstraint("tenant_id", "user_id", name="uq_tenant_user"),)
