package oStations

import (
	"database/sql"
	"errors"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/kokizzu/gotro/L"
)

type Station struct {
	DB *sqlx.DB `db:"-" json:"-"`

	Id              int       `db:"id" json:"id"`
	CreatedAt       time.Time `db:"created_at" json:"created_at"`
	UpdatedAt       time.Time `db:"updated_at" json:"updated_at"`
	DeletedAt       time.Time `db:"deleted_at" json:"deleted_at"`
	Name            string    `db:"name" json:"name"`
	Longitude       float64   `db:"long" json:"long"`
	Latitude        float64   `db:"lat" json:"lat"`
	IMEI            string    `db:"imei" json:"imei"`
	Location        string    `db:"location" json:"location"`
	Public          bool      `db:"public" json:"public"`
	History         string    `db:"history" json:"history"`
	HistCount       int       `db:"hist_count" json:"hist_count"`
	GroupID         int       `db:"group_id" json:"group_id"`
	MinFilter       float64   `db:"min_filter" json:"min_filter"`
	MaxFilter       float64   `db:"max_filter" json:"max_filter"`
	UpdatedBy       int       `db:"updated_by" json:"updated_by"`
	DeletedBy       int       `db:"deleted_by" json:"deleted_by"`
	RestoredBy      int       `db:"restored_by" json:"restored_by"`
	CreatedBy       int       `db:"created_by" json:"created_by"`
	UniqueId        string    `db:"unique_id" json:"unique_id"`
	IsDeleted       bool      `db:"is_deleted" json:"is_deleted"`
	Data            any       `db:"data" json:"data"`
	PublicDL        bool      `db:"public_dl" json:"public_dl"`
	LastSubmittedAt time.Time `db:"last_submitted_at" json:"last_submitted_at"`
	LastLevelSensor float64   `db:"last_level_sensor" json:"last_level_sensor"`
}

func NewStationMutator(db *sqlx.DB) *Station {
	return &Station{DB: db}
}

func (s *Station) FindByIMEI() bool {
	query := `-- Station) FindByIMEI
SELECT
	id,
	COALESCE(created_at, '0001-01-01 00:00:00') AS created_at,
	COALESCE(updated_at, '0001-01-01 00:00:00') AS updated_at,
	COALESCE(deleted_at, '0001-01-01 00:00:00') AS deleted_at,
	COALESCE(name, '') AS name,
	COALESCE(long, 0) AS long,
	COALESCE(lat, 0) AS lat,
	COALESCE(imei, '') AS imei,
	COALESCE(location, '') AS location,
	COALESCE(public, false) AS public,
	COALESCE(history, '') AS history,
	COALESCE(hist_count, 0) AS hist_count,
	COALESCE(group_id, 0) AS group_id,
	COALESCE(min_filter, 0) AS min_filter,
	COALESCE(max_filter, 0) AS max_filter,
	COALESCE(updated_by, 0) AS updated_by,
	COALESCE(deleted_by, 0) AS deleted_by,
	COALESCE(restored_by, 0) AS restored_by,
	COALESCE(created_by, 0) AS created_by,
	COALESCE(unique_id, '') AS unique_id,
	COALESCE(is_deleted, false) AS is_deleted,
	COALESCE(data, '{}'::jsonb) AS data,
	COALESCE(public_dl, false) AS public_dl,
	COALESCE(last_submitted_at, '0001-01-01 00:00:00') AS last_submitted_at,
	COALESCE(last_level_sensor, 0) AS last_level_sensor
FROM stations WHERE imei = $1 LIMIT 1`
	err := s.DB.Get(s, query, s.IMEI)

	if errors.Is(err, sql.ErrNoRows) {
		return false
	}

	if err != nil {
		L.LOG.Error(err)
		return false
	}

	return true
}

func (s *Station) FindById() bool {
	query := `-- Station) FindById
SELECT
	id,
	COALESCE(created_at, '0001-01-01 00:00:00') AS created_at,
	COALESCE(updated_at, '0001-01-01 00:00:00') AS updated_at,
	COALESCE(deleted_at, '0001-01-01 00:00:00') AS deleted_at,
	COALESCE(name, '') AS name,
	COALESCE(long, 0) AS long,
	COALESCE(lat, 0) AS lat,
	COALESCE(imei, '') AS imei,
	COALESCE(location, '') AS location,
	COALESCE(public, false) AS public,
	COALESCE(history, '') AS history,
	COALESCE(hist_count, 0) AS hist_count,
	COALESCE(group_id, 0) AS group_id,
	COALESCE(min_filter, 0) AS min_filter,
	COALESCE(max_filter, 0) AS max_filter,
	COALESCE(updated_by, 0) AS updated_by,
	COALESCE(deleted_by, 0) AS deleted_by,
	COALESCE(restored_by, 0) AS restored_by,
	COALESCE(created_by, 0) AS created_by,
	COALESCE(unique_id, '') AS unique_id,
	COALESCE(is_deleted, false) AS is_deleted,
	COALESCE(data, '{}'::jsonb) AS data,
	COALESCE(public_dl, false) AS public_dl,
	COALESCE(last_submitted_at, '0001-01-01 00:00:00') AS last_submitted_at,
	COALESCE(last_level_sensor, 0) AS last_level_sensor
FROM stations WHERE id = $1 LIMIT 1`
	err := s.DB.Get(s, query, s.Id)

	if errors.Is(err, sql.ErrNoRows) {
		return false
	}

	if err != nil {
		L.LOG.Error(err)
		return false
	}

	return true
}

func (s *Station) DoInsert() error {
	query := `-- Station) DoInsert
INSERT INTO stations (created_at, updated_at, name, imei, last_submitted_at, last_level_sensor, long, lat, group_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING id, created_at, updated_at, name, imei, last_submitted_at, last_level_sensor, long, lat, group_id`

	if err := s.DB.QueryRowx(query,
		time.Now(), time.Now(),
		s.Name, s.IMEI, s.LastSubmittedAt, s.LastLevelSensor,
		s.Longitude, s.Latitude, s.GroupID,
	).StructScan(s); err != nil {
		return err
	}

	return nil
}

func (s *Station) DoUpdateMetricById() error {
	query := `-- Station) DoUpdateMetricById
UPDATE stations SET
updated_at = $1, last_submitted_at = GREATEST($2,last_submitted_at), 
last_level_sensor = (CASE WHEN $2 > last_submitted_at THEN $3 ELSE last_level_sensor END)
WHERE id = $4`

	if _, err := s.DB.Exec(query,
		time.Now(), s.LastSubmittedAt, s.LastLevelSensor, s.Id,
	); err != nil {
		return err
	}

	return nil
}
