package oStations

import (
	"fmt"
	"time"

	"luwes/sql"

	"github.com/jmoiron/sqlx"
)

type StationMinutes struct {
	DB *sqlx.DB `db:"-"`

	At   time.Time `db:"at"`
	SLID int       `db:"slid"`
	SID  int       `db:"sid"`
}

func NewStationMinutesMutator(db *sqlx.DB) *StationMinutes {
	return &StationMinutes{DB: db}
}

func (sm *StationMinutes) DoInsert(stationId int) error {
	query := func(table string) string {
		qstr := `-- StationMinutes) DoInsert
INSERT INTO ` + table + ` (at, slid, sid)
VALUES (:at, :slid, :sid) ON CONFLICT DO NOTHING`
		return qstr
	}

	_, err := sm.DB.NamedExec(query("station_minutes"), sm)
	if err != nil {
		return err
	}

	tableMinutesID := fmt.Sprintf("station_minutes_%d", stationId)
	if sql.PG.TableExists(tableMinutesID) {
		_, err := sm.DB.NamedExec(query(tableMinutesID), sm)
		if err != nil {
			return err
		}
	}

	return nil
}
