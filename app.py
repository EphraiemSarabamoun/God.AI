from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import os

# Attempt to import the function from your God-Workflow.py file
from God_Workflow import generate_god_like_response # Assuming filename is God_Workflow.py

# --- Flask App Setup ---
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
# We'll create a 'static' subfolder for the frontend.html for better organization
# Or serve directly from BASE_DIR if frontend.html is there.
# For simplicity, let's assume frontend.html will be in the same directory (BASE_DIR).
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes, helpful for development
CONVERSATION_HISTORY = []
# --- Routes ---
@app.route('/')
def index():
    return render_template('frontend.html') 

@app.route('/api/godchat', methods=['POST'])
def god_chat_endpoint():
    global CONVERSATION_HISTORY
    """Handles chat requests from the frontend and uses the agentic workflow."""
    data = request.get_json()
    print(f"Received data: {data}")
    user_prompt = data['prompt'].strip()
    for i, turn in enumerate(CONVERSATION_HISTORY):
        print(f"Turn {i+1} - User: {turn['user']}")
        print(f"Turn {i+1} - God: {turn['god']}")

    print(f"Received prompt for God-like response: {user_prompt}")
        # Call the imported agentic workflow function
        # The model_name parameter in generate_god_like_response is currently illustrative
        # as get_ollama_response_simple in your God-Workflow.py hardcodes 'llama3:70b'
    god_response = generate_god_like_response(user_prompt,CONVERSATION_HISTORY)
    # Add the current turn to the history
    CONVERSATION_HISTORY.append({"user": user_prompt, "god": god_response})

    # Optional: Limit history size to prevent it from growing indefinitely
    MAX_HISTORY_TURNS = 10 # Keep last 10 turns (20 messages total)
    if len(CONVERSATION_HISTORY) > MAX_HISTORY_TURNS:
        CONVERSATION_HISTORY = CONVERSATION_HISTORY[-MAX_HISTORY_TURNS:]

    print(f"God-like response: {god_response}")
    return jsonify({"response": god_response})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False) 

# TODO: Add logic to prevent multiple prayers at once.