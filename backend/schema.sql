DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    monthly_query_count INTEGER DEFAULT 0 NOT NULL,
    last_query_month TEXT, -- Stores the month of the last query (e.g., "YYYY-MM")
    is_subscribed INTEGER DEFAULT 0 NOT NULL -- 0 for false, 1 for true (paid user)
);