package oStations

import (
	"bytes"
	"errors"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"

	//"math/rand"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"luwes/sql"
	"luwes/sql/oPredictions"

	"github.com/goccy/go-json"
	"github.com/kokizzu/gotro/A"
	"github.com/kokizzu/gotro/B"
	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/F"
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/L"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"
	"github.com/kokizzu/gotro/T"
	"github.com/kokizzu/gotro/W"
	"github.com/kokizzu/gotro/X"
	"github.com/nfnt/resize"
)

const TABLE = `stations`

var TM_MASTER Pg.TableModel
var SELECT = ``
var TM_MASTER_OWNER Pg.TableModel

const (
	AGG_NONE   = `none`
	AGG_MINUTE = `minute`
	AGG_HOUR   = `hour`
)

// freelancer change 20200110
/*const LAST_QUERY = `
SELECT x1.id, x2.submitted_at "last_update", x2.level_sensor "level"
FROM stations x1
CROSS JOIN LATERAL (
	SELECT submitted_at, level_sensor
	FROM station_logs
	WHERE station_id = x1.id
	ORDER BY submitted_at DESC NULLS LAST
	LIMIT 1
) x2
WHERE x1.is_deleted = false
`*/
const LAST_QUERY = ` 
SELECT x1.id, x1.last_submitted_at "updated_at", x1.last_level_sensor "level"
FROM stations x1
WHERE x1.is_deleted = false
`

var Z func(string) string
var ZZ func(string) string
var ZJ func(string) string
var ZB func(bool) string
var ZI func(int64) string
var ZLIKE func(string) string
var ZT func(strs ...string) string

func init() {
	Z = S.Z
	ZB = S.ZB
	ZZ = S.ZZ
	ZJ = S.ZJJ
	ZI = S.ZI
	ZT = S.ZT
	ZLIKE = S.ZLIKE

	common_fields := []Pg.FieldModel{
		{Key: `id`},
		{Key: `is_deleted`},
		{Key: `created_at`, Type: `datetime`},
		{Label: `Name`, Key: `name`, NotDataCol: true},
		{Label: `Group`, Key: `group_id`, NotDataCol: true, Type: `select`, HtmlSubType: `Groups`},
		{Label: `Longitude`, Key: `long`, Type: `float`, NotDataCol: true},
		{Label: `Latitude`, Key: `lat`, Type: `float`, NotDataCol: true},
		{Label: `Min Filter`, Key: `min_filter`, Type: `float`, NotDataCol: true},
		{Label: `Max Filter`, Key: `max_filter`, Type: `float`, NotDataCol: true},
		{Label: `Alert Line`, Key: `alert_line`, FormTooltip: `separate with comma`},
		{Label: `Public?`, Key: `public`, Type: `bool`, NotDataCol: true},
		{Label: `Public DL?`, Key: `public_dl`, Type: `bool`, NotDataCol: true},
		//{Label: `E-Mail`, Key: `email`, NotDataCol: true},
		{Label: `Location`, Key: `location`, NotDataCol: true},
		{Label: `History`, Key: `history`, Type: `textarea`, NotDataCol: true},
		{Label: `Picture Time`, Key: `picture_time`, Type: `datetime`, FormHide: true},
		{Label: `Picture Size`, Key: `picture_size`, Type: `integer`, FormHide: true},
		{Label: `North Picture Time`, Key: `north_time`, Type: `datetime`, FormHide: true},
		{Label: `North Picture Size`, Key: `north_size`, Type: `integer`, FormHide: true},
		{Label: `South Picture Time`, Key: `south_time`, Type: `datetime`, FormHide: true},
		{Label: `South Picture Size`, Key: `south_size`, Type: `integer`, FormHide: true},
		{Label: `West Picture Time`, Key: `west_time`, Type: `datetime`, FormHide: true},
		{Label: `West Picture Size`, Key: `west_size`, Type: `integer`, FormHide: true},
		{Label: `East Picture Time`, Key: `east_time`, Type: `datetime`, FormHide: true},
		{Label: `East Picture Size`, Key: `east_size`, Type: `integer`, FormHide: true},
		{Label: `Install Date`, Key: `install_date`, Type: `date`},
		{Label: `Install Team`, Key: `install_team`, Type: `text`},
		{Label: `Supervisor Contact`, Key: `supervisor_contact`, Type: `textarea`},
		{Label: `Operator Contact`, Key: `operator_contact`, Type: `textarea`},
		{Label: `Time Zone`, Key: `tz`, Type: `number`},
	}

	TM_MASTER = Pg.TableModel{
		CacheName: TABLE + `_STATIONS_MASTER`,
		Fields: append([]Pg.FieldModel{
			{Label: `IMEI`, Key: `imei`, NotDataCol: true},
			{Label: `Picture`, Key: `picture`, Type: `image_readonly`, FormHide: true},
			{Label: `North Picture`, Key: `north`, Type: `image_readonly`, FormHide: true},
			{Label: `South Picture`, Key: `south`, Type: `image_readonly`, FormHide: true},
			{Label: `West Picture`, Key: `west`, Type: `image_readonly`, FormHide: true},
			{Label: `East Picture`, Key: `east`, Type: `image_readonly`, FormHide: true},
			{Label: `Last Level`, Key: `level`, Type: `float`, FormHide: true, CustomQuery: `x2.level`},
			{Label: `Last Submit`, Key: `updated_at`, Type: `datetime`, FormHide: true, CustomQuery: `EXTRACT( EPOCH FROM x2.last_update )`},
			{Label: `Embed HTML`, Key: `embed_html`, Type: `textarea`},
			{Label: `Show Embed`, Key: `show_embed`, Type: `bool`},
		}, common_fields...),
	}

	TM_MASTER_OWNER = Pg.TableModel{
		CacheName: TABLE + `_STATIONS_MASTER_OWNER`,
		Fields: append([]Pg.FieldModel{
			{Label: `Picture`, Key: `picture`, Type: `image`, FormHide: true},
			{Label: `North Picture`, Key: `north`, Type: `image`, FormHide: true},
			{Label: `South Picture`, Key: `south`, Type: `image`, FormHide: true},
			{Label: `West Picture`, Key: `west`, Type: `image`, FormHide: true},
			{Label: `East Picture`, Key: `east`, Type: `image`, FormHide: true},
			{Label: `Supervisor Contact`, Key: `supervisor_contact`, Type: `textarea`},
		}, common_fields...),
	}
	SELECT = TM_MASTER.Select()
}

// 2017-06-28 Haries
func CanAccess_ByUser_ByStation(user_id, sta_id int64, is_backoffice bool) bool {
	if is_backoffice {
		return true
	}
	query := ZT(I.ToS(user_id), I.ToS(sta_id)) + `
	SELECT COALESCE((
		SELECT COUNT(*)
		FROM stations
		WHERE id = ` + ZI(sta_id) + `
			AND (
				group_id = (
					SELECT group_id
					FROM users
					WHERE id = ` + ZI(user_id) + `
				)
				OR public
			)
	)>0,false)`
	return sql.PG.QBool(query)
}

// convertImageToJPEG converts from PNG to JPEG.
func ResizeImage_WithMaxSize(w io.Writer, r io.Reader, src_is_png bool, max_wh uint) error {
	var img image.Image
	var err error
	if src_is_png {
		img, err = png.Decode(r)
	} else {
		img, _, err = image.Decode(r)
	}
	if err != nil {
		return err
	}
	// resize
	rect := img.Bounds()
	point := rect.Size()
	nw, nh := uint(point.X), uint(point.Y)
	if nw > nh {
		if nw > max_wh {
			nh = nh * max_wh / nw
			nw = max_wh
		}
	} else {
		if nh > max_wh {
			nw = nw * max_wh / nh
			nh = max_wh
		}
	}
	img = resize.Resize(nw, nh, img, resize.Lanczos3)
	// encode to jpg
	return jpeg.Encode(w, img, &jpeg.Options{Quality: 100})
}

// 2016-08-04 Prayogo
func API_FileUpload_ByTable_ByContext_ByKey_ByPrefix(rm *W.RequestModel, table string, ctx *W.Context, req_key, prefix string) {
	key := rm.Posts.GetStr(`key`)
	if key == req_key {
		name, ext, content_type, reader := ctx.UploadedFile(`file`)
		if name == `` {
			rm.Ajax.Error(sql.ERR_007_UPLOAD_ERROR + ext)
			return
		}
		is_png := content_type == `image/png`
		if W.MIME2EXT[content_type] == `` {
			if key == `video` {
				if !(content_type == `application/octet-stream` && (ext == `.mov` || ext == `.mp4`)) {
					// allow mov video
					rm.Ajax.Error(sql.ERR_008_INVALID_CONTENT_TYPE + content_type + ` should be mov or mp4`)
					return
				}
			} else if !(content_type == `image/jpeg` || is_png) {
				rm.Ajax.Error(sql.ERR_008_INVALID_CONTENT_TYPE + content_type + ` should be jpg or png`)
				return
			}
		}
		save_dir := ``
		filename := key + ext
		dir := key
		switch key {
		case `north`, `south`, `west`, `east`:
			dir = `picture`
			fallthrough
		default:
			save_dir = T.DateStr()[:7] + `/` // year month
			filename = save_dir + prefix + rm.Id + `_` + T.Filename() + `_` + S.RandomPassword(4) + ext
		}

		time_key := key + `_time`
		size_key := key + `_size`

		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			dm := Pg.NewRow(tx, table, rm)

			// create directory (when not exists)
			rel_path := dir + `s/`
			pub_dir := ctx.Engine.BaseDir + W.PUBLIC_SUBDIR + rel_path
			err := os.MkdirAll(pub_dir+save_dir, os.ModePerm)
			msg := sql.ERR_501_CANNOT_CREATE_DIR
			if L.IsError(err, msg, pub_dir+save_dir) {
				return rm.Ajax.Error(msg + save_dir)
			}

			// create the file
			filepath := pub_dir + filename
			writer, err := os.Create(filepath)
			msg = sql.ERR_502_CANNOT_CREATE_FILE
			if L.IsError(err, msg, filepath) {
				return rm.Ajax.Error(msg + filename)
			}
			defer writer.Close()

			// convert/copy file
			if key == `profpic` {
				err = ResizeImage_WithMaxSize(writer, reader, is_png, 256) // to PNG
				msg = sql.ERR_121_CONVERT_FILE
			} else {
				_, err = io.Copy(writer, reader) // first param: size copied
				msg = sql.ERR_503_CANNOT_MOVE_FILE
			}
			if L.IsError(err, msg, filepath) {
				return rm.Ajax.Error(msg + filename)
			}

			// check size copied
			stat, err := writer.Stat()
			size := stat.Size()
			msg = sql.ERR_122_STAT_FILE
			if L.IsError(err, msg, filepath) {
				return rm.Ajax.Error(msg + filename)
			}

			// save to database
			dm.SetValStr(key, `/`+rel_path+filename)
			dm.SetValEpoch(time_key)
			dm.SetVal(size_key, size)
			dm.SetVal(`uploader_id`, rm.Actor)
			if req_key == `video` {
				dm.Unset(`youtube`)
				dm.Unset(`youtube_response`)
				dm.Unset(`youtube_preview`)
				dm.Unset(`youtube_preview_response`)
			}
			dm.UpsertRow()
			return rm.Ajax.LastError()
		})
	} else {
		// @API-END
		rm.Ajax.Error(sql.ERR_002_INVALID_UPLOAD_KEY + key + `, should be: ` + req_key)
	}
}

// 2017-06-25 Prayogo
func API_GuestOwner_SensorData_ByIsGuest(rm *W.RequestModel, is_guest bool) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	if sta_id == 0 {
		sta_id = rm.Ctx.Posts().GetInt(`sta_id`)
	}
	last_mod := rm.Posts.GetInt(`last_mod`)
	option := rm.Posts.GetStr(`option`)
	max_date := rm.Posts.GetInt(`max_date`)
	var result A.MSX
	if sql.IS_USE_CLICKHOUSE {
		result = CH_SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz(sta_id, last_mod, option, max_date, is_guest, ``, `r`, false, 0)
	} else {
		result = SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz(sta_id, last_mod, option, max_date, is_guest, ``, `r`, false, 0)
	}
	rm.Ajax.Set(`result`, result)

	if rm.Posts.GetInt(`predict_counter`)%oPredictions.MULTIPLIER == 1 {
		oPredictions.API_GuestOwner_Prediction(rm, result)
	}
}

// 2017-09-16 Michael
func AllStation_AsMap() M.SS {
	ram_key := ZT()
	query := ram_key + `
	SELECT id, "name"
	FROM stations
	WHERE is_deleted = false
`
	return sql.PG.QStrStrMap(query)
}

// 2017-05-30 Prayogo
func AllPublic() A.MSX {
	ram_key := ZT()
	query := ram_key + `
	SELECT id, "name"
	FROM stations
	WHERE is_deleted = false
		AND (
			public = true
			OR group_id = (
				SELECT id
				FROM groups
				WHERE "name" = 'Guest'
			)
		)
		` + sql.GroupOnly(`group_id`) + `
	ORDER BY 2
	`
	return sql.PG.CQMapArray(TABLE, ram_key, query)
}

// 2017-06-11 Prayogo
func AllPublic_AsMap() M.SX {
	ram_key := ZT()
	query := ram_key + ` -- o_stations.go:301 AllPublic
	SELECT id
		, "name"
		, lat
		, "long"
	FROM stations
	WHERE is_deleted = false
		AND (
			public = true
			OR group_id = (
				SELECT id
				FROM groups
				WHERE "name" = 'Guest'
			)
		)
		` + sql.GroupOnly(`group_id`) + `
	ORDER BY 2
	`
	return sql.PG.CQStrMapMap(TABLE, ram_key, `id`, query)

}

// 2017-07-25 Prayogo
func LastSensorData_ByUser_IsBackoffice(user_id int64, is_bo bool) A.MSX {
	where_add := ``
	if !is_bo {
		where_add = `	AND x1.group_id = (
		SELECT group_id
		FROM users
		WHERE id = ` + ZI(user_id) + `
	)`
	}
	ram_key := ZT(I.ToS(user_id), B.ToS(is_bo))
	query := ram_key + LAST_QUERY + where_add + sql.GroupOnly(`x1.group_id`)

	fmt.Println(`query:`, query)
	return sql.PG.CQMapArray(`station_logs`, ram_key, query)
}

// 2017-06-25 Prayogo
func API_GuestOwner_LastSensorData_ByUser_ByIsBackoffice(rm *W.RequestModel, user_id int64, is_bo bool) {
	result := LastSensorData_ByUser_IsBackoffice(user_id, is_bo)
	rm.Ajax.Set(`result`, result)
}

// 2017-06-04 Prayogo
func AllPrivate_ByUser_ByIsBackoffice(user_id int64, is_bo bool) A.MSX {
	ram_key := ZT(I.ToS(user_id), B.ToS(is_bo))
	query := ``
	if is_bo {
		query = ram_key + `
	SELECT x1.id, COALESCE(x2.name || ': ','') || x1.name || (CASE WHEN x1.public THEN ' (public)' ELSE '' END) "name"
	FROM stations x1
		LEFT JOIN groups x2
			ON x1.group_id = x2.id
	WHERE x1.is_deleted = false
		` + sql.GroupOnly(`x1.group_id`) + `
	ORDER BY 2
	`
	} else {
		query = ram_key + `
	SELECT id, x1.name || (CASE WHEN x1.public THEN ' (public)' ELSE '' END) "name"
	FROM stations x1
	WHERE x1.is_deleted = false
		AND x1.group_id = (
				SELECT group_id
				FROM users
				WHERE id = ` + ZI(user_id) + `
			)
		` + sql.GroupOnly(`x1.group_id`) + `
	ORDER BY 2
	`
	}
	return sql.PG.CQMapArray(TABLE, ram_key, query)
}

// 2017-06-04 Prayogo
func AllPrivate_AsMap_ByUser_ByIsBackoffice(user_id int64, is_bo bool) M.SX {
	ram_key := ZT(I.ToS(user_id), B.ToS(is_bo))
	//L.Print(ram_key)
	query := ``
	if is_bo {
		query = ram_key + `
	SELECT x1.id
		, COALESCE(x2.name || ': ','') || x1.name || (CASE WHEN x1.public THEN ' (public)' ELSE '' END) "name"
		, x1.lat
		, x1.long
	FROM stations x1
		LEFT JOIN groups x2
			ON x1.group_id = x2.id
	WHERE x1.is_deleted = false
		` + sql.GroupOnly(`x1.group_id`) + `
	ORDER BY 2
	`
	} else {
		query = ram_key + `
	SELECT x1.id
		, x1.name || (CASE WHEN x1.public THEN ' (public)' ELSE '' END) "name"
		, x1.lat
		, x1.long
	FROM stations x1
	WHERE is_deleted = false
		AND group_id = (
				SELECT id
				FROM users
				WHERE id = ` + ZI(user_id) + `
			)
		` + sql.GroupOnly(`x1.group_id`) + `
	ORDER BY 2
	`
	}
	return sql.PG.CQStrMapMap(TABLE, ram_key, `id`, query)
}

// 2017-06-04 Haries
func Search_ByQueryParams(qp *Pg.QueryParams) {
	qp.RamKey = ZT(qp.Term)
	if qp.Term != `` {
		qp.Where += ` AND (
			x1.name ILIKE ` + ZLIKE(qp.Term) + `
			OR x1.imei LIKE ` + ZLIKE(qp.Term) + `
		)`
	}
	qp.From = `FROM ` + TABLE + ` x1
		LEFT JOIN (` + LAST_QUERY + `) x2
			ON x1.id = x2.id`
	qp.OrderBy = `x1.id`
	qp.Select = SELECT
	qp.SearchQuery_ByConn(sql.PG)
}

// 2017-06-04 Haries
func API_Superadmin_Search(rm *W.RequestModel) {
	qp := Pg.NewQueryParams(rm.Posts, &TM_MASTER)
	Search_ByQueryParams(qp)
	qp.ToAjax(rm.Ajax)
}

// 2017-06-04 Haries
func One_ByID(id int64) M.SX {
	ram_key := ZT(I.ToS(id))
	query := ram_key + `
		SELECT ` + SELECT + `
		FROM ` + TABLE + ` x1
			LEFT JOIN (` + LAST_QUERY + `) x2
				ON x1.id = x2.id
		WHERE x1.id = ` + ZI(id)
	return sql.PG.CQFirstMap(TABLE, ram_key, query)
}

// 2017-06-04 Haries
func API_OwnerSuperadmin_Form(rm *W.RequestModel) {
	rm.Ajax.SX = One_ByID(S.ToI(rm.Id))
}

// 2017-06-04 Haries
func API_OwnerSuperadmin_SaveDeleteRestore(rm *W.RequestModel) {
	if rm.Level.GetBool(`is_readonly`) {
		rm.Ajax.Error(`Readonly user may not edit the station`)
		return
	}

	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		dm := Pg.NewRow(tx, TABLE, rm) // NewPostlessData
		dm.SetNonData(`name`)
		dm.SetNonData(`long`)
		dm.SetNonData(`lat`)
		dm.SetNonData(`min_filter`)
		dm.SetNonData(`max_filter`)
		dm.SetNonData(`imei`)
		dm.SetNonData(`public`)
		dm.SetNonData(`public_dl`)
		dm.SetNonData(`location`)
		dm.SetNonData(`history`)
		dm.SetNonData(`group_id`)
		dm.SetFloat(`install_date`)
		dm.SetStr(`alert_line`)
		dm.SetStr(`install_team`)
		dm.SetStr(`supervisor_contact`)
		dm.SetStr(`operator_contact`)
		dm.SetStr(`embed_html`)
		dm.SetBool(`show_embed`)
		dm.UpsertRow()
		if !rm.Ajax.HasError() {
			dm.WipeUnwipe(rm.Action)
		}
		return rm.Ajax.LastError()
	})
}

// 2017-07-11 Haries
func SensorData_BySta_ByLastMod_ByOption_ByMaxDate_ByLevelOnly_ByAgg_ByRaw_IsLogFormat_ByTz(sta_id, last_mod int64, option string, max_date int64, level_only bool, agg string, rw string, raw_format bool, tz int64) A.MSX {
	ram_key := ZT(I.ToS(sta_id), I.ToS(last_mod), option, I.ToS(max_date), B.ToS(level_only), agg, rw, B.ToS(raw_format), I.ToS(tz))
	where_and_max_date := ``
	if max_date > 0 {
		where_and_max_date += ` AND EXTRACT(EPOCH FROM submitted_at) <= ` + I.ToS(max_date)
	}
	NewTableName := `station_logs_` + I.ToS(sta_id)
	table_exists := sql.PG.TableExists(NewTableName)
	where_and := S.If(!table_exists, ` AND x1.station_id = `+ZI(sta_id)) + `
 		` + where_and_max_date
	//AND x1.level_sensor >= COALESCE((SELECT min_filter FROM stations WHERE id = ` + ZI(sta_id) + `),-999999)
	//AND x1.level_sensor <= COALESCE((SELECT max_filter FROM stations WHERE id = ` + ZI(sta_id) + `),+999999)
	//last_mod_sql := `(SELECT COALESCE(EXTRACT(EPOCH FROM (MAX(submitted_at)- INTERVAL '%s')),0) FROM station_logs x1 WHERE 1=1)`
	//last_mod_sql := `(SELECT COALESCE(EXTRACT(EPOCH FROM (MAX(submitted_at)- INTERVAL '%s')),0) FROM station_logs x1 WHERE 1=1 ` + where_and + `)`
	last_mod_sql := `(SELECT COALESCE(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP- INTERVAL '%s')),0))`
	if last_mod == 0 {
		interval := ``
		switch option {
		case `6h`, `6hr`:
			interval = `6 hours`
		case `12h`, `12dr`:
			interval = `12 hours`
		case `1d`, `1dr`:
			interval = `1 day`
		case `3d`, `3dr`:
			interval = `3 days`
		case `7d`, `7dr`:
			interval = `7 days`
		case `30d`, `30dr`:
			interval = `30 days`
		case `1y`, `1yr`:
			interval = `1 year`
		default: // range
		}
		last_mod_sql = fmt.Sprintf(last_mod_sql, interval)
		//L.Print(last_mod_sql)
		last_mod_sql = sql.PG.QStr(last_mod_sql)
	} else {
		last_mod_sql = ZI(last_mod)
	}
	time_key := `EXTRACT(EPOCH FROM x1.submitted_at)`
	distinct_on := `` //`DISTINCT ON (2)` // bikin lemot
	if tz == 0 {
		if agg == `hour` || agg == `hh` {
			time_key = `(LEFT(x1.submitted_at::TEXT,13)||':00')`
		} else if agg == `minute` || agg == `mm` {
			time_key = `(LEFT(x1.submitted_at::TEXT,16))`
		} else if agg == `none` {
			time_key = `(LEFT(x1.submitted_at::TEXT,19))`
		} else {
			distinct_on = ``
		}
	} else {
		if agg == `hour` || agg == `hh` {
			time_key = `(LEFT((x1.submitted_at + interval '` + I.ToS(tz) + ` hour')::TEXT,13)||':00')`
		} else if agg == `minute` || agg == `mm` {
			time_key = `(LEFT((x1.submitted_at + interval '` + I.ToS(tz) + ` hour')::TEXT,16))`
		} else if agg == `none` {
			time_key = `(LEFT((x1.submitted_at + interval '` + I.ToS(tz) + ` hour')::TEXT,19))`
		} else {
			time_key += `+(` + I.ToS(tz) + `*3600)`
		}
	}

	with_as, join, join_on := ``, ``, ``
	//L.Print(rw)
	if table_exists {
		// Freelancer 20200110 add
		if S.EndsWith(rw, `r`) {
			join = `x2 JOIN `
			join_on = `ON x2.slid = x1.id`
			if S.EndsWith(option, `h`) || option == `1d` || option == `3d` {
				join = ``
				join_on = ``
			} else if option == `7d` {
				with_as = `WITH x2 AS ( SELECT slid FROM station_minutes_` + I.ToS(sta_id) + ` WHERE EXTRACT(EPOCH FROM at) > ` + last_mod_sql + ` )`
			} else {
				with_as = `WITH x2 AS ( SELECT slid FROM station_hours_` + I.ToS(sta_id) + ` WHERE EXTRACT(EPOCH FROM at) > ` + last_mod_sql + ` )`
			}
		} else {
			with_as = `WITH x2 AS ( SELECT DISTINCT ON(2) x2.slid, %s WHERE x2.sid = ` + ZI(sta_id) + ` ORDER BY 2 )`
			time_opt := rw[:len(rw)-1]
			//L.Print(`time_opt:`, time_opt)
			extract_time := ``
			join = `x2 JOIN `
			join_on = ` ON x2.slid = x1.id`
			if S.EndsWith(time_opt, `m`) {
				t := time_opt[:len(time_opt)-1]
				//L.Print(t)
				extract_time = `date_trunc('hour', x2.at) + date_part('minute', x2.at)::int / ` + t + ` * interval '` + t + ` min' FROM station_minutes_` + I.ToS(sta_id) + ` x2`
				with_as = fmt.Sprintf(with_as, extract_time)
				//L.Print(with_as)
			} else if S.EndsWith(time_opt, `h`) {
				extract_time = `x2.at FROM station_hours_` + I.ToS(sta_id) + ` x2`
				with_as = fmt.Sprintf(with_as, extract_time)
				//L.Print(with_as)
			} else {
				with_as = ``
				join = ``
				join_on = ``
			}
		}
		query := ram_key + `
		` + with_as + `
		SELECT ` + distinct_on + ` x1.id
			, ` + time_key + ` "submitted_at"
			, COALESCE(x1.level_sensor, 0) "level_sensor"
			` + S.If(!level_only, `
			, COALESCE(x1.accel_x, 0) "accel_x"
			, COALESCE(x1.accel_y, 0) "accel_y"
			, COALESCE(x1.accel_z, 0) "accel_z"
			, COALESCE(x1.power_current, 0) "power_current"
			, COALESCE(x1.power_voltage, 0) "power_voltage"
			, COALESCE(round(x1.wind_speed::NUMERIC * 1.94384,3)::FLOAT8, 0) "wind_speed"
			, COALESCE(round(x1.wind_speed_average::NUMERIC * 1.94384,3)::FLOAT8, 0) "wind_speed_average"
			, COALESCE(round(x1.wind_gust::NUMERIC * 1.94384,3)::FLOAT8, 0) "wind_gust"
			, COALESCE(x1.temperature, 0) "temperature"
			, COALESCE(x1.humidity, 0) "humidity"
			, COALESCE(x1.barometric_pressure, 0) "barometric_pressure"
			, COALESCE(x1.wind_direction, 0) "wind_direction"
			, COALESCE(x1.wind_direction_average, 0) "wind_direction_average"
			, COALESCE(x1.raindrop, 0) "raindrop"
			, COALESCE(x1.rain_rate, 0) "rain_rate"`) + `
			` + S.If(raw_format, `,
			(x1.sequence
			|| '#' || x3.name
			|| '#' || x3.imei
			|| '#' || TO_CHAR(x1.submitted_at,'HH12:MI:SS#DD-MM-YYYY')
			|| '#' || TO_CHAR(x1.level_sensor,'FM9999990.000')
			|| '#' || TO_CHAR(COALESCE(x3.lat,x1.accel_x),'FM9999990.00') || ',' || TO_CHAR(COALESCE(x3.long,x1.accel_y),'FM9999990.00') || ',' || TO_CHAR(x1.accel_z,'FM9999990.00')
			|| '#' || TO_CHAR(x1.power_voltage,'FM9999990.00')
			|| '#' || TO_CHAR(x1.power_current,'FM9999990.00')
			) "old_raw"`) + `
			` + S.If(raw_format && !level_only, `,
			(x3.imei
			|| '#' || x3.name
			|| '#' || TO_CHAR(COALESCE(x1.accel_x),'FM9999990.00') || ',' || TO_CHAR(COALESCE(x1.accel_y),'FM9999990.00') || ',' || TO_CHAR(x1.accel_z,'FM9999990.00')
			|| '#' || TO_CHAR(COALESCE(x1.power_voltage),'FM9999990.00') || ',' || TO_CHAR(COALESCE(x1.power_current),'FM9999990.00')
			|| '#' || TO_CHAR(x1.submitted_at,'HH12:MI:SS#DD-MM-YYYY')
			|| '#' || TO_CHAR(x1.level_sensor,'FM9999990.000')
			|| '#' || TO_CHAR(x1.temperature,'FM9999990.000')
			|| '#' || TO_CHAR(x1.humidity,'FM9999990')
			|| '#' || TO_CHAR(x1.barometric_pressure,'FM9999990.000')
			|| '#' || TO_CHAR(x1.wind_speed,'FM9999990.000')
			|| '#' || TO_CHAR(x1.wind_speed_average,'FM9999990.000')
			|| '#' || TO_CHAR(x1.wind_gust,'FM9999990.000')
			|| '#' || TO_CHAR(x1.wind_direction,'FM9999990.000')
			|| '#' || TO_CHAR(x1.wind_direction_average,'FM9999990.000')
			|| '#' || TO_CHAR(x1.raindrop,'FM9999990.000')
			|| '#' || TO_CHAR(x1.rain_rate,'FM9999990.000')
			) "raw"`) + `
		FROM ` + join +
			NewTableName + ` x1 ` + join_on +
			S.If(raw_format, `
			JOIN stations x3
				ON x1.station_id = x3.id`) + `
		WHERE EXTRACT(EPOCH FROM x1.submitted_at) > ` + last_mod_sql + `
		` + where_and + `
		ORDER BY 2
		`

		now := time.Now()
		res := sql.PG.QMapArray(query)
		L.TimeTrack(now, query)

		return res
		// Freelancer 20200110 add end
	} else {
		if S.EndsWith(rw, `r`) {
			join = `x2 JOIN `
			join_on = `ON x2.slid = x1.id`
			if S.EndsWith(option, `h`) || option == `1d` || option == `3d` {
				join = ``
				join_on = ``
			} else if option == `7d` {
				with_as = `WITH x2 AS ( SELECT slid FROM station_minutes WHERE sid = ` + ZI(sta_id) + ` AND EXTRACT(EPOCH FROM at) > ` + last_mod_sql + ` )`
			} else {
				with_as = `WITH x2 AS ( SELECT slid FROM station_hours WHERE sid = ` + ZI(sta_id) + ` AND EXTRACT(EPOCH FROM at) > ` + last_mod_sql + ` )`
			}
		} else {
			with_as = `WITH x2 AS ( SELECT DISTINCT ON(2) x2.slid, %s WHERE x2.sid = ` + ZI(sta_id) + ` ORDER BY 2 )`
			time_opt := rw[:len(rw)-1]
			//L.Print(`time_opt:`, time_opt)
			extract_time := ``
			join = `x2 JOIN `
			join_on = ` ON x2.slid = x1.id`
			if S.EndsWith(time_opt, `m`) {
				t := time_opt[:len(time_opt)-1]
				//L.Print(t)
				extract_time = `date_trunc('hour', x2.at) + date_part('minute', x2.at)::int / ` + t + ` * interval '` + t + ` min' FROM station_minutes x2`
				with_as = fmt.Sprintf(with_as, extract_time)
				//L.Print(with_as)
			} else if S.EndsWith(time_opt, `h`) {
				extract_time = `x2.at FROM station_hours x2`
				with_as = fmt.Sprintf(with_as, extract_time)
				//L.Print(with_as)
			} else {
				with_as = ``
				join = ``
				join_on = ``
			}
		}

		query := ram_key + `
		` + with_as + `
		SELECT ` + distinct_on + ` x1.id
			, ` + time_key + ` "submitted_at"
			, x1.level_sensor
			` + S.If(!level_only, `
			, x1.accel_x
			, x1.accel_y
			, x1.accel_z
			, x1.power_current
			, x1.power_voltage`) + `
			` + S.If(raw_format, `,
			(x1.sequence
			|| '#' || x3.name
			|| '#' || x3.imei
			|| '#' || TO_CHAR(x1.submitted_at,'HH12:MI:SS#DD-MM-YYYY')
			|| '#' || TO_CHAR(x1.level_sensor,'FM9999990.000')
			|| '#' || TO_CHAR(COALESCE(x3.lat,x1.accel_x),'FM9999990.00') || ',' || TO_CHAR(COALESCE(x3.long,x1.accel_y),'FM9999990.00') || ',' || TO_CHAR(x1.accel_z,'FM9999990.00')
			|| '#' || TO_CHAR(x1.power_voltage,'FM9999990.00')
			|| '#' || TO_CHAR(x1.power_current,'FM9999990.00')
			) "raw"`) + `
		FROM ` + join +
			`station_logs x1 ` + join_on +
			S.If(raw_format, `
			JOIN stations x3
				ON x1.station_id = x3.id`) + `
		WHERE EXTRACT(EPOCH FROM x1.submitted_at) > ` + last_mod_sql + `
		` + where_and + `
		ORDER BY 2
		`
		//L.Print(query)
		now := time.Now()
		res := sql.PG.QMapArray(query)
		L.TimeTrack(now, query)

		return res

	}
}

// 2017-06-28 Haries
func API_OwnerSuperadmin_FileUpload(rm *W.RequestModel) {
	table := TABLE
	key := rm.Posts.GetStr(`key`)
	switch key {
	case `picture`, `north`, `west`, `south`, `east`:
		API_FileUpload_ByTable_ByContext_ByKey_ByPrefix(rm, table, rm.Ctx, key, rm.Id+`_`+key)
		Pg.RamGlobalEvict_ByAjax_ByBucket(rm.Ajax, table)
	default:
		rm.Ajax.Error(sql.ERR_002_INVALID_UPLOAD_KEY + key)
	}
}

// 2017-10-17 Prayogo
func API_Superadmin_ShiftRange(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	start_date := posts.GetFloat(`start_date`)
	end_date := posts.GetFloat(`end_date`)
	delta := posts.GetFloat(`delta`)
	// freelancer add 20200110
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		query := ZT(I.ToS(sta_id), F.ToS(start_date),
			F.ToS(end_date)) + `
UPDATE ` + NewTableName + `
		SET level_sensor = level_sensor + ` + F.ToS(delta) + `
		WHERE EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
			AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date)

		verify_q := `SELECT MAX(level_sensor), MIN(level_sensor)
FROM ` + NewTableName + `
WHERE EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date)
		before := sql.PG.QFirstMap(verify_q)
		first_q := `
SELECT COALESCE((
	SELECT submitted_at || ' = ' || level_sensor
	FROM ` + NewTableName + `
	WHERE EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	ORDER BY submitted_at
	LIMIT 1
),'')`
		last_q := `SELECT COALESCE((
SELECT submitted_at || ' = ' || level_sensor
	FROM ` + NewTableName + `
	WHERE EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date) + `
	ORDER BY submitted_at DESC
	LIMIT 1
),'')`
		before[`_first`] = sql.PG.QStr(first_q)
		before[`_last`] = sql.PG.QStr(last_q)
		rm.Ajax.Set(`before`, before)
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			res := tx.DoExec(query)
			ra, err := res.RowsAffected()
			rm.Ajax.Set(`affected`, ra)
			if err != nil {
				rm.Ajax.Error(err.Error())
			}
			return ``
		})

		after := sql.PG.QFirstMap(verify_q)
		after[`_first`] = sql.PG.QStr(first_q)
		after[`_last`] = sql.PG.QStr(last_q)
		rm.Ajax.Set(`after`, after)
		L.Print(`---------------------- START_SHIFT_RANGE_BACKUP`)
		L.Print(query)
		L.Print(`---------------------- END_SHIFT_RANGE_BACKUP`)
		// freelancer end add 20200110
	} else {
		query := ZT(I.ToS(sta_id), F.ToS(start_date),
			F.ToS(end_date)) + `
UPDATE station_logs
		SET level_sensor = level_sensor + ` + F.ToS(delta) + `
		WHERE station_id = ` + I.ToS(sta_id) + `
			AND EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
			AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date)

		verify_q := `SELECT MAX(level_sensor), MIN(level_sensor)
FROM station_logs
WHERE station_id = ` + I.ToS(sta_id) + `
	AND EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date)
		before := sql.PG.QFirstMap(verify_q)
		first_q := `
SELECT COALESCE((
	SELECT submitted_at || ' = ' || level_sensor
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	ORDER BY submitted_at
	LIMIT 1
),'')`
		last_q := `SELECT COALESCE((
SELECT submitted_at || ' = ' || level_sensor
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date) + `
	ORDER BY submitted_at DESC
	LIMIT 1
),'')`
		before[`_first`] = sql.PG.QStr(first_q)
		before[`_last`] = sql.PG.QStr(last_q)
		rm.Ajax.Set(`before`, before)
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			res := tx.DoExec(query)
			ra, err := res.RowsAffected()
			rm.Ajax.Set(`affected`, ra)
			if err != nil {
				rm.Ajax.Error(err.Error())
			}
			return ``
		})

		after := sql.PG.QFirstMap(verify_q)
		after[`_first`] = sql.PG.QStr(first_q)
		after[`_last`] = sql.PG.QStr(last_q)
		rm.Ajax.Set(`after`, after)
		L.Print(`---------------------- START_SHIFT_RANGE_BACKUP`)
		L.Print(query)
		L.Print(`---------------------- END_SHIFT_RANGE_BACKUP`)
	}
}

// 2017-10-17 Prayogo
func API_Superadmin_CheckRange(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	start_date := posts.GetFloat(`start_date`)
	end_date := posts.GetFloat(`end_date`)
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		verify_q := `SELECT MAX(level_sensor), MIN(level_sensor), COUNT(*)
FROM ` + NewTableName + `
WHERE EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date)
		now := sql.PG.QFirstMap(verify_q)
		first_q := `
SELECT COALESCE((
	SELECT submitted_at || ' = ' || level_sensor
	FROM ` + NewTableName + `
	WHERE EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	ORDER BY submitted_at
	LIMIT 1
),'')`
		last_q := `SELECT COALESCE((
SELECT submitted_at || ' = ' || level_sensor
	FROM ` + NewTableName + `
	WHERE EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date) + `
	ORDER BY submitted_at DESC
	LIMIT 1
),'')`
		now[`_first`] = sql.PG.QStr(first_q)
		now[`_last`] = sql.PG.QStr(last_q)
		rm.Ajax.Set(`now`, now)
		// freelancer 20200110 end add
	} else {
		verify_q := `SELECT MAX(level_sensor), MIN(level_sensor), COUNT(*)
FROM station_logs
WHERE station_id = ` + I.ToS(sta_id) + `
	AND EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date)
		now := sql.PG.QFirstMap(verify_q)
		first_q := `
SELECT COALESCE((
	SELECT submitted_at || ' = ' || level_sensor
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND EXTRACT(EPOCH FROM submitted_at) >= ` + F.ToS(start_date) + `
	ORDER BY submitted_at
	LIMIT 1
),'')`
		last_q := `SELECT COALESCE((
SELECT submitted_at || ' = ' || level_sensor
	FROM station_logs
	WHERE station_id = ` + I.ToS(sta_id) + `
		AND EXTRACT(EPOCH FROM submitted_at) <= ` + F.ToS(end_date) + `
	ORDER BY submitted_at DESC
	LIMIT 1
),'')`
		now[`_first`] = sql.PG.QStr(first_q)
		now[`_last`] = sql.PG.QStr(last_q)
		rm.Ajax.Set(`now`, now)
	}
}

// 2018-10-04 Prayogo
func API_SuperAdmin_EraseAllPermanently(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)

	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// Freelancer 20200110 add
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			res := tx.DoExec(`DELETE FROM station_hours_` + I.ToS(sta_id))
			v, _ := res.RowsAffected()
			rm.Ajax.Set(`station_hours`, v)
			res = tx.DoExec(`DELETE FROM station_minutes_` + I.ToS(sta_id))
			v, _ = res.RowsAffected()
			rm.Ajax.Set(`station_minutes`, v)
			res = tx.DoExec(`DELETE FROM station_logs_` + I.ToS(sta_id))
			v, _ = res.RowsAffected()
			rm.Ajax.Set(`station_logs`, v)
			return ``
		})
		// Freelancer 20200110 end add
	} else {
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			res := tx.DoExec(`DELETE FROM station_hours WHERE sid = ` + ZI(sta_id))
			v, _ := res.RowsAffected()
			rm.Ajax.Set(`station_hours`, v)
			res = tx.DoExec(`DELETE FROM station_minutes WHERE sid = ` + ZI(sta_id))
			v, _ = res.RowsAffected()
			rm.Ajax.Set(`station_minutes`, v)
			res = tx.DoExec(`DELETE FROM station_logs WHERE station_id = ` + ZI(sta_id))
			v, _ = res.RowsAffected()
			rm.Ajax.Set(`station_logs`, v)
			return ``
		})
	}
}

// 2017-06-22 Prayogo
func API_Superadmin_StatDate(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	date := posts.GetStr(`date`)
	ram_key := ZT(I.ToS(sta_id), date)
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// Freelancer 20200110 add
		query := ram_key + `
WITH x1 AS (
	SELECT EXTRACT('hour' FROM submitted_at) AS "hour"
		, ROUND(level_sensor::NUMERIC,1) AS "level"
		, COUNT(*) AS "cou"
	FROM station_logs_` + I.ToS(sta_id) + `
	WHERE date_trunc('day',submitted_at) = ` + Z(date) + `
	GROUP BY 1,2
	ORDER BY 1
)
SELECT hour
	, STRING_AGG(level::TEXT || ' x ' || cou::TEXT, ' | ' ORDER BY level) "stat"
FROM x1
GROUP BY 1
`
		result := sql.PG.CQMapArray(`station_logs`, ram_key, query)

		L.Print(`Query :::::: `, query)
		L.Print(`RESULT :::::: `, result)
		rm.Ajax.Set(`result`, result)
		// Freelancer 20200110 end add
	} else {
		query := ram_key + `
WITH x1 AS (
	SELECT EXTRACT('hour' FROM submitted_at) AS "hour"
		, ROUND(level_sensor::NUMERIC,1) AS "level"
		, COUNT(*) AS "cou"
	FROM station_logs 
	WHERE station_id = ` + ZI(sta_id) + ` 
		AND date_trunc('day',submitted_at) = ` + Z(date) + `
	GROUP BY 1,2
	ORDER BY 1
)
SELECT hour
	, STRING_AGG(level::TEXT || ' x ' || cou::TEXT, ' | ' ORDER BY level) "stat"
FROM x1
GROUP BY 1
`
		result := sql.PG.CQMapArray(`station_logs`, ram_key, query)

		L.Print(`Query :::::: `, query)
		L.Print(`RESULT :::::: `, result)
		rm.Ajax.Set(`result`, result)
	}
}

// 2017-06-22 Prayogo
func StartEndLogs_ById(sta_id int64) (string, string) {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		query := ZT(I.ToS(sta_id)) + `
SELECT MIN(submitted_at), MAX(submitted_at)
FROM ` + NewTableName
		return sql.PG.QStrStr(query)
		// freelancer 20200110 end add
	} else {
		query := ZT(I.ToS(sta_id)) + `
SELECT MIN(submitted_at), MAX(submitted_at)
FROM station_logs
WHERE station_id = ` + ZI(sta_id)
		return sql.PG.QStrStr(query)
	}
}

// 2017-06-22 Prayogo
func API_Superadmin_DeleteHourLevel(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	date := posts.GetStr(`date`)
	hour := posts.GetInt(`hour`)
	level := posts.GetStr(`level`)

	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// Freelancer 20200110 add
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			query := ZT() + `
		DELETE FROM ` + NewTableName + ` 
		WHERE station_id = ` + ZI(sta_id) + ` 
			AND date_trunc('day',submitted_at) = ` + Z(date) + `
			AND EXTRACT('hour' FROM submitted_at) = ` + ZI(hour) + `
			AND ROUND(level_sensor::NUMERIC,1) = ` + Z(level) + `
		`
			ra, err := tx.DoExec(query).RowsAffected()
			if err != nil {
				rm.Ajax.Error(err.Error())
			}
			rm.Ajax.Set(`deleted`, ra)
			return rm.Ajax.LastError()
		})
		Pg.RamGlobalEvict_ByAjax_ByBucket(rm.Ajax, `station_logs`)
		API_Superadmin_StatDate(rm)
		// Freelancer 20200110 end add
	} else {
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			query := ZT() + `
		DELETE FROM station_logs 
		WHERE station_id = ` + ZI(sta_id) + ` 
			AND date_trunc('day',submitted_at) = ` + Z(date) + `
			AND EXTRACT('hour' FROM submitted_at) = ` + ZI(hour) + `
			AND ROUND(level_sensor::NUMERIC,1) = ` + Z(level) + `
		`
			ra, err := tx.DoExec(query).RowsAffected()
			if err != nil {
				rm.Ajax.Error(err.Error())
			}
			rm.Ajax.Set(`deleted`, ra)
			return rm.Ajax.LastError()
		})
		Pg.RamGlobalEvict_ByAjax_ByBucket(rm.Ajax, `station_logs`)
		API_Superadmin_StatDate(rm)
	}

}

// 2017-06-22 Prayogo
func API_Superadmin_FormHourLevel(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	posts := rm.Ctx.Posts()
	date := posts.GetStr(`date`)
	hour := posts.GetInt(`hour`)
	level := posts.GetStr(`level`)
	ram_key := ZT(I.ToS(sta_id), date, I.ToS(hour), level)
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		//Freelancer 20200110 add
		query := ram_key + `
		SELECT id, SUBSTRING(submitted_at::TEXT FROM 12 FOR 8) hhmmss, level_sensor
		FROM ` + NewTableName + ` 
		WHERE date_trunc('day',submitted_at) = ` + Z(date) + `
			AND EXTRACT('hour' FROM submitted_at) = ` + ZI(hour) + `
			AND ROUND(level_sensor::NUMERIC,1) = ` + Z(level) + `
		ORDER BY 2`

		L.Print(`QUERY :: `, query)
		result := sql.PG.QMapArray(query)
		rm.Ajax.Set(`result`, result)
		//Freelancer 20200110 end add
	} else {
		query := ram_key + `
		SELECT id, SUBSTRING(submitted_at::TEXT FROM 12 FOR 8) hhmmss, level_sensor
		FROM station_logs 
		WHERE station_id = ` + ZI(sta_id) + ` 
			AND date_trunc('day',submitted_at) = ` + Z(date) + `
			AND EXTRACT('hour' FROM submitted_at) = ` + ZI(hour) + `
			AND ROUND(level_sensor::NUMERIC,1) = ` + Z(level) + `
		ORDER BY 2`

		L.Print(`QUERY :: `, query)
		result := sql.PG.QMapArray(query)
		rm.Ajax.Set(`result`, result)
	}
}

// 2017-07-01 Prayogo
func API_Superadmin_UpdateHourLevel(rm *W.RequestModel) {
	sta_id := rm.Ctx.ParamInt(`sta_id`)
	update_list := rm.Ctx.Posts().GetJsonMap(`update_list`)
	total := int64(0)
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			for k, v := range update_list {
				query := `UPDATE ` + NewTableName + ` SET level_sensor = ` + F.ToS(X.ToF(v)) + ` WHERE id = ` + X.ToS(k)
				L.Print(`Query :::::::`, query)
				aff, _ := tx.DoExec(query).RowsAffected()
				total += aff
			}
			return ``
		})
		rm.Ajax.Set(`updated`, total)

		Pg.RamGlobalEvict_ByAjax_ByBucket(rm.Ajax, `station_logs`)
		API_Superadmin_StatDate(rm)
		// freelancer 20200110 end
	} else {
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			for k, v := range update_list {
				query := `UPDATE station_logs SET level_sensor = ` + F.ToS(X.ToF(v)) + ` WHERE id = ` + X.ToS(k)
				aff, _ := tx.DoExec(query).RowsAffected()

				L.Print(`Query :::::::`, query)
				total += aff
			}
			return ``
		})
		rm.Ajax.Set(`updated`, total)

		Pg.RamGlobalEvict_ByAjax_ByBucket(rm.Ajax, `station_logs`)
		API_Superadmin_StatDate(rm)
	}

}

// 2017-07-09 Prayogo
func ActiveStation_Count() int64 {
	query := ZT() + `
SELECT COUNT(*) 
FROM stations
WHERE is_deleted = false
	`
	return sql.PG.QInt(query)
}

// 2017-07-01 Prayogo
func Check_LastSubmit_ByMinute(minute int64) A.MSX {
	/*
			query := ZT() + `
		SELECT x1.id
		, x1.name
		, x2.submitted_at "last_sent"
		, EXTRACT(EPOCH FROM DATE_TRUNC('second',(now() at time zone 'utc'))-x2.submitted_at) "ago"
		, DATE_TRUNC('second',(now() at time zone 'utc'))-x2.submitted_at "ago2"
		FROM stations x1
		CROSS JOIN LATERAL (
			SELECT submitted_at
			FROM station_logs
			WHERE station_id = x1.id
			ORDER BY submitted_at DESC NULLS LAST
			LIMIT 1
		) x2
		WHERE x1.is_deleted = false
			AND EXTRACT(EPOCH FROM (now() at time zone 'utc')-x2.submitted_at) > ` + I.ToS(minute) + `*60
		ORDER BY 4
		`
			return sql.PG.QMapArray(query)*/
	//freelancer 20200110
	query := ZT() + `
SELECT x1.id
, x1.name
, x1.last_submitted_at "last_sent"
, EXTRACT(EPOCH FROM DATE_TRUNC('second',(now() at time zone 'utc'))-x1.last_submitted_at) "ago"
, DATE_TRUNC('second',(now() at time zone 'utc'))-x1.last_submitted_at "ago2"
FROM stations x1
WHERE x1.is_deleted = false
	AND EXTRACT(EPOCH FROM (now() at time zone 'utc')-x1.last_submitted_at) > ` + I.ToS(minute) + `*60
ORDER BY 4
`
	return sql.PG.QMapArray(query)
	//freelancer 20200110 end

}

func GenInsert(table string, kvparams M.SX, suffix string) (string, []interface{}) {
	query := bytes.Buffer{}
	params := []interface{}{}
	query.WriteString(`INSERT INTO ` + table + `( `)
	len := 0
	for key, val := range kvparams {
		if len > 0 {
			query.WriteString(`, `)
		}
		query.WriteString(key)
		params = append(params, val)
		len++
	}
	query.WriteString(` ) SELECT `)
	for z := 1; z <= len; z++ {
		if z > 1 {
			query.WriteString(`, `)
		}
		query.WriteString(`$` + I.ToStr(z))
	}
	query.WriteString(` `)
	query.WriteString(suffix)
	return query.String(), params
}

// 2021-04-14 Kiswono
const retId = ` RETURNING id`

func InsertLog_ByStation_ByColKV(sta_id int64, kv M.SX) (id int64) {
	table := `station_logs_` + I.ToS(sta_id)
	query, params := GenInsert(table, kv, ` WHERE NOT EXISTS (SELECT 1 FROM `+table+` WHERE submitted_at = `+S.Q(kv.GetStr(`submitted_at`))+`)`+retId)
	rows := sql.PG.QAll(query, params...)
	defer rows.Close()
	if rows.Next() {
		rows.Scan(&id)
	}
	return
}
func InsertHours_ByStation_ByColKV(sta_id int64, kv M.SX) {
	table := `station_hours_` + I.ToS(sta_id)
	query, params := GenInsert(table, kv, ` WHERE NOT EXISTS (SELECT 1 FROM `+table+` WHERE uniq_hours(at) = uniq_hours(`+S.Q(kv.GetStr(`at`))+`))`)
	rows := sql.PG.QAll(query, params...)
	defer rows.Close()
}
func InsertMinutes_ByStation_ByColKV(sta_id int64, kv M.SX) {
	table := `station_minutes_` + I.ToS(sta_id)
	query, params := GenInsert(table, kv, ` WHERE NOT EXISTS (SELECT 1 FROM `+table+` WHERE uniq_minute(at) = uniq_minute(`+S.Q(kv.GetStr(`at`))+`))`)
	rows := sql.PG.QAll(query, params...)
	defer rows.Close()
}
func CreateTables(sta_id int64) bool {
	ok := true
	_, err := sql.PG.Adapter.Exec(`SELECT create_station_logs_station(` + I.ToS(sta_id) + `)`)
	ok = ok && L.IsError(err, `failed create logs table`)
	_, err = sql.PG.Adapter.Exec(`SELECT create_station_hours_station(` + I.ToS(sta_id) + `)`)
	ok = ok && L.IsError(err, `failed create hours table`)
	_, err = sql.PG.Adapter.Exec(`SELECT create_station_minutes_station(` + I.ToS(sta_id) + `)`)
	ok = ok && L.IsError(err, `failed create minutes table`)
	return ok
}

// 2017-09-16 Michael
func AllLog_ByStation_AfterId_ByLimit(sta_id, after_id, limit int64) A.MSX {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// Freelancer 20200110
		query := ZT() + `
SELECT *
FROM ` + NewTableName + `
WHERE 1=1
	` + S.If(after_id > 0, `AND id > `+ZI(after_id)) + `
ORDER BY id
LIMIT ` + I.ToS(limit)
		return sql.PG.QMapArray(query)
		// Freelancer 20200110 end
	} else {
		query := ZT() + `
SELECT *
FROM station_logs
WHERE 1=1
	` + S.If(after_id > 0, `AND id > `+ZI(after_id)) + `
	AND station_id = ` + ZI(sta_id) + `
ORDER BY id
LIMIT ` + I.ToS(limit)
		return sql.PG.QMapArray(query)
	}

}

func ProxyFetchToJson(posts *W.Posts) M.SX {
	target := posts.GetStr(`url`)
	//L.Print("URL:>", target)

	form := url.Values{}
	keys := []string{`a`, `pwd`, `sta_id`, `after_id`, `limit`}
	for _, key := range keys {
		val := posts.GetStr(key)
		if key == `pwd` {
			val += T.DateStr()
		}
		if val != `` {
			form.Add(key, val)
		}
	}
	req, err := http.NewRequest("POST", target, strings.NewReader(form.Encode()))
	if err != nil {
		L.LOG.Error(err)
	}
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	//L.Print("response Status:", resp.Status)
	//L.Print("response Headers:", resp.Header)
	body, _ := io.ReadAll(resp.Body)
	//L.Print("response Body:", string(body))

	return S.JsonToMap(string(body))
}

// 2017-09-15 Michael
func API_Superadmin_ProxyGetStation(rm *W.RequestModel) {
	json := ProxyFetchToJson(rm.Posts)
	rm.Ajax.SX = json
}

func FindId_ByImei(imei string) int64 {
	query := ZT() + `
		SELECT COALESCE((
			SELECT id
			FROM stations
			WHERE imei = ` + Z(imei) + `
			LIMIT 1
		),0)
		`
	return sql.PG.QInt(query)
}

func CheckDuplicateLog(submitted_at string, sta_id int64) int64 {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// Freelancer 20100110 add
		query := ZT() + `
		SELECT COALESCE((
			SELECT id
			FROM ` + NewTableName + `
			WHERE submitted_at = ` + Z(submitted_at) + `), 0)`
		return sql.PG.QInt(query)
		// Freelancer 20100110 end
	} else {
		query := ZT() + `
		SELECT COALESCE((
			SELECT id
			FROM station_logs
			WHERE submitted_at = ` + Z(submitted_at) + `
			AND station_id = ` + ZI(sta_id) + ` ), 0)`
		return sql.PG.QInt(query)
	}

}

func API_Superadmin_ProxyImport(rm *W.RequestModel) {
	// insert 1 1 ke station dan station_logs
	json := ProxyFetchToJson(rm.Posts)
	station := json.GetMSX(`station`)
	imei := station.GetStr(`imei`) //[1:] + `1` // TODO: dihapus, hanya untuk testing lokal
	sta_id := FindId_ByImei(imei)
	after_id := rm.Posts.GetInt(`after_id`)
	if sta_id == 0 {
		sql.PG.DoTransaction(func(tx *Pg.Tx) string {
			query := `INSERT INTO stations(created_at,
				name, long, lat, imei, location, history, group_id, min_filter, max_filter, is_deleted)
				VALUES(TO_TIMESTAMP(%f) at time zone 'utc',
				%s, %f, %f, %s, '%s', '%s', %d, %f, %f, %t) RETURNING id`
			query = fmt.Sprintf(query, station.GetFloat(`created_at`),
				Z(station.GetStr(`name`)), station.GetFloat(`long`), station.GetFloat(`lat`), Z(imei),
				station.GetStr(`location`), station.GetStr(`history`), station.GetInt(`group_id`),
				station.GetFloat(`min_filter`), station.GetFloat(`max_filter`), station.GetBool(`is_deleted`))
			//L.Print(query)
			rows := tx.QAll(query)
			defer rows.Close()
			if rows.Next() {
				rows.Scan(&sta_id)
			}
			return ``
		})
	}
	logs := json.GetAX(`logs`)
	imported := 0
	duplicate := 0
	for _, log_any := range logs {
		log := (log_any).(map[string]interface{}) // coba dulu bisa langsung M.SX
		their_log_id := X.ToI(log[`id`])
		//submitted_at := X.ToS(log[`submitted_at`])
		if after_id < their_log_id {
			after_id = their_log_id
		}
		log_id := int64(0)
		if CheckDuplicateLog(X.ToS(log[`submitted_at`]), sta_id) == 0 {
			created_at := `NULL`
			updated_at := `NULL`
			deleted_at := `NULL`
			if log[`created_at`] != nil {
				created_at = `'` + X.ToS(log[`created_at`]) + `'`
			}
			if log[`updated_at`] != nil {
				updated_at = `'` + X.ToS(log[`updated_at`]) + `'`
			}
			if log[`deleted_at`] != nil {
				deleted_at = `'` + X.ToS(log[`deleted_at`]) + `'`
			}
			// Freelancer 20100110 change
			NewTableName := `station_logs_` + I.ToS(sta_id)
			if sql.PG.TableExists(NewTableName) {
				// Freelancer 20200110 add
				sql.PG.DoTransaction(func(tx *Pg.Tx) string {
					query := `INSERT INTO ` + NewTableName + `(created_at, updated_at, deleted_at, submitted_at,
				station_id, sequence, level_sensor, accel_x, accel_y, accel_z,
				power_current, ip_address, log_type, power_voltage, is_deleted)
				VALUES(%s, %s, %s, '%s', %d, %d, %f, %f, %f, %f, %f, '%s', %d, %f,  %t) RETURNING id`
					query = fmt.Sprintf(query, created_at, updated_at, deleted_at, X.ToS(log[`submitted_at`]),
						sta_id, X.ToI(log[`sequence`]), X.ToF(log[`level_sensor`]), X.ToF(log[`accel_x`]), X.ToF(log[`accel_y`]), X.ToF(log[`accel_z`]),
						X.ToF(log[`power_current`]), X.ToS(log[`ip_address`]), X.ToI(log[`log_type`]), X.ToF(log[`power_voltage`]), X.ToBool(log[`is_deleted`]))
					rows := tx.QAll(query)
					defer rows.Close()
					if rows.Next() {
						rows.Scan(&log_id)
						//L.Print(log_id)
					}
					if rows.Err() == nil {
						imported += 1
					}
					return ``
				})

				if log_id != 0 {
					if FindUniqHours(X.ToS(log[`submitted_at`]), sta_id) < 1 {
						sql.PG.DoTransaction(func(tx *Pg.Tx) string {
							query := `INSERT INTO station_hours_` + I.ToS(sta_id) + `(at, slid, sid) VALUES('` + X.ToS(log[`submitted_at`]) + `',
						` + X.ToS(log_id) + `, ` + X.ToS(sta_id) + `)`
							//L.Print(query)
							tx.DoExec(query)
							return ``
						})
					}

					if FindUniqMinutes(X.ToS(log[`submitted_at`]), sta_id) < 1 {
						sql.PG.DoTransaction(func(tx *Pg.Tx) string {
							query := `INSERT INTO station_minutes_` + I.ToS(sta_id) + `(at, slid, sid) VALUES('` + X.ToS(log[`submitted_at`]) + `',
						` + X.ToS(log_id) + `, ` + X.ToS(sta_id) + `)`
							//L.Print(query)
							tx.DoExec(query)
							return ``
						})
					}
				}
				// Freelancer 20200110 end
			} else {
				sql.PG.DoTransaction(func(tx *Pg.Tx) string {
					query := `INSERT INTO station_logs(created_at, updated_at, deleted_at, submitted_at,
				station_id, sequence, level_sensor, accel_x, accel_y, accel_z,
				power_current, ip_address, log_type, power_voltage, is_deleted)
				VALUES(%s, %s, %s, '%s', %d, %d, %f, %f, %f, %f, %f, '%s', %d, %f,  %t) RETURNING id`
					query = fmt.Sprintf(query, created_at, updated_at, deleted_at, X.ToS(log[`submitted_at`]),
						sta_id, X.ToI(log[`sequence`]), X.ToF(log[`level_sensor`]), X.ToF(log[`accel_x`]), X.ToF(log[`accel_y`]), X.ToF(log[`accel_z`]),
						X.ToF(log[`power_current`]), X.ToS(log[`ip_address`]), X.ToI(log[`log_type`]), X.ToF(log[`power_voltage`]), X.ToBool(log[`is_deleted`]))
					rows := tx.QAll(query)
					defer rows.Close()
					if rows.Next() {
						rows.Scan(&log_id)
						//L.Print(log_id)
					}
					if rows.Err() == nil {
						imported += 1
					}
					return ``
				})

				if log_id != 0 {
					if FindUniqHours(X.ToS(log[`submitted_at`]), sta_id) < 1 {
						sql.PG.DoTransaction(func(tx *Pg.Tx) string {
							query := `INSERT INTO station_hours(at, slid, sid) VALUES('` + X.ToS(log[`submitted_at`]) + `',
						` + X.ToS(log_id) + `, ` + X.ToS(sta_id) + `)`
							//L.Print(query)
							tx.DoExec(query)
							return ``
						})
					}

					if FindUniqMinutes(X.ToS(log[`submitted_at`]), sta_id) < 1 {
						sql.PG.DoTransaction(func(tx *Pg.Tx) string {
							query := `INSERT INTO station_minutes(at, slid, sid) VALUES('` + X.ToS(log[`submitted_at`]) + `',
						` + X.ToS(log_id) + `, ` + X.ToS(sta_id) + `)`
							//L.Print(query)
							tx.DoExec(query)
							return ``
						})
					}
				}
			}

		} else {
			duplicate += 1
		}
	}
	rm.Ajax.Set(`after_id`, after_id)
	rm.Ajax.Set(`imported`, imported)
	rm.Ajax.Set(`duplicate`, duplicate)
}

func API_Superadmin_ProxyMigrate(rm *W.RequestModel) {
	sql.PG.DoTransaction(func(tx *Pg.Tx) string {
		query := `do
			$do$
				declare
				begin
					perform move_station_logs_station();
					perform move_station_hours_station();
					perform move_station_minutes_station();
				end;
			$do$`
		rows := tx.QAll(query)
		defer rows.Close()
		return ``
	})
}

func FindUniqHours(submitted_at string, sta_id int64) int64 {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		query := ZT() + `
		SELECT COUNT(*) FROM station_hours_` + I.ToS(sta_id) + ` WHERE uniq_hours(at) = uniq_hours('` + X.ToS(submitted_at) + `')`
		//L.Print(query)
		ra := sql.PG.QInt(query)
		//L.Print(ra)
		return ra
		// freelancer 20200110 end
	} else {
		query := ZT() + `
		SELECT COUNT(*) FROM station_hours WHERE sid = '` + X.ToS(sta_id) +
			`' AND uniq_hours(at) = uniq_hours('` + X.ToS(submitted_at) + `')`
		//L.Print(query)
		ra := sql.PG.QInt(query)
		//L.Print(ra)
		return ra
	}
}

func FindUniqMinutes(submitted_at string, sta_id int64) int64 {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		query := ZT() + `
	SELECT COUNT(*) FROM station_minutes_` + I.ToS(sta_id) + ` WHERE uniq_minute(at) = uniq_minute('` + X.ToS(submitted_at) + `')`
		return sql.PG.QInt(query)
		// freelancer 20200110 end
	} else {
		query := ZT() + `
	SELECT COUNT(*) FROM station_minutes_` + I.ToS(sta_id) + ` WHERE uniq_minute(at) = uniq_minute('` + X.ToS(submitted_at) + `')`
		return sql.PG.QInt(query)
	}
}

func FindStation_ByCoordOrImei(lat, lng, imei string) M.SX {
	// lalu diberikan return value berupa nama station, IMEI, level, timestamp dalam bentuk| JSON bagusnya
	//     Interval mungkin di 15 menit sudah cukup. Tapi kita sesuaikan nanti dengan hasil tes

	query := ZT() + `
SELECT x1.id, x1.name, x1.imei
FROM stations x1
WHERE `
	if imei != `` {
		query += `x1.imei = ` + Z(imei)
	} else if lat != `` && lng != `` {
		query += `(
	x1.long = ` + Z(lng) + `
	AND x1.lat = ` + Z(lat) + `
)`
	} else {
		query += ` 1=2 `
	}
	return sql.PG.QFirstMap(query)
}

// 2018-08-14 Prayogo
// 2018-12-27 Prayogo
func AverageLevel_ByStationBySnap(sta_id int64, snap int64) M.SX {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		epoch := T.Epoch() - snap*60
		query := ZT() + `
SELECT MIN(x1.submitted_at) "min_timestamp"
	, MAX(x1.submitted_at) "max_timestamp"
	, AVG(x1.level_sensor) "average_level"
	, COUNT(x1.*) "cache_count"
FROM ` + NewTableName + ` x1
WHERE EXTRACT(EPOCH FROM x1.submitted_at) > ` + I.ToS(epoch)
		return sql.PG.QFirstMap(query)
		// freelancer 20200110 end
	} else {
		epoch := T.Epoch() - snap*60
		query := ZT() + `
SELECT MIN(x1.submitted_at) "min_timestamp"
	, MAX(x1.submitted_at) "max_timestamp"
	, AVG(x1.level_sensor) "average_level"
	, COUNT(x1.*) "cache_count"
FROM station_logs x1
WHERE x1.station_id = ` + ZI(sta_id) + `
	AND EXTRACT(EPOCH FROM x1.submitted_at) > ` + I.ToS(epoch)
		return sql.PG.QFirstMap(query)
	}
}

// 2018-12-27 Prayogo
func LastLog_ByStation(sta_id int64) M.SX {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec", submitted_at, level_sensor
FROM ` + NewTableName + `
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
		// freelancer 20200110 end
	} else {
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec", submitted_at, level_sensor
FROM station_logs
WHERE station_id = ` + ZI(sta_id) + `
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
	}
}

// 2024-07-14 Prayogo
func RawLevelAfterInterval_ByStation(staId int64, interval string) A.X {
	NewTableName := `station_logs_` + I.ToS(staId)
	if sql.PG.TableExists(NewTableName) {
		ram_key := ZT(I.ToS(staId))
		query := ram_key + fmt.Sprintf(`
SELECT submitted_at, level_sensor
FROM `+NewTableName+`
WHERE submitted_at > CURRENT_TIMESTAMP - INTERVAL '%s'
	AND submitted_at <= CURRENT_TIMESTAMP
ORDER BY submitted_at DESC
`, interval)
		return sql.PG.QArray(query)
		// freelancer 20200110 end
	} else {
		ram_key := ZT(I.ToS(staId))
		query := ram_key + fmt.Sprintf(`
SELECT submitted_at, level_sensor
FROM station_logs
WHERE station_id = `+ZI(staId)+`
	AND submitted_at > CURRENT_TIMESTAMP - INTERVAL '%s'
	AND submitted_at <= CURRENT_TIMESTAMP
ORDER BY submitted_at DESC
`, interval)
		return sql.PG.QArray(query)
	}
}

// 2021-03-05 Prayogo
func LastLogWithPowerAccel_ByStation(sta_id int64) M.SX {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec", submitted_at, level_sensor 
	, power_current, power_voltage, accel_x, accel_y, raindrop
FROM ` + NewTableName + `
WHERE submitted_at < CURRENT_TIMESTAMP
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
		// freelancer 20200110 end
	} else {
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec", submitted_at, level_sensor
	, power_current, power_voltage, accel_x, accel_y
FROM station_logs
WHERE station_id = ` + ZI(sta_id) + `
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
	}
}

// 2022-02-03 Prayogo
func LastLogWithPowerAccel2_ByStation(sta_id int64) M.SX {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec", submitted_at, level_sensor 
	, power_current, power_voltage, accel_x, accel_y
	, raindrop
	, wind_gust "pump_status"
	, rain_rate "rain_gauge"
	, wind_direction_average "eth_send_resp"
	, wind_gust "eth_send_status"
FROM ` + NewTableName + `
WHERE submitted_at < CURRENT_TIMESTAMP
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
		// freelancer 20200110 end
	} else {
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec", submitted_at, level_sensor
	, power_current, power_voltage, accel_x, accel_y
FROM station_logs
WHERE station_id = ` + ZI(sta_id) + `
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
	}
}

// 2022-04-14 Prayogo
func LastLogAll_ByStation(sta_id int64) M.SX {
	NewTableName := `station_logs_` + I.ToS(sta_id)
	if sql.PG.TableExists(NewTableName) {
		// freelancer 20200110 add
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec"
	, submitted_at
	, level_sensor 
	, accel_x
	, accel_y
	, accel_z
	, power_current
	, log_type
	, power_voltage
	, temperature
	, wind_speed
	, soil_moisture
	, wind_direction
	, raindrop
	, humidity
	, barometric_pressure
	, wind_speed_average
	, wind_gust
	, wind_direction_average
	, rain_rate
FROM ` + NewTableName + `
WHERE submitted_at < CURRENT_TIMESTAMP
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
		// freelancer 20200110 end
	} else {
		ram_key := ZT(I.ToS(sta_id))
		query := ram_key + `
SELECT id "rec", submitted_at, level_sensor
	, power_current, power_voltage, accel_x, accel_y
FROM station_logs
WHERE station_id = ` + ZI(sta_id) + `
ORDER BY submitted_at DESC
LIMIT 1
`
		return sql.PG.CQFirstMap(`station_logs`, ram_key, query)
	}
}

func IsPublicStation(sta_id int64) (isPublic bool) {
	ram_key := ZT(I.ToS(sta_id))
	query := ram_key + `
		SELECT COALESCE(public, false)
		FROM stations
		WHERE id = ` + ZI(sta_id)

	err := sql.PG.Adapter.Get(&isPublic, query)
	if err != nil {
		L.LOG.Error(err)
	}

	return
}

// 2025-02-27 Ahmad Habibi
func AllGroupsWithStations() (M.SX, error) {
	var res = M.SX{}

	query := `WITH
	station_data AS (
		SELECT
			g.name AS group_name,
			COALESCE(s.imei, '') AS imei,
			COALESCE(s.name, '') AS station_name,
			COALESCE(last_level_sensor, 0.0) AS level_sensor,
			COALESCE(TO_CHAR(last_submitted_at, 'YYYY-MM-DD HH24:MI:SS'), '') AS last_active,
			CASE
				WHEN s.last_submitted_at IS NULL THEN 0
				ELSE EXTRACT(EPOCH FROM (NOW() - s.last_submitted_at::TIMESTAMP))::INT
			END AS last_active_sec
		FROM groups g
		LEFT JOIN stations s ON g.id = s.group_id
	)

	SELECT
		group_name,
		CASE
			WHEN COUNT(imei) = 0 OR BOOL_AND(imei IS NULL OR imei = '') THEN '{}'::json
			ELSE
			JSON_OBJECT_AGG(imei, JSON_BUILD_OBJECT(
				'imei', imei,
				'station_name', station_name,
				'level_sensor', level_sensor,
				'last_active', last_active,
				'last_active_sec', last_active_sec
			))
		END AS group_data
	FROM station_data
	GROUP BY group_name
	`

	rows, err := sql.PG.Adapter.Query(query)
	if err != nil {
		L.LOG.Error(err)
		return res, err
	}

	for rows.Next() {
		var groupName string
		var groupData []byte

		if err := rows.Scan(&groupName, &groupData); err != nil {
			L.LOG.Error(err)
			return res, err
		}

		var data M.SX
		if err := json.Unmarshal(groupData, &data); err != nil {
			L.LOG.Error(err)
			return res, err
		}

		res[groupName] = data
	}

	return res, nil
}

// 2025-09-24 Ahmad Habibi
func SearchAnomalies_StationLogs() A.X {
	var res = A.X{}

	query := `SELECT
		x1.id AS id,
		x2.name AS name,
		x1.submitted_at AS submitted_at
	FROM station_logs x1
	LEFT JOIN stations x2 ON x1.station_id = x2.id
	WHERE x1.submitted_at > NOW()
	ORDER BY x1.submitted_at DESC`

	rows, err := sql.PG.Adapter.Query(query)
	if err != nil {
		L.LOG.Error(err)
		return res
	}

	for rows.Next() {
		var id uint64
		var stationName string
		var submittedAt time.Time
		if err := rows.Scan(
			&id, &stationName, &submittedAt,
		); err != nil {
			L.LOG.Error(err)
			return res
		}

		var row = M.SX{
			"id":           id,
			"station_name": stationName,
			"submitted_at": submittedAt,
		}

		res = append(res, row)
	}

	return res
}

// 2025-09-26 Ahmad Habibi
func DeleteStationLogById(id uint64) error {
	_, err := sql.PG.Adapter.Exec(`DELETE FROM station_logs WHERE id = $1`, id)
	if err != nil {
		L.LOG.Error(err)
		return errors.New(`failed to delete station log`)
	}

	return nil
}
