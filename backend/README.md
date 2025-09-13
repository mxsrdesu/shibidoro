# Shibidoro Backend

Flask API server for the Shibidoro Pomodoro timer.

## Setup

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run the server
python app.py
```

The server will start on `http://localhost:5000`.

### Docker Development
```bash
# Build and run with docker-compose
docker-compose up --build

# Run in background
docker-compose up -d
```

## API Endpoints

### Timer Operations
- `GET /timer/status` - Get current timer state
- `POST /timer/start` - Start the timer
- `POST /timer/pause` - Pause the timer
- `POST /timer/skip` - Skip current session
- `POST /timer/complete` - Complete current session (called automatically when timer reaches 0)

### Settings
- `GET /settings` - Get timer settings
- `PUT /settings` - Update timer settings

### Statistics
- `GET /stats/sessions` - Get session history with optional filters
- `GET /stats/today` - Get today's session statistics

### Health Check
- `GET /health` - Health check endpoint

## Database

SQLite database with the following models:
- **Settings**: Timer durations and configuration
- **TimerState**: Current timer state
- **Session**: Completed session records

## Default Settings

- Focus session: 25 minutes (1500 seconds)
- Short break: 5 minutes (300 seconds)
- Long break: 15 minutes (900 seconds)
- Sessions before long break: 4