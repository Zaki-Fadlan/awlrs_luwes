package oGroups

import (
	"luwes/sql"

	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"
	"github.com/kokizzu/gotro/W"
)

const TABLE = `groups`

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
		CacheName: TABLE + `_GROUPS_MASTER`,
		Fields: []Pg.FieldModel{
			{Key: `id`},
			{Key: `is_deleted`},
			{Label: `Name`, Key: `name`, NotDataCol: true},
			//{Label: `Full Name`, Key: `full_name`, NotDataCol: true},
			//{Label: `App ID`, Key: `app_id`, FormHide: true, NotDataCol:true},
			//{Label: `Is App?`, Key: `is_app`, Type: `boolean`, FormHide: true},
			//{Label: `E-Mail`, Key: `email`, NotDataCol: true},
			{Label: `Note`, Key: `note`, NotDataCol: true},
			//{Label: `Phone`, Key: `phone`, Type: `phone`, FormHide: true},
			//{Label: `Permission`, Key: `permission`},
		},
	}
	SELECT = TM_MASTER.Select()
}

// 2017-06-24 Haries
func All_ForSelect() M.SS {
	ram_key := ZT()
	query := ram_key + `
	SELECT id, name || COALESCE(': ' || (CASE WHEN note <> '' THEN note END),'') || (CASE WHEN is_deleted THEN ' (deleted)' ELSE '' END)
	FROM groups
	`
	return sql.PG.CQStrStrMap(TABLE, ram_key, query)
}

// 2017-06-04 Haries
func Search_ByQueryParams(qp *Pg.QueryParams) {
	qp.RamKey = ZT(qp.Term)
	if qp.Term != `` {
		qp.Where += ` AND x1.name ILIKE ` + ZLIKE(qp.Term)
	}
	qp.From = `FROM ` + TABLE + ` x1`
	qp.OrderBy = `x1.id`
	qp.Select = SELECT
	qp.SearchQuery_ByConn(sql.PG)
}

// 2017-06-04 Haries
func API_Superadmin_Search(rm *W.RequestModel) {
	qp := Pg.NewQueryParams(rm.Posts, &TM_MASTER)

	Search_ByQueryParams(qp)
	qp.ToAjax(rm.Ajax)
}

// 2017-06-04 Haries
func One_ByID(id int64) M.SX {
	ram_key := ZT(I.ToS(id))
	query := ram_key + `
		SELECT ` + SELECT + `
		FROM ` + TABLE + ` x1
		WHERE x1.id = ` + ZI(id)
	//L.Print(query)
	return sql.PG.CQFirstMap(TABLE, ram_key, query)
}

// 2017-06-04 Haries
func API_Superadmin_Form(rm *W.RequestModel) {
	//L.Print(rm.Id)
	rm.Ajax.SX = One_ByID(S.ToI(rm.Id))
}

// 2017-06-04 Haries
func API_Superadmin_SaveDeleteRestore(rm *W.RequestModel) {
	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		dm := Pg.NewNonDataRow(tx, TABLE, rm)
		dm.SetNonData(`name`)
		dm.SetNonData(`note`)
		dm.UpsertRow()
		if !rm.Ajax.HasError() {
			dm.WipeUnwipe(rm.Action)
		}
		return rm.Ajax.LastError()
	})
}
