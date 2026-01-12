package oPredictions

import (
	"time"

	"luwes/sql"

	"github.com/kokizzu/gotro/A"
	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/F"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"
	"github.com/kokizzu/gotro/W"
	"github.com/kokizzu/gotro/X"
)

var TM_MASTER Pg.TableModel

const TABLE = `predictions`

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
		CacheName: TABLE + `_STATIONS_MASTER`,
		Fields: []Pg.FieldModel{
			{Key: `id`},
			{Key: `created_at`, Type: `datetime`, FormHide: true, NotDataCol: true},
			{Label: `Time`, Key: `predict_epoch`, Type: `datetime`, NotDataCol: true}, // the date
			{Label: `Level`, Key: `level`, Type: `float`, NotDataCol: true},
		},
	}
}

const PREDICTION_DATETIME_FORMAT = `2006-01-02 15:04:05`
const MULTIPLIER = 60

// 2017-08-28 Prayogo
func Search_ByQueryParams(qp *Pg.QueryParams, sta_id int64) {
	qp.RamKey = ZT(qp.Term)
	qp.From = `FROM ` + TABLE + ` x1`
	qp.OrderBy = `predict_epoch::FLOAT DESC`
	qp.Where = `AND x1.station_id = ` + ZI(sta_id)
	qp.Select = qp.Model.Select()
	qp.SearchQuery_ByConn(sql.PG)
}

// 2017-08-28 Prayogo
func API_Superadmin_Search(rm *W.RequestModel) {
	qp := Pg.NewQueryParams(rm.Posts, &TM_MASTER)
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	Search_ByQueryParams(qp, sta_id)
	qp.ToAjax(rm.Ajax)
}

// 2017-08-28 Prayogo
func One_ByID(id int64) M.SX {
	ram_key := ZT(I.ToS(id))
	query := ram_key + `
		SELECT ` + TM_MASTER.Select() + `
		FROM ` + TABLE + ` x1
		WHERE x1.id = ` + ZI(id)
	return sql.PG.CQFirstMap(TABLE, ram_key, query)
}

// 2017-08-28 Prayogo
func API_OwnerSuperadmin_Form(rm *W.RequestModel) {
	rm.Ajax.SX = One_ByID(S.ToI(rm.Id))
}

// 2017-08-28 Prayogo
func API_OwnerSuperadmin_SaveDelete(rm *W.RequestModel) {
	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		dm := Pg.NewRow(tx, TABLE, rm) // NewPostlessData
		dm.SetNonData(`level`)
		dm.SetNonData(`predict_epoch`)
		if rm.Action == `delete` {
			dm.PermanentErase()
		} else {
			dm.UpsertRow()
		}
		return rm.Ajax.LastError()
	})
}

// 2017-06-22 Prayogo
func API_Superadmin_EraseAll(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		query := ZT() + `
		DELETE FROM ` + TABLE + `
		WHERE station_id = ` + ZI(sta_id) + ` 
		`
		ra, err := tx.DoExec(query).RowsAffected()
		if err != nil {
			rm.Ajax.Error(err.Error())
		}
		rm.Ajax.Set(`deleted`, ra)
		return rm.Ajax.LastError()
	})
	Pg.RamGlobalEvict_ByAjax_ByBucket(rm.Ajax, TABLE)
}

// 2017-08-28 Prayogo
func API_Superadmin_InsertUpdate(rm *W.RequestModel) {
	lines := rm.Posts.GetStr(`lines`)
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	rows := S.Split(lines, "\n")
	ins := int64(0)
	upd := int64(0)
	err_str := ``
	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		for no, row := range rows {
			if len(row) < 1 {
				continue
			}
			cells := S.Split(row, "\t")
			if len(cells) < 2 {
				err_str += `Line not separated with tab: ` + I.ToStr(no) + ` ` + lines + "\n"
				break
			}
			t, err := time.Parse(PREDICTION_DATETIME_FORMAT, cells[0])
			if err != nil {
				err_str += `Time not in ` + PREDICTION_DATETIME_FORMAT + ` format: ` + I.ToStr(no) + ` ` + lines + "\n"
				break
			}
			level_str := F.ToS(S.ToF(cells[1]))
			query := `INSERT INTO predictions(predict_epoch, station_id, level) values (` + I.ToS(t.Unix()) + `, ` + I.ToS(sta_id) + `, ` + level_str + `)
ON CONFLICT (predict_epoch,station_id) DO UPDATE SET level = ` + level_str + ` RETURNING id;`
			ex := tx.DoExec(query)
			id, _ := ex.LastInsertId()
			if id > 0 {
				ins += 1
			} else {
				af, _ := ex.RowsAffected()
				if af > 0 {
					upd += 1
				}
			}
		}
		return ``
	})

	rm.Ajax.Info(`Updated: ` + I.ToS(upd) + ` Insert: ` + I.ToS(ins))
	if len(err_str) > 0 {
		rm.Ajax.Error(err_str)
	}
}

// 2017-08-28 Prayogo
func Preds_BySta_ByStart_ByDur(sta_id, start_predict, predict_dur int64, rows A.MSX) A.MSX {
	if start_predict == 0 {
		for _, row := range rows {
			start_predict = int64(X.ToF(row[`submitted_at`]))
			break
		}
		//ram_key := ZT(I.ToS(sta_id))
		//query := ram_key + `
		//SELECT LEAST((
		//	SELECT EXTRACT(EPOCH FROM submitted_at)
		//	FROM station_logs
		//	WHERE station_id = ` + ZI(sta_id) + `
		//	ORDER BY submitted_at DESC NULLS LAST
		//	LIMIT 1
		//),EXTRACT(EPOCH FROM CURRENT_TIMESTAMP))::BIGINT`
		//start_predict = time.Now().Unix() // sql.PG.CQInt(`station_logs`, ram_key, query)
		//predict_dur += time.Now().Unix() - start_predict
	}
	end_predict := I.Max(time.Now().Unix(), start_predict) + predict_dur
	ram_key := ZT(I.ToS(sta_id), I.ToS(start_predict), I.ToS(predict_dur))
	query := ram_key + `
	SELECT predict_epoch
		, level
	FROM predictions
	WHERE station_id = ` + ZI(sta_id) + `
		AND predict_epoch > ` + ZI(start_predict) + `
		AND predict_epoch <= ` + ZI(end_predict) + `
	LIMIT 1000` // TODO: replace back when needed

	now := time.Now()
	res := sql.PG.QMapArray(query)
	L.TimeTrack(now, query)
	return res
}

// 2017-08-28 Prayogo
func API_GuestOwner_Prediction(rm *W.RequestModel, rows A.MSX) {
	last_predict := rm.Posts.GetInt(`last_predict`)
	predict_dur := rm.Posts.GetInt(`predict_dur`)
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	result := Preds_BySta_ByStart_ByDur(sta_id, last_predict, predict_dur, rows)
	rm.Ajax.Set(`preds`, result)
}
