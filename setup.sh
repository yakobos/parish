# 1. Jump directly into your identity microservice directory
cd services/private-id-service

# 2. Build your local SQLite tracking database from your master schema script
python3 -c "
import sqlite3
conn = sqlite3.connect('parish_core.db')
with open('../../shared/database/base_schema.sql', 'r') as f:
    conn.executescript(f.read())
# Pre-populate your local test church sandbox key
conn.execute(\"INSERT OR IGNORE INTO parishes (id, name, city, jurisdiction) VALUES ('test-parish-uuid', 'Sandbox Parish', 'Spokane', 'Antiochian');\")
# Seed your master lookup table with base saints
conn.execute(\"INSERT OR IGNORE INTO saints (id, official_name, common_name, feast_day_date) VALUES ('st-john-bap', 'St. John the Baptist', 'St. John the Baptist', '01-07'), ('st-nicholas', 'St. Nicholas', 'St. Nicholas', '12-06'), ('st-spyridon', 'St. Spyridon', 'St. Spyridon', '12-12');\")
conn.commit()
conn.close()
print('✨ SQLite engine initialized with master schema and local data filters.')
"

# 3. Fire up your lightweight development backend script
python3 app.py
