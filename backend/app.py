from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import os
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash

from God_Workflow import generate_god_like_response


DATABASE = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'users.db')

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row 
    return db

def init_db():
    with app.app_context():
        db = get_db()
        with app.open_resource('schema.sql', mode='r') as f:
            db.cursor().executescript(f.read())
        db.commit()

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

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__)
app.config['DATABASE'] = DATABASE 
CORS(app)  
CONVERSATION_HISTORY = [] 

from flask import g

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

@app.route('/')
def index():
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
    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
    if cursor.fetchone():
        return jsonify({"message": "Username already exists"}), 409 
    
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
        return jsonify({"message": "Login successful"}), 200 
    else:
        return jsonify({"message": "Invalid username or password"}), 401


@app.route('/api/godchat', methods=['POST'])
def god_chat_endpoint():
    global CONVERSATION_HISTORY
    data = request.get_json()
    print(f"Received data: {data}")
    user_prompt = data.get('prompt', '').strip() 

    if not user_prompt:
        return jsonify({"error": "Prompt cannot be empty"}), 400
        
    god_response = generate_god_like_response(user_prompt, CONVERSATION_HISTORY)
    CONVERSATION_HISTORY.append({"user": user_prompt, "god": god_response})
    MAX_HISTORY_TURNS = 10 
    if len(CONVERSATION_HISTORY) > MAX_HISTORY_TURNS:
        CONVERSATION_HISTORY = CONVERSATION_HISTORY[-MAX_HISTORY_TURNS:]
    print(f"God-like response: {god_response}")
    return jsonify({"response": god_response})

if __name__ == '__main__':
    create_schema_if_not_exists() 
    with app.app_context(): 
        if not os.path.exists(DATABASE):
            print(f"Database not found at {DATABASE}. Initializing...")
            init_db()
            print("Database initialized.")
        else:
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