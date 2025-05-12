# God.AI
This is a fun project where I use a 70b local Llama3 model to simulate God in an app.
Demo Video: https://github.com/EphraiemSarabamoun/God.AI/blob/main/Demo_Video.mov

## Project Structure

*   `/backend`: Contains the Python Flask server and AI logic.
*   `/frontend_app`: Contains the Flutter mobile application.

## Prerequisites

*   **Python:** Ensure Python (3.8 or newer recommended) is installed. You can download it from [python.org](https://www.python.org/).
*   **Pip:** Python's package installer, usually comes with Python.
*   **Flutter SDK:** Ensure the Flutter SDK is installed. You can find installation instructions at [flutter.dev](https://flutter.dev/docs/get-started/install).
*   **Ollama (or other LLM service):** This project is configured to use a local LLM via Ollama. Ensure Ollama is running and the specified model (e.g., Llama3 70b) is downloaded and accessible. Note, model is heavy so make sure your GPU can handle it. Update `God_Workflow.py` if you are using a different model or service.

## Running the Backend (Python Flask Server)

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```


2.  **Run Backend:**
    Set up your enviornment and run
    ```bash
    pipenv install
    pipenv run run
    ```
    The backend server should now be running.
## Running the Frontend (Flutter App)

1.  **Navigate to the frontend directory:**
    ```bash
    cd frontend_app
    ```

2.  **Get Flutter packages:**
    ```bash
    flutter pub get
    ```

3.  **Update API URLs (Important):**
    *   Open `lib/login_page.dart` and update `_loginApiUrl` with the correct IP address and port of your running backend (e.g., `http://YOUR_LOCAL_IP:8080/api/login`).
    *   Open `lib/registration_page.dart` and update `_registerApiUrl` similarly (e.g., `http://YOUR_LOCAL_IP:8080/api/register`).
    *   Open `lib/main.dart` and update the `_godChatApiUrl` in the `OracleHomePageState` (around line 60) with the correct IP and port for the chat endpoint (e.g., `http://YOUR_LOCAL_IP:8080/api/godchat`).
    *   *Note: `YOUR_LOCAL_IP` is the IP address of the machine running the backend, accessible from the device/emulator running the Flutter app. Using `localhost` or `127.0.0.1` will only work if the app is running on the same machine as the backend.*

4.  **Run the Flutter application:**
    *   Ensure you have an emulator running or a device connected.
    *   Execute the following command:
        ```bash
        flutter run
        ```

## Development Notes

*   The backend uses SQLite for user authentication. The database file (`users.db`) and schema (`schema.sql`) will be created automatically in the `backend` directory when `app.py` is first run.
*   Conversation history for the God chat is currently stored in memory on the backend.
*   To run the app on a physical iphone, connect your phone to a mac laptop and run flutter there.
