package sql

import (
	"crypto/tls"
	dbsql "database/sql"
	"fmt"
	"os"
	"time"

	"github.com/ClickHouse/clickhouse-go/v2"
	"github.com/jmoiron/sqlx"
	"github.com/kokizzu/gotro/D/Ch"
	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/W"
)

var WEBMASTER_EMAILS = M.SS{
	`kiswono@gmail.com`: `Kiswono Prayogo`,
	//`mcien02@gmail.com`: `Michael`,
	//`dikaiyosh@gmail.com`:         `Dikaimin`,
	//`ahmad.fajar260695@gmail.com`: `Ahmad Fajar Prasetiyo`,
	//`haries.akbar@gmail.com`:      `Haries Maulana Akbar`,
	`joshjosman@gmail.com`:        `Parluhutan Manurung`, // boss
	`ida.sianipar@gmail.com`:      `Farida Sianipar`,     // istrinya
	`joshuabonasuhul@hotmail.com`: `Joshua Bonasuhul`,    // anaknya
	//`phamhoangtien1987@gmail.com`: `Pham Hoang Tien`,
	`muhamad.alfan01@gmail.com`: `Muhamad Alfan`,
	`ahmadhabibi7159@gmail.com`: `Ahmad Habibi`,
}

const SUPPORT_EMAIL = `luwesofficial@gmail.com`
const DEBUGGER_EMAIL = `kiswono+luwes@gmail.com`

var PROJECT_NAME string
var DOMAIN string
var GROUP_ID string

var PG *Pg.RDBMS
var CH *Ch.Adapter

var IS_USE_CLICKHOUSE bool
var DOUBLE_WRITE_DB bool

func init() {
	//PG = Pg.NewConn(`geo`, `geo`)
	W.Mailers = map[string]*W.SmtpConfig{
		``: {
			Name:     `Mailer Daemon`,
			Username: `xxx`,
			Password: `!`,
			Hostname: `xx`,
			Port:     587,
		}

	}
}

func ConnectPostgres() {
	opt := `host=127.0.0.1 port=5433 user=geo password=geopass dbname=geo sslmode=disable` // data3.luwesinovasimandiri.com
	conn := sqlx.MustConnect(`postgres`, opt)
	//conn.DB.SetMaxIdleConns(1)  // according to http://jmoiron.github.io/sqlx/#connectionPool
	conn.DB.SetMaxOpenConns(61) // TODO: change this according to postgresql.conf -3
	PG = &Pg.RDBMS{
		Name:    `geo2@dataluwes`,
		Adapter: conn,
	}
}

func ConnectClickhouse() {
	const chHost = `127.0.0.1`
	const chPort = `9003`
	const chUser = `luwesC`
	const chPass = `luwesPC`
	const chDB = `default`
	const chUseSsl = false

	hostPort := fmt.Sprintf("%s:%s", chHost, chPort)
	conf := &clickhouse.Options{
		Addr: []string{hostPort},
		Auth: clickhouse.Auth{
			Database: chDB,
			Username: chUser,
			Password: chPass,
		},
		Settings: clickhouse.Settings{
			`max_execution_time`: 60,
		},
		DialTimeout: 5 * time.Second,
		Compression: &clickhouse.Compression{
			Method: clickhouse.CompressionLZ4,
		},
	}
	if chUseSsl {
		conf.TLS = &tls.Config{
			InsecureSkipVerify: true,
		}
	}
	connectFunc := func() *dbsql.DB {
		conn := clickhouse.OpenDB(conf)
		conn.SetMaxIdleConns(5)
		conn.SetMaxOpenConns(10)
		conn.SetConnMaxLifetime(time.Hour)
		return conn
	}
	conn := connectFunc()
	err := conn.Ping()
	if L.IsError(err, `Failed to connect to ClickHouse database`) {
		os.Exit(1)
	}
	CH = &Ch.Adapter{
		DB:        conn,
		Reconnect: connectFunc,
	}
}

type NullTime struct {
	Time  time.Time `json:"time"`
	Valid bool      `json:"valid"`
}

func (nt *NullTime) Scan(value any) error {
	sqlNullTime := dbsql.NullTime{}
	if err := sqlNullTime.Scan(value); err != nil {
		return err
	}
	nt.Time = sqlNullTime.Time
	nt.Valid = sqlNullTime.Valid
	return nil
}

func (nt NullTime) Value() (any, error) {
	if !nt.Valid {
		return nil, nil
	}
	return nt.Time, nil
}
