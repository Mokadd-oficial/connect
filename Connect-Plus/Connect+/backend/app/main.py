import os
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from jose import jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret")
JWT_EXPIRES_MIN = int(os.getenv("JWT_EXPIRES_MIN", "120"))

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

app = FastAPI(title="Connect+ API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # depois restringimos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def make_token(user_id: str, role_code: str):
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "role": role_code,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=JWT_EXPIRES_MIN)).timestamp()),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")

class RegisterIn(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role_code: str = "employee"  # pode travar no backend se quiser

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class AuthOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: UUID
    full_name: str
    email: EmailStr
    role_code: str

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/auth/register", response_model=AuthOut)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    # evita roles inválidas
    if payload.role_code not in ("admin", "employee", "hr"):
        raise HTTPException(400, detail="role_code inválida")

    # checa email
    row = db.execute(
        text("SELECT user_id FROM app_user WHERE email = :email"),
        {"email": str(payload.email)},
    ).fetchone()
    if row:
        raise HTTPException(409, detail="Email já cadastrado")
    
    if len(payload.password.encode("utf-8")) > 72:
        raise HTTPException(400, detail="Senha muito longa (máx. 72 bytes).")

    password_hash = pwd_ctx.hash(payload.password)

    row = db.execute(
        text("""
            INSERT INTO app_user (user_id, full_name, email, password_hash, role_code)
            VALUES (gen_random_uuid(), :full_name, :email, :password_hash, :role_code)
            RETURNING user_id, full_name, email, role_code
        """),
        {
            "full_name": payload.full_name,
            "email": str(payload.email),
            "password_hash": password_hash,
            "role_code": payload.role_code,
        },
    ).fetchone()
    db.commit()

    token = make_token(str(row.user_id), row.role_code)
    return AuthOut(
        access_token=token,
        user_id=row.user_id,
        full_name=row.full_name,
        email=row.email,
        role_code=row.role_code,
    )

@app.post("/auth/login", response_model=AuthOut)
def login(payload: LoginIn, db: Session = Depends(get_db)):
    row = db.execute(
        text("""
            SELECT user_id, full_name, email, password_hash, role_code, is_active
            FROM app_user
            WHERE email = :email
        """),
        {"email": str(payload.email)},
    ).fetchone()

    if not row or not row.password_hash:
        raise HTTPException(401, detail="Usuário ou senha inválidos")

    if not row.is_active:
        raise HTTPException(403, detail="Usuário desativado")

    if not pwd_ctx.verify(payload.password, row.password_hash):
        raise HTTPException(401, detail="Usuário ou senha inválidos")

    token = make_token(str(row.user_id), row.role_code)
    return AuthOut(
        access_token=token,
        user_id=row.user_id,
        full_name=row.full_name,
        email=row.email,
        role_code=row.role_code,

def get_current_user(authorization: Optional[str] = Header(default=None)):
    if not authorization:
        raise HTTPException(401, detail="Missing Authorization header")

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(401, detail="Invalid Authorization header")

    token = parts[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
    except Exception:
        raise HTTPException(401, detail="Invalid token")

    user_id = payload.get("sub")
    role_code = payload.get("role")
    if not user_id or not role_code:
        raise HTTPException(401, detail="Invalid token payload")

    return {"user_id": user_id, "role_code": role_code}

    )

@app.get("/islands")
def list_islands(db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT i.island_id, i.name, i.size_label, i.created_at,
               it.code AS island_type_code, it.name AS island_type_name
        FROM island i
        JOIN island_type it ON it.island_type_id = i.island_type_id
        ORDER BY i.created_at DESC
    """)).fetchall()
    return [dict(r._mapping) for r in rows]


@app.get("/islands/{island_id}/areas")
def list_island_areas(island_id: str, db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT area_id, island_id, name, description, sort_order
        FROM island_area
        WHERE island_id = :island_id
        ORDER BY sort_order ASC, name ASC
    """), {"island_id": island_id}).fetchall()
    return [dict(r._mapping) for r in rows]


@app.get("/islands/{island_id}/missions")

def list_missions(island_id: str, area_id: Optional[str] = None, db: Session = Depends(get_db)):
    if area_id:
        rows = db.execute(text("""
            SELECT mission_id, island_id, area_id, title, category, description, sort_order, xp_reward, created_at
            FROM mission
            WHERE island_id = :island_id AND area_id = :area_id
            ORDER BY sort_order ASC, created_at ASC
        """), {"island_id": island_id, "area_id": area_id}).fetchall()
    else:
        rows = db.execute(text("""
            SELECT mission_id, island_id, area_id, title, category, description, sort_order, xp_reward, created_at
            FROM mission
            WHERE island_id = :island_id
            ORDER BY sort_order ASC, created_at ASC
        """), {"island_id": island_id}).fetchall()

    return [dict(r._mapping) for r in rows]


@app.get("/missions/{mission_id}/tasks")
def list_tasks(mission_id: str, db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT t.task_id, t.mission_id, t.task_type_id,
               tt.code AS task_type_code, tt.name AS task_type_name,
               t.title, t.content_url, t.instructions, t.sort_order, t.created_at
        FROM mission_task t
        JOIN task_type tt ON tt.task_type_id = t.task_type_id
        WHERE t.mission_id = :mission_id
        ORDER BY t.sort_order ASC, t.created_at ASC
    """), {"mission_id": mission_id}).fetchall()
    return [dict(r._mapping) for r in rows]
