"""
SignBridge Database & Authentication Store
Connects to MongoDB (local or Atlas) with in-memory resilient fallback.
Provides secure password hashing (PBKDF2-HMAC-SHA256) and user session management.
"""

import os
import uuid
import hashlib
import secrets
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List

logger = logging.getLogger("signbridge.db")

MONGODB_URI = os.environ.get("MONGODB_URI", "mongodb://127.0.0.1:27017")
DB_NAME = "signbridge_db"

_mongo_client = None
_db = None
_is_mongodb_connected = False

# Resilient in-memory fallback stores
_MEM_USERS: Dict[str, Dict[str, Any]] = {}
_MEM_SESSIONS: Dict[str, Dict[str, Any]] = {}
_MEM_HISTORY: Dict[str, List[Dict[str, Any]]] = {}


def init_db():
    global _mongo_client, _db, _is_mongodb_connected
    if _mongo_client is not None:
        return _db

    try:
        from pymongo import MongoClient
        logger.info(f"Connecting to MongoDB at {MONGODB_URI}...")
        _mongo_client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=2000)
        # Test connection
        _mongo_client.server_info()
        _db = _mongo_client[DB_NAME]
        _is_mongodb_connected = True
        
        # Ensure unique index on email
        _db.users.create_index("email", unique=True)
        _db.sessions.create_index("token", unique=True)
        logger.info("MongoDB connected successfully. Collections initialized.")
    except Exception as e:
        logger.warning(f"MongoDB not available ({e}). Using resilient in-memory fallback store.")
        _is_mongodb_connected = False
        _db = None

    return _db


# Password Hashing Utilities (PBKDF2-HMAC-SHA256 with 100,000 iterations)
def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        100000,
    )
    return f"{salt}${key.hex()}"


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        salt, key_hex = stored_hash.split("$", 1)
        test_key = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            salt.encode("utf-8"),
            100000,
        )
        return secrets.compare_digest(test_key.hex(), key_hex)
    except Exception:
        return False


def create_user(
    email: str,
    password: str,
    full_name: str,
    role: str = "deaf_user",
    preferred_lang: str = "en",
) -> Optional[Dict[str, Any]]:
    db = init_db()
    email_clean = email.strip().lower()
    
    if get_user_by_email(email_clean) is not None:
        return None  # User already exists

    user_id = str(uuid.uuid4())[:12]
    pwd_hash = hash_password(password)
    now_iso = datetime.now(timezone.utc).isoformat()

    doc = {
        "user_id": user_id,
        "email": email_clean,
        "password_hash": pwd_hash,
        "full_name": full_name.strip(),
        "role": role,
        "preferred_lang": preferred_lang,
        "created_at": now_iso,
    }

    if _is_mongodb_connected and db is not None:
        try:
            db.users.insert_one(dict(doc))
        except Exception as err:
            logger.error(f"MongoDB insert error: {err}")
            _MEM_USERS[email_clean] = doc
    else:
        _MEM_USERS[email_clean] = doc

    # Return safe user profile without password hash
    safe_user = dict(doc)
    safe_user.pop("password_hash", None)
    safe_user.pop("_id", None)
    return safe_user


def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    db = init_db()
    email_clean = email.strip().lower()

    if _is_mongodb_connected and db is not None:
        try:
            doc = db.users.find_one({"email": email_clean})
            if doc:
                doc.pop("_id", None)
                return doc
        except Exception as e:
            logger.warning(f"MongoDB query failed: {e}")

    return _MEM_USERS.get(email_clean)


def get_user_by_id(user_id: str) -> Optional[Dict[str, Any]]:
    db = init_db()
    if _is_mongodb_connected and db is not None:
        try:
            doc = db.users.find_one({"user_id": user_id})
            if doc:
                doc.pop("_id", None)
                return doc
        except Exception as e:
            logger.warning(f"MongoDB query failed: {e}")

    for u in _MEM_USERS.values():
        if u.get("user_id") == user_id:
            return u
    return None


def create_session(user_id: str) -> str:
    db = init_db()
    token = f"sb_{secrets.token_urlsafe(32)}"
    now_iso = datetime.now(timezone.utc).isoformat()
    session_doc = {
        "token": token,
        "user_id": user_id,
        "created_at": now_iso,
    }

    if _is_mongodb_connected and db is not None:
        try:
            db.sessions.insert_one(dict(session_doc))
        except Exception:
            _MEM_SESSIONS[token] = session_doc
    else:
        _MEM_SESSIONS[token] = session_doc

    return token


def get_session(token: str) -> Optional[Dict[str, Any]]:
    db = init_db()
    if _is_mongodb_connected and db is not None:
        try:
            s = db.sessions.find_one({"token": token})
            if s:
                s.pop("_id", None)
                return s
        except Exception:
            pass

    return _MEM_SESSIONS.get(token)


# History Persistence
def save_history(session_id: str, item_dict: Dict[str, Any]):
    db = init_db()
    item_dict["session_id"] = session_id
    if _is_mongodb_connected and db is not None:
        try:
            db.history.insert_one(dict(item_dict))
        except Exception:
            pass

    if session_id not in _MEM_HISTORY:
        _MEM_HISTORY[session_id] = []
    _MEM_HISTORY[session_id].append(item_dict)


def fetch_history(session_id: str) -> List[Dict[str, Any]]:
    db = init_db()
    if _is_mongodb_connected and db is not None:
        try:
            docs = list(db.history.find({"session_id": session_id}).sort("timestamp", 1))
            for d in docs:
                d.pop("_id", None)
            if docs:
                return docs
        except Exception:
            pass

    return _MEM_HISTORY.get(session_id, [])


# Initialize connection on load
init_db()
