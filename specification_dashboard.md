# System Specification & Design - Luwes Water Sensor

**Version**: 1.0.0  
**Date**: January 8, 2026  
---

## Component Specifications

### Web Server (Port 3001)

**Technology**: 
- Gorilla Mux v1.8.0 (HTTP Router)
- kokizzu/gotro v1.4501.2212 (Framework)

**Responsibilities**:
- Serve frontend assets
- REST API endpoints
- Session management
- Authentication & Authorization
- Business logic orchestration

**Routes** (from `router.go`):

```go
// Public Routes
"" → Home page
"guest/public_map" → Public station map
"guest/public_stations" → Public station list
"guest/public_station/:sta_id" → Station detail
"guest/download_log/:sta_id/:option/:format/:dl_opt/:tz" → Download data

// Authentication
"login" → Login page
"login/forgot" → Password reset
"login/verify/:from" → Email verification
"logout" → Logout

// Owner Routes (Authenticated)
"owner/private_map" → Private station map
"owner/private_stations" → Owners stations
"owner/multi_stations" → Multi-station view
"owner/station_info/:sta_id" → Station configuration

// Engineer Routes
"engineer/log" → System logs
"engineer/log_info/:sta_id" → Station logs

// SuperAdmin Routes
"superadmin/users" → User management
"superadmin/groups" → Group management
"superadmin/stations" → Station management
"superadmin/set_predictions/:sta_id" → Prediction settings
"superadmin/anomalies" → Anomaly detection
"superadmin/import" → Data import
"superadmin/migrate" → Database migration
```

**Code Location**: `webserver.go`, `router.go`, `handler/`

---

### 5. Database Layer

#### PostgreSQL (Port 5433)

**Purpose**: Primary transactional database

**Tables**:
- `users`, `groups`, `user_auths` - User management
- `stations` - Station metadata
- `station_logs_{id}` - Raw sensor data (partitioned)
- `station_minutes_{id}` - Minute aggregations (partitioned)
- `station_hours_{id}` - Hour aggregations (partitioned)
- `predictions` - Water level predictions

**Features**:
- Partitioning by station_id
- Automatic partition creation via triggers
- Foreign key constraints
- JSONB for extensibility

**Connection**:
```go
// sql/config.go
opt := `host=127.0.0.1 port=5433 user=geo password=geopass dbname=geo sslmode=disable`
conn := sqlx.MustConnect(`postgres`, opt)
```

#### Redis (Port 6380)

**Purpose**: Session management & caching

**Usage**:
- Session storage (DB 9, prefix: `session::`)
- Query result caching
- Rate limiting counters
- Temporary data

**Connection**:
```go
// webserver.go
redis_conn := Rd.NewRedisSession(`127.0.0.1:6380`, ``, 9, `session::`)
```

## Data Flow

```
┌──────────────┐
│   Browser    │
└──────┬───────┘
       │
       ├──► HTTP GET /guest/public_stations
       │    └──► Auth Filter (check session)
       │         └──► Handler: hGuest.PublicStations
       │              └──► Query: stations WHERE public=true
       │                   └──► Join: groups, last data
       │                        └──► Response: JSON
       │
       ├──► HTTP GET /guest/public_station/:sta_id
       │    └──► Handler: hGuest.PublicStation
       │         └──► Query: station_logs_{sta_id}
       │              ├──► Filter: date range, option (1d/1w/1m/1y)
       │              ├──► Source: PostgreSQL (recent) or ClickHouse (old)
       │              └──► Response: JSON time-series data
       │
       ├──► HTTP POST /login
       │    └──► Handler: pLogin.API_All_Login
       │         └──► Validate: email + password
       │              └──► Create session in Redis
       │                   └──► Response: session token
       │
       └──► HTTP GET /owner/private_stations
            └──► Auth Filter (require login)
                 └──► Handler: hOwner.PrivateStations
                      └──► Query: stations WHERE group_id = user.group_id
                           └──► Response: JSON
```

**Current Implementation**: Polling via AJAX

```javascript
// Frontend polling (current)
setInterval(() => {
  fetch('/api/station/123/latest')
    .then(res => res.json())
    .then(data => updateChart(data))
}, 60000) // Every 60 seconds
```

---

## API Specifications

### Authentication APIs

#### 1. POST `/login`

**Purpose**: User login

**Request**:
```json
{
  "email": "user@example.com",
  "password": "hashed_password"
}
```

**Response** (Success):
```json
{
  "success": true,
  "user_id": 123,
  "session_id": "session_token_here",
  "role": "owner"
}
```

**Response** (Error):
```json
{
  "success": false,
  "errors": ["Invalid email or password"]
}
```

**Code**: `sql/pLogin/login.go`

---

#### 2. POST `/logout`

**Purpose**: User logout

**Request**: None (uses session)

**Response**:
```json
{
  "success": true
}
```

---

### Station Data APIs

#### 3. GET `/guest/public_stations`

**Purpose**: Get list of public stations

**Query Parameters**:
- `page` (optional): Page number
- `limit` (optional): Items per page
- `search` (optional): Search by name/location

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 110,
      "name": "Station Manado",
      "location": "Manado, Sulawesi Utara",
      "lat": 1.4748,
      "long": 124.8421,
      "last_submitted_at": "2026-01-08T15:30:00Z",
      "last_level_sensor": 1.234,
      "group_name": "BMKG"
    }
  ],
  "total": 177,
  "page": 1,
  "limit": 20
}
```

**Code**: `handler/hGuest/guest.go`

---

#### 4. GET `/guest/public_station/:sta_id`

**Purpose**: Get station detail with time-series data

**Path Parameters**:
- `sta_id`: Station ID

**Query Parameters**:
- `option`: Time range (`1d`, `1w`, `1m`, `3m`, `6m`, `1y`, `all`)
- `last_mod`: Last modification timestamp (for delta updates)
- `max_date`: Maximum date timestamp
- `level_only`: Return only level sensor data (`true`/`false`)
- `tz`: Timezone offset GMT (e.g., `7` for GMT+7)

**Response**:
```json
{
  "success": true,
  "station": {
    "id": 110,
    "name": "Station Manado",
    "location": "Manado, Sulawesi Utara",
    "lat": 1.4748,
    "long": 124.8421
  },
  "data": [
    {
      "submitted_at": 1736343000,
      "level_sensor": 1.234,
      "temperature": 28.5,
      "humidity": 65,
      "wind_speed": 3.2,
      "accel_x": 0.01,
      "accel_y": 0.02,
      "accel_z": 0.98
    }
  ],
  "count": 1440
}
```

**Data Source Logic**:
```go
// If recent data (< 30 days): PostgreSQL
// If old data (> 30 days): ClickHouse
// If DOUBLE_WRITE_DB enabled: Query both and merge
```

**Code**: `handler/hGuest/guest.go`, `sql/oStations/station.go`

---

#### 5. GET `/guest/download_log/:sta_id/:option/:format/:dl_opt/:tz`

**Purpose**: Download station data in various formats

**Path Parameters**:
- `sta_id`: Station ID
- `option`: Time range (`1d`, `1w`, `1m`, `1y`)
- `format`: Output format (`csv`, `xlsx`, `json`)
- `dl_opt`: Download option (`all`, `level_only`)
- `tz`: Timezone GMT offset

**Response**: File download (CSV/XLSX/JSON)

**CSV Format**:
```csv
Timestamp,Level(m),Temperature(°C),Humidity(%),Wind Speed(m/s)
2026-01-08 15:30:00,1.234,28.5,65,3.2
2026-01-08 15:31:00,1.235,28.6,64,3.3
```

**XLSX Format**: Same as CSV but in Excel format

**JSON Format**: Same as API response

**Code**: `handler/hGuest/guest.go`

---

#### 6. GET `/owner/private_stations`

**Purpose**: Get owner's private stations

**Authentication**: Required (session)

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 250,
      "name": "Private Station A",
      "location": "Jakarta",
      "lat": -6.2088,
      "long": 106.8456,
      "last_submitted_at": "2026-01-08T15:30:00Z",
      "last_level_sensor": 2.345,
      "public": false,
      "public_dl": false
    }
  ]
}
```

**Code**: `handler/hOwner/owner.go`

---

#### 7. GET `/owner/multi_stations`

**Purpose**: Compare multiple stations in one view

**Authentication**: Required

**Query Parameters**:
- `station_ids[]`: Array of station IDs

**Response**:
```json
{
  "success": true,
  "stations": [
    {
      "id": 110,
      "name": "Station A",
      "data": [...]
    },
    {
      "id": 167,
      "name": "Station B",
      "data": [...]
    }
  ]
}
```

**Code**: `handler/hOwner/owner.go`

---

### Admin APIs

#### 8. POST `/superadmin/stations`

**Purpose**: Create/Update/Delete stations

**Authentication**: SuperAdmin role required

**Request** (Create):
```json
{
  "action": "create",
  "name": "New Station",
  "imei": "123456789012345",
  "location": "Location Name",
  "lat": -6.2088,
  "long": 106.8456,
  "group_id": 1,
  "public": true,
  "public_dl": false
}
```

**Response**:
```json
{
  "success": true,
  "station_id": 500
}
```

**Code**: `handler/hSuperAdmin/superadmin.go`

---

#### 9. POST `/superadmin/set_predictions/:sta_id`

**Purpose**: Set water level predictions for alerts

**Authentication**: SuperAdmin required

**Request**:
```json
{
  "predictions": [
    {
      "predict_epoch": 1736350000,
      "level": 2.5
    },
    {
      "predict_epoch": 1736353600,
      "level": 2.8
    }
  ]
}
```

**Response**:
```json
{
  "success": true,
  "inserted": 2
}
```

**Code**: `handler/hSuperAdmin/superadmin.go`

---

## Real-time Communication

### Current Implementation: AJAX Polling

**Frontend Pattern**:
```javascript
// views/guest/public_station_chart.svelte
let intervalId;

onMount(() => {
  // Initial load
  loadStationData();
  
  // Poll every 60 seconds
  intervalId = setInterval(() => {
    loadStationData();
  }, 60000);
});

onDestroy(() => {
  clearInterval(intervalId);
});

async function loadStationData() {
  const response = await axios.get(`/guest/public_station/${stationId}`, {
    params: {
      option: '1d',
      last_mod: lastModified, // Delta update
      tz: 7
    }
  });
  
  if (response.data.success) {
    updateChart(response.data.data);
  }
}
```

---

## Frontend Integration

### Technology Stack

- **Framework**: Svelte (compiled to vanilla JS)
- **Bundler**: esbuild v0.16.17
- **Maps**: MapLibre GL v3.6.2
- **Charts**: ApexCharts v3.45.0
- **HTTP**: Axios v1.6.2
- **Icons**: svelte-icons-pack v2.1.0
- **Date Picker**: date-picker-svelte v2.10.1

### Page Structure

```
views/
├── home.svelte                     # Landing page
├── login/
│   ├── index.svelte               # Login form
│   ├── forgot.svelte              # Password reset
│   └── reset.svelte               # Reset password
├── guest/
│   ├── public_map.svelte          # Map with all public stations
│   ├── public_stations.svelte     # Station list
│   ├── public_station_chart.svelte # Station detail with chart
│   └── public_station_list.svelte # Table view
├── owner/
│   ├── private_map.svelte         # Owner's station map
│   ├── private_stations.svelte    # Owner's stations
│   ├── multi_stations.svelte      # Compare multiple stations
│   └── station_info.svelte        # Edit station config
├── engineer/
│   ├── log.svelte                 # System logs
│   └── log_info.svelte            # Station-specific logs
└── superadmin/
    ├── users.svelte               # User management
    ├── groups.svelte              # Group management
    ├── stations.svelte            # Station management
    ├── set_predictions.svelte     # Set predictions
    ├── anomalies.svelte           # Anomaly detection
    ├── import.svelte              # Data import
    └── migrate.svelte             # Database migration
```

### Data Fetching Pattern

#### 1. Initial Load
```javascript
<script>
import axios from 'axios'
import { onMount } from 'svelte'

let stations = []
let loading = true

onMount(async () => {
  try {
    const response = await axios.get('/guest/public_stations')
    if (response.data.success) {
      stations = response.data.data
    }
  } catch (error) {
    console.error('Failed to load stations:', error)
  } finally {
    loading = false
  }
})
</script>

{#if loading}
  <div>Loading...</div>
{:else}
  {#each stations as station}
    <div>{station.name}</div>
  {/each}
{/if}
```

#### 2. Periodic Refresh (Current Pattern)
```javascript
let refreshInterval = 60000 // 60 seconds
let intervalId

onMount(() => {
  loadData()
  intervalId = setInterval(loadData, refreshInterval)
})

onDestroy(() => {
  clearInterval(intervalId)
})

async function loadData() {
  // Fetch latest data
  const response = await axios.get('/api/station/123/latest')
  // Update UI
}
```

#### 3. Real-time Updates (Future Pattern)
```javascript
import { onMount, onDestroy } from 'svelte'

let eventSource

onMount(() => {
  // Connect to SSE
  eventSource = new EventSource('/api/stream/station/123')
  
  eventSource.onmessage = (event) => {
    const newData = JSON.parse(event.data)
    updateChart(newData)
  }
  
  eventSource.onerror = (error) => {
    console.error('SSE error:', error)
  }
})

onDestroy(() => {
  if (eventSource) {
    eventSource.close()
  }
})
```

---

### Chart Integration

**ApexCharts Usage**:
```javascript
<script>
import ApexCharts from 'apexcharts'

let chart
let chartData = []

onMount(() => {
  const options = {
    chart: {
      type: 'line',
      height: 350
    },
    series: [{
      name: 'Water Level',
      data: chartData
    }],
    xaxis: {
      type: 'datetime'
    },
    yaxis: {
      title: {
        text: 'Level (meters)'
      }
    }
  }
  
  chart = new ApexCharts(document.querySelector("#chart"), options)
  chart.render()
})

function updateChart(newData) {
  chart.updateSeries([{
    data: newData.map(d => ({
      x: d.submitted_at * 1000,
      y: d.level_sensor
    }))
  }])
}
</script>

<div id="chart"></div>
```

---

### Map Integration

**MapLibre GL Usage**:
```javascript
<script>
import maplibregl from 'maplibre-gl'
import { SvelteMapLibre } from 'svelte-maplibre'

let map
let markers = []

onMount(() => {
  stations.forEach(station => {
    const marker = new maplibregl.Marker()
      .setLngLat([station.long, station.lat])
      .setPopup(new maplibregl.Popup().setHTML(`
        <h3>${station.name}</h3>
        <p>Level: ${station.last_level_sensor}m</p>
      `))
      .addTo(map)
    
    markers.push(marker)
  })
})
</script>

<SvelteMapLibre
  bind:map
  center={[106.8456, -6.2088]}
  zoom={5}
  style="https://tiles.example.com/style.json"
/>
```

---

## Authentication & Authorization

### Session Management

**Storage**: Redis (Database 9)

**Session Data**:
```go
type Session struct {
    UserID    int64
    Email     string
    Role      string  // "guest", "owner", "engineer", "superadmin"
    GroupID   int64
    ExpireAt  time.Time
}
```

**Session Key Format**:
```
session::{session_id}
```

**Session Flow**:
```
1. User submits login form
2. Backend validates credentials
3. Create session in Redis (7 days TTL)
4. Return session cookie to browser
5. Browser includes cookie in subsequent requests
6. Backend validates session before each request
```

---

### Role-Based Access Control (RBAC)

**Roles**:

| Role | Access |
|------|--------|
| **Guest** | - View public stations<br>- Download public data<br>- No authentication required |
| **Owner** | - All guest permissions<br>- View own stations (private)<br>- Download own data<br>- View station configuration |
| **Engineer** | - All owner permissions<br>- View system logs<br>- View technical data |
| **SuperAdmin** | - All permissions<br>- User management<br>- Station management<br>- System configuration<br>- Data import/export |

**Implementation**:
```go
// webserver.go
func AuthFilter(ctx *W.Context) {
    userID := ctx.Session.GetInt(`user_id`)
    
    if userID > 0 {
        // Logged in - load user data
        role := ctx.Session.GetStr(`role`)
        ctx.Set(`role`, role)
    }
    
    ctx.Session.Touch() // Extend session
    ctx.Next()(ctx)
}
```

**Route Protection**:
```go
// Example: SuperAdmin only route
func (ctx *W.Context) {
    role := ctx.GetStr(`role`)
    if role != `superadmin` {
        ctx.Error(403, `Forbidden`)
        return
    }
    
    // Proceed with handler
}
```

---

## API Reference Summary

### Public Endpoints (No Auth Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Home page |
| GET | `/guest/public_stations` | List public stations |
| GET | `/guest/public_station/:id` | Station detail + data |
| GET | `/guest/public_map` | Map view |
| GET | `/guest/download_log/:id/:opt/:fmt/:dl/:tz` | Download data |
| POST | `/login` | User login |
| POST | `/login/forgot` | Password reset |

### Authenticated Endpoints

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| GET | `/owner/private_stations` | Owner | Owner's stations |
| GET | `/owner/multi_stations` | Owner | Compare stations |
| GET | `/owner/station_info/:id` | Owner | Station config |
| GET | `/engineer/log` | Engineer | System logs |
| POST | `/superadmin/users` | Admin | User management |
| POST | `/superadmin/stations` | Admin | Station management |
| POST | `/superadmin/set_predictions/:id` | Admin | Set predictions |

---

## Documentation References

- **[Database Schema](database.md)**: Complete database structure
- **[Documentation](documentation_dashboard.md)**: Overview and guides

---

**Version**: 1.0.0  
**Last Updated**: January 8, 2026  

