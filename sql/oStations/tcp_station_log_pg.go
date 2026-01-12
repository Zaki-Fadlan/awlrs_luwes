package oStations

import (
	gosql "database/sql"
	"errors"
	"fmt"
	"time"

	"luwes/sql"

	"github.com/jmoiron/sqlx"
	"github.com/kokizzu/gotro/L"
)

type StationLogPg struct {
	DB *sqlx.DB `db:"-" json:"-"`
	StationLog
}

func NewStationLogPq(db *sqlx.DB) *StationLogPg {
	return &StationLogPg{DB: db}
}

func (slog *StationLogPg) FindById() bool {
	query := `-- StationLogPg) FindById
SELECT id FROM station_logs WHERE id = $1`
	err := slog.DB.Get(slog, query, slog.Id)
	if err != nil {
		if errors.Is(err, gosql.ErrNoRows) {
			return false
		}
		L.LOG.Error(err)
		return false
	}
	return true
}

func (slog *StationLogPg) DoInsert() error {
	query := `-- StationLogPg) DoInsert
INSERT INTO station_logs
(
	created_at, updated_at, submitted_at, sequence, level_sensor, 
	accel_x, accel_y, accel_z, power_current, ip_address, log_type, station_id, power_voltage, data, is_deleted,
	temperature, wind_speed, soil_moisture, wind_direction, raindrop, humidity, barometric_pressure, wind_speed_average, wind_gust, wind_direction_average, rain_rate
)
VALUES (
	:created_at, :updated_at, :submitted_at, :sequence, :level_sensor, 
	:accel_x, :accel_y, :accel_z, :power_current, :ip_address, :log_type, :station_id, :power_voltage, :data, :is_deleted,
	:temperature, :wind_speed, :soil_moisture, :wind_direction, :raindrop, :humidity, :barometric_pressure, :wind_speed_average, :wind_gust, :wind_direction_average, :rain_rate
)
ON CONFLICT ON CONSTRAINT uniq_sid_sat DO NOTHING`

	_, err := slog.DB.NamedExec(query, slog)
	if err != nil {
		L.LOG.Error(err)
		return err
	}

	L.Print(`Success:: (slog *StationLogPg) DoInsert()`)

	return nil
}

func (slog *StationLogPg) DoUpdateById() error {
	query := `-- StationLogPg) DoUpdateById
UPDATE station_logs
	SET updated_at = :updated_at, submitted_at = :submitted_at, sequence = :sequence, level_sensor = :level_sensor,
	accel_x = :accel_x, accel_y = :accel_y, accel_z = :accel_z, power_current = :power_current, ip_address = :ip_address,
	log_type = :log_type, station_id = :station_id, power_voltage = :power_voltage, data = :data, is_deleted = :is_deleted,
	temperature = :temperature, wind_speed = :wind_speed, soil_moisture = :soil_moisture, wind_direction = :wind_direction, raindrop = :raindrop
WHERE id = :id`

	_, err := slog.DB.NamedExec(query, slog)
	if err != nil {
		L.LOG.Error(err)
		return err
	}

	return nil
}

// insert to DB from protocol 14 data
func (slog *StationLogPg) DoInsert14() error {
	query := func(table string, id int) string {
		uniqSidSat := `uniq_sid_sat`
		if id != 0 {
			uniqSidSat += fmt.Sprintf("_%d", id)
		}
		qstr := `-- StationLogPg) DoInsert14
INSERT INTO ` + table + `
(created_at, updated_at, station_id, sequence, submitted_at, level_sensor, power_voltage, power_current,
accel_x, accel_y, accel_z, temperature, wind_speed, soil_moisture, wind_direction, raindrop, ip_address)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
ON CONFLICT ON CONSTRAINT ` + uniqSidSat + ` DO NOTHING`
		//L.Print(qstr)
		return qstr
	}
	err := slog.DB.QueryRowx(query("station_logs", 0)+`
RETURNING id, station_id`,
		time.Now(), time.Now(),
		slog.StationId, slog.Sequence, slog.SubmittedAt, slog.LevelSensor, slog.PowerVoltage, slog.PowerCurrent,
		slog.AccelX, slog.AccelY, slog.AccelZ, slog.Temperature, slog.WindSpeed, slog.SoilMoisture, slog.WindDirection, slog.RainDrop,
		slog.IPAddress,
	).StructScan(&slog.StationLog)
	if errors.Is(err, gosql.ErrNoRows) {
		return nil
	}
	if err != nil {
		L.IsError(err, `failed to insert station logs: `+query("station_logs", 0))

		return err
	}

	tableSlogID := fmt.Sprintf("station_logs_%d", slog.StationId)
	if sql.PG.TableExists(tableSlogID) {
		if _, err := slog.DB.Exec(query(tableSlogID, slog.StationId),
			time.Now(), time.Now(),
			slog.StationId, slog.Sequence, slog.SubmittedAt, slog.LevelSensor, slog.PowerVoltage, slog.PowerCurrent,
			slog.AccelX, slog.AccelY, slog.AccelZ, slog.Temperature, slog.WindSpeed, slog.SoilMoisture, slog.WindDirection, slog.RainDrop,
			slog.IPAddress,
		); err != nil {
			return err
		}
	}

	//L.Print(`Success:: (slog *StationLogPg) DoInsert14()`)

	return nil
}

// insert to DB from protocol 16 data
func (slog *StationLogPg) DoInsert16() error {
	query := func(table string, id int) string {
		uniqSidSat := `uniq_sid_sat`
		if id != 0 {
			uniqSidSat += fmt.Sprintf("_%d", id)
		}
		return `-- StationLogPg) DoInsert16
INSERT INTO ` + table + `
(created_at, updated_at, station_id, submitted_at, level_sensor, power_voltage, power_current,
accel_x, accel_y, accel_z, temperature, humidity, barometric_pressure, wind_speed, wind_speed_average, wind_gust, wind_direction, wind_direction_average,
raindrop, rain_rate, ip_address)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
ON CONFLICT ON CONSTRAINT ` + uniqSidSat + ` DO NOTHING`
	}

	if err := slog.DB.QueryRowx(query("station_logs", 0)+`
RETURNING id, station_id`,
		time.Now(), time.Now(),
		slog.StationId, slog.SubmittedAt, slog.LevelSensor, slog.PowerVoltage, slog.PowerCurrent,
		slog.AccelX, slog.AccelY, slog.AccelZ, slog.Temperature, slog.Humidity, slog.BarometricPressure,
		slog.WindSpeed, slog.WindSpeedAverage, slog.WindGust, slog.WindDirection, slog.WindDirectionAverage,
		slog.RainDrop, slog.RainRate, slog.IPAddress,
	).StructScan(&slog.StationLog); err != nil {
		return err
	}

	tableSlogID := fmt.Sprintf("station_logs_%d", slog.StationId)
	if sql.PG.TableExists(tableSlogID) {
		if _, err := slog.DB.Exec(query(tableSlogID, slog.Id+1),
			time.Now(), time.Now(),
			slog.StationId, slog.SubmittedAt, slog.LevelSensor, slog.PowerVoltage, slog.PowerCurrent,
			slog.AccelX, slog.AccelY, slog.AccelZ, slog.Temperature, slog.Humidity, slog.BarometricPressure,
			slog.WindSpeed, slog.WindSpeedAverage, slog.WindGust, slog.WindDirection, slog.WindDirectionAverage,
			slog.RainDrop, slog.RainRate, slog.IPAddress,
		); err != nil {
			return err
		}
	}

	L.Print(`Success:: (slog *StationLogPg) DoInsert16()`)

	return nil
}

func (slog *StationLogPg) FindMinuteHour(staId int) error {
	query := fmt.Sprintf("SELECT id, submitted_at FROM station_logs_%d ORDER BY submitted_at DESC LIMIT 1;", staId)
	err := slog.DB.Get(slog, query)
	if err != nil {
		return err
	}

	return nil
}

func (slog *StationLogPg) FindLogsByStationIdWithOffsetWithLimit(staId int64, offset, limit int, callback func(rows *gosql.Rows) error) error {
	query := `-- StationLogPg) FindLogsByStationIdWithOffsetWithLimit
SELECT
	id,
	COALESCE(created_at, '0001-01-01 00:00:00') AS created_at,
	COALESCE(updated_at, '0001-01-01 00:00:00') AS updated_at,
	COALESCE(deleted_at, '0001-01-01 00:00:00') AS deleted_at,
	COALESCE(submitted_at, '0001-01-01 00:00:00') AS submitted_at,
	COALESCE(sequence, 0) AS sequence,
	COALESCE(level_sensor, 0) AS level_sensor,
	COALESCE(accel_x, 0) AS accel_x,
	COALESCE(accel_y, 0) AS accel_y,
	COALESCE(accel_z, 0) AS accel_z,
	COALESCE(power_current, 0) AS power_current,
	COALESCE(ip_address, '') AS ip_address,
	COALESCE(log_type, 0) AS log_type,
	COALESCE(station_id, 0) AS station_id,
	COALESCE(power_voltage, 0) AS power_voltage,
	COALESCE(data, '{}'::jsonb) AS data,
	COALESCE(is_deleted, false) AS is_deleted,
	COALESCE(temperature, 0) AS temperature,
	COALESCE(wind_speed, 0) AS wind_speed,
	COALESCE(soil_moisture, 0) AS soil_moisture,
	COALESCE(wind_direction, 0) AS wind_direction,
	COALESCE(raindrop, 0) AS raindrop,
	COALESCE(humidity, 0) AS humidity,
	COALESCE(barometric_pressure, 0) AS barometric_pressure,
	COALESCE(wind_speed_average, 0) AS wind_speed_average,
	COALESCE(wind_gust, 0) AS wind_gust,
	COALESCE(wind_direction_average, 0) AS wind_direction_average,
	COALESCE(rain_rate, 0) AS rain_rate
FROM station_logs
WHERE station_id = $1
ORDER BY submitted_at ASC
LIMIT $2 OFFSET $3;`

	rows, err := sql.PG.Adapter.Query(query, staId, limit, offset)
	if err != nil {
		return err
	}
	defer rows.Close()

	err = callback(rows)

	return err
}

func (slog *StationLogPg) CountTotalLogsByStationId(staId int) (int, error) {
	var count int
	query := `StationLogPg) CountTotalLogsByStationId
SELECT COUNT(1) FROM station_logs WHERE station_id = $1`
	err := sql.PG.Adapter.Get(&count, query, staId)

	return count, err
}
