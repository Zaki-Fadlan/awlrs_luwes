package pgtest

import (
	"fmt"
	"log"
	"luwes/sql"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/jmoiron/sqlx"
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

	L.PanicIf(err, "could not start resource")

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

	var exitCode int
	defer func() {
		os.Exit(exitCode)
	}()

	defer pg.Close()

	exitCode = m.Run()
}
