package oStations

import (
	"luwes/sql"
	"time"

	"github.com/kokizzu/gotro/A"
	"github.com/kokizzu/gotro/B"
	"github.com/kokizzu/gotro/F"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"
	"github.com/kokizzu/gotro/W"
	"github.com/kokizzu/gotro/X"
)

const (
	KeyID                   = `id`
	KeyCreatedAt            = `created_at`
	KeyIsDeleted            = `is_deleted`
	KeyAccelX               = `accel_x`
	KeyAccelY               = `accel_y`
	KeyAccelZ               = `accel_z`
	KeyBarometricPressure   = `barometric_pressure`
	KeyHumidity             = `humidity`
	KeyLevelSensor          = `level_sensor`
	KeyPowerCurrent         = `power_current`
	KeyPowerVoltage         = `power_voltage`
	KeyRainRate             = `rain_rate`
	KeyRaindrop             = `raindrop`
	KeySubmittedAt          = `submitted_at`
	KeyTemperature          = `temperature`
	KeyWindDirection        = `wind_direction`
	KeyWindDirectionAverage = `wind_direction_average`
	KeyWindGust             = `wind_gust`
	KeyWindSpeed            = `wind_speed`
	KeyWindSpeedAverage     = `wind_speed_average`
)

const (
	LabelSubmittedAt  string = `Submitted At`
	LabelAccelX       string = `Latitude`
	LabelAccelY       string = `Longitude`
	LabelLevelSensor  string = `Level Sensor`
	LabelPowerCurrent string = `Power Current`
	LabelPowerVoltage string = `Power Voltage`
)

func CH_SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz(sta_id, last_mod int64, option string, max_date int64, level_only bool, agg string, rw string, raw_format bool, tz int64) (stationLogs A.MSX) {
	ram_key := ZT(I.ToS(sta_id), I.ToS(last_mod), option, I.ToS(max_date), B.ToS(level_only), agg, rw, B.ToS(raw_format), I.ToS(tz))

	tableToQuery := `station_logs`

	if S.EndsWith(rw, `r`) {
		if S.EndsWith(option, `h`) || option == `1d` || option == `3d` {
			tableToQuery = `station_logs`
		} else if option == `7d` {
			tableToQuery = `station_minutes_mv`
		} else {
			tableToQuery = `station_hours_mv`
		}
	}

	last_mod_sql := `-- CH_SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz
SELECT
	toUnixTimestamp(submitted_at) submitted_at, level_sensor ` + S.If(!level_only, `
	, accel_x, accel_y, accel_z, barometric_pressure, humidity,
	power_current, power_voltage, rain_rate, raindrop, temperature,
	wind_direction, wind_direction_average, wind_gust, wind_speed, wind_speed_average`) + `
FROM ` + tableToQuery + ` WHERE station_id = ` + I.ToS(sta_id)
	if last_mod == 0 {
		interval := ``
		switch option {
		case `6h`, `6hr`:
			interval = `6 HOUR`
		case `12h`, `12dr`:
			interval = `12 HOUR`
		case `1d`, `1dr`:
			interval = `1 DAY`
		case `3d`, `3dr`:
			interval = `3 DAY`
		case `7d`, `7dr`:
			interval = `7 DAY`
		case `30d`, `30dr`:
			interval = `30 DAY`
		case `1y`, `1yr`:
			interval = `1 YEAR`
		default: // range
		}
		last_mod_sql += ` AND submitted_at > NOW() - (INTERVAL ` + interval + `)`
	} else {
		last_mod_sql += ` AND submitted_at > fromUnixTimestamp(` + I.ToS(last_mod) + `)
			AND submitted_at < fromUnixTimestamp(` + I.ToS(max_date) + `)`
	}

	query := ram_key + `
		` + last_mod_sql + ` ORDER BY submitted_at DESC`

	now := time.Now()
	rows, err := sql.CH.DB.Query(query)

	L.Print(`QUERY : `, query)
	L.TimeTrack(now, query)
	L.IsError(err, `failed to get station logs: `+query)

	for rows.Next() {
		var (
			submittedAt          uint64
			lvSensor             float64
			accelX               float64
			accelY               float64
			accelZ               float64
			barometricPressure   float64
			humidity             float64
			powerCurrent         float64
			powerVoltage         float64
			rainRate             float64
			rainDrop             float64
			temperature          float64
			windDirection        float64
			windDirectionAverage float64
			windGust             float64
			windSpeed            float64
			windSpeedAverage     float64
		)
		if level_only {
			rows.Scan(&submittedAt, &lvSensor)
		} else {
			rows.Scan(
				&submittedAt,
				&lvSensor,
				&accelX,
				&accelY,
				&accelZ,
				&barometricPressure,
				&humidity,
				&powerCurrent,
				&powerVoltage,
				&rainRate,
				&rainDrop,
				&temperature,
				&windDirection,
				&windDirectionAverage,
				&windGust,
				&windSpeed,
				&windSpeedAverage,
			)
		}

		stationLogs = append(stationLogs, M.SX{
			KeyAccelX:               accelX,
			KeyAccelY:               accelY,
			KeyAccelZ:               accelZ,
			KeyBarometricPressure:   barometricPressure,
			KeyHumidity:             humidity,
			KeyLevelSensor:          lvSensor,
			KeyPowerCurrent:         powerCurrent,
			KeyPowerVoltage:         powerVoltage,
			KeyRainRate:             rainRate,
			KeyRaindrop:             rainDrop,
			KeySubmittedAt:          submittedAt,
			KeyTemperature:          temperature,
			KeyWindDirection:        windDirection,
			KeyWindDirectionAverage: windDirectionAverage,
			KeyWindGust:             windGust,
			KeyWindSpeed:            windSpeed,
			KeyWindSpeedAverage:     windSpeedAverage,
		})
	}

	L.IsError(rows.Err(), `CH_SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz() :`)

	rows.Close()

	return
}

// 2024-10-14 Ahmad Habibi
func CH_StartEndLogs_ById(sta_id int64) (string, string) {
	query := `SELECT MIN(submitted_at), MAX(submitted_at)
		FROM station_logs WHERE station_id = ` + I.ToS(sta_id)

	var (
		min string
		max string
	)

	now := time.Now()
	err := sql.CH.DB.QueryRow(query).Scan(&min, &max)

	L.Print(`QUERY : `, query)
	L.IsError(err, `failed to get start_log and end_log from station logs: `+query)
	L.TimeTrack(now, query)

	return min, max
}

// 2024-10-15 Ahmad Habibi
func CH_API_Superadmin_UpdateHourLevel(rm *W.RequestModel) {
	stationId := rm.Ctx.ParamInt(`sta_id`)
	updateList := rm.Ctx.Posts().GetJsonMap(`update_list_ch`)
	date := rm.Ctx.Posts().GetStr(`date`)

	L.Print(`Update List (CH) :`, updateList)

	total := int64(0)

	for submittedAt, levelSensor := range updateList {
		query := `ALTER TABLE station_logs
			UPDATE level_sensor = ` + F.ToS(X.ToF(levelSensor)) + `
			WHERE submitted_at = ` + S.Z(submittedAt) + `
			AND station_id = ` + I.ToS(stationId)

		now := time.Now()
		res, err := sql.CH.DB.Exec(query)
		L.IsError(err, `CH_API_Superadmin_UpdateHourLevel(rm *W.RequestModel):`)
		L.Print(`QUERY : `, query)
		L.TimeTrack(now, query)

		aff, _ := res.RowsAffected()
		total += aff
	}

	rm.Ajax.Set(`updated`, total)

	result := statDate(stationId, date)
	rm.Ajax.Set(`result`, result)
}

// 2024-10-16 Ahmad Habibi
func CH_API_Superadmin_StatDate(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	date := posts.GetStr(`date`)

	result := statDate(sta_id, date)
	rm.Ajax.Set(`result`, result)
}

func statDate(sta_id int64, date string) A.MSX {
	ram_key := ZT(I.ToS(sta_id), date)

	query := ram_key + `
	WITH x1 AS (
		SELECT
			toHour(submitted_at) hour,
			round(level_sensor, 2) level,
			count(*) cou
		FROM station_logs
		WHERE toDate(submitted_at) = ` + S.Z(date) + `
			AND station_id = ` + I.ToS(sta_id) + ` 
		GROUP BY hour, level
		ORDER BY hour
	)

	SELECT
		hour,
		arrayStringConcat(groupArray(concat(level, ' x ', cou)), ' | ') stat
	FROM x1
	GROUP BY hour`

	now := time.Now()
	rows, err := sql.CH.DB.Query(query)

	L.Print(`Query :::::: `, query)
	L.TimeTrack(now, query)
	L.IsError(err, `failed to get daily log: `+query)

	var result A.MSX

	for rows.Next() {
		var (
			hour int64
			stat string
		)
		rows.Scan(&hour, &stat)

		result = append(result, M.SX{
			`hour`: hour,
			`stat`: stat,
		})
	}

	return result
}

// 2024-10-16 Ahmad Habibi
func CH_API_Superadmin_DeleteHourLevel(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	date := posts.GetStr(`date`)
	hour := posts.GetInt(`hour`)
	level := posts.GetStr(`level`)

	query := `ALTER TABLE station_logs
		DELETE WHERE station_id = ` + I.ToS(sta_id) + `
		AND toDate(submitted_at) = ` + S.Z(date) + `
		AND toHour(submitted_at) = ` + I.ToS(hour) + ` 
		AND level_sensor = ` + level

	now := time.Now()
	res, err := sql.CH.DB.Exec(query)
	L.IsError(err, `CH_API_Superadmin_DeleteHourLevel(rm *W.RequestModel:`)
	L.Print(`QUERY : `, query)
	L.TimeTrack(now, query)

	aff, _ := res.RowsAffected()
	rm.Ajax.Set(`deleted`, aff)

	result := statDate(sta_id, date)
	rm.Ajax.Set(`result`, result)
}

// 2024-10-17 Ahmad Habibi
func CH_API_Superadmin_FormHourLevel(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	date := posts.GetStr(`date`)
	hour := posts.GetInt(`hour`)
	level := posts.GetStr(`level`)
	ram_key := ZT(I.ToS(sta_id), date, I.ToS(hour), level)

	if hour == 0 {
		hour = 12 // IDK but this way is work
	}
	query := ram_key + `
	SELECT formatDateTime(submitted_at, '%H:%m:%S') hhmmss, level_sensor
	FROM station_logs
	WHERE toDate(submitted_at) = ` + Z(date) + `
		AND toHour(submitted_at) = ` + I.ToS(hour) + `
		AND toString(round(level_sensor, 2)) = ` + Z(level) + `
	ORDER BY level_sensor`

	now := time.Now()
	rows, err := sql.CH.DB.Query(query)

	L.Print(`Query :::::: `, query)
	L.TimeTrack(now, query)
	L.IsError(err, `failed to get hour levels: `+query)

	var result A.MSX

	for rows.Next() {
		var (
			hhmmss      string
			levelSensor float64
		)
		rows.Scan(&hhmmss, &levelSensor)

		result = append(result, M.SX{
			`hhmmss`:       hhmmss,
			`level_sensor`: levelSensor,
		})
	}

	rm.Ajax.Set(`result`, result)
}

// 2024-10-17 Ahmad Habibi
func CH_API_Superadmin_CheckRange(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	start_date := posts.GetFloat(`start_date`)
	end_date := posts.GetFloat(`end_date`)

	queryMinMaxCount := `SELECT
		min(level_sensor) min,
		max(level_sensor) max,
		count(*)
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND toUnixTimestamp(submitted_at) >= ` + F.ToS(start_date) + `
		AND toUnixTimestamp(submitted_at) <= ` + F.ToS(end_date)

	var (
		min   float64
		max   float64
		count int64
		first string
		last  string
	)

	now1 := time.Now()
	err := sql.CH.DB.QueryRow(queryMinMaxCount).Scan(&min, &max, &count)
	L.Print(`QUERY queryMinMaxCount : `, queryMinMaxCount)
	L.IsError(err, `failed to get min, max, count from station logs: `+queryMinMaxCount)
	L.TimeTrack(now1, queryMinMaxCount)

	queryFirstSubmittedAt := `SELECT concat(submitted_at, ' = ', level_sensor) first
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND toUnixTimestamp(submitted_at) >= ` + F.ToS(start_date) + `
		ORDER BY submitted_at
	LIMIT 1`

	now2 := time.Now()
	err = sql.CH.DB.QueryRow(queryFirstSubmittedAt).Scan(&first)
	L.Print(`QUERY queryFirstSubmittedAt : `, queryFirstSubmittedAt)
	L.IsError(err, `failed to get first submitted_at from station logs: `+queryFirstSubmittedAt)
	L.TimeTrack(now2, queryFirstSubmittedAt)

	queryLastSubmittedAt := `SELECT concat(submitted_at, ' = ', level_sensor) first
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND toUnixTimestamp(submitted_at) <= ` + F.ToS(start_date) + `
		ORDER BY submitted_at DESC
	LIMIT 1`

	now3 := time.Now()
	err = sql.CH.DB.QueryRow(queryLastSubmittedAt).Scan(&last)
	L.Print(`QUERY queryLastSubmittedAt : `, queryLastSubmittedAt)
	L.IsError(err, `failed to get last submitted_at from station logs: `+queryLastSubmittedAt)
	L.TimeTrack(now3, queryLastSubmittedAt)

	result := M.SX{
		`min`:    min,
		`max`:    max,
		`count`:  count,
		`_first`: first,
		`_last`:  last,
	}

	rm.Ajax.Set(`now`, result)
}

// 2024-10-17 Ahmad Habibi
func CH_API_Superadmin_ShiftRange(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	start_date := posts.GetFloat(`start_date`)
	end_date := posts.GetFloat(`end_date`)
	delta := posts.GetFloat(`delta`)

	query := `ALTER TABLE station_logs
	UPDATE level_sensor = level_sensor + ` + F.ToS(delta) + `
	WHERE toUnixTimestamp(submitted_at) >= ` + F.ToS(start_date) + `
		AND toUnixTimestamp(submitted_at) <= ` + F.ToS(end_date) + `
		AND station_id = ` + I.ToS(sta_id)

	verify_q := `SELECT
		min(level_sensor) min,
		max(level_sensor) max
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND toUnixTimestamp(submitted_at) >= ` + F.ToS(start_date) + `
		AND toUnixTimestamp(submitted_at) <= ` + F.ToS(end_date)

	first_q := `SELECT concat(submitted_at, ' = ', level_sensor) first
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND toUnixTimestamp(submitted_at) >= ` + F.ToS(start_date) + `
		ORDER BY submitted_at
	LIMIT 1`

	last_q := `SELECT concat(submitted_at, ' = ', level_sensor) first
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND toUnixTimestamp(submitted_at) <= ` + F.ToS(start_date) + `
		ORDER BY submitted_at DESC
	LIMIT 1`

	var (
		beforeMin   float64
		beforeMax   float64
		beforeFirst string
		beforeLast  string
	)

	var err error

	err = sql.CH.DB.QueryRow(verify_q).Scan(&beforeMin, &beforeMax)
	L.IsError(err, `Before verify_q :`)

	err = sql.CH.DB.QueryRow(first_q).Scan(&beforeFirst)
	L.IsError(err, `Before first_q :`)

	err = sql.CH.DB.QueryRow(last_q).Scan(&beforeLast)
	L.IsError(err, `Before last_q :`)

	before := M.SX{
		`min`:    beforeMin,
		`max`:    beforeMax,
		`_first`: beforeFirst,
		`_last`:  beforeLast,
	}

	now := time.Now()
	res, err := sql.CH.DB.Exec(query)
	L.IsError(err, `CH_API_Superadmin_ShiftRange: `)
	L.TimeTrack(now, query)

	affected, err := res.RowsAffected()
	if err != nil {
		rm.Ajax.Error(err.Error())
	}

	var (
		afterMin   float64
		afterMax   float64
		afterFirst string
		afterLast  string
	)

	err = sql.CH.DB.QueryRow(verify_q).Scan(&afterMin, &afterMax)
	L.IsError(err, `After verify_q :`)

	err = sql.CH.DB.QueryRow(first_q).Scan(&afterFirst)
	L.IsError(err, `After first_q :`)

	err = sql.CH.DB.QueryRow(last_q).Scan(&afterLast)
	L.IsError(err, `After last_q :`)

	after := M.SX{
		`min`:    afterMin,
		`max`:    afterMax,
		`_first`: afterFirst,
		`_last`:  afterLast,
	}

	rm.Ajax.Set(`affected`, affected)
	rm.Ajax.Set(`before`, before)
	rm.Ajax.Set(`after`, after)

	L.Print(`---------------------- START_SHIFT_RANGE_BACKUP`)
	L.Print(query)
	L.Print(`---------------------- END_SHIFT_RANGE_BACKUP`)
}

// 2024-10-17 Ahmad Habibi
func CH_API_SuperAdmin_EraseAllPermanently(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)

	queryDeleteHours := `ALTER TABLE station_hours_mv DELETE WHERE station_id = ` + I.ToS(sta_id)
	res, err := sql.CH.DB.Exec(queryDeleteHours)
	L.IsError(err, `queryDeleteHours :`)
	v, _ := res.RowsAffected()
	rm.Ajax.Set(`station_hours`, v)

	queryDeleteMinutes := `ALTER TABLE station_minutes_mv DELETE WHERE station_id = ` + I.ToS(sta_id)
	res, err = sql.CH.DB.Exec(queryDeleteMinutes)
	L.IsError(err, `queryDeleteMinutes :`)
	v, _ = res.RowsAffected()
	rm.Ajax.Set(`station_minutes`, v)

	queryDeleteLogs := `ALTER TABLE station_logs DELETE WHERE station_id = ` + I.ToS(sta_id)
	res, err = sql.CH.DB.Exec(queryDeleteLogs)
	L.IsError(err, `queryDeleteLogs :`)
	v, _ = res.RowsAffected()
	rm.Ajax.Set(`station_logs`, v)
}
