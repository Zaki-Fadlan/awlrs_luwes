package oStations

import (
	"fmt"
	"time"

	"luwes/sql"

	"github.com/jmoiron/sqlx"
)

type StationHours struct {
	DB *sqlx.DB `db:"-"`

	At   time.Time `db:"at"`
	SLID int       `db:"slid"`
	SID  int       `db:"sid"`
}

func NewStationHoursMutator(db *sqlx.DB) *StationHours {
	return &StationHours{DB: db}
}

func (sh *StationHours) DoInsert(stationId int) error {
	query := func(table string) string {
		qstr := `INSERT INTO ` + table + ` (at, slid, sid)
		VALUES (:at, :slid, :sid) ON CONFLICT DO NOTHING`
		//L.Print(qstr)
		return qstr
	}

	_, err := sh.DB.NamedExec(query("station_hours"), sh)
	if err != nil {
		return err
	}

	tableHoursID := fmt.Sprintf("station_hours_%d", stationId)
	if sql.PG.TableExists(tableHoursID) {
		_, err := sh.DB.NamedExec(query(tableHoursID), sh)
		if err != nil {
			return err
		}
	}

	//L.Print(`Success:: (sh *StationHours) DoInsert()`)

	return nil
}
