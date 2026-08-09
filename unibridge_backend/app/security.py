import bcrypt

def hash_password(password: str) -> str:
    """Hashes a plain-text password using bcrypt directly."""
    if not password:
        raise ValueError("Password cannot be empty.")
    
    # Safely truncate to 72 bytes for bcrypt compatibility
    pwd_bytes = password.encode('utf-8')[:72]
    
    # Generate salt and hash
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pwd_bytes, salt)
    
    return hashed.decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies a plain-text password against a stored bcrypt hash."""
    if not hashed_password or not isinstance(hashed_password, str) or not plain_password:
        return False

    try:
        pwd_bytes = plain_password.encode('utf-8')[:72]
        hash_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(pwd_bytes, hash_bytes)
    except Exception:
        return False