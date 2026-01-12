package oStations

import (
	"fmt"
	"luwes/sql"
	"os"

	gosql "database/sql"

	"github.com/fatih/color"
	"github.com/goccy/go-json"
	"github.com/kokizzu/gotro/L"
	"github.com/pierrec/lz4/v4"
)

const backupDir = `./backup`

func getBackupStationFileOutput(imei string, offset, limit int) string {
	return fmt.Sprintf(
		"%s/station_%s_%d_%d.jsonline.lz4",
		backupDir, imei, offset, limit,
	)
}

func BackupStationLogByImei(imei string) {
	err := os.MkdirAll(backupDir, os.ModePerm)
	if err != nil {
		L.LOG.Error(`failed to create backup directory :`, err)
		return
	}

	station := NewStationMutator(sql.PG.Adapter)
	station.IMEI = imei

	if !station.FindByIMEI() {
		L.LOG.Error(fmt.Sprintf(`Station with IMEI %s not found`, imei))
		return
	}

	stationLog := NewStationLogPq(sql.PG.Adapter)

	totalRows, err := stationLog.CountTotalLogsByStationId(station.Id)
	if err != nil {
		L.LOG.Error(err)
		return
	}

	batchSize := 10_000

	for offset := 0; offset < totalRows; offset += batchSize {
		err := func() error {
			outputFile := getBackupStationFileOutput(imei, offset, batchSize)
			file, err := os.Create(outputFile)
			if err != nil {
				return err
			}
			defer file.Close()

			lz4Writer := lz4.NewWriter(file)
			defer lz4Writer.Close()

			stationJsonRow, err := json.Marshal(station)
			if err != nil {
				L.LOG.Error(`Err json.Marshal(station): `, err)
				return err
			}

			_, err = lz4Writer.Write(append(stationJsonRow, '\n'))
			if err != nil {
				L.LOG.Error(`Err lz4Writer.Write(append(stationJsonRow, '\n')): `, err)
				return err
			}

			err = stationLog.FindLogsByStationIdWithOffsetWithLimit(int64(station.Id), offset, batchSize, func(rows *gosql.Rows) error {
				for rows.Next() {
					var row StationLog
					err := rows.Scan(
						&row.Id,
						&row.CreatedAt,
						&row.UpdatedAt,
						&row.DeletedAt,
						&row.SubmittedAt,
						&row.Sequence,
						&row.LevelSensor,
						&row.AccelX,
						&row.AccelY,
						&row.AccelZ,
						&row.PowerCurrent,
						&row.IPAddress,
						&row.LogType,
						&row.StationId,
						&row.PowerVoltage,
						&row.Data,
						&row.IsDeleted,
						&row.Temperature,
						&row.WindSpeed,
						&row.SoilMoisture,
						&row.WindDirection,
						&row.RainDrop,
						&row.Humidity,
						&row.BarometricPressure,
						&row.WindSpeedAverage,
						&row.WindGust,
						&row.WindDirectionAverage,
						&row.RainRate,
					)
					if err != nil {
						L.LOG.Error(`Err rows.Scan: `, err)
						return err
					}
					jsonRow, err := json.Marshal(row)
					if err != nil {
						L.LOG.Error(`Err json.Marshal(row): `, err)
						return err
					}

					_, err = lz4Writer.Write(append(jsonRow, '\n'))
					if err != nil {
						L.LOG.Error(`Err lz4Writer.Write(append(jsonRow, '\n')): `, err)
						return err
					}
				}

				return nil
			})
			if err != nil {
				return err
			}

			fmt.Println(color.GreenString("[OK] Backed up to file " + outputFile))

			return nil
		}()
		if err != nil {
			L.LOG.Error(err)
			return
		}
	}
}

func BackupStationLogByStationId(stationId int) {
	err := os.MkdirAll(backupDir, os.ModePerm)
	if err != nil {
		L.LOG.Error(`failed to create backup directory :`, err)
		return
	}

	station := NewStationMutator(sql.PG.Adapter)
	station.Id = stationId

	if !station.FindById() {
		L.LOG.Error(fmt.Sprintf(`Station with Station ID %d not found`, stationId))
		return
	}

	stationLog := NewStationLogPq(sql.PG.Adapter)

	totalRows, err := stationLog.CountTotalLogsByStationId(station.Id)
	if err != nil {
		L.LOG.Error(err)
		return
	}

	batchSize := 10_000

	for offset := 0; offset < totalRows; offset += batchSize {
		err := func() error {
			outputFile := getBackupStationFileOutput(station.IMEI, offset, batchSize)
			file, err := os.Create(outputFile)
			if err != nil {
				return err
			}
			defer file.Close()

			lz4Writer := lz4.NewWriter(file)
			defer lz4Writer.Close()

			stationJsonRow, err := json.Marshal(station)
			if err != nil {
				L.LOG.Error(`Err json.Marshal(station): `, err)
				return err
			}

			_, err = lz4Writer.Write(append(stationJsonRow, '\n'))
			if err != nil {
				L.LOG.Error(`Err lz4Writer.Write(append(stationJsonRow, '\n')): `, err)
				return err
			}

			err = stationLog.FindLogsByStationIdWithOffsetWithLimit(int64(station.Id), offset, batchSize, func(rows *gosql.Rows) error {
				for rows.Next() {
					var row StationLog
					err := rows.Scan(
						&row.Id,
						&row.CreatedAt,
						&row.UpdatedAt,
						&row.DeletedAt,
						&row.SubmittedAt,
						&row.Sequence,
						&row.LevelSensor,
						&row.AccelX,
						&row.AccelY,
						&row.AccelZ,
						&row.PowerCurrent,
						&row.IPAddress,
						&row.LogType,
						&row.StationId,
						&row.PowerVoltage,
						&row.Data,
						&row.IsDeleted,
						&row.Temperature,
						&row.WindSpeed,
						&row.SoilMoisture,
						&row.WindDirection,
						&row.RainDrop,
						&row.Humidity,
						&row.BarometricPressure,
						&row.WindSpeedAverage,
						&row.WindGust,
						&row.WindDirectionAverage,
						&row.RainRate,
					)
					if err != nil {
						L.LOG.Error(`Err rows.Scan: `, err)
						return err
					}

					jsonRow, err := json.Marshal(row)
					if err != nil {
						L.LOG.Error(`Err json.Marshal(row): `, err)
						return err
					}

					_, err = lz4Writer.Write(append(jsonRow, '\n'))
					if err != nil {
						L.LOG.Error(`Err lz4Writer.Write(append(jsonRow, '\n')): `, err)
						return err
					}
				}

				return nil
			})
			if err != nil {
				return err
			}

			fmt.Println(color.GreenString("[OK] Backed up to file " + outputFile))

			return nil
		}()
		if err != nil {
			L.LOG.Error(err)
			return
		}
	}
}
