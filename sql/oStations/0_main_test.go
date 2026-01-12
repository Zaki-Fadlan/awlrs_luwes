package oStations

import (
	dbsql "database/sql"
	"fmt"
	"log"
	"luwes/sql"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/ClickHouse/clickhouse-go/v2"
	"github.com/jmoiron/sqlx"
	"github.com/kokizzu/gotro/D/Ch"
	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/L"
	_ "github.com/lib/pq"
	"github.com/ory/dockertest/v3"
	"github.com/ory/dockertest/v3/docker"
)

const (
	pgUser     = `geo`
	pgPassword = `geopass`
	pgDB       = `geo`
)

func TestMain(m *testing.M) {
	pool, err := dockertest.NewPool(``)
	L.PanicIf(err, `could not construct pool`)

	err = pool.Client.Ping()
	L.PanicIf(err, `could not connect to Docker`)

	path, _ := filepath.Abs(`../init.sql`)

	pg, err := pool.RunWithOptions(&dockertest.RunOptions{
		Repository: `postgres`,
		Tag:        `16`,
		Env: []string{
			`POSTGRES_USER=` + pgUser,
			`POSTGRES_PASSWORD=` + pgPassword,
			`POSTGRES_DB=` + pgDB,
		},
		Mounts: []string{path + ":/docker-entrypoint-initdb.d/init.sql"},
	}, func(hc *docker.HostConfig) {
		hc.AutoRemove = true
		hc.RestartPolicy = docker.RestartPolicy{
			Name: `no`,
		}
	})
	L.PanicIf(err, "dockertest postgres: could not start resource")

	postgresPort := pg.GetPort("5432/tcp")
	_ = os.Setenv("POSTGRES_PORT", postgresPort)

	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		`127.0.0.1`, postgresPort, pgUser, pgPassword, pgDB,
	)

	var testDb *sqlx.DB
	for {
		testDb, err = sqlx.Connect("postgres", connStr)
		if err != nil {
			log.Print(`waiting for postgres to start: `, err)
			time.Sleep(time.Second)
			continue
		}

		sql.PG = &Pg.RDBMS{
			Name:    `geo2@dataluwes`,
			Adapter: testDb,
		}
		log.Println("Connected to PostgreSQL on port " + postgresPort)
		break
	}
	L.PanicIf(err, "could not connect to postgres")

	ch, err := pool.RunWithOptions(&dockertest.RunOptions{
		Repository: `clickhouse/clickhouse-server`,
		Tag:        `23.11.2.11`,
		Env: []string{
			`CLICKHOUSE_USER=luwesC`,
			`CLICKHOUSE_PASSWORD=luwesPC`,
			`CLICKHOUSE_DB=luwesDB`,
		},
	})
	L.PanicIf(err, "dockertest clickhouse: could not start resource")

	clickhousePort := ch.GetPort("9000/tcp")

	chHostPort := "127.0.0.1:" + clickhousePort
	chConf := &clickhouse.Options{
		Addr: []string{chHostPort},
		Auth: clickhouse.Auth{
			Database: "default",
			Username: "luwesC",
			Password: "luwesPC",
		},
		Settings: clickhouse.Settings{
			`max_execution_time`: 60,
		},
		DialTimeout: 5 * time.Second,
		Compression: &clickhouse.Compression{
			Method: clickhouse.CompressionLZ4,
		},
	}

	connectFunc := func() *dbsql.DB {
		conn := clickhouse.OpenDB(chConf)
		conn.SetMaxIdleConns(5)
		conn.SetMaxOpenConns(10)
		conn.SetConnMaxLifetime(time.Hour)
		return conn
	}

	for {
		chConn := connectFunc()
		if chConn.Ping() != nil {
			log.Print(`waiting for clickhouse to start: `, err)
			time.Sleep(time.Second)
			continue
		}
		sql.CH = &Ch.Adapter{
			DB:        chConn,
			Reconnect: connectFunc,
		}
		log.Println("Connected to ClickHouse on port " + clickhousePort)

		break
	}

	createStationLogTableClickhouse()

	LoadChTimedBuffer()

	var exitCode int
	defer func() {
		os.Exit(exitCode)
	}()

	defer pg.Close()
	// defer ch.Close()

	exitCode = m.Run()
}

func createChTable(a *Ch.Adapter, tableName Ch.TableName, props *Ch.TableProp) bool {
	ok := a.UpsertTable(tableName, props)
	if !ok {
		L.Print(`Upsert table failed: ` + tableName)
	}
	return ok
}

func createStationLogTableClickhouse() {
	prop := &Ch.TableProp{
		Fields: []Ch.Field{
			{Name: `created_at`, Type: Ch.DateTime},
			{Name: `updated_at`, Type: Ch.DateTime},
			{Name: `submitted_at`, Type: Ch.DateTime},
			{Name: `sequence`, Type: Ch.UInt32},
			{Name: `level_sensor`, Type: Ch.Float64},
			{Name: `accel_x`, Type: Ch.Float64},
			{Name: `accel_y`, Type: Ch.Float64},
			{Name: `accel_z`, Type: Ch.Float64},
			{Name: `power_current`, Type: Ch.Float64},
			{Name: `ip_address`, Type: Ch.String},
			{Name: `log_type`, Type: Ch.UInt32},
			{Name: `station_id`, Type: Ch.UInt32},
			{Name: `power_voltage`, Type: Ch.Float64},
			{Name: `data`, Type: Ch.String},
			{Name: `temperature`, Type: Ch.Float64},
			{Name: `wind_speed`, Type: Ch.Float64},
			{Name: `soil_moisture`, Type: Ch.Float64},
			{Name: `wind_direction`, Type: Ch.Float64},
			{Name: `raindrop`, Type: Ch.Float64},
			{Name: `humidity`, Type: Ch.UInt32},
			{Name: `barometric_pressure`, Type: Ch.Float64},
			{Name: `wind_speed_average`, Type: Ch.Float64},
			{Name: `wind_gust`, Type: Ch.Float64},
			{Name: `wind_direction_average`, Type: Ch.Float64},
			{Name: `rain_rate`, Type: Ch.Float64},
		},
		Engine:     Ch.ReplacingMergeTree,
		Partitions: []string{`station_id`},
		Orders:     []string{`station_id`, `submitted_at`},
	}

	ok := createChTable(sql.CH, Ch.TableName(`station_logs`), prop)
	if ok {
		// Create station_hours_mv Materialized View
		ok := sql.CH.CreateMaterializedViews(`station_hours_mv`, &Ch.MVProp{
			SourceTable: `station_logs`,
			SourceColumns: []string{
				`left(toString(submitted_at), 13) AS submitted_at_hour`,
				`*`,
			},
			Engine:     Ch.ReplacingMergeTree,
			Partitions: []string{`station_id`},
			Orders:     []string{`station_id`, `submitted_at_hour`},
		})
		if !ok {
			L.Print(`Create station_hours_mv Materialized View failed`)
		}

		// Create station_minutes_mv Materialized View
		ok = sql.CH.CreateMaterializedViews(`station_minutes_mv`, &Ch.MVProp{
			SourceTable: `station_logs`,
			SourceColumns: []string{
				`left(toString(submitted_at), 16) AS submitted_at_minute`,
				`*`,
			},
			Engine:     Ch.ReplacingMergeTree,
			Partitions: []string{`station_id`},
			Orders:     []string{`station_id`, `submitted_at_minute`},
		})
		if !ok {
			L.Print(`Create station_minutes_mv Materialized View failed`)
		}
	}
}
