package oStations

import "time"

const TableStationLog = `station_logs`

type StationLog struct {
	Id                   int       `db:"id" json:"id"`
	CreatedAt            time.Time `db:"created_at" json:"created_at"`
	UpdatedAt            time.Time `db:"updated_at" json:"updated_at"`
	DeletedAt            time.Time `db:"deleted_at" json:"deleted_at"`
	SubmittedAt          time.Time `db:"submitted_at" json:"submitted_at"`
	Sequence             int       `db:"sequence" json:"sequence"`
	LevelSensor          float64   `db:"level_sensor" json:"level_sensor"`
	AccelX               float64   `db:"accel_x" json:"accel_x"`
	AccelY               float64   `db:"accel_y" json:"accel_y"`
	AccelZ               float64   `db:"accel_z" json:"accel_z"`
	PowerCurrent         float64   `db:"power_current" json:"power_current"`
	IPAddress            string    `db:"ip_address" json:"ip_address"`
	LogType              int       `db:"log_type" json:"log_type"`
	StationId            int       `db:"station_id" json:"station_id"`
	PowerVoltage         float64   `db:"power_voltage" json:"power_voltage"`
	Data                 any       `db:"data" json:"data"`
	IsDeleted            bool      `db:"is_deleted" json:"is_deleted"`
	Temperature          float64   `db:"temperature" json:"temperature"`
	WindSpeed            float64   `db:"wind_speed" json:"wind_speed"`
	SoilMoisture         float64   `db:"soil_moisture" json:"soil_moisture"`
	WindDirection        float64   `db:"wind_direction" json:"wind_direction"`
	RainDrop             float64   `db:"raindrop" json:"raindrop"`
	Humidity             int       `db:"humidity" json:"humidity"`
	BarometricPressure   float64   `db:"barometric_pressure" json:"barometric_pressure"`
	WindSpeedAverage     float64   `db:"wind_speed_average" json:"wind_speed_average"`
	WindGust             float64   `db:"wind_gust" json:"wind_gust"`
	WindDirectionAverage float64   `db:"wind_direction_average" json:"wind_direction_average"`
	RainRate             float64   `db:"rain_rate" json:"rain_rate"`
}
