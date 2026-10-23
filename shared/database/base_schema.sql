PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS parishes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    jurisdiction TEXT NOT NULL CHECK(jurisdiction IN ('Antiochian', 'OCA', 'GOARCH', 'ROCOR', 'Other')),
    calendar_type TEXT NOT NULL CHECK(calendar_type IN ('OLD', 'NEW')) DEFAULT 'NEW'
);

CREATE TABLE IF NOT EXISTS saints (
    id TEXT PRIMARY KEY,
    official_name TEXT NOT NULL,
    common_name TEXT NOT NULL,
    feast_day_date TEXT NOT NULL,
    icon_url TEXT
);

CREATE TABLE IF NOT EXISTS households (
    id TEXT PRIMARY KEY,
    parish_id TEXT NOT NULL REFERENCES parishes(id) ON DELETE CASCADE,
    family_name TEXT NOT NULL,
    ui_display_name TEXT NOT NULL,
    shared_address TEXT,
    shared_email TEXT,
    shared_phone TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS parishioners (
    id TEXT PRIMARY KEY,
    parish_id TEXT NOT NULL REFERENCES parishes(id) ON DELETE CASCADE,
    household_id TEXT REFERENCES households(id) ON DELETE SET NULL,
    home_parish_id TEXT NOT NULL REFERENCES parishes(id),
    patron_saint_id TEXT REFERENCES saints(id) ON DELETE SET NULL,
    
    life_status TEXT NOT NULL CHECK(life_status IN ('Alive', 'Reposed')) DEFAULT 'Alive',
    development_stage TEXT NOT NULL CHECK(development_stage IN ('Unborn', 'Child', 'Adult')) DEFAULT 'Adult',
    
    first_name TEXT,                           
    last_name TEXT NOT NULL,                   
    gender TEXT CHECK(gender IN ('M', 'F')),   
    date_of_birth TEXT,                        
    date_of_repose TEXT,                       
    job_title TEXT,
    
    languages_spoken TEXT DEFAULT 'English',
    
    personal_email TEXT,
    personal_phone TEXT,
    personal_address TEXT,
    
    receive_email_newsletter INTEGER NOT NULL CHECK(receive_email_newsletter IN (0, 1)) DEFAULT 1,
    receive_sms_alerts INTEGER NOT NULL CHECK(receive_sms_alerts IN (0, 1)) DEFAULT 0,
    include_in_public_directory INTEGER NOT NULL CHECK(include_in_public_directory IN (0, 1)) DEFAULT 1,
    
    liturgical_name TEXT,                      
    clerical_rank TEXT NOT NULL CHECK(clerical_rank IN (
        'Laity', 'Reader', 'Subdeacon', 'Deacon', 'Priest', 'Choir Director'
    )) DEFAULT 'Laity',
    
    spiritual_status TEXT NOT NULL CHECK(spiritual_status IN (
        'Active Inquirer', 'Inconsistent Inquirer', 'Catechumen', 
        'Baptized', 'Lapsed', 'Guest'
    )),
    regularity TEXT NOT NULL CHECK(regularity IN (
        'Weekly', 'Monthly', 'Seasonally', 'Annually', 'Irregularly'
    )),
    antiochian_good_standing INTEGER NOT NULL CHECK(antiochian_good_standing IN (0, 1)) DEFAULT 1,
    
    first_visited_month_year TEXT,             
    catechumen_date TEXT,                      
    baptism_chrismation_date TEXT,             
    
    stewardship_envelope_number TEXT,          
    dietary_notes TEXT,                        
    mobility_notes TEXT,                       
    cemetery_plot_number TEXT,                 
    
    last_seen_date TEXT DEFAULT (date('now')), 
    last_online_activity TEXT,                 
    
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS personal_relationships (
    id TEXT PRIMARY KEY,
    parish_id TEXT NOT NULL REFERENCES parishes(id) ON DELETE CASCADE,
    person_a_id TEXT NOT NULL REFERENCES parishioners(id) ON DELETE CASCADE,
    person_b_id TEXT NOT NULL REFERENCES parishioners(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL CHECK(relationship_type IN (
        'Parent', 'Child', 'Spouse', 'Sibling', 'Godparent', 'Godchild', 'Confessor', 'Spiritual Child'
    )),
    CHECK(person_a_id != person_b_id)
);

CREATE INDEX IF NOT EXISTS idx_parishioner_lookup ON parishioners (parish_id, last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_household_lookup ON households (parish_id, family_name);
CREATE INDEX IF NOT EXISTS idx_relationship_lookup ON personal_relationships (person_a_id, relationship_type);
CREATE INDEX IF NOT EXISTS idx_saint_matching ON parishioners (patron_saint_id);
