package oEngineer

import (
	"fmt"
	"luwes/sql"
	"luwes/sql/oGroups"
	"luwes/sql/oStations"
	"testing"
	"time"

	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/X"
	"github.com/stretchr/testify/assert"
)

func TestStationLogsEngineer(t *testing.T) {
	t.Run(`insertGroup`, func(t *testing.T) {
		group := oGroups.NewGroupMutator(sql.PG.Adapter)
		group.Name = "Group for station engineer"
		group.Note = "test note"
		group.UniqueId = sql.RandomCapitalString(15)
		group.CreatedBy = 1
		group.UpdatedBy = 1
		assert.NoError(t, group.Insert(), `failed to insert a new group`)

		t.Run(`insertStation`, func(t *testing.T) {
			station := oStations.NewStationMutator(sql.PG.Adapter)
			station.Name = `Test Station`
			station.IMEI = sql.RandomNumString(15)
			station.LastSubmittedAt = time.Now()
			station.LastLevelSensor = 1.439
			station.Longitude = 116.324944
			station.Latitude = -8.650979
			station.GroupID = group.Id
			assert.NoError(t, station.DoInsert(), `failed to insert a new station`)

			t.Run(`insertStationLog`, func(t *testing.T) {
				stationLog := oStations.NewStationLogPq(sql.PG.Adapter)
				stationLog.StationId = station.Id
				stationLog.SubmittedAt = time.Now()
				stationLog.Sequence = 111
				stationLog.LevelSensor = 4.2
				stationLog.PowerCurrent = 3.8
				stationLog.PowerVoltage = 50.1
				stationLog.AccelX = 6.2
				stationLog.AccelY = 1.7
				stationLog.AccelZ = 8

				assert.NoError(t, stationLog.DoInsert14(), `failed to insert a new station log`)

				t.Run(`showDataLog`, func(t *testing.T) {
					qp := Pg.NewQueryParams(nil, &TM_MASTER)
					ShowDataLog(qp, int64(station.Id))

					result := M.SX{}
					qp.ToMSX(result)

					fmt.Println(X.ToJsonPretty(result))
				})
			})
		})
	})
}
