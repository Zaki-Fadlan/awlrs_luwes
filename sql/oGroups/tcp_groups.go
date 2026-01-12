package oGroups

import (
	dbsql "database/sql"
	"errors"
	"luwes/sql"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/kokizzu/gotro/L"
)

type Group struct {
	DB         *sqlx.DB
	Id         int          `db:"id" json:"id"`
	Name       string       `db:"name" json:"name"`
	Note       string       `db:"note" json:"note"`
	UniqueId   string       `db:"unique_id" json:"unique_id"`
	Data       any          `db:"data" json:"data"`
	CreatedAt  time.Time    `db:"created_at" json:"created_at"`
	CreatedBy  int          `db:"created_by" json:"created_by"`
	UpdatedAt  time.Time    `db:"updated_at" json:"updated_at"`
	UpdatedBy  int          `db:"updated_by" json:"updated_by"`
	DeletedAt  sql.NullTime `db:"deleted_at" json:"deleted_at"`
	DeletedBy  int          `db:"deleted_by" json:"deleted_by"`
	RestoredBy int          `db:"restored_by" json:"restored_by"`
	IsDeleted  bool         `db:"is_deleted" json:"is_deleted"`
}

func NewGroupMutator(db *sqlx.DB) *Group {
	return &Group{DB: db}
}

func (g *Group) Insert() error {
	query := `INSERT INTO groups
		(name, note, unique_id, data, created_at, created_by, updated_at, updated_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, name, note, unique_id, data, created_at, created_by, updated_at, updated_by`

	if err := g.DB.QueryRowx(query,
		g.Name, g.Note, g.UniqueId, g.Data, time.Now(), g.CreatedBy, time.Now(), g.UpdatedBy,
	).StructScan(g); err != nil {
		errMsg := `failed to insert group`
		L.IsError(err, errMsg)
		return errors.New(errMsg)
	}
	return nil
}

func (g *Group) FindByName() bool {
	query := `SELECT
		id, name,
		COALESCE(note, '') AS note,
		COALESCE(unique_id, '') AS unique_id,
		COALESCE(data, '{}'::jsonb) AS data,
		created_at,
		COALESCE(created_by, 0) AS created_by,
		updated_at,
		COALESCE(updated_by, 0) AS updated_by,
		deleted_at,
		COALESCE(deleted_by, 0) AS deleted_by,
		COALESCE(restored_by, 0) AS restored_by,
		is_deleted
	FROM groups WHERE name = $1`
	err := g.DB.Get(g, query, g.Name)

	return !errors.Is(err, dbsql.ErrNoRows)
}
