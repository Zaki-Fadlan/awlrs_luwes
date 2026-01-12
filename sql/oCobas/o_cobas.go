package oCobas

import (
	"luwes/sql"

	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"
	"github.com/kokizzu/gotro/W"
)

const TABLE = `cobas`

var TM_MASTER Pg.TableModel

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
		CacheName: TABLE + `_USERS_MASTER`,
		Fields: []Pg.FieldModel{
			{Key: `id`},
			{Key: `is_deleted`},
			{Label: `Name`, Key: `name`},
			{Label: `Note`, Key: `note`, Type: `textarea`},
			{Label: `Age`, Key: `age`, Type: `int`},
		},
	}
}

// 2017-06-04 Haries
func API_Superadmin_Search(rm *W.RequestModel) {
	qp := Pg.NewQueryParams(rm.Posts, &TM_MASTER)
	Search_ByQueryParams(qp)
	qp.ToAjax(rm.Ajax)
}

// 2017-06-04 Haries
func Search_ByQueryParams(qp *Pg.QueryParams) {
	qp.RamKey = ZT(qp.Term)
	if qp.Term != `` {
		qp.Where += ` AND (
			(x1.data->>'name') ILIKE ` + ZLIKE(qp.Term) + `
			OR (x1.data->>'note') ILIKE ` + ZLIKE(qp.Term) + `
		)`
	}
	qp.From = `FROM ` + TABLE + ` x1`
	qp.OrderBy = `x1.id`
	qp.Select = TM_MASTER.Select()
	qp.SearchQuery_ByConn(sql.PG)
}

// 2017-06-04 Haries
func API_Superadmin_Form(rm *W.RequestModel) {
	//L.Print(rm.Id)
	rm.Ajax.SX = One_ByID(S.ToI(rm.Id))
}

// 2017-06-04 Haries
func One_ByID(id int64) M.SX {
	ram_key := ZT(I.ToS(id))
	query := ram_key + `
		SELECT ` + TM_MASTER.Select() + `
		FROM ` + TABLE + ` x1
		WHERE x1.id = ` + ZI(id)
	return sql.PG.CQFirstMap(TABLE, ram_key, query)
}

// 2017-06-04 Haries
func API_Superadmin_SaveDeleteRestore(rm *W.RequestModel) {
	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		dm := Pg.NewRow(tx, TABLE, rm)
		dm.SetStr(`name`)
		dm.SetStr(`note`)
		dm.SetInt(`age`)
		dm.UpsertRow()
		if !rm.Ajax.HasError() {
			dm.WipeUnwipe(rm.Action)
		}
		return rm.Ajax.LastError()
	})
}
