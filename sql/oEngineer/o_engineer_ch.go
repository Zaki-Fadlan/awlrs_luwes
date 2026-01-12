package oEngineer

import (
	"luwes/sql"
	"luwes/sql/oStations"
	"time"

	"github.com/kokizzu/gotro/A"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/W"
)

const (
	TypeText 				= `text`
	TypeTextArea 		= `textarea`
	TypeEmail 			= `email`
	TypePassword 		= `password`
	TypeNumber 			= `number`
	TypePhone 			= `phone`
	TypeDate 				= `date`
	TypeBool 				= `bool`
	TypeCheckbox 		= `checkbox`
	TypeCombobox 		= `combobox`
	TypeSelect			= `select`
	TypePercentage	= `percentage`
	TypeFloat 			= `float`
	TypeColor 			= `color`
	TypeDatetime 		= `datetime`
)

const (
	LimitDefault10 int64 = 10
	LimitDefault20 int64 = 20
	LimitDefault40 int64 = 40
	LimitDefault100 int64 = 100
	LimitDefault200 int64 = 200
	LimitDefault400 int64 = 400
	LimitDefault1000 int64 = 1000
)

type FormField struct {
	Key 		string `json:"key"`
	Label		string `json:"label"`
	Type 		string `json:"type"`
	ToopTip string `json:"tooltip"`
}

type GridField struct {
	Key 		string `json:"key"`
	Label		string `json:"label"`
	Type 		string `json:"type"`
	Footer	string `json:"footer"`
}

// 2024-10-11 Ahmad Habibi
func CH_ShowDataLog_DEFAULT(res M.SX, sta_id int64) {
	orderBy := oStations.KeySubmittedAt + ` DESC`
	result := CH_ShowDataLog(sta_id, orderBy, 0, 10)

	res[`rows`] = result[`rows`]
	res[`count`] = result[`count`]
	res[`offset`] =  result[`offset`]
	res[`limit`] = result[`limit`]
	res[`form_fields`] = []FormField{
		{
			Key: oStations.KeySubmittedAt,
			Label: oStations.LabelSubmittedAt,
			Type: TypeDatetime,
			ToopTip: oStations.LabelSubmittedAt,
		},
		{
			Key: oStations.KeyAccelX,
			Label: oStations.LabelAccelX,
			Type: TypeFloat,
			ToopTip: oStations.LabelAccelX,
		},
		{
			Key: oStations.KeyAccelY,
			Label: oStations.LabelAccelY,
			Type: TypeFloat,
			ToopTip: oStations.LabelAccelY,
		},
		{
			Key: oStations.KeyLevelSensor,
			Label: oStations.LabelLevelSensor,
			Type: TypeFloat,
			ToopTip: oStations.LabelLevelSensor,
		},
		{
			Key: oStations.KeyPowerCurrent,
			Label: oStations.LabelPowerCurrent,
			Type: TypeFloat,
			ToopTip: oStations.LabelPowerCurrent,
		},
		{
			Key: oStations.KeyPowerVoltage,
			Label: oStations.LabelPowerVoltage,
			Type: TypeFloat,
			ToopTip: oStations.LabelPowerVoltage,
		},
	}

	res[`grid_fields`] = []GridField{
		{
			Key: oStations.KeySubmittedAt,
			Label: oStations.LabelSubmittedAt,
			Type: TypeDatetime,
			Footer: ``,
		},
		{
			Key: oStations.KeyAccelX,
			Label: oStations.LabelAccelX,
			Type: TypeFloat,
			Footer: ``,
		},
		{
			Key: oStations.KeyAccelY,
			Label: oStations.LabelAccelY,
			Type: TypeFloat,
			Footer: ``,
		},
		{
			Key: oStations.KeyLevelSensor,
			Label: oStations.LabelLevelSensor,
			Type: TypeFloat,
			Footer: ``,
		},
		{
			Key: oStations.KeyPowerCurrent,
			Label: oStations.LabelPowerCurrent,
			Type: TypeFloat,
			Footer: ``,
		},
		{
			Key: oStations.KeyPowerVoltage,
			Label: oStations.LabelPowerVoltage,
			Type: TypeFloat,
			Footer: ``,
		},
	}
}

// 2024-10-12 Ahmad Habibi
func CH_LogSearch(rm *W.RequestModel, sta_id int64) {
	offset := rm.Posts.GetInt(`offset`)
	limit := rm.Posts.GetInt(`limit`)
	order := rm.Posts.GetJsonStrArr(`order`)

	// Skip for now:
	// filter := rm.Posts.GetJsonMap(`filter`)
	// term := rm.Posts.GetStr(`term`)

	orderBy := oStations.KeySubmittedAt + ` DESC`
	if len(order) == 1 {
		toOrder := order[0]
		switch toOrder {
			case `+`+oStations.KeyCreatedAt, `-`+oStations.KeyCreatedAt:
				if toOrder == `+`+oStations.KeyCreatedAt {
					orderBy = oStations.KeyCreatedAt + ` ASC`
				} else {
					orderBy = oStations.KeyCreatedAt + ` DESC`
				}
			case `+`+oStations.KeySubmittedAt, `-`+oStations.KeySubmittedAt:
				if toOrder == `+`+oStations.KeySubmittedAt {
					orderBy = oStations.KeySubmittedAt + ` ASC`
				} else {
					orderBy = oStations.KeySubmittedAt + ` DESC`
				}
			case `+`+oStations.KeyAccelX, `-`+oStations.KeyAccelX:
				if toOrder == `+`+oStations.KeyAccelX {
					orderBy = oStations.KeyAccelX + ` ASC`
				} else {
					orderBy = oStations.KeyAccelX + ` DESC`
				}
			case `+`+oStations.KeyAccelY, `-`+oStations.KeyAccelY:
				if toOrder == `+`+oStations.KeyAccelY {
					orderBy = oStations.KeyAccelY + ` ASC`
				} else {
					orderBy = oStations.KeyAccelY + ` DESC`
				}
			case `+`+oStations.KeyLevelSensor, `-`+oStations.KeyLevelSensor:
				if toOrder == `+`+oStations.KeyLevelSensor {
					orderBy = oStations.KeyLevelSensor + ` ASC`
				} else {
					orderBy = oStations.KeyLevelSensor + ` DESC`
				}
			case `+`+oStations.KeyPowerCurrent, `-`+oStations.KeyPowerCurrent:
				if toOrder == `+`+oStations.KeyPowerCurrent {
					orderBy = oStations.KeyPowerCurrent + ` ASC`
				} else {
					orderBy = oStations.KeyPowerCurrent + ` DESC`
				}
			case `+`+oStations.KeyPowerVoltage, `-`+oStations.KeyPowerVoltage:
				if toOrder == `+`+oStations.KeyPowerVoltage {
					orderBy = oStations.KeyPowerVoltage + ` ASC`
				} else {
					orderBy = oStations.KeyPowerVoltage + ` DESC`
				}
			default:
				orderBy = oStations.KeySubmittedAt + ` DESC`
		}
	}

	res := CH_ShowDataLog(sta_id, orderBy, offset, limit)
	
	rm.Ajax.Set(`rows`, res[`rows`])
	rm.Ajax.Set(`count`, res[`count`])
	rm.Ajax.Set(`offset`, res[`offset`])
	rm.Ajax.Set(`limit`, res[`limit`])
}

// 2024-10-11 Ahmad Habibi
func CH_ShowDataLog(sta_id int64, orderBy string, offset, limit int64) M.SX {
	// Check limit, must be in a list of limits
	switch limit {
	case LimitDefault10, LimitDefault20, LimitDefault40, LimitDefault100, LimitDefault200, LimitDefault400, LimitDefault1000:
		break
	default:
		limit = LimitDefault10
	}

	query1 := `SELECT
		accel_x, accel_y, level_sensor, power_current, power_voltage,
		toUnixTimestamp(created_at) created_at, toUnixTimestamp(submitted_at) submitted_at
		FROM station_logs WHERE station_id = ` + I.ToS(sta_id) + `
		ORDER BY `+ orderBy +`
		LIMIT `+ I.ToS(limit) +` OFFSET `+ I.ToS(offset)
	
	nowQuery1 := time.Now()
	rows, err := sql.CH.DB.Query(query1)

	L.Print(`QUERY 1 : `, query1)
	L.TimeTrack(nowQuery1, query1)
	L.IsError(err, `failed to get station logs: `+query1)
	
	var stationLogs A.MSX
	for rows.Next() {
		var (
			accelX float64
			accelY float64
			lvSensor float64
			powerCurrent float64
			powerVoltage float64
			created_at uint64
			submittedAt uint64
		)
		rows.Scan(
			&accelX, &accelY, &lvSensor,
			&powerCurrent,&powerVoltage,
			&created_at, &submittedAt,
		)

		stationLogs = append(stationLogs, M.SX{
			oStations.KeyID: I.ToS(sta_id),
			oStations.KeyAccelX: accelX,
			oStations.KeyAccelY: accelY,
			oStations.KeyLevelSensor: lvSensor,
			oStations.KeyPowerCurrent: powerCurrent,
			oStations.KeyPowerVoltage: powerVoltage,
			oStations.KeyCreatedAt: created_at,
			oStations.KeySubmittedAt: submittedAt,
			oStations.KeyIsDeleted: false, // since it has no column in clickhouse, set it as "false"
		})
	}

	query2 := `SELECT COUNT(*)
		FROM station_logs WHERE station_id = ` + I.ToS(sta_id)

	var count int64

	nowQuery2 := time.Now()
	err = sql.CH.DB.QueryRow(query2).Scan(&count)

	L.IsError(err, `failed to count station log rows: `+query2)
	L.Print(`QUERY 2 : `, query2)
	L.TimeTrack(nowQuery2, query2)

	return M.SX{
		`rows`: stationLogs,
		`count`: count,
		`offset`: offset,
		`limit`: limit,
	}
}