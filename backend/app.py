from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime, timezone
import os
from enum import Enum

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('SQLALCHEMY_DATABASE_URI', 'sqlite:///shibidoro.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
CORS(app)

class TimerStatus(Enum):
    STOPPED = "stopped"
    RUNNING = "running"
    PAUSED = "paused"

class SessionType(Enum):
    FOCUS = "focus"
    SHORT_BREAK = "short_break"
    LONG_BREAK = "long_break"

class Settings(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    focus_duration = db.Column(db.Integer, default=25 * 60)  # 25 minutes in seconds
    short_break_duration = db.Column(db.Integer, default=5 * 60)  # 5 minutes in seconds
    long_break_duration = db.Column(db.Integer, default=15 * 60)  # 15 minutes in seconds
    sessions_before_long_break = db.Column(db.Integer, default=4)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

class TimerState(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    status = db.Column(db.Enum(TimerStatus), default=TimerStatus.STOPPED)
    current_session_type = db.Column(db.Enum(SessionType), default=SessionType.FOCUS)
    remaining_time = db.Column(db.Integer, default=0)
    session_count = db.Column(db.Integer, default=0)
    start_time = db.Column(db.DateTime, nullable=True)
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

class Session(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    session_type = db.Column(db.Enum(SessionType), nullable=False)
    duration = db.Column(db.Integer, nullable=False)  # in seconds
    completed = db.Column(db.Boolean, default=False)
    started_at = db.Column(db.DateTime, nullable=False)
    completed_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

def init_db():
    with app.app_context():
        db.create_all()

        # Initialize default settings if none exist
        if not Settings.query.first():
            default_settings = Settings()
            db.session.add(default_settings)

        # Initialize timer state if none exists
        if not TimerState.query.first():
            timer_state = TimerState()
            db.session.add(timer_state)

        db.session.commit()

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'})

@app.route('/timer/status', methods=['GET'])
def get_timer_status():
    timer_state = TimerState.query.first()
    if not timer_state:
        return jsonify({'error': 'Timer state not found'}), 404

    return jsonify({
        'status': timer_state.status.value,
        'current_session_type': timer_state.current_session_type.value,
        'remaining_time': timer_state.remaining_time,
        'session_count': timer_state.session_count,
        'start_time': timer_state.start_time.isoformat() if timer_state.start_time else None
    })

@app.route('/timer/start', methods=['POST'])
def start_timer():
    timer_state = TimerState.query.first()
    settings = Settings.query.first()

    if not timer_state or not settings:
        return jsonify({'error': 'Timer state or settings not found'}), 404

    if timer_state.status == TimerStatus.RUNNING:
        return jsonify({'error': 'Timer is already running'}), 400

    # If starting fresh or resuming
    if timer_state.status == TimerStatus.STOPPED:
        # Determine session duration based on current session type
        if timer_state.current_session_type == SessionType.FOCUS:
            timer_state.remaining_time = settings.focus_duration
        elif timer_state.current_session_type == SessionType.SHORT_BREAK:
            timer_state.remaining_time = settings.short_break_duration
        else:  # LONG_BREAK
            timer_state.remaining_time = settings.long_break_duration

    timer_state.status = TimerStatus.RUNNING
    timer_state.start_time = datetime.now(timezone.utc)

    # Create a new session record
    session = Session(
        session_type=timer_state.current_session_type,
        duration=timer_state.remaining_time,
        started_at=timer_state.start_time
    )
    db.session.add(session)
    db.session.commit()

    return jsonify({
        'status': timer_state.status.value,
        'current_session_type': timer_state.current_session_type.value,
        'remaining_time': timer_state.remaining_time,
        'session_count': timer_state.session_count
    })

@app.route('/timer/pause', methods=['POST'])
def pause_timer():
    timer_state = TimerState.query.first()
    if not timer_state:
        return jsonify({'error': 'Timer state not found'}), 404

    if timer_state.status != TimerStatus.RUNNING:
        return jsonify({'error': 'Timer is not running'}), 400

    # Calculate elapsed time and update remaining time
    if timer_state.start_time:
        # Make start_time timezone-aware if it isn't already
        start_time = timer_state.start_time
        if start_time.tzinfo is None:
            start_time = start_time.replace(tzinfo=timezone.utc)

        elapsed = (datetime.now(timezone.utc) - start_time).total_seconds()
        timer_state.remaining_time = max(0, timer_state.remaining_time - int(elapsed))

    timer_state.status = TimerStatus.PAUSED
    timer_state.start_time = None
    db.session.commit()

    return jsonify({
        'status': timer_state.status.value,
        'current_session_type': timer_state.current_session_type.value,
        'remaining_time': timer_state.remaining_time,
        'session_count': timer_state.session_count,
        'start_time': None
    })

@app.route('/timer/skip', methods=['POST'])
def skip_session():
    timer_state = TimerState.query.first()
    settings = Settings.query.first()

    if not timer_state or not settings:
        return jsonify({'error': 'Timer state or settings not found'}), 404

    # Mark current session as completed
    current_session = Session.query.filter_by(
        session_type=timer_state.current_session_type,
        completed=False
    ).order_by(Session.created_at.desc()).first()

    if current_session:
        current_session.completed = True
        current_session.completed_at = datetime.now(timezone.utc)

    # Progress to next session type
    if timer_state.current_session_type == SessionType.FOCUS:
        timer_state.session_count += 1
        if timer_state.session_count % settings.sessions_before_long_break == 0:
            timer_state.current_session_type = SessionType.LONG_BREAK
        else:
            timer_state.current_session_type = SessionType.SHORT_BREAK
    else:  # Was on a break, go back to focus
        timer_state.current_session_type = SessionType.FOCUS

    timer_state.status = TimerStatus.STOPPED
    timer_state.remaining_time = 0
    timer_state.start_time = None

    db.session.commit()

    return jsonify({
        'status': timer_state.status.value,
        'current_session_type': timer_state.current_session_type.value,
        'remaining_time': timer_state.remaining_time,
        'session_count': timer_state.session_count
    })

@app.route('/timer/complete', methods=['POST'])
def complete_session():
    """Called when a session naturally completes (timer reaches 0)"""
    timer_state = TimerState.query.first()
    settings = Settings.query.first()

    if not timer_state or not settings:
        return jsonify({'error': 'Timer state or settings not found'}), 404

    # Mark current session as completed
    current_session = Session.query.filter_by(
        session_type=timer_state.current_session_type,
        completed=False
    ).order_by(Session.created_at.desc()).first()

    if current_session:
        current_session.completed = True
        current_session.completed_at = datetime.now(timezone.utc)

    # Progress to next session type
    if timer_state.current_session_type == SessionType.FOCUS:
        timer_state.session_count += 1
        if timer_state.session_count % settings.sessions_before_long_break == 0:
            timer_state.current_session_type = SessionType.LONG_BREAK
        else:
            timer_state.current_session_type = SessionType.SHORT_BREAK
    else:  # Was on a break, go back to focus
        timer_state.current_session_type = SessionType.FOCUS

    timer_state.status = TimerStatus.STOPPED
    timer_state.remaining_time = 0
    timer_state.start_time = None

    db.session.commit()

    return jsonify({
        'status': timer_state.status.value,
        'current_session_type': timer_state.current_session_type.value,
        'remaining_time': timer_state.remaining_time,
        'session_count': timer_state.session_count
    })

@app.route('/settings', methods=['GET'])
def get_settings():
    settings = Settings.query.first()
    if not settings:
        return jsonify({'error': 'Settings not found'}), 404

    return jsonify({
        'focus_duration': settings.focus_duration,
        'short_break_duration': settings.short_break_duration,
        'long_break_duration': settings.long_break_duration,
        'sessions_before_long_break': settings.sessions_before_long_break
    })

@app.route('/settings', methods=['PUT'])
def update_settings():
    settings = Settings.query.first()
    if not settings:
        return jsonify({'error': 'Settings not found'}), 404

    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    # Validate and update settings
    if 'focus_duration' in data:
        if not isinstance(data['focus_duration'], int) or data['focus_duration'] <= 0:
            return jsonify({'error': 'focus_duration must be a positive integer'}), 400
        settings.focus_duration = data['focus_duration']

    if 'short_break_duration' in data:
        if not isinstance(data['short_break_duration'], int) or data['short_break_duration'] <= 0:
            return jsonify({'error': 'short_break_duration must be a positive integer'}), 400
        settings.short_break_duration = data['short_break_duration']

    if 'long_break_duration' in data:
        if not isinstance(data['long_break_duration'], int) or data['long_break_duration'] <= 0:
            return jsonify({'error': 'long_break_duration must be a positive integer'}), 400
        settings.long_break_duration = data['long_break_duration']

    if 'sessions_before_long_break' in data:
        if not isinstance(data['sessions_before_long_break'], int) or data['sessions_before_long_break'] <= 0:
            return jsonify({'error': 'sessions_before_long_break must be a positive integer'}), 400
        settings.sessions_before_long_break = data['sessions_before_long_break']

    settings.updated_at = datetime.now(timezone.utc)
    db.session.commit()

    return jsonify({
        'focus_duration': settings.focus_duration,
        'short_break_duration': settings.short_break_duration,
        'long_break_duration': settings.long_break_duration,
        'sessions_before_long_break': settings.sessions_before_long_break
    })

@app.route('/stats/sessions', methods=['GET'])
def get_session_stats():
    # Get query parameters for filtering
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    session_type = request.args.get('type')

    query = Session.query.filter_by(completed=True)

    # Apply date filters
    if start_date:
        try:
            start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            query = query.filter(Session.completed_at >= start_dt)
        except ValueError:
            return jsonify({'error': 'Invalid start_date format. Use ISO format.'}), 400

    if end_date:
        try:
            end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
            query = query.filter(Session.completed_at <= end_dt)
        except ValueError:
            return jsonify({'error': 'Invalid end_date format. Use ISO format.'}), 400

    # Apply session type filter
    if session_type:
        try:
            session_type_enum = SessionType(session_type)
            query = query.filter(Session.session_type == session_type_enum)
        except ValueError:
            return jsonify({'error': 'Invalid session type. Use: focus, short_break, or long_break'}), 400

    sessions = query.order_by(Session.completed_at.desc()).all()

    session_data = []
    for session in sessions:
        session_data.append({
            'id': session.id,
            'session_type': session.session_type.value,
            'duration': session.duration,
            'started_at': session.started_at.isoformat(),
            'completed_at': session.completed_at.isoformat() if session.completed_at else None
        })

    # Calculate summary statistics
    total_sessions = len(sessions)
    focus_sessions = len([s for s in sessions if s.session_type == SessionType.FOCUS])
    total_focus_time = sum(s.duration for s in sessions if s.session_type == SessionType.FOCUS)

    return jsonify({
        'sessions': session_data,
        'summary': {
            'total_sessions': total_sessions,
            'focus_sessions': focus_sessions,
            'total_focus_time_seconds': total_focus_time,
            'total_focus_time_minutes': total_focus_time // 60
        }
    })

@app.route('/stats/today', methods=['GET'])
def get_today_stats():
    from datetime import date
    today = date.today()
    start_of_day = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)
    end_of_day = datetime.combine(today, datetime.max.time()).replace(tzinfo=timezone.utc)

    sessions = Session.query.filter(
        Session.completed == True,
        Session.completed_at >= start_of_day,
        Session.completed_at <= end_of_day
    ).all()

    focus_sessions = [s for s in sessions if s.session_type == SessionType.FOCUS]
    total_focus_time = sum(s.duration for s in focus_sessions)

    return jsonify({
        'date': today.isoformat(),
        'total_sessions': len(sessions),
        'focus_sessions': len(focus_sessions),
        'total_focus_time_seconds': total_focus_time,
        'total_focus_time_minutes': total_focus_time // 60
    })

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5001, debug=True)