package oStations

import (
	"luwes/sql"
	"luwes/sql/oGroups"
	"testing"
	"time"

	"github.com/kokizzu/gotro/X"
	"github.com/stretchr/testify/assert"
)

func TestStations(t *testing.T) {
	t.Run(`insertGroupMustSucceed`, func(t *testing.T) {
		group := oGroups.NewGroupMutator(sql.PG.Adapter)
		group.Name = "Group for Stations"
		group.Note = "test note"
		group.UniqueId = sql.RandomCapitalString(15)
		group.CreatedBy = 1
		group.UpdatedBy = 1
		assert.NoError(t, group.Insert(), `failed to insert a new group`)

		t.Run(`insertStationMustSucceed`, func(t *testing.T) {
			imei := sql.RandomNumString(15)

			station := NewStationMutator(sql.PG.Adapter)
			station.Name = `Test Insert Station`
			station.IMEI = imei
			station.LastSubmittedAt = time.Now()
			station.LastLevelSensor = 1.439
			station.Longitude = 116.324944
			station.Latitude = -8.650979
			station.GroupID = group.Id
			assert.NoError(t, station.DoInsert(), `failed to insert a new station`)

			t.Log(X.ToJsonPretty(station))

			t.Run(`findStationByImei`, func(t *testing.T) {
				staByImei := NewStationMutator(sql.PG.Adapter)
				staByImei.IMEI = imei
				assert.True(t, staByImei.FindByIMEI(), `failed to find station by IMEI`)

				t.Log(X.ToJsonPretty(staByImei))
			})

			t.Run(`findStationById`, func(t *testing.T) {
				staById := NewStationMutator(sql.PG.Adapter)
				staById.Id = station.Id
				assert.True(t, staById.FindById(), `failed to find station by ID`)

				t.Log(X.ToJsonPretty(staById))
			})
		})
	})
}
