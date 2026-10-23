-- Player accounts. Login identity only: profiles, heroes and inventories get
-- their own tables in later migrations and reference accounts(id).
CREATE TABLE accounts (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Display/login name as typed; uniqueness is case-insensitive (see index).
    username      text        NOT NULL CHECK (username ~ '^[A-Za-z0-9_]{3,20}$'),
    -- Argon2id PHC string. Plaintext passwords are never stored.
    password_hash text        NOT NULL CHECK (password_hash LIKE '$argon2id$%'),
    status        text        NOT NULL DEFAULT 'active'
                              CHECK (status IN ('active', 'suspended', 'deleted')),
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX accounts_username_lower_key ON accounts (lower(username));
