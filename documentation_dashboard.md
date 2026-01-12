# Luwes Water Sensor - Technical Documentation (Dashboard & Web App)

## Deskripsi Sistem

Luwes Water Sensor adalah sistem monitoring tingkat air real-time untuk sungai, laut, dan bendungan di seluruh Indonesia. Dokumentasi ini berfokus pada arsitektur **Web Dashboard**, **Backend Application**, dan **Frontend**.

**Deployment Date**: January 8, 2026  
**Server URL**: http://localhost:3001 (Development)

---

## Stack Teknologi

### Backend Technologies (Web Application)

#### 1. **Go (Golang)**
- **Versi**: 1.25.5
- **Toolchain**: go1.24.2
- **Fungsi**: Bahasa pemrograman utama untuk server backend
- **Penggunaan**: 
  - HTTP Web Server (port 3001)
  - REST API handling
  - Business Logic & Database Interaction
- **Framework/Library Utama**:
  - `gorilla/mux` v1.8.0 - HTTP router
  - `kokizzu/gotro` v1.4501.2212 - Framework utilitas (Strings, Maps, Validation)
  - `goccy/go-json` v0.10.3 - High-perf JSON processing

#### 2. **NATS (Internal Messaging)**
- **Versi**: v2.12.3
- **Fungsi**: Message broker untuk komunikasi internal antar service
- **Penggunaan**: 
  - Menghubungkan Backend (Web) dengan service lain
  - Broadcasting notifikasi realtime

---

### Database Technologies

#### 1. **PostgreSQL** (Core Relational DB)
- **Versi**: 16.10
- **Fungsi**: Penyimpanan data utama (User, Station, Configuration, Recent Logs)
- **Library Client**: `jmoiron/sqlx` v1.4.0
- **Penggunaan Utama**:
  - Authentication (Users, Sessions)
  - Station Metadata & Configuration
  - Data Predictions & Anomalies
  - Recent Time-series Data (`station_hours_XXX`)

#### 2. **ClickHouse** (Analytics DB)
- **Versi**: 23.11.2.11
- **Fungsi**: Analitik Big Data & Long-term History
- **Library Client**: `ClickHouse/clickhouse-go/v2`
- **Fitur Kunci**: 
  - Columnar Storage untuk aggregate query super cepat
  - Kompresi LZ4 untuk efisiensi hard disk
  - Digunakan untuk query "All Time" atau rentang waktu > 1 tahun

#### 3. **Redis** (Cache & Session)
- **Versi**: 8.2.2
- **Fungsi**: In-memory Key-Value
- **Penggunaan**:
  - **Session Management**: DB 9, Prefix `session::`
  - **Caching**: Menyimpan hasil query berat sementara
  - **Rate Limiting**: Throttling request per IP

#### 4. **Tarantool** (High-Speed In-Memory)
- **Fungsi**: Caching & Real-time State
- **Penggunaan**: Menyimpan snapshot state terakhir stasiun untuk akses instan (<1ms)

---

### Frontend Technologies

#### 1. **Svelte Framework**
- **Architecture**: Component-based SPA (Single Page Application)
- **Compiler**: No Virtual DOM (Compile to Vanilla JS)
- **Struktur Halaman**:
  - **Guest**: Public Map, Station List, Charts
  - **Owner**: Dashboard Monitoring Pribadi
  - **SuperAdmin**: Manajemen User, Group, & Konfigurasi Sistem

#### 2. **Visualization Libraries**
- **ApexCharts** (v3.45.0): Rendering grafik time-series (Water Level, Rainfall) yang interaktif.
- **MapLibre GL** (v3.6.2): Peta interaktif (GIS) untuk visualisasi lokasi stasiun, clustering, dan status.

#### 3. **Build System**
- **Bundler**: `esbuild` (Super cepat)
- **Structure**: `views/` directory berisi file `.svelte` yang dikompilasi ke `public/js/`.

---

## Arsitektur Sistem (Web & Dashboard)

### Server Components Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Luwes Web Server (Port 3001)             │
│                 (Gorilla Mux + Go Handlers)                 │
├─────────┬───────────────────┬───────────────────┬───────────┤
│ Auth    │   Guest View      │   Owner View      │ Admin API │
└─────────┴───────────────────┴───────────────────┴───────────┘
     │              │                   │               │
     ▼              ▼                   ▼               ▼
┌─────────┐   ┌────────────┐      ┌────────────┐  ┌───────────┐
│  Redis  │   │ Tarantool  │      │ PostgreSQL │  │ ClickHouse│
│ Session │   │ Fast Cache │      │  Core DB   │  │ Analytics │
└─────────┘   └────────────┘      └────────────┘  └───────────┘
```

### Data Flow (Web Request)

1.  **Client Request**: Browser meminta halaman/API ke Port 3001.
2.  **Routing & Auth**: 
    *   `AuthFilter` mengecek Session di **Redis**.
    *   Jika valid, request diteruskan ke Handler yang sesuai (misal: `hGuest`, `hOwner`).
3.  **Data Retrieval**:
    *   **Hot Data** (Status Terkini): Diambil dari **Tarantool** atau **Redis**.
    *   **Transactional Data** (User, Config): Diambil dari **PostgreSQL**.
    *   **Historical Data** (Grafik 1 Bulan+): Diambil dari **ClickHouse**.
4.  **Response**: Server mengirim balik JSON (untuk API) atau HTML (untuk Page Render).

---

## Database Schema Overview

### PostgreSQL Tables Focus

*   **Core Entities**:
    *   `users`: Akun login & credential.
    *   `groups`: Organisasi pemilik stasiun.
    *   `stations`: Metadata stasiun (Lokasi, Nama, Tipe).
*   **Operational**:
    *   `predictions`: Hasil prediksi API EXTERNAL untuk level air.
    *   `anomalies`: Log deteksi anomali data.
*   **Time-Series**:
    *   `station_logs_XXX`: Raw data (dipartisi).
    *   `station_hours_XXX`: Agregasi per jam.

---

## Build & Deployment (Web App)

### Backend Build
```bash
go build -o luwes-server *.go
```

### Frontend Build
```bash
cd views
npm install
npm run build  # Mengompilasi Svelte ke JS bundle di /public
```

### Running
```bash
./luwes-server
# Web UI tersedia di http://localhost:3001
```

---

## Monitoring & Security

### Security Features
*   **Session Management**: Redis-backed session dengan isolasi prefix.
*   **Role-Based Access**: Logic pemisahan Guest, Owner, dan SuperAdmin di level Handler.
*   **Input Validation**: Sanitasi input pada Go request struct.

### Performance
*   **Connection Pooling**: Database connection pool (pgx/sqlx) untuk menahan beban tinggi.
*   **GZIP Compression**: Aset statis dan API response dikompresi.
*   **In-Memory Caching**: Penggunaan agresif Tarantool/Redis untuk data yang sering diakses (status stasiun).

---

## Project Structure

```
luwes-master/
├── go.mod                   # Dependencies
├── webserver.go             # Entry point HTTP Server
├── router.go                # Route definitions
├── handler/                 # Controllers / Business Logic
│   ├── hGuest/              # Public facing features (Map, List)
│   ├── hOwner/              # Private dashboard features
│   ├── hSuperAdmin/         # Administration features
│   └── hEngineer/           # System logs view
├── views/                   # Svelte Source Code
│   ├── guest/               # Public Components
│   └── ...
├── public/                  # Compiled Assets (JS/CSS)
├── sql/                     # Database Models (ORM-like wrappers)
│   ├── oStations/           # Station Logic
│   ├── oUsers/              # User Logic
│   └── ...
```
