from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import os
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash

# Attempt to import the function from your God-Workflow.py file
from God_Workflow import generate_god_like_response # Assuming filename is God_Workflow.py

# --- Database Setup ---
DATABASE = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'users.db')

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row # Access columns by name
    return db

def init_db():
    with app.app_context():
        db = get_db()
        with app.open_resource('schema.sql', mode='r') as f:
            db.cursor().executescript(f.read())
        db.commit()

# Call this function once to create the schema.sql file if it doesn't exist
# and then to initialize the database.
def create_schema_if_not_exists():
    schema_path = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'schema.sql')
    if not os.path.exists(schema_path):
        with open(schema_path, 'w') as f:
            f.write("""
            DROP TABLE IF EXISTS users;
            CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL
            );
            """)
        print("schema.sql created. Please run the app again to initialize the database if it's the first time.")

# --- Flask App Setup ---
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__)
app.config['DATABASE'] = DATABASE # For convenience, though not strictly used by get_db directly
CORS(app)  # Enable CORS for all routes
CONVERSATION_HISTORY = [] # WARNING: This will be shared among all users. Needs to be user-specific in a real multi-user app.

# Import 'g' for application context
from flask import g

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

# --- Routes ---
@app.route('/')
def index():
    # This still serves your HTML frontend, which is separate from the Flutter app's auth
    return render_template('frontend.html')

@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if not username or not email or not password:
        return jsonify({"message": "Missing username, email, or password"}), 400

    db = get_db()
    cursor = db.cursor()

    # Check if username or email already exists
    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
    if cursor.fetchone():
        return jsonify({"message": "Username already exists"}), 409 # 409 Conflict
    
    cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
    if cursor.fetchone():
        return jsonify({"message": "Email already registered"}), 409

    password_hash = generate_password_hash(password)
    
    try:
        cursor.execute("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
                       (username, email, password_hash))
        db.commit()
        return jsonify({"message": "User registered successfully"}), 201
    except sqlite3.Error as e:
        db.rollback()
        return jsonify({"message": f"Database error: {e}"}), 500
    finally:
        cursor.close()


@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({"message": "Missing username or password"}), 400

    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
    user = cursor.fetchone()
    cursor.close()

    if user and check_password_hash(user['password_hash'], password):
        # In a real app, you'd generate a session token (JWT) here
        return jsonify({"message": "Login successful"}), 200 # Optionally return user info or token
    else:
        return jsonify({"message": "Invalid username or password"}), 401


@app.route('/api/godchat', methods=['POST'])
def god_chat_endpoint():
    # IMPORTANT: This endpoint is currently NOT protected.
    # Any client can call it without logging in.
    # You would need to implement token-based authentication or session management
    # to protect this route and associate CONVERSATION_HISTORY with specific users.
    global CONVERSATION_HISTORY
    data = request.get_json()
    print(f"Received data: {data}")
    user_prompt = data.get('prompt', '').strip() # Use .get for safety

    if not user_prompt:
        return jsonify({"error": "Prompt cannot be empty"}), 400
        
    # ... (rest of your godchat logic) ...
    # For demonstration, let's assume it continues as before
    # The model_name parameter in generate_god_like_response is currently illustrative
    # as get_ollama_response_simple in your God-Workflow.py hardcodes 'llama3:70b'
    god_response = generate_god_like_response(user_prompt, CONVERSATION_HISTORY)
    CONVERSATION_HISTORY.append({"user": user_prompt, "god": god_response})
    MAX_HISTORY_TURNS = 10 
    if len(CONVERSATION_HISTORY) > MAX_HISTORY_TURNS:
        CONVERSATION_HISTORY = CONVERSATION_HISTORY[-MAX_HISTORY_TURNS:]
    print(f"God-like response: {god_response}")
    return jsonify({"response": god_response})

if __name__ == '__main__':
    create_schema_if_not_exists() # Create schema.sql if it doesn't exist
    with app.app_context(): # Ensure app context for db initialization
        # Check if DB exists, if not, initialize it
        if not os.path.exists(DATABASE):
            print(f"Database not found at {DATABASE}. Initializing...")
            init_db()
            print("Database initialized.")
        else:
            # You might want to add a check here to see if the 'users' table exists
            # and call init_db() if it doesn't, in case the db file exists but is empty/corrupted.
            conn = sqlite3.connect(DATABASE)
            cursor = conn.cursor()
            try:
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users';")
                if not cursor.fetchone():
                    print("'users' table not found. Initializing database schema...")
                    init_db()
                    print("Database schema initialized.")
                else:
                    print("Database and 'users' table found.")
            except sqlite3.Error as e:
                print(f"Error checking database schema: {e}. Attempting to initialize.")
                init_db()
                print("Database schema initialized.")
            finally:
                conn.close()

    app.run(host='0.0.0.0', port=8080, debug=True)