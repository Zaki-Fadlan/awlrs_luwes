package oStations

import (
	"luwes/sql"
	"luwes/sql/oGroups"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestStationLog(t *testing.T) {
	t.Run(`insertStationLogsChMustSucceed`, func(t *testing.T) {
		stationLogCh := &StationLogCh{}

		stationLogCh.StationId = 20
		stationLogCh.SubmittedAt = time.Now()
		stationLogCh.Sequence = 111
		stationLogCh.LevelSensor = 4.2
		stationLogCh.PowerCurrent = 3.8
		stationLogCh.PowerVoltage = 50.1
		stationLogCh.AccelX = 6.2
		stationLogCh.AccelY = 1.7
		stationLogCh.AccelZ = 8

		assert.NoError(t, stationLogCh.DoInsert14(), `failed to insert a new station log [ch]`)
	})

	t.Run(`insertGroupMustSucceed`, func(t *testing.T) {
		group := oGroups.NewGroupMutator(sql.PG.Adapter)
		group.Name = "Group for Station Log"
		group.Note = "test note"
		group.UniqueId = sql.RandomCapitalString(15)
		group.CreatedBy = 1
		group.UpdatedBy = 1
		assert.NoError(t, group.Insert(), `failed to insert a new group`)

		t.Run(`insertStationMustSucceed`, func(t *testing.T) {
			station := NewStationMutator(sql.PG.Adapter)
			station.Name = `Test Station`
			station.IMEI = sql.RandomNumString(15)
			station.LastSubmittedAt = time.Now()
			station.LastLevelSensor = 1.439
			station.Longitude = 116.324944
			station.Latitude = -8.650979
			station.GroupID = group.Id
			assert.NoError(t, station.DoInsert(), `failed to insert a new station`)

			t.Run(`insertStationLogsMustSucceed`, func(t *testing.T) {
				stationLog := NewStationLogPq(sql.PG.Adapter)
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
			})
		})
	})
}
