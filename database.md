# Database Schema Documentation - Luwes Water Sensor

**Database Version**: PostgreSQL 16.10
**Schema**: public  
**Total Tables**: 531  
**Last Updated**: January 8, 2026

---

## Database Overview

Sistem Luwes Water Sensor menggunakan PostgreSQL sebagai database utama dengan pola partitioning untuk time-series data. Database ini menyimpan informasi pengguna, stasiun sensor, dan data monitoring air dalam berbagai granularitas waktu.

### Database Connection (use this in .env files)
```
Host: 127.0.0.1
Port: 5433
Database: geo
User: geo
Password: geopass
```

**Database ini di-design untuk time-series data monitoring**, dimana data sensor **SELALU bertambah** setiap kali:
- Sensor mengirim data via **TCP** (Port 1025/1026)
- Data masuk via **MQTT** (Port 1884)
- Message diterima via **NATS** (Port 4223)

---

## Table Categories

### 1. Core Tables (5 tables)
- `users` - User management
- `groups` - Organization/group management
- `stations` - Water sensor stations
- `user_auths` - Authentication logs
- `predictions` - Water level predictions

### 2. Time-Series Base Tables (3 tables)
- `station_logs` - Raw sensor data (real-time)
- `station_minutes` - Minutely aggregated data
- `station_hours` - Hourly aggregated data

### 3. Partitioned Tables (523 tables)
- `station_logs_{station_id}` - Per-station raw logs (177 tables)
- `station_minutes_{station_id}` - Per-station minute data (173 tables)
- `station_hours_{station_id}` - Per-station hour data (173 tables)

---

## Core Tables Detail

### 1. Table: `users`

**Purpose**: Menyimpan informasi user yang dapat mengakses sistem.

**Structure**:
```sql
CREATE TABLE users (
    id                SERIAL PRIMARY KEY,
    created_at        TIMESTAMP WITHOUT TIME ZONE,
    updated_at        TIMESTAMP WITHOUT TIME ZONE,
    deleted_at        TIMESTAMP WITHOUT TIME ZONE,
    email             VARCHAR(50) UNIQUE NOT NULL,
    password          VARCHAR(88),
    reset_id          VARCHAR(88),
    verified          BOOLEAN DEFAULT FALSE,
    note              TEXT,
    group_id          INTEGER NOT NULL REFERENCES groups(id),
    phone             VARCHAR(24) UNIQUE,
    full_name         VARCHAR(50),
    updated_by        BIGINT,
    deleted_by        BIGINT,
    restored_by       BIGINT,
    created_by        BIGINT,
    unique_id         VARCHAR(240) UNIQUE,
    is_deleted        BOOLEAN NOT NULL DEFAULT FALSE,
    data              JSONB DEFAULT '{}'
);
```

**Indexes**:
- `users_pkey` - PRIMARY KEY (id)
- `email_unique` - UNIQUE (email)
- `unique_users_email` - UNIQUE (email)
- `users_phone_key` - UNIQUE (phone)
- `users_unique_id_key` - UNIQUE (unique_id)

**Foreign Keys**:
- `group_id` → `groups(id)`

**Referenced By**:
- `user_auths.user_id`

**Field Details**:
- `id`: Auto-increment unique identifier
- `email`: User email for login (max 50 chars)
- `password`: Hashed password (max 88 chars)
- `reset_id`: Password reset token
- `verified`: Email verification status
- `group_id`: Organization/group reference (NOT NULL)
- `phone`: Contact phone number (unique)
- `full_name`: Display name
- `is_deleted`: Soft delete flag
- `data`: Additional JSON data for extensibility
- `created_at`, `updated_at`, `deleted_at`: Audit timestamps
- `created_by`, `updated_by`, `deleted_by`, `restored_by`: Audit user IDs

---

### 2. Table: `groups`

**Purpose**: Organisasi atau group yang memiliki stasiun sensor.

**Structure**:
```sql
CREATE TABLE groups (
    id          SERIAL PRIMARY KEY,
    created_at  TIMESTAMP WITHOUT TIME ZONE,
    updated_at  TIMESTAMP WITHOUT TIME ZONE,
    deleted_at  TIMESTAMP WITHOUT TIME ZONE,
    name        VARCHAR(50) UNIQUE,
    note        TEXT,
    updated_by  BIGINT,
    deleted_by  BIGINT,
    restored_by BIGINT,
    created_by  BIGINT,
    unique_id   VARCHAR(240) UNIQUE,
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    data        JSONB DEFAULT '{}'
);
```

**Indexes**:
- `groups_pkey` - PRIMARY KEY (id)
- `groups_unique_id_key` - UNIQUE (unique_id)
- `unique_groups_name` - UNIQUE (name)

**Referenced By**:
- `stations.group_id`
- `users.group_id`

**Field Details**:
- `id`: Auto-increment unique identifier
- `name`: Group/organization name (unique, max 50 chars)
- `note`: Additional notes/description
- `unique_id`: External unique identifier (max 240 chars)
- `is_deleted`: Soft delete flag
- `data`: JSON field for extensibility
- Audit fields: created_at, updated_at, deleted_at, created_by, updated_by, deleted_by, restored_by


---

### 3. Table: `stations`

**Purpose**: Stasiun sensor monitoring air (sungai, laut, bendungan).

**Structure**:
```sql
CREATE TABLE stations (
    id                  SERIAL PRIMARY KEY,
    created_at          TIMESTAMP WITHOUT TIME ZONE,
    updated_at          TIMESTAMP WITHOUT TIME ZONE,
    deleted_at          TIMESTAMP WITHOUT TIME ZONE,
    name                VARCHAR(50),
    long                DOUBLE PRECISION,          -- Longitude (koordinat GPS)
    lat                 DOUBLE PRECISION,          -- Latitude (koordinat GPS)
    imei                VARCHAR(15) UNIQUE,        -- Device IMEI
    location            VARCHAR(50),               -- Location description
    public              BOOLEAN,                   -- Publicly accessible
    history             TEXT,                      -- Historical notes
    hist_count          INTEGER,
    group_id            INTEGER NOT NULL REFERENCES groups(id),
    min_filter          DOUBLE PRECISION DEFAULT -2,
    max_filter          DOUBLE PRECISION DEFAULT 2,
    updated_by          BIGINT,
    deleted_by          BIGINT,
    restored_by         BIGINT,
    created_by          BIGINT,
    unique_id           VARCHAR(240) UNIQUE,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    data                JSONB DEFAULT '{}',
    public_dl           BOOLEAN DEFAULT FALSE,     -- Public download allowed
    last_submitted_at   TIMESTAMP WITHOUT TIME ZONE,
    last_level_sensor   DOUBLE PRECISION           -- Last recorded water level
);
```

**Indexes**:
- `stations_pkey` - PRIMARY KEY (id)
- `stations_unique_id_key` - UNIQUE (unique_id)
- `unique_stations_imei` - UNIQUE (imei)

**Foreign Keys**:
- `group_id` → `groups(id)`

**Referenced By**:
- Multiple `station_logs_{id}` tables (177 references)
- Table partitioning for each station

**Field Details**:
- `id`: Auto-increment unique identifier
- `name`: Station name (max 50 chars)
- `long`, `lat`: GPS coordinates (double precision)
- `imei`: Device International Mobile Equipment Identity (unique, 15 chars)
- `location`: Human-readable location description
- `public`: Whether station data is publicly accessible
- `public_dl`: Whether public download is allowed
- `group_id`: Owner organization (NOT NULL)
- `min_filter`, `max_filter`: Data filtering thresholds (default -2 to 2)
- `last_submitted_at`: Timestamp of last data submission
- `last_level_sensor`: Most recent water level reading
- `data`: JSON field for additional metadata
- Audit fields: Standard audit trail

**Partitioned Child Tables**: Each station gets dedicated tables:
- `station_logs_{station_id}` - Real-time sensor data
- `station_minutes_{station_id}` - Minute-level aggregations
- `station_hours_{station_id}` - Hour-level aggregations

---

### 4. Table: `user_auths`

**Purpose**: Log aktivitas autentikasi user (login history).

**Structure**:
```sql
CREATE TABLE user_auths (
    id                      SERIAL PRIMARY KEY,
    created_at              TIMESTAMP WITHOUT TIME ZONE,
    updated_at              TIMESTAMP WITHOUT TIME ZONE,
    deleted_at              TIMESTAMP WITHOUT TIME ZONE,
    authid                  VARCHAR(50),           -- Authentication session ID
    remote_addr             VARCHAR(50),           -- Client IP address
    http_x_forwarded_for    VARCHAR(50),           -- Proxy/forwarded IP
    user_agent              VARCHAR(50),           -- Browser user agent
    history                 TEXT,                  -- Login history
    hist_count              INTEGER,               -- History count
    user_id                 INTEGER NOT NULL REFERENCES users(id)
);
```

**Indexes**:
- `user_auths_pkey` - PRIMARY KEY (id)

**Foreign Keys**:
- `user_id` → `users(id)`

**Field Details**:
- `id`: Auto-increment unique identifier
- `authid`: Session authentication identifier
- `remote_addr`: Client's IP address
- `http_x_forwarded_for`: IP if behind proxy/load balancer
- `user_agent`: Browser/client identification string
- `history`: Text log of authentication events
- `hist_count`: Number of historical entries
- `user_id`: Reference to authenticated user (NOT NULL)
- Timestamp fields: created_at, updated_at, deleted_at

**Purpose**:
- Track user login activities
- Security audit trail
- Session management
- IP-based access control

---

### 5. Table: `predictions`

**Purpose**: Prediksi tinggi air untuk peringatan dini.

**Structure**:
```sql
CREATE TABLE predictions (
    id              BIGSERIAL PRIMARY KEY,
    created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    predict_epoch   DOUBLE PRECISION,              -- Unix timestamp prediksi
    station_id      INTEGER NOT NULL,
    level           DOUBLE PRECISION NOT NULL      -- Predicted water level
);
```

**Indexes**:
- `predictions_pkey` - PRIMARY KEY (id)
- `predictions_sta` - (station_id)
- `sta_id__predict_epoch` - UNIQUE (station_id, predict_epoch)

**Field Details**:
- `id`: Auto-increment 64-bit identifier
- `created_at`: Timestamp when prediction was created (default NOW())
- `predict_epoch`: Unix epoch timestamp untuk waktu prediksi
- `station_id`: ID stasiun yang diprediksi (NOT NULL)
- `level`: Tinggi air yang diprediksi dalam meter (NOT NULL)

**Purpose**:
- Early warning system untuk banjir
- Trend analysis
- Machine learning predictions
- Alert generation

---

## Time-Series Tables

### 1. Table: `station_logs` (Base Table)

**Purpose**: Data mentah real-time dari sensor stasiun (partitioned by station_id).

**Structure**:
```sql
CREATE TABLE station_logs (
    id                      SERIAL PRIMARY KEY,
    created_at              TIMESTAMP WITHOUT TIME ZONE,
    updated_at              TIMESTAMP WITHOUT TIME ZONE,
    deleted_at              TIMESTAMP WITHOUT TIME ZONE,
    submitted_at            TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    sequence                INTEGER,
    level_sensor            DOUBLE PRECISION,          -- Water level (meter)
    accel_x                 DOUBLE PRECISION,          -- Accelerometer X-axis
    accel_y                 DOUBLE PRECISION,          -- Accelerometer Y-axis
    accel_z                 DOUBLE PRECISION,          -- Accelerometer Z-axis
    power_current           DOUBLE PRECISION,          -- Battery current (mA)
    ip_address              VARCHAR(50),               -- Sender IP
    log_type                INTEGER,
    station_id              INTEGER NOT NULL,
    power_voltage           DOUBLE PRECISION,          -- Battery voltage (V)
    data                    JSONB,                     -- Additional sensor data
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    temperature             DOUBLE PRECISION,          -- Temperature (°C)
    wind_speed              DOUBLE PRECISION,          -- Wind speed (m/s)
    soil_moisture           DOUBLE PRECISION,          -- Soil moisture (%)
    wind_direction          DOUBLE PRECISION,          -- Wind direction (degrees)
    raindrop                DOUBLE PRECISION,          -- Rain intensity
    humidity                INTEGER,                   -- Humidity (%)
    barometric_pressure     DOUBLE PRECISION,          -- Pressure (hPa)
    wind_speed_average      DOUBLE PRECISION,          -- Avg wind speed
    wind_gust               DOUBLE PRECISION,          -- Wind gust (m/s)
    wind_direction_average  DOUBLE PRECISION,          -- Avg wind direction
    rain_rate               DOUBLE PRECISION           -- Rainfall rate (mm/h)
);
```

**Indexes**:
- `station_logs_pkey` - PRIMARY KEY (id)
- `order_sid_sat` - (station_id, submitted_at)
- `station_id__submitted_at` - (station_id, submitted_at DESC)
- `station_logs__sta_id__epoch` - CLUSTER (station_id, epoch(submitted_at))
- `station_logs__sta_id__submit_date` - (station_id, date_trunc('day', submitted_at))
- `submitted_at_index` - (submitted_at)
- `uniq_sid_sat` - UNIQUE (station_id, submitted_at)

**Triggers**:
- `trigger_ai_station_logs` - AFTER INSERT → `fn_ai_station_logs()`
  - Auto-creates partitioned table `station_logs_{station_id}` if not exists
  - Routes data to correct partition

**Partitioned Tables**: `station_logs_{station_id}`
- Automatically created when new station submits data
- Each station has dedicated table for performance
- Current partitions: 177 stations

**Sensor Data Fields**:
- **Water Monitoring**:
  - `level_sensor`: Primary measurement - water level in meters
  
- **Motion Sensors** (for earthquake/tsunami detection):
  - `accel_x`, `accel_y`, `accel_z`: 3-axis accelerometer readings
  
- **Weather Station Data**:
  - `temperature`: Air temperature in Celsius
  - `humidity`: Relative humidity percentage
  - `barometric_pressure`: Atmospheric pressure in hPa
  - `wind_speed`: Instantaneous wind speed (m/s)
  - `wind_speed_average`: Average wind speed
  - `wind_gust`: Maximum wind gust
  - `wind_direction`: Wind direction in degrees (0-360)
  - `wind_direction_average`: Average wind direction
  - `raindrop`: Rain detection/intensity
  - `rain_rate`: Rainfall rate in mm/hour
  - `soil_moisture`: Soil moisture percentage
  
- **Power Monitoring**:
  - `power_voltage`: Battery/power supply voltage
  - `power_current`: Current consumption in milliamps
  
- **Metadata**:
  - `submitted_at`: Exact timestamp when data submitted (NOT NULL)
  - `sequence`: Message sequence number
  - `ip_address`: Source IP of data submission
  - `log_type`: Classification of log entry
  - `data`: JSONB for additional/custom sensor data

**Data Flow**:
1. Sensor sends data via MQTT/TCP
2. Insert into `station_logs`
3. Trigger routes to `station_logs_{station_id}`
4. Aggregation processes create minute/hour summaries

---

### 2. Table: `station_minutes` (Base Table)

**Purpose**: Agregasi data per-menit (partitioned by station_id).

**Structure**:
```sql
CREATE TABLE station_minutes (
    at      TIMESTAMP WITHOUT TIME ZONE,    -- Minute timestamp
    slid    INTEGER NOT NULL,                -- Station log ID reference
    sid     INTEGER NOT NULL,                -- Station ID
    PRIMARY KEY (slid, sid)
);
```

**Indexes**:
- `station_minutes_pkey` - PRIMARY KEY (slid, sid)
- `index_station_minutes_sid` - (sid)
- `index_station_minutes_slid` - (slid)
- `station_minutes_at_sid` - CLUSTER (epoch(at), sid)
- `station_minutes_sid_at` - (sid, at)
- `uniq_mm` - UNIQUE (uniq_minute(at), sid)

**Triggers**:
- `trigger_ai_station_minutes` - AFTER INSERT → `fn_ai_station_minutes()`
  - Creates `station_minutes_{station_id}` if needed
  - Routes to partition

**Partitioned Tables**: `station_minutes_{station_id}`
- Per-station minute-level aggregation
- Current partitions: 173 stations

**Purpose**:
- Minute-level time-series data
- Faster queries than raw logs
- Intermediate aggregation level
- Trend analysis

**Field Details**:
- `at`: Truncated to minute boundary timestamp
- `slid`: Reference to source log entry ID
- `sid`: Station identifier (partition key)

---

### 3. Table: `station_hours` (Base Table)

**Purpose**: Agregasi data per-jam (partitioned by station_id).

**Structure**:
```sql
CREATE TABLE station_hours (
    at      TIMESTAMP WITHOUT TIME ZONE,    -- Hour timestamp
    slid    INTEGER NOT NULL,                -- Station log ID reference
    sid     INTEGER NOT NULL,                -- Station ID
    PRIMARY KEY (slid, sid)
);
```

**Indexes**:
- `station_hours_pkey` - PRIMARY KEY (slid, sid)
- `index_station_hours_sid` - CLUSTER (sid)
- `station_hours_at_sid` - (epoch(at), sid)
- `uniq_hh` - UNIQUE (uniq_hours(at), sid)

**Triggers**:
- `trigger_ai_station_hours` - AFTER INSERT → `fn_ai_station_hours()`
  - Creates `station_hours_{station_id}` if needed
  - Routes to partition

**Partitioned Tables**: `station_hours_{station_id}`
- Per-station hourly aggregation
- Current partitions: 173 stations

**Purpose**:
- Hourly time-series data
- Historical analysis
- Reporting and dashboards
- Long-term storage

**Field Details**:
- `at`: Truncated to hour boundary timestamp
- `slid`: Reference to source log entry ID
- `sid`: Station identifier (partition key)

---

## Database Functions

### 1. `check_table_exist(table_name TEXT) → BOOLEAN`

**Purpose**: Memeriksa apakah table ada di schema public.

**Returns**: TRUE jika table exists, FALSE otherwise.

**Usage**:
```sql
SELECT check_table_exist('station_logs_110');
```

---

### 2. `create_station_hours_station(station_id INTEGER) → VOID`

**Purpose**: Membuat tabel `station_hours_{station_id}` untuk stasiun baru.

**Parameters**:
- `station_id`: ID stasiun yang akan dibuatkan tabel

**Creates**:
- Table: `station_hours_{station_id}`
- Indexes
- Foreign key constraints

**Usage**:
```sql
SELECT create_station_hours_station(123);
```

---

### 3. `create_station_logs_station(station_id INTEGER) → VOID`

**Purpose**: Membuat tabel `station_logs_{station_id}` untuk stasiun baru.

**Parameters**:
- `station_id`: ID stasiun yang akan dibuatkan tabel

**Creates**:
- Table: `station_logs_{station_id}` with all sensor columns
- Indexes for performance
- Foreign key to stations table
- Triggers

**Auto-called by**: `fn_ai_station_logs()` trigger

---

### 4. `create_station_minutes_station(station_id INTEGER) → VOID`

**Purpose**: Membuat tabel `station_minutes_{station_id}` untuk stasiun baru.

**Parameters**:
- `station_id`: ID stasiun yang akan dibuatkan tabel

**Creates**:
- Table: `station_minutes_{station_id}`
- Indexes
- Constraints

---

### 5. `fn_ai_station_logs() → TRIGGER`

**Purpose**: Trigger function setelah INSERT ke station_logs.

**Actions**:
1. Check if `station_logs_{station_id}` exists
2. Create table if not exists (via `create_station_logs_station()`)
3. Route data to correct partition
4. Update station metadata (last_submitted_at, last_level_sensor)

**Triggered by**: INSERT on `station_logs`

---

### 6. `fn_ai_station_hours() → TRIGGER`

**Purpose**: Trigger function setelah INSERT ke station_hours.

**Actions**:
1. Check partition existence
2. Create if needed
3. Route to partition

**Triggered by**: INSERT on `station_hours`

---

### 7. `fn_ai_station_minutes() → TRIGGER`

**Purpose**: Trigger function setelah INSERT ke station_minutes.

**Actions**:
1. Check partition existence
2. Create if needed
3. Route to partition

**Triggered by**: INSERT on `station_minutes`

---

### 8. `uniq_hours(some_time TIMESTAMP) → TEXT`

**Purpose**: Generate unique string untuk jam tertentu.

**Parameters**:
- `some_time`: Timestamp to convert

**Returns**: String representation of hour (e.g., "2026-01-08 15")

**Used by**: UNIQUE index on station_hours

---

### 9. `uniq_minute(some_time TIMESTAMP) → TEXT`

**Purpose**: Generate unique string untuk menit tertentu.

**Parameters**:
- `some_time`: Timestamp to convert

**Returns**: String representation of minute (e.g., "2026-01-08 15:30")

**Used by**: UNIQUE index on station_minutes

---

### 10. `drop_tables_with_name() → VOID`

**Purpose**: Utility function untuk drop tables dengan pattern tertentu.

**Usage**: Maintenance and cleanup operations.

---

### 11. `move_station_hours_station() → VOID`

**Purpose**: Migrasi data station_hours ke partisi yang benar.

**Usage**: Data migration and reorganization.

---

### 12. `move_station_logs_station() → VOID`

**Purpose**: Migrasi data station_logs ke partisi yang benar.

**Usage**: Data migration and reorganization.

---

### 13. `move_station_minutes_station() → VOID`

**Purpose**: Migrasi data station_minutes ke partisi yang benar.

**Usage**: Data migration and reorganization.

---

## Entity Relationship Diagram (ERD)

```
┌──────────────────┐
│     groups       │
│                  │
│ PK: id          │
│    name         │◄────────┐
│    note         │         │
│    unique_id    │         │ group_id
│    data (jsonb) │         │
└──────────────────┘         │
         ▲                   │
         │                   │
         │ group_id          │
         │                   │
         │                   │
┌────────┴─────────┐  ┌──────┴───────────────┐
│     users        │  │     stations         │
│                  │  │                      │
│ PK: id          │  │ PK: id              │
│ FK: group_id    │  │ FK: group_id        │
│    email        │  │    name             │
│    password     │  │    imei (unique)    │
│    phone        │  │    long, lat        │
│    full_name    │  │    location         │
│    verified     │  │    public           │
│    data (jsonb) │  │    last_submitted_at│
└─────────┬────────┘  │    last_level_sensor│
          │           │    data (jsonb)     │
          │           └──────┬───────────────┘
          │ user_id          │
          │                  │ station_id
          ▼                  │
┌──────────────────┐         │
│   user_auths     │         │
│                  │         ├─────────────┐
│ PK: id          │         │             │
│ FK: user_id     │         ▼             ▼
│    authid       │  ┌──────────────┐ ┌──────────────┐
│    remote_addr  │  │station_logs  │ │ predictions  │
│    user_agent   │  │              │ │              │
│    history      │  │PK: id        │ │PK: id        │
└──────────────────┘  │   station_id │ │   station_id │
                      │   submitted_at│ │   level      │
                      │   level_sensor│ │   predict_   │
                      │   temperature │ │     epoch    │
                      │   wind_speed  │ └──────────────┘
                      │   humidity    │
                      │   accel_x/y/z │
                      │   data (jsonb)│
                      └───────┬────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
                ▼             ▼             ▼
        ┌────────────┐ ┌────────────┐ ┌────────────┐
        │station_logs│ │station_    │ │station_    │
        │    _110    │ │ minutes_110│ │ hours_110  │
        │            │ │            │ │            │
        │(partition) │ │(partition) │ │(partition) │
        └────────────┘ └────────────┘ └────────────┘
                ... (177 stations) ...
```

---

## Partitioning Strategy

### Why Partitioning?

1. **Performance**: Queries on specific stations are much faster
2. **Scalability**: Each station can grow independently
3. **Maintenance**: Easier to archive/delete old data per station
4. **Isolation**: Issues with one station don't affect others

### Partition Naming Convention

- **station_logs_{id}**: Raw sensor data for station ID
- **station_minutes_{id}**: Minute-aggregated data for station ID
- **station_hours_{id}**: Hour-aggregated data for station ID

### Current Partitions

| Partition Type       | Count | Example IDs |
|---------------------|-------|-------------|
| station_logs_*      | 177   | 99, 110, 167, 245, 247, 249, 259, ..., 645 |
| station_minutes_*   | 173   | 99, 110, 167, 245, 247, 249, 259, ..., 636 |
| station_hours_*     | 173   | 110, 167, 245, 247, 249, 259, ..., 636 |

### Auto-Partitioning Process

1. **New Data Arrives**: Sensor sends data via MQTT/TCP
2. **Insert to Base Table**: Data inserted into `station_logs`
3. **Trigger Fires**: `trigger_ai_station_logs` executes
4. **Check Partition**: `fn_ai_station_logs()` checks if partition exists
5. **Create if Needed**: Calls `create_station_logs_station(station_id)`
6. **Route Data**: Data automatically moved to `station_logs_{station_id}`
7. **Aggregation**: Background processes create minute/hour summaries

---

## Data Types & Constraints

### Standard Field Types

| Field Pattern | Type | Description |
|--------------|------|-------------|
| id | SERIAL / BIGSERIAL | Auto-increment primary key |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |
| deleted_at | TIMESTAMP | Soft delete timestamp |
| is_deleted | BOOLEAN | Soft delete flag (NOT NULL, DEFAULT FALSE) |
| unique_id | VARCHAR(240) | External unique identifier (UNIQUE) |
| data | JSONB | Extensible JSON data (DEFAULT '{}') |
| *_by fields | BIGINT | Audit trail user IDs |

### Sensor-Specific Types

| Field | Type | Unit | Range |
|-------|------|------|-------|
| level_sensor | DOUBLE PRECISION | meters | -∞ to +∞ |
| temperature | DOUBLE PRECISION | °Celsius | -50 to +60 (typical) |
| humidity | INTEGER | % | 0 to 100 |
| barometric_pressure | DOUBLE PRECISION | hPa | 800 to 1100 (typical) |
| wind_speed | DOUBLE PRECISION | m/s | 0 to +∞ |
| wind_direction | DOUBLE PRECISION | degrees | 0 to 360 |
| rain_rate | DOUBLE PRECISION | mm/hour | 0 to +∞ |
| accel_x/y/z | DOUBLE PRECISION | g-force | -10 to +10 (typical) |
| power_voltage | DOUBLE PRECISION | Volts | 0 to +∞ |
| power_current | DOUBLE PRECISION | mA | 0 to +∞ |

---

## Indexes & Performance

### Indexing Strategy

1. **Primary Keys**: All tables have SERIAL/BIGSERIAL PKs
2. **Unique Constraints**: Email, phone, IMEI, unique_id
3. **Foreign Keys**: Automatic indexes on FK columns
4. **Time-Series**: Composite indexes on (station_id, timestamp)
5. **Clustering**: CLUSTER on most-queried indexes for locality

### Critical Indexes

#### station_logs Performance
```sql
-- Most used for queries
CREATE INDEX station_logs__sta_id__epoch ON station_logs 
    USING btree (station_id, date_part('epoch', submitted_at)) CLUSTER;

-- Time-range queries
CREATE INDEX station_id__submitted_at ON station_logs 
    USING btree (station_id, submitted_at DESC NULLS LAST);

-- Uniqueness constraint
CREATE UNIQUE INDEX uniq_sid_sat ON station_logs 
    USING btree (station_id, submitted_at);
```

#### station_hours Performance
```sql
-- Primary access pattern
CREATE INDEX index_station_hours_sid ON station_hours 
    USING btree (sid) CLUSTER;

-- Time-based queries
CREATE INDEX station_hours_at_sid ON station_hours 
    USING btree (date_part('epoch', at), sid);
```

#### station_minutes Performance
```sql
-- Clustered for sequential reads
CREATE INDEX station_minutes_at_sid ON station_minutes 
    USING btree (date_part('epoch', at), sid) CLUSTER;

-- Bi-directional queries
CREATE INDEX station_minutes_sid_at ON station_minutes 
    USING btree (sid, at);
```

---

## Query Patterns

### Common Queries

#### 1. Get Latest Reading for Station
```sql
SELECT 
    submitted_at,
    level_sensor,
    temperature,
    humidity,
    wind_speed
FROM station_logs_110  -- Direct partition access
ORDER BY submitted_at DESC
LIMIT 1;
```

#### 2. Get Hourly Data for Date Range
```sql
SELECT 
    at as hour,
    AVG(sl.level_sensor) as avg_level,
    MAX(sl.level_sensor) as max_level,
    MIN(sl.level_sensor) as min_level
FROM station_hours_110 sh
JOIN station_logs_110 sl ON sh.slid = sl.id
WHERE at BETWEEN '2026-01-01' AND '2026-01-31'
GROUP BY at
ORDER BY at;
```

#### 3. Get All Stations with Latest Data
```sql
SELECT 
    s.id,
    s.name,
    s.location,
    s.lat,
    s.long,
    s.last_submitted_at,
    s.last_level_sensor,
    g.name as group_name
FROM stations s
JOIN groups g ON s.group_id = g.id
WHERE s.is_deleted = FALSE
  AND s.public = TRUE
ORDER BY s.last_submitted_at DESC;
```

#### 4. Get User Stations
```sql
SELECT 
    s.*,
    COUNT(sl.id) as total_logs
FROM stations s
JOIN groups g ON s.group_id = g.id
JOIN users u ON u.group_id = g.id
LEFT JOIN station_logs sl ON sl.station_id = s.id 
    AND sl.submitted_at > NOW() - INTERVAL '24 hours'
WHERE u.id = $1
  AND s.is_deleted = FALSE
GROUP BY s.id;
```

#### 5. Get Predictions for Station
```sql
SELECT 
    predict_epoch,
    to_timestamp(predict_epoch) as predict_time,
    level,
    created_at
FROM predictions
WHERE station_id = $1
  AND predict_epoch > extract(epoch from NOW())
ORDER BY predict_epoch;
```

---

## Data Growth & Insert Mechanism

### CATATAN: Database AKAN TERUS BERTAMBAH

**Database ini di-design untuk time-series data monitoring**, dimana data sensor **SELALU bertambah** setiap kali:
- Sensor mengirim data via **TCP** (Port 1025/1026)
- Data masuk via **MQTT** (Port 1884)
- Message diterima via **NATS** (Port 4223)

### Insert Behavior per Table

#### 1. **station_logs_{station_id}** - ALWAYS INSERT ✅

**Setiap data yang masuk PASTI membuat row baru**:

```go
// Golang TCP Server (shell/tcpserver.go)
func (s *TCPServer) OnTraffic(c gnet.Conn) (action gnet.Action) {
    // Parse data dari sensor
    _, stationLogPg, err = models.ParseToPostgreSQL(buf)
    
    // INSERT SETIAP KALI data masuk
    if dataLength == 16 {
        if err := stationLogPg.DoInsert16(); err != nil {
            return
        }
    } else {
        if err := stationLogPg.DoInsert14(); err != nil {
            return
        }
    }
}
```

**Frequency**: Jika sensor mengirim setiap **1 menit**, maka:
- **1 jam** = 60 rows
- **1 hari** = 1,440 rows
- **1 bulan** = 43,200 rows
- **1 tahun** = 525,600 rows per station

**Protection**: Unique constraint `(station_id, submitted_at)` mencegah duplikasi timestamp yang sama.

---

#### 2. **station_minutes_{station_id}** - CONDITIONAL INSERT ⚠️

**Hanya insert jika MENIT BERUBAH dari data sebelumnya**:

```go
// Golang TCP Server (shell/tcpserver.go)
if newLastSubmittedAt.Minute() != station.LastSubmittedAt.Minute() {
    stationMinutes := oStations.NewStationMinutesMutator(s.db)
    stationMinutes.At = stationLogPg.SubmittedAt
    stationMinutes.SLID = stationLogPg.Id
    stationMinutes.SID = station.Id
    
    if err := stationMinutes.DoInsert(station.Id); err != nil {
        return
    }
}
```

**Logic**:
- Compare timestamp menit saat ini dengan menit terakhir di database
- Jika **berbeda** → INSERT row baru
- Jika **sama** → SKIP (tidak insert)

**Example**:
```
Data 1: 2026-01-08 15:30:00 → INSERT (menit baru)
Data 2: 2026-01-08 15:30:30 → SKIP (masih menit 30)
Data 3: 2026-01-08 15:30:45 → SKIP (masih menit 30)
Data 4: 2026-01-08 15:31:00 → INSERT (menit berubah ke 31)
```

**Frequency**: Maksimal **1 row per menit** per station.

---

#### 3. **station_hours_{station_id}** - CONDITIONAL INSERT ⚠️

**Hanya insert jika JAM BERUBAH dari data sebelumnya**:

```go
// Golang TCP Server (shell/tcpserver.go)
if newLastSubmittedAt.Hour() != station.LastSubmittedAt.Hour() {
    stationHours := oStations.NewStationHoursMutator(s.db)
    stationHours.At = stationLogPg.SubmittedAt
    stationHours.SLID = stationLogPg.Id
    stationHours.SID = station.Id
    
    if err := stationHours.DoInsert(station.Id); err != nil {
        return
    }
}
```

**Logic**:
- Compare timestamp jam saat ini dengan jam terakhir di database
- Jika **berbeda** → INSERT row baru
- Jika **sama** → SKIP (tidak insert)

**Frequency**: Maksimal **1 row per jam** per station = **24 rows/hari**.

---

#### 4. **stations** - INSERT ONLY FOR NEW IMEI 🆕

**Hanya bertambah saat sensor dengan IMEI baru pertama kali mengirim data**:

```go
// Golang TCP Server (shell/tcpserver.go)
// create new station if not found
if !station.FindByIMEI() {
    group := oGroups.NewGroupMutator(s.db)
    group.Name = "Guest"
    
    if !group.FindByName() {
        return errors.New("group not found")
    }
    
    // INSERT new station
    station.GroupID = group.Id
    if err := station.DoInsert(); err != nil {
        return err
    }
}
```

**Frequency**: Hanya ketika **sensor baru** dengan IMEI yang belum terdaftar mulai mengirim data.

---

### Data Format Support

Sistem mendukung **2 format data** dari sensor:

#### Format 14 Fields (Legacy - Port 1025)
```
seq#name#imei#time#date#level#accel_x,y,z#voltage#current
```
Example:
```
100#ST0001#863071010698188#07:03:13#23-08-2013#1785#2.87,0.25,0.05#11.57#0.08
```

#### Format 16 Fields (New - Port 1026)
```
imei#name#lat,long,alt#volt,curr#datetime#level#temp#humid#pressure#wind_speed#wind_avg#wind_gust#wind_dir#wind_dir_avg#rainfall#rain_rate
```
Example:
```
866191037511318#luwes#-1.993,160.892,0.000#12.8,0.08#12-08-2019 12:24:00#1.243#28.1#68#999.8#3.4#3.0#6.1#90#100#10#2
```

---

### Data Protection Mechanisms

#### 1. Unique Constraint (Prevent Duplicates)
```sql
-- Defined in station_logs structure
CREATE UNIQUE INDEX uniq_sid_sat ON station_logs 
    USING btree (station_id, submitted_at);
```
**Prevents**: Data dengan station_id dan timestamp yang sama tidak bisa di-insert dua kali.

#### 2. Future Timestamp Validation (NATS)
```go
// Golang NATS Subscriber (shell/nats.go)
maxFuture := time.Now().Add(24 * time.Hour)

if stationLogCh.SubmittedAt.After(maxFuture) {
    return errors.New(`submitted_at is in future: ` + stationLogCh.SubmittedAt.String())
}
```
**Prevents**: Data dengan timestamp lebih dari 24 jam di masa depan akan di-reject.

#### 3. Year Validation (Ruby Legacy)
```ruby
# Ruby TCP Server (shell/tcpserver.rb)
vyear = Date.today.year
if ((y < vyear - 1) or (y > vyear + 1)) and data[0].to_i < 0
    # Replace with server time for old streaming data
    t = Time.new.utc
    y, m, d, hh, mm, ss = t.year, t.month, t.day, t.hour, t.min, t.sec
end
```
**Prevents**: Data dengan tahun di luar range ±1 tahun akan menggunakan server timestamp.

#### 4. Outlier Filter (Ruby Legacy)
```ruby
# Ruby TCP Server (shell/tcpserver_new.rb)
mm = H.query "SELECT ... FROM station_logs_#{sid} ORDER BY submitted_at DESC LIMIT 5"
if mm.length == 5
    mm = filter_outlier mm  # Filter anomali sebelum agregasi
    r = mm.first
    save_obj = {at: r[:sa], slid: r[:id], sid: sid}
    StationMinute.new(save_obj).save rescue nil
end
```
**Prevents**: Data anomali tidak masuk ke agregasi minutes/hours.

---

### Estimated Data Growth

#### Scenario: 1 Station, Data Every 1 Minute

| Timeframe | station_logs | station_minutes | station_hours |
|-----------|-------------|-----------------|---------------|
| 1 hour    | 60 rows     | 60 rows         | 1 row         |
| 1 day     | 1,440 rows  | 1,440 rows      | 24 rows       |
| 1 week    | 10,080 rows | 10,080 rows     | 168 rows      |
| 1 month   | 43,200 rows | 43,200 rows     | 720 rows      |
| 1 year    | 525,600 rows | 525,600 rows   | 8,760 rows    |

#### Current System: 177 Active Stations

| Timeframe | Total station_logs | Total station_minutes | Total station_hours |
|-----------|-------------------|----------------------|-------------------|
| 1 day     | 254,880 rows      | 254,880 rows         | 4,248 rows        |
| 1 week    | 1,784,160 rows    | 1,784,160 rows       | 29,736 rows       |
| 1 month   | 7,646,400 rows    | 7,646,400 rows       | 127,440 rows      |
| 1 year    | 93,033,600 rows   | 93,033,600 rows      | 1,550,520 rows    |

**Storage Estimate** (PostgreSQL):
- **Raw logs**: ~93 million rows/year
- **Approximate size**: 20-30 GB/year (with indexes)
- **ClickHouse archive**: 5-10 GB/year (compressed)

---

### Database Maintenance Strategy

#### 1. Automatic Archival (Configured in system)

| Data Type | PostgreSQL Retention | Archive to ClickHouse | Action |
|-----------|---------------------|----------------------|--------|
| station_logs | 30 days | After 7 days | Move old data |
| station_minutes | 90 days | After 30 days | Move old data |
| station_hours | 1 year | After 90 days | Move old data |

**Process**:
```bash
# Automatic archival scripts (to be scheduled)
# 1. Move data to ClickHouse
# 2. Delete from PostgreSQL
# 3. VACUUM to reclaim space
```

#### 2. Partition Management

**Drop Old Partitions** (when data archived):
```sql
-- Example: Drop old station logs partition after archival
DROP TABLE IF EXISTS station_logs_110_2025_01 CASCADE;
```

**Benefits**:
- Instant deletion (no VACUUM needed)
- Space reclaimed immediately
- No impact on other partitions

#### 3. Regular Maintenance

**Weekly Tasks**:
```sql
-- Vacuum analyze large tables
VACUUM ANALYZE station_logs;
VACUUM ANALYZE station_minutes;
VACUUM ANALYZE station_hours;
```

**Monthly Tasks**:
```sql
-- Reindex heavily updated tables
REINDEX TABLE stations;
REINDEX TABLE users;
```

---

### Monitoring Data Growth

#### Check Current Database Size
```sql
SELECT 
    pg_size_pretty(pg_database_size('geo')) as database_size;
```

#### Check Table Sizes
```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                   pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE 'station_logs%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;
```

#### Check Row Counts per Station
```sql
SELECT 
    station_id,
    COUNT(*) as total_rows,
    MIN(submitted_at) as first_data,
    MAX(submitted_at) as last_data,
    pg_size_pretty(
        pg_total_relation_size('station_logs_' || station_id)
    ) as partition_size
FROM station_logs
GROUP BY station_id
ORDER BY total_rows DESC
LIMIT 20;
```

#### Check Data Insertion Rate
```sql
-- Rows inserted in last 24 hours
SELECT 
    station_id,
    COUNT(*) as rows_last_24h,
    COUNT(*) / 1440.0 as avg_per_minute
FROM station_logs
WHERE submitted_at > NOW() - INTERVAL '24 hours'
GROUP BY station_id
ORDER BY rows_last_24h DESC;
```

---

### Performance Considerations

#### 1. Write Performance
- **High**: 254,880 inserts/day for 177 stations
- **Peak**: ~3 inserts/second average
- **Partitioning**: Distributes writes across tables
- **Indexes**: Carefully designed to not slow down inserts

#### 2. Query Performance
- **Direct Partition Access**: Much faster than querying base table
- **Clustered Indexes**: Sequential reads are optimized
- **Aggregation Tables**: minutes/hours reduce query load

#### 3. Disk I/O
- **SSD Recommended**: Random writes dari multiple stations
- **WAL Optimization**: Consider separate WAL disk
- **Vacuum**: Regular maintenance prevents bloat

---

## Data Retention & Archival

### Retention Policy

| Data Type | Retention in PostgreSQL | Archive to ClickHouse |
|-----------|------------------------|----------------------|
| station_logs (raw) | 30 days | After 7 days |
| station_minutes | 90 days | After 30 days |
| station_hours | 1 year | After 90 days |
| predictions | 6 months | Not archived |
| user_auths | 1 year | After 6 months |

### Archival Process

1. **ClickHouse Storage**: Old data moved to ClickHouse for analytics
2. **Soft Delete**: Use `is_deleted` flag instead of hard deletes
3. **Partition Dropping**: Old partitions can be dropped independently
4. **Backup**: Regular backups via `do_backup_dataluwes.sh`

---

## Migration & Initialization

### Initial Schema Setup

```bash
# Initialize database
docker exec -i postgres_luwes psql -U geo -d geo < sql/init.sql
```

### Create New Station Tables

```sql
-- Automatically created by triggers, or manually:
SELECT create_station_logs_station(NEW_STATION_ID);
SELECT create_station_minutes_station(NEW_STATION_ID);
SELECT create_station_hours_station(NEW_STATION_ID);
```

---

## Security & Access Control

### User Roles

1. **SuperAdmin**: Full access to all features
2. **Owner**: Access to own organization's stations
3. **Engineer**: View logs and technical data
4. **Guest**: Public stations only

### Authentication

- Email + Password (hashed with bcrypt-compatible)
- Session stored in Redis (database 9, prefix: `session::`)
- Token-based for API access
- OAuth support (Facebook, Google)

### Data Privacy

- `public` flag controls public visibility
- `public_dl` flag controls download permissions
- Soft delete preserves audit trail
- `group_id` enforces organization boundaries

---

## Maintenance Tasks

### Regular Tasks

1. **VACUUM**: Weekly vacuum analyze on large tables
2. **REINDEX**: Monthly reindex on heavily updated tables
3. **Backup**: Daily automated backups
4. **Monitoring**: Check partition counts and sizes
5. **Archive**: Move old data to ClickHouse

### Monitoring Queries

```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

-- Count rows per partition
SELECT 
    'station_logs_' || station_id as partition,
    COUNT(*) as row_count
FROM station_logs
GROUP BY station_id
ORDER BY row_count DESC;

-- Check for missing partitions
SELECT 
    s.id as station_id,
    s.name,
    check_table_exist('station_logs_' || s.id) as has_logs_table,
    check_table_exist('station_minutes_' || s.id) as has_minutes_table,
    check_table_exist('station_hours_' || s.id) as has_hours_table
FROM stations s
WHERE s.is_deleted = FALSE;
```

---

## Troubleshooting

### Common Issues

#### 1. Partition Not Created
**Symptom**: Data not appearing in queries
**Solution**: 
```sql
SELECT create_station_logs_station(STATION_ID);
```

#### 2. Slow Queries
**Symptom**: Queries taking >1 second
**Check**: 
- Use EXPLAIN ANALYZE
- Verify indexes exist
- Check if querying base table instead of partition
**Solution**: Query specific partition directly

#### 3. Duplicate Key Errors
**Symptom**: `uniq_sid_sat` constraint violation
**Cause**: Same station submitting duplicate timestamp
**Solution**: Application-level deduplication or ON CONFLICT DO NOTHING

#### 4. Disk Space Issues
**Symptom**: Disk full warnings
**Solution**: 
- Archive old data to ClickHouse
- Drop old partitions
- Run VACUUM FULL on large tables

---

## Database Statistics

**Last Updated**: January 8, 2026

| Metric | Value |
|--------|-------|
| Total Tables | 531 |
| Core Tables | 5 |
| Base Time-Series Tables | 3 |
| Partitioned Tables | 523 |
| Active Stations | 0 (fresh install) |
| Database Functions | 13 |
| Triggers | 3 (AFTER INSERT) |
| Foreign Keys | Multiple per table |
| Indexes | 5-8 per table |

---


