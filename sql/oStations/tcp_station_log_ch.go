package oStations

import (
	"errors"
	"luwes/sql"
	"time"

	dbsql "database/sql"

	chBuffer "github.com/kokizzu/ch-timed-buffer"

	"github.com/kokizzu/gotro/L"
)

var timedBufferDoInsert16 *chBuffer.TimedBuffer
var timedBufferDoInsert14 *chBuffer.TimedBuffer

func LoadChTimedBuffer() {
	timedBufferDoInsert16 = chBuffer.NewTimedBuffer(sql.CH.DB, 1000, 1*time.Second,
		func(tx *dbsql.Tx) *dbsql.Stmt {
			query := `-- StationLogCh) DoInsert16
	INSERT INTO station_logs
		(created_at, updated_at, station_id, submitted_at, level_sensor, power_voltage, power_current,
		accel_x, accel_y, accel_z, temperature, humidity, barometric_pressure, wind_speed, wind_speed_average, wind_gust, wind_direction, wind_direction_average,
		raindrop, rain_rate, ip_address)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`

			stmt, err := tx.Prepare(query)
			L.IsError(err, `failed to tx.Prepare: `+query)

			return stmt
		},
	)

	timedBufferDoInsert14 = chBuffer.NewTimedBuffer(sql.CH.DB, 1000, 1*time.Second,
		func(tx *dbsql.Tx) *dbsql.Stmt {
			query := `-- StationLogCh) DoInsert14
INSERT INTO station_logs
	(created_at, updated_at, station_id, sequence, submitted_at, level_sensor, power_voltage, power_current,
	accel_x, accel_y, accel_z, temperature, wind_speed, soil_moisture, wind_direction, raindrop, ip_address)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`

			stmt, err := tx.Prepare(query)
			L.IsError(err, `failed to tx.Prepare: `+query)

			return stmt
		},
	)
}

type StationLogCh struct {
	StationLog
}

func (slog *StationLogCh) DoInsert14() error {
	if timedBufferDoInsert14 == nil {
		LoadChTimedBuffer()
	}
	if !timedBufferDoInsert14.Insert([]any{
		time.Now(), time.Now(),
		slog.StationId, slog.Sequence, slog.SubmittedAt, slog.LevelSensor, slog.PowerVoltage, slog.PowerCurrent,
		slog.AccelX, slog.AccelY, slog.AccelZ, slog.Temperature, slog.WindSpeed, slog.SoilMoisture, slog.WindDirection, slog.RainDrop,
		slog.IPAddress,
	}) {
		return errors.New(`(slog *StationLogCh) DoInsert14() - failed to insert station logs`)
	}

	L.Print(`Success:: (slog *StationLogCh) DoInsert14()`)

	return nil
}

func (slog *StationLogCh) DoInsert16() error {
	if timedBufferDoInsert16 == nil {
		LoadChTimedBuffer()
	}

	if !timedBufferDoInsert16.Insert([]any{
		time.Now(), time.Now(),
		slog.StationId, slog.SubmittedAt, slog.LevelSensor, slog.PowerVoltage, slog.PowerCurrent,
		slog.AccelX, slog.AccelY, slog.AccelZ, slog.Temperature, slog.Humidity, slog.BarometricPressure,
		slog.WindSpeed, slog.WindSpeedAverage, slog.WindGust, slog.WindDirection, slog.WindDirectionAverage,
		slog.RainDrop, slog.RainRate, slog.IPAddress,
	}) {
		return errors.New(`(slog *StationLogCh) DoInsert16() - failed to insert station logs`)
	}

	return nil
}
