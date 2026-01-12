package oUsers

import (
	"time"

	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"
	"github.com/kokizzu/gotro/W"

	"luwes/sql"
)

const TABLE = `users`

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
		CacheName: TABLE + `_USERS_MASTER`,
		Fields: []Pg.FieldModel{
			{Key: `id`},
			{Key: `is_deleted`},
			{Label: `Full Name`, Key: `full_name`, NotDataCol: true},
			//{Label: `App ID`, Key: `app_id`, FormHide: true, NotDataCol:true},
			//{Label: `Is App?`, Key: `is_app`, Type: `boolean`, FormHide: true},
			{Label: `Verified?`, Key: `verified`, Type: `bool`, NotDataCol: true},
			{Label: `E-Mail`, Key: `email`, NotDataCol: true},
			{Label: `Phone`, Key: `phone`, Type: `phone`, NotDataCol: true},
			{Label: `Note`, Key: `note`, NotDataCol: true},
			{Label: `Group`, Key: `group_id`, NotDataCol: true, Type: `select`, HtmlSubType: `Groups`},
			{Label: `Readonly?`, Key: `is_readonly`, Type: `bool`},
		},
	}
	SELECT = TM_MASTER.Select()
}

// 2017-05-30 Prayogo
func FindID_ByPhone(ident string) int64 {
	query := ZT(ident) + `
	SELECT COALESCE((
		SELECT id
		FROM ` + TABLE + `
		WHERE is_deleted = false
			AND phone = ` + Z(ident) + `
		LIMIT 1
	),0)`
	return sql.PG.QInt(query)
}

// 2017-05-30 Prayogo
func FindID_ByIdent_ByPass(ident, pass string) int64 {
	pass = S.HashPassword(pass)
	query := ZT(ident, pass) + `
	SELECT COALESCE((
		SELECT id
		FROM ` + TABLE + `
		WHERE is_deleted = false
			AND LOWER(email) = LOWER(` + Z(ident) + `)
			AND password = ` + Z(pass) + `
		LIMIT 1
	),0)`
	return sql.PG.QInt(query)
}

// 2017-05-30 Prayogo
func FindID_ByEmail(email string) int64 {
	query := ZT(email) + `
	SELECT COALESCE((
		SELECT id
		FROM ` + TABLE + `
		WHERE is_deleted = false
			AND LOWER(email) = LOWER(` + Z(email) + `)
		LIMIT 1
	),0)`
	return sql.PG.QInt(query)
}

// 2017-05-30 Prayogo
func FindID_ByCompactName_ByEmail(ident, email string) int64 {
	ident = S.Trim(ident)
	email = S.Trim(email)
	if email == `` {
		return 0
	}
	ident = Z(ident)
	email = Z(email)
	query := ZT(ident, email) + `
	SELECT COALESCE((
		SELECT id
		FROM ` + TABLE + `
		WHERE is_deleted = false
			AND LOWER(email) = LOWER(` + email + `)
	),0)`
	return sql.PG.QInt(query)
}

// 2024-04-06 Ahmad Habibi
func Id_Name_Email_UpdatedAt_ByIdentByPass(ident, pass string) M.SX {
	pass = S.HashPassword(pass)
	query := ZT(ident, pass) + `
	SELECT
		COALESCE(id, 0) id,
		COALESCE(full_name, '') full_name,
		COALESCE(email, '') email,
		COALESCE(EXTRACT(EPOCH FROM updated_at), 0)::INTEGER updated_at
	FROM ` + TABLE + `
	WHERE is_deleted = false
		AND LOWER(email) = LOWER(` + Z(ident) + `)
		AND PASSWORD = ` + Z(pass) + `
	LIMIT 1;`

	return sql.PG.QFirstMap(query)
}

// 2024-04-06 Ahmad Habibi
func Id_Name_Email_UpdatedAt_ByPhone(ident string) M.SX {
	query := ZT(ident) + `
	SELECT
		COALESCE(id, 0) id,
		COALESCE(full_name, '') full_name,
		COALESCE(email, '') email,
		COALESCE(EXTRACT(EPOCH FROM updated_at), 0)::INTEGER updated_at
	FROM ` + TABLE + `
	WHERE is_deleted = false
		AND phone = ` + Z(ident) + `
	LIMIT 1;`

	return sql.PG.QFirstMap(query)
}

// 2017-05-30 Prayogo
func Name_Emails_ByID(id int64) (string, []string) {
	ram_key := ZT(I.ToS(id))
	query := ram_key + `
SELECT COALESCE(full_name,''), email
FROM ` + TABLE + `
WHERE id = ` + ZI(id)
	name, mail := sql.PG.QStrStr(query)
	return name, []string{name + ` <` + mail + `>`}
}

// 2017-06-04 Haries
func Search_ByQueryParams(qp *Pg.QueryParams) {
	qp.RamKey = ZT(qp.Term)
	if qp.Term != `` {
		qp.Where += ` AND x1.full_name ILIKE ` + ZLIKE(qp.Term)
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
	return sql.PG.CQFirstMap(TABLE, ram_key, query)
}

// 2017-06-04 Haries
func API_Superadmin_Form(rm *W.RequestModel) {
	rm.Ajax.SX = One_ByID(S.ToI(rm.Id))
}

// 2017-06-04 Haries
func API_Superadmin_SaveDeleteRestore(rm *W.RequestModel) {
	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		dm := Pg.NewNonDataRow(tx, TABLE, rm)
		dm.SetNonData(`full_name`)
		dm.SetNonData(`email`)
		dm.SetNonData(`group_id`)
		dm.SetNonData(`note`)
		dm.SetNonData(`phone`)
		dm.SetNonData(`verified`)
		dm.SetBool(`is_readonly`)
		dm.UpsertRow()
		if !rm.Ajax.HasError() {
			dm.WipeUnwipe(rm.Action)
		}
		return rm.Ajax.LastError()
	})
}

// 2025-03-15 Ahmad Habibi
type User struct {
	Id         int64        `db:"id" json:"id"`
	CreatedAt  time.Time    `db:"created_at" json:"created_at"`
	UpdatedAt  time.Time    `db:"updated_at" json:"updated_at"`
	DeletedAt  sql.NullTime `db:"deleted_at" json:"deleted_at"`
	Email      string       `db:"email" json:"email"`
	Password   string       `db:"password" json:"password"`
	ResetId    string       `db:"reset_id" json:"reset_id"`
	Verified   bool         `db:"verified" json:"verified"`
	Note       string       `db:"note" json:"note"`
	GroupId    int64        `db:"group_id" json:"group_id"`
	Phone      string       `db:"phone" json:"phone"`
	FullName   string       `db:"full_name" json:"full_name"`
	UpdatedBy  int64        `db:"updated_by" json:"updated_by"`
	CreatedBy  int64        `db:"created_by" json:"created_by"`
	DeletedBy  int64        `db:"deleted_by" json:"deleted_by"`
	RestoredBy int64        `db:"restored_by" json:"restored_by"`
	UniqueId   string       `db:"unique_id" json:"unique_id"`
	IsDeleted  bool         `db:"is_deleted" json:"is_deleted"`
	Data       string       `db:"data" json:"data"`
}

func NewUser() *User {
	return &User{}
}

func (u *User) DoInsert() error {
	query := `INSERT INTO ` + TABLE + `
	(created_at, updated_at, email, reset_id, verified,
	note, group_id, phone, full_name, password, updated_by, created_by, unique_id, is_deleted, data)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	RETURNING id, created_at, updated_at, email, reset_id, verified,
	note, group_id, phone, full_name, password, updated_by, created_by, unique_id, is_deleted, data`

	u.Password = S.HashPassword(u.Password)
	err := sql.PG.Adapter.QueryRowx(query,
		u.CreatedAt, u.UpdatedAt, u.Email, u.ResetId, u.Verified,
		u.Note, u.GroupId, u.Phone, u.FullName, u.Password, u.UpdatedBy, u.CreatedBy, u.UniqueId, u.IsDeleted, u.Data,
	).StructScan(u)
	if err != nil {
		L.IsError(err, `failed to insert user`)
		return err
	}

	return nil
}
