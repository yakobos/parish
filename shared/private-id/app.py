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
