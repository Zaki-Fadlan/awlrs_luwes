package oStations

import (
	"fmt"
	"luwes/sql"
	"os"
	"testing"

	"github.com/joho/godotenv"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/X"
)

func TestCompareStationMetrics(t *testing.T) {
	if X.ToBool(os.Getenv(`SKIP_CLICKHOUSE`)) {
		t.Skip(`Skip TestCompareStationMetrics`)
	}

	godotenv.Load(`../../.env`)
	sql.ConnectClickhouse()
	sql.ConnectPostgres()

	staIds := []int64{
		646, 451,
	}
	lastMods := []int64{
		1588105500, 1588108500,
	}
	options := []string{
		"1y",
	}
	maxDates := []int64{
		1728890500, 1588470600,
	}
	levelOnlies := []bool{
		false, // true,
	}
	timezoneGMTs := []int64{
		0, 8,
	}

	for _, staId := range staIds {
		for _, lastMod := range lastMods {
			for _, option := range options {
				for _, maxDate := range maxDates {
					for _, levelOnly := range levelOnlies {
						for _, tz := range timezoneGMTs {
							initial_rows_ch := CH_SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz(
								staId, lastMod, option, maxDate, levelOnly, ``, `r`, false, tz,
							)

							initial_rows_pg := SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz(
								staId, lastMod, option, maxDate, levelOnly, ``, `r`, false, tz,
							)

							lenRowsCh := len(initial_rows_ch)
							lenRowsPg := len(initial_rows_pg)

							if lenRowsCh == lenRowsPg && (lenRowsCh > 0 && lenRowsPg > 0) {
								for idx := 0; idx < lenRowsCh-1; idx++ {
									isMatchValue(idx, KeySubmittedAt,
										X.ToF(initial_rows_ch[idx][KeySubmittedAt]),
										X.ToF(initial_rows_pg[idx][KeySubmittedAt]),
									)

									isMatchValue(idx, KeyLevelSensor,
										X.ToF(initial_rows_ch[idx][KeyLevelSensor]),
										X.ToF(initial_rows_pg[idx][KeyLevelSensor]),
									)

									isMatchValue(idx, KeyAccelX,
										X.ToF(initial_rows_ch[idx][KeyAccelX]),
										X.ToF(initial_rows_pg[idx][KeyAccelX]),
									)

									isMatchValue(idx, KeyAccelY,
										X.ToF(initial_rows_ch[idx][KeyAccelY]),
										X.ToF(initial_rows_pg[idx][KeyAccelY]),
									)

									isMatchValue(idx, KeyAccelZ,
										X.ToF(initial_rows_ch[idx][KeyAccelZ]),
										X.ToF(initial_rows_pg[idx][KeyAccelZ]),
									)

									isMatchValue(idx, KeyBarometricPressure,
										X.ToF(initial_rows_ch[idx][KeyBarometricPressure]),
										X.ToF(initial_rows_pg[idx][KeyBarometricPressure]),
									)

									isMatchValue(idx, KeyHumidity,
										X.ToF(initial_rows_ch[idx][KeyHumidity]),
										X.ToF(initial_rows_pg[idx][KeyHumidity]),
									)

									isMatchValue(idx, KeyPowerCurrent,
										X.ToF(initial_rows_ch[idx][KeyPowerCurrent]),
										X.ToF(initial_rows_pg[idx][KeyPowerCurrent]),
									)

									isMatchValue(idx, KeyPowerVoltage,
										X.ToF(initial_rows_ch[idx][KeyPowerVoltage]),
										X.ToF(initial_rows_pg[idx][KeyPowerVoltage]),
									)

									isMatchValue(idx, KeyRainRate,
										X.ToF(initial_rows_ch[idx][KeyRainRate]),
										X.ToF(initial_rows_pg[idx][KeyRainRate]),
									)

									isMatchValue(idx, KeyRaindrop,
										X.ToF(initial_rows_ch[idx][KeyRaindrop]),
										X.ToF(initial_rows_pg[idx][KeyRaindrop]),
									)

									isMatchValue(idx, KeyTemperature,
										X.ToF(initial_rows_ch[idx][KeyTemperature]),
										X.ToF(initial_rows_pg[idx][KeyTemperature]),
									)

									isMatchValue(idx, KeyWindDirection,
										X.ToF(initial_rows_ch[idx][KeyWindDirection]),
										X.ToF(initial_rows_pg[idx][KeyWindDirection]),
									)

									isMatchValue(idx, KeyWindDirectionAverage,
										X.ToF(initial_rows_ch[idx][KeyWindDirectionAverage]),
										X.ToF(initial_rows_pg[idx][KeyWindDirectionAverage]),
									)

									isMatchValue(idx, KeyWindGust,
										X.ToF(initial_rows_ch[idx][KeyWindGust]),
										X.ToF(initial_rows_pg[idx][KeyWindGust]),
									)

									isMatchValue(idx, KeyWindSpeed,
										X.ToF(initial_rows_ch[idx][KeyWindSpeed]),
										X.ToF(initial_rows_pg[idx][KeyWindSpeed]),
									)

									isMatchValue(idx, KeyWindSpeedAverage,
										X.ToF(initial_rows_ch[idx][KeyWindSpeedAverage]),
										X.ToF(initial_rows_pg[idx][KeyWindSpeedAverage]),
									)
								}
							} else {
								L.Print(`No data for station logs.........`)
							}
						}
					}
				}
			}
		}
	}
}

func isMatchValue(idx int, key string, valueCh, valuePg any) {
	if valueCh == valuePg {
		fmt.Println(`[` + I.ToS(int64(idx)) + `] Ch ` + key + ` : ` + X.ToS(valueCh))
		fmt.Println(`[` + I.ToS(int64(idx)) + `] Pg ` + key + ` : ` + X.ToS(valuePg))

		return
	}

	fmt.Println(`[` + I.ToS(int64(idx)) + `] ` + key + ` data mismatch: CH=` + X.ToS(valueCh) + ` PG=` + X.ToS(valuePg))
}
