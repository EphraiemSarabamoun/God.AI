from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import os
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime       
from flask_jwt_extended import create_access_token, jwt_required, JWTManager, get_jwt_identity

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
                password_hash TEXT NOT NULL,
                monthly_query_count INTEGER DEFAULT 0 NOT NULL,
                last_query_month TEXT,
                is_subscribed INTEGER DEFAULT 0 NOT NULL
            );
            """)
        print("schema.sql created. Please run the app again to initialize the database if it's the first time.")

# --- Flask App Setup ---
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__)
app.config['DATABASE'] = DATABASE
app.config["JWT_SECRET_KEY"] = "your-super-secret-key-change-this-immediately"  # Change this!
jwt = JWTManager(app)
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
        access_token = create_access_token(identity=user['id'])
        return jsonify(access_token=access_token, message="Login successful"), 200
    else:
        return jsonify({"message": "Invalid username or password"}), 401


@app.route('/api/godchat', methods=['POST'])
def god_chat_endpoint():

    global CONVERSATION_HISTORY
    
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor()
    cursor.execute("SELECT id, monthly_query_count, last_query_month, is_subscribed FROM users WHERE id = ?", (user_id,))
    user = cursor.fetchone()

    if not user:
        return jsonify({"message": "User not found"}), 404

    current_month_str = datetime.utcnow().strftime('%Y-%m')
    monthly_query_count = user['monthly_query_count']
    
    # Reset monthly count if it's a new month
    if user['last_query_month'] != current_month_str:
        monthly_query_count = 0
        # No need to update last_query_month here yet, will be updated after successful query or if limit hit

    if not user['is_subscribed'] and monthly_query_count >= 20:
        # Update last_query_month even if limit is hit, to ensure reset logic works next month
        cursor.execute("UPDATE users SET last_query_month = ? WHERE id = ?", (current_month_str, user_id))
        db.commit()
        cursor.close()
        return jsonify({
            "message": "You have used all your 20 free prayers for this month. Please upgrade for unlimited access.",
            "limit_reached": True,
            "remaining_free_queries": 0
        }), 402 # 402 Payment Required

    data = request.get_json()
    user_prompt = data.get('prompt', '').strip()

    if not user_prompt:
        cursor.close()
        return jsonify({"error": "Prompt cannot be empty"}), 400
        
    god_response = generate_god_like_response(user_prompt, CONVERSATION_HISTORY)
    CONVERSATION_HISTORY.append({"user": user_prompt, "god": god_response})
    MAX_HISTORY_TURNS = 10 
    if len(CONVERSATION_HISTORY) > MAX_HISTORY_TURNS:
        CONVERSATION_HISTORY = CONVERSATION_HISTORY[-MAX_HISTORY_TURNS:]

    # Increment query count and update last query month
    new_monthly_query_count = monthly_query_count + 1
    cursor.execute("UPDATE users SET monthly_query_count = ?, last_query_month = ? WHERE id = ?",
                   (new_monthly_query_count, current_month_str, user_id))
    db.commit()
    cursor.close()
    
    remaining_queries = None
    if not user['is_subscribed']:
        remaining_queries = 20 - new_monthly_query_count
        if remaining_queries < 0: remaining_queries = 0 # Should not happen if limit check is correct

    print(f"God-like response: {god_response}")
    response_data = {"response": god_response}
    if remaining_queries is not None:
        response_data["remaining_free_queries"] = remaining_queries
    return jsonify(response_data)


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