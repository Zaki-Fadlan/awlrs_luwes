package oStations

import (
	"luwes/sql"
	"luwes/sql/oGroups"
	"os"
	"testing"
	"time"

	"github.com/joho/godotenv"
	"github.com/kokizzu/gotro/F"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/X"
	"github.com/stretchr/testify/assert"
)

func TestGetStartEndLog(t *testing.T) {
	if X.ToBool(os.Getenv(`SKIP_CLICKHOUSE`)) {
		t.Skip(`Skip TestCompareStationMetrics`)
	}

	godotenv.Load(`../../.env`)
	sql.ConnectClickhouse()
	sql.ConnectPostgres()

	var stationId int64 = 451

	min, max := CH_StartEndLogs_ById(stationId)

	t.Log(`[ StationID ` + I.ToS(stationId) + `] Start Log = ` + min)
	t.Log(`[ StationID ` + I.ToS(stationId) + `] End Log = ` + max)
}

func TestGroupsWithStations(t *testing.T) {
	t.Run(`insertGroup`, func(t *testing.T) {
		group := oGroups.NewGroupMutator(sql.PG.Adapter)
		group.Name = "Group for station"
		group.Note = "test note"
		group.UniqueId = sql.RandomCapitalString(15)
		group.CreatedBy = 1
		group.UpdatedBy = 1
		assert.NoError(t, group.Insert(), `failed to insert a new group`)

		t.Run(`insertStation`, func(t *testing.T) {
			station := NewStationMutator(sql.PG.Adapter)
			station.Name = `Test Station`
			station.IMEI = sql.RandomNumString(15)
			station.LastSubmittedAt = time.Now()
			station.LastLevelSensor = 1.439
			station.Longitude = 116.324944
			station.Latitude = -8.650979
			station.GroupID = group.Id
			assert.NoError(t, station.DoInsert(), `failed to insert a new station`)

			t.Run(`getAllGroupsWithStations`, func(t *testing.T) {
				result, err := AllGroupsWithStations()
				assert.NoError(t, err, `failed to get all groups with stations`)

				t.Log(X.ToJsonPretty(result))
			})
		})
	})
}

func TestAllStations(t *testing.T) {
	t.Run(`allStationAsMap`, func(t *testing.T) {
		res := AllStation_AsMap()
		assert.NotNil(t, res)
		t.Log(`All Stations as map: `, X.ToJsonPretty(res))
	})

	t.Run(`insertGroupForPublicStation`, func(t *testing.T) {
		group := oGroups.NewGroupMutator(sql.PG.Adapter)
		group.Name = "Guest"
		group.Note = "test note"
		group.UniqueId = sql.RandomCapitalString(15)
		group.CreatedBy = 1
		group.UpdatedBy = 1
		assert.NoError(t, group.Insert(), `failed to insert a new group for public station`)

		t.Run(`insertPublicStation`, func(t *testing.T) {
			station := NewStationMutator(sql.PG.Adapter)
			station.Name = `Test Public Station`
			station.IMEI = sql.RandomNumString(15)
			station.LastSubmittedAt = time.Now()
			station.LastLevelSensor = 1.439
			station.Longitude = 116.324944
			station.Latitude = -8.650979
			station.GroupID = group.Id
			station.Public = true
			assert.NoError(t, station.DoInsert(), `failed to insert a new public station`)

			t.Run(`findIdByImei`, func(t *testing.T) {
				staId := FindId_ByImei(station.IMEI)
				t.Log(`Station find by IMEI : `, staId)
			})

			lastSubmittedStr := station.LastSubmittedAt.Format(time.DateTime)

			t.Run(`checkDuplicateLog`, func(t *testing.T) {
				staLogId := CheckDuplicateLog(lastSubmittedStr, int64(station.Id))
				t.Log(`Duplicate station log ID:`, staLogId)
			})

			t.Run(`findStationByCoordOrImei`, func(t *testing.T) {
				res := FindStation_ByCoordOrImei(F.ToS(station.Latitude), F.ToS(station.Longitude), station.IMEI)

				t.Log(`Station by Coord or IMEI: `, X.ToJsonPretty(res))
			})

			t.Run(`averageLevelByStationBySnap`, func(t *testing.T) {
				res := AverageLevel_ByStationBySnap(int64(station.Id), 15)
				t.Log(`Average level by station by snap:`, X.ToJsonPretty(res))
			})

			t.Run(`allPublic`, func(t *testing.T) {
				res := AllPublic()
				t.Log(`All Public Stations: `, X.ToJsonPretty(res))
			})

			t.Run(`allPublicAsMap`, func(t *testing.T) {
				res := AllPublic_AsMap()
				t.Log(`All Public Stations as map: `, X.ToJsonPretty(res))
			})

			t.Run(`rawLevelAfterIntervalByStation`, func(t *testing.T) {
				res := RawLevelAfterInterval_ByStation(int64(station.Id), `1 hour`)
				t.Log(`Raw level after internal by station: `, res)
			})

			t.Run(`lastLogWithPowerAccelByStation`, func(t *testing.T) {
				res := LastLogWithPowerAccel_ByStation(int64(station.Id))
				t.Log(`Last log with power access by station: `, X.ToJsonPretty(res))
			})

			t.Run(`lastLogAllByStation`, func(t *testing.T) {
				res := LastLogAll_ByStation(int64(station.Id))
				t.Log(`lastLogAllByStation`, X.ToJsonPretty(res))
			})

			t.Run(`IsPublicStation`, func(t *testing.T) {
				isPublic := IsPublicStation(int64(station.Id))
				t.Log(`Is station `+station.Name+` public: `, isPublic)
			})

			t.Run(`lastLogByStation`, func(t *testing.T) {
				res := LastLog_ByStation(int64(station.Id))
				t.Log(`Last Log by Station: `, X.ToJsonPretty(res))
			})
		})
	})

	t.Run(`activeStationCount`, func(t *testing.T) {
		total := ActiveStation_Count()
		t.Log(`Total Active Station: `, total)
	})

	t.Run(`checkLastSubmitByMinute`, func(t *testing.T) {
		res := Check_LastSubmit_ByMinute(10)
		t.Log(`Last Submit by minute: `, X.ToJsonPretty(res))
	})
}
