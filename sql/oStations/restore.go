package oStations

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"luwes/sql"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fatih/color"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/X"
	"github.com/pierrec/lz4/v4"
)

func getBackupFiles(imei string) (files []string, err error) {
	err = filepath.Walk(backupDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasPrefix(info.Name(), `station_`+imei+`_`) {
			files = append(files, info.Name())
		}

		return nil
	})
	if err != nil {
		L.LOG.Error("error walking through directory:", err)
		return
	}

	if len(files) == 0 {
		err = errors.New("no backup files available")
		return
	}

	return
}

func RestoreStationByImei(imei string) {
	files, err := getBackupFiles(imei)
	if err != nil {
		L.LOG.Error(err)
		return
	}

	for idx, f := range files {
		filePath := (backupDir + "/" + f)

		if err := func() error {
			defer subTaskPrint(color.BlueString("[%d] Restoring file %s", (idx + 1), filePath))()

			file, err := os.Open(filePath)
			if err != nil {
				L.LOG.Error("failed to open file: ", err)
				return err
			}
			defer file.Close()

			reader := lz4.NewReader(file)
			scanner := bufio.NewScanner(reader)

			stat := &sql.ImporterStat{}
			defer stat.Print(`last`)

			var idxLine int = 0
			for scanner.Scan() {
				stat.Total++
				stat.Print()
				idxLine++

				line := scanner.Text()

				if idxLine == 1 {
					stat.Total--
					var out Station
					err := json.Unmarshal([]byte(line), &out)
					if err != nil {
						L.LOG.Error(err)
						return err
					}
					station := NewStationMutator(sql.PG.Adapter)
					station.IMEI = out.IMEI
					if !station.FindByIMEI() {
						station.Name = out.Name
						station.LastSubmittedAt = out.LastSubmittedAt
						station.LastLevelSensor = out.LastLevelSensor
						station.Longitude = out.Longitude
						station.Latitude = out.Latitude
						station.GroupID = out.GroupID
						return station.DoInsert()
					}
					fmt.Printf("[%d] Station: \n", idxLine)
					fmt.Println(X.ToJsonPretty(station))
					continue
				}

				var stationLog StationLog
				err := json.Unmarshal([]byte(line), &stationLog)
				if err != nil {
					L.LOG.Error(err)
					return err
				}

				staLog := NewStationLogPq(sql.PG.Adapter)
				staLog.Id = stationLog.Id
				staLog.CreatedAt = stationLog.CreatedAt
				staLog.UpdatedAt = time.Now()
				staLog.DeletedAt = stationLog.DeletedAt
				staLog.SubmittedAt = stationLog.SubmittedAt
				staLog.Sequence = stationLog.Sequence
				staLog.LevelSensor = stationLog.LevelSensor
				staLog.AccelX = stationLog.AccelX
				staLog.AccelY = stationLog.AccelY
				staLog.AccelZ = stationLog.AccelZ
				staLog.PowerCurrent = stationLog.PowerCurrent
				staLog.IPAddress = stationLog.IPAddress
				staLog.LogType = stationLog.LogType
				staLog.StationId = stationLog.StationId
				staLog.PowerVoltage = stationLog.PowerVoltage
				staLogDataBye, err := json.Marshal(stationLog.Data)
				if err != nil {
					L.LOG.Error(err)
					return err
				}
				staLog.Data = string(staLogDataBye)
				staLog.IsDeleted = stationLog.IsDeleted
				staLog.Temperature = stationLog.Temperature
				staLog.WindSpeed = stationLog.WindSpeed
				staLog.SoilMoisture = stationLog.SoilMoisture
				staLog.WindDirection = stationLog.WindDirection
				staLog.RainDrop = stationLog.RainDrop
				staLog.Humidity = stationLog.Humidity
				staLog.BarometricPressure = stationLog.BarometricPressure
				staLog.WindSpeedAverage = stationLog.WindSpeedAverage
				staLog.WindGust = stationLog.WindGust
				staLog.WindDirectionAverage = stationLog.WindDirectionAverage
				staLog.RainRate = stationLog.RainRate

				if staLog.FindById() {
					if err := staLog.DoUpdateById(); err != nil {
						L.LOG.Error(err)
						return err
					}
					stat.Ok(true)
					continue
				}

				if err := staLog.DoInsert(); err != nil {
					L.LOG.Error(err)
					return err
				}

				stat.Ok(true)
			}

			return nil
		}(); err != nil {
			return
		}
	}
}

func subTaskPrint(str string) func() {
	startBlueStat := color.BlueString(`  [Start] ` + str)
	endBlueStat := color.BlueString(`  [End] ` + str)
	fmt.Println(startBlueStat)
	return func() {
		fmt.Println(endBlueStat)
	}
}
