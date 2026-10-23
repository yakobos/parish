import os
import sqlite3
import uuid
from flask import Flask, request, redirect, render_template

# Point Flask explicitly to your internal template subdirectory
template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), 'templates'))
app = Flask(__name__, template_folder=template_dir)

# Fallback cleanly to a local file for this weekend's rapid testing
DB_PATH = os.environ.get('DATABASE_PATH', os.path.join(os.path.dirname(__file__), 'parish_core.db'))

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

@app.route('/')
def home():
    # Flask will automatically seek index.html inside your templates/ folder
    return render_template('index.html')

# Keep the rest of your /api/add-parishioner logic exactly the same below...
@app.route('/api/add-parishioner', methods=['POST'])
def add_parishioner():
    # Fetch parameters straight from the HTML Form
    first_name = request.form.get('first_name') or None
    last_name = request.form.get('last_name')
    gender = request.form.get('gender') if request.form.get('development_stage') != 'Unborn' else None
    liturgical_name = request.form.get('liturgical_name') or None
    patron_saint_id = request.form.get('patron_saint_id') or None
    spiritual_status = request.form.get('spiritual_status')
    regularity = request.form.get('regularity')
    development_stage = request.form.get('development_stage')
    personal_phone = request.form.get('personal_phone') or None
    personal_email = request.form.get('personal_email') or None
    languages_spoken = request.form.get('languages_spoken', 'English')
    job_title = request.form.get('job_title') or None

    # hardcoded placeholders for local weekend sandbox testing
    parish_id = "test-parish-uuid" 
    home_parish_id = "test-parish-uuid"
    person_uuid = str(uuid.uuid4())

    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute('''
            INSERT INTO parishioners (
                id, parish_id, home_parish_id, patron_saint_id, 
                first_name, last_name, gender, liturgical_name,
                spiritual_status, regularity, development_stage,
                personal_phone, personal_email, languages_spoken, job_title,
                life_status, antiochian_good_standing, last_seen_date
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Alive', 1, date('now'));
        ''', (
            person_uuid, parish_id, home_parish_id, patron_saint_id,
            first_name, last_name, gender, liturgical_name,
            spiritual_status, regularity, development_stage,
            personal_phone, personal_email, languages_spoken, job_title
        ))
        conn.commit()
    except sqlite3.Error as e:
        print(f"Database Error: {e}")
    finally:
        conn.close()

    # Instantly cycles back to a fresh entry form so you can type the next person with no lag
    return redirect('/')

if __name__ == '__main__':
    # Initialize mock structural lookup keys for development safety if needed
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("INSERT OR IGNORE INTO parishes (id, name, city, jurisdiction) VALUES ('test-parish-uuid', 'Sandbox Parish', 'Spokane', 'Antiochian');")
    conn.commit()
    conn.close()
    
    app.run(host='0.0.0.0', port=8080, debug=True)
