package oEngineer

import (
	"luwes/sql"

	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"

	//"github.com/kokizzu/gotro/W"

	"github.com/kokizzu/gotro/W"
)

const TABLE = `station_logs`

var TM_MASTER Pg.TableModel
var SELECT = ``

var Z func(string) string
var ZZ func(string) string
var ZJ func(string) string
var ZB func(bool) string
var ZI func(int64) string
var ZLIKE func(string) string
var ZT func(strs ...string) string

func init() {
	Z = S.Z
	ZB = S.ZB
	ZZ = S.ZZ
	ZJ = S.ZJJ
	ZI = S.ZI
	ZT = S.ZT
	ZLIKE = S.ZLIKE

	TM_MASTER = Pg.TableModel{
		CacheName: TABLE + `_STATION_MASTER`,
		Fields: []Pg.FieldModel{
			{Key: `id`},
			{Key: `is_deleted`},
			{Key: `created_at`, Type: `datetime`},
			{Label: `submitted at`, Key: `submitted_at`, Type: `datetime`, NotDataCol: true, CustomQuery: `EXTRACT( EPOCH FROM x1.submitted_at)`},
			{Label: `latitude`, Key: `accel_x`, Type: `float`, NotDataCol: true},
			{Label: `longitude`, Key: `accel_y`, Type: `float`, NotDataCol: true},
			{Label: `level`, Key: `level_sensor`, Type: `float`, NotDataCol: true},
			{Label: `power current`, Key: `power_current`, Type: `float`, NotDataCol: true},
			{Label: `power voltage`, Key: `power_voltage`, Type: `float`, NotDataCol: true},
			//{Label: `Temperature`, Key: `temperature`, Type:`float`, NotDataCol: true},
			//{Label: `Wind Speed`, Key: `wind_speed`, Type: `float`, NotDataCol: true},
			//{Label: `Soil Moisture`, Key: `soil_moisture`, Type: `float`, NotDataCol: true},
			//{Label: `Wind Direction`, Key: `wind_direction`, Type: `float`, NotDataCol: true},
			//{Label: `Raindrop`, Key: `raindrop`, Type: `float`, NotDataCol: true},
		},
	}
}

// 2017-10-10 Michael
func ShowDataLog(qp *Pg.QueryParams, sta_id int64) {
	qp.RamKey = ZT(qp.Term)
	// Freelancer 20200109
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		last_mod_sql := `(SELECT COALESCE(EXTRACT(EPOCH FROM (MAX(submitted_at)- INTERVAL '1 hours')),0) FROM ` + NewTableName + ` WHERE 1=1)`
		last_mod_sql = sql.PG.QStr(last_mod_sql)
		qp.Where += `AND EXTRACT(EPOCH FROM submitted_at) >` + last_mod_sql
		qp.From = `FROM ` + NewTableName + ` x1`
		qp.OrderBy = `4 DESC NULLS FIRST`
		//qp.TableSuffix = I.ToS(sta_id)
		// Freelancer end 20200109
	} else {
		last_mod_sql := `(SELECT COALESCE(EXTRACT(EPOCH FROM (MAX(submitted_at)- INTERVAL '1 hours')),0) FROM station_logs WHERE 1=1)`
		last_mod_sql = sql.PG.QStr(last_mod_sql)
		qp.Where += `AND EXTRACT(EPOCH FROM submitted_at) >` + last_mod_sql + ` AND x1.station_id = ` + I.ToS(sta_id)
		qp.From = `FROM ` + TABLE + ` x1`
		qp.OrderBy = `4 DESC NULLS FIRST`
	}

	qp.Select = TM_MASTER.Select()
	qp.SearchQuery_ByConn(sql.PG)
}

// 2017-10-10 Michael
func One_ByID(id int64) M.SX {
	ram_key := ZT(I.ToS(id))
	query := ram_key + `
		SELECT ` + TM_MASTER.Select() + `
		FROM ` + TABLE + ` x1
		WHERE x1.id = ` + ZI(id)
	return sql.PG.CQFirstMap(TABLE, ram_key, query)
}

// 2017-10-10 Michael
func LogSearch(rm *W.RequestModel, sta_id int64) {
	qp := Pg.NewQueryParams(rm.Posts, &TM_MASTER)
	ShowDataLog(qp, sta_id)
	qp.ToAjax(rm.Ajax)
}
