-- cancel trigger
DROP TRIGGER trigger_ai_station_minutes ON station_minutes;
DROP TRIGGER trigger_ai_station_hours  ON station_hours;
DROP TRIGGER trigger_ai_station_logs ON station_logs;

alter table "public"."station_logs" 
ADD COLUMN   "humidity" int4,
ADD COLUMN   "barometric_pressure" float8,
ADD COLUMN   "wind_speed_average" float8,
ADD COLUMN   "wind_gust" float8,
ADD COLUMN   "wind_direction_average" float8,
ADD COLUMN   "rain_rate" float8;

ALTER TABLE public.stations
ADD COLUMN last_submitted_at timestamp without time zone,
ADD COLUMN last_level_sensor float8;

-- MUST BE as postgres
GRANT ALL ON TABLESPACE data2 TO geo;
GRANT ALL ON TABLESPACE data2 TO geo2;

-- Create function
CREATE OR REPLACE FUNCTION "public"."check_table_exist"("table_name" text)
  RETURNS "pg_catalog"."bool" AS $BODY$
DECLARE
    sql_str             varchar(10000);
    cur_ctd REFCURSOR;
    is_exist boolean;
BEGIN
    sql_str := 'SELECT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = ''public'' AND tablename = '''||table_name||''')';
    OPEN cur_ctd FOR EXECUTE sql_str;
    fetch cur_ctd into is_exist;
    close cur_ctd;
    return is_exist;
  END;
$BODY$
  LANGUAGE plpgsql;


--
CREATE OR REPLACE FUNCTION "public"."create_station_logs_station"("station_id" int4)
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE
    sql_str             varchar(10000);
    cur_ctd REFCURSOR;
    is_exist boolean;
BEGIN
    EXECUTE 'CREATE TABLE IF NOT EXISTS station_logs_'||station_id||' (
  id int4 NOT NULL DEFAULT nextval(''station_logs_id_seq''::regclass),
  created_at timestamp(6),
  updated_at timestamp(6),
  deleted_at timestamp(6),
  submitted_at timestamp(6) NOT NULL,
  sequence int4,
  level_sensor float8,
  accel_x float8,
  accel_y float8,
  accel_z float8,
  power_current float8,
  ip_address varchar(50) COLLATE "default",
  log_type int4,
  station_id int4 NOT NULL,
  power_voltage float8,
  data jsonb,
  is_deleted bool NOT NULL DEFAULT false,
  temperature float8,
  wind_speed float8,
  soil_moisture float8,
  wind_direction float8,
  raindrop float8,
  humidity int4,
  barometric_pressure float8, 
  wind_speed_average float8,
  wind_gust float8,
  wind_direction_average float8,
  rain_rate float8
)';

  execute 'ALTER TABLE station_logs_'||station_id||' OWNER TO geo';
  BEGIN
    execute 'ALTER TABLE ONLY station_logs_'||station_id||' ADD CONSTRAINT uniq_sid_sat_'||station_id||' UNIQUE (submitted_at)';
  EXCEPTION
    WHEN duplicate_object THEN RAISE NOTICE 'Table constraint uniq_sid_sat_ already exists';
  END;
  BEGIN
    execute 'ALTER TABLE ONLY station_logs_'||station_id||' ADD CONSTRAINT station_logs_'||station_id||'_station_fk FOREIGN KEY (station_id) REFERENCES stations(id)';
  EXCEPTION
    WHEN duplicate_object THEN RAISE NOTICE 'Table constraint _station_fk already exists';
  END;
   execute 'CREATE INDEX IF NOT EXISTS station_logs_'||station_id||'_submitted_at ON station_logs_' ||station_id||'(submitted_at) ' ;
   execute 'CREATE INDEX IF NOT EXISTS station_logs_'||station_id||'_epoch ON station_logs_' ||station_id||'(EXTRACT(EPOCH FROM submitted_at)) ' ;
END;
$BODY$
  LANGUAGE plpgsql;

-- 
CREATE OR REPLACE FUNCTION "public"."create_station_hours_station"("station_id" int4)
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE
    sql_str             varchar(10000);
    cur_ctd REFCURSOR;
    is_exist boolean;
BEGIN
  execute 'CREATE TABLE IF NOT EXISTS station_hours_'||station_id||' (
  at timestamp(6),
  slid int4 NOT NULL,
  sid int4 NOT NULL
  ) ';
  execute 'ALTER TABLE station_hours_'||station_id||' OWNER TO geo';
  
  BEGIN
   execute 'ALTER TABLE ONLY station_hours_'||station_id||' ADD CONSTRAINT station_hours_pkey_'||station_id||' PRIMARY KEY (slid)';
  EXCEPTION
    WHEN duplicate_object THEN RAISE NOTICE 'Table constraint station_hours_pkey_ already exists';
  END;
  execute 'CREATE INDEX IF NOT EXISTS station_hours_at_idx_'||station_id||' ON station_hours_'||station_id||' USING btree (at) ';

  execute 'CREATE UNIQUE INDEX IF NOT EXISTS uniq_hh_'||station_id||' ON station_hours_'||station_id||' USING btree (uniq_hours(at)) ';
  END;
$BODY$
  LANGUAGE plpgsql;

--
CREATE OR REPLACE FUNCTION "public"."create_station_minutes_station"("station_id" int4)
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE
BEGIN
  execute 'CREATE TABLE IF NOT EXISTS station_minutes_'||station_id||' (
  at timestamp(6),
  slid int4 NOT NULL,
  sid int4 NOT NULL
  ) ';
  execute 'ALTER TABLE station_minutes_'||station_id||' OWNER TO geo';
  BEGIN
    execute 'ALTER TABLE ONLY station_minutes_'||station_id||' ADD CONSTRAINT station_minutes_pkey_'||station_id||' PRIMARY KEY (slid)';
  EXCEPTION
    WHEN duplicate_object THEN RAISE NOTICE 'Table constraint station_minutes_pkey_ already exists';
  END;
  execute 'CREATE INDEX IF NOT EXISTS station_minutes_at_idx_'||station_id||' ON station_minutes_'||station_id||' USING btree (at) ';
  execute 'CREATE INDEX IF NOT EXISTS station_minutes_epoch_'||station_id||' ON station_minutes_'||station_id||' (EXTRACT(EPOCH FROM at)) ';
  execute 'CREATE UNIQUE INDEX IF NOT EXISTS uniq_mm_'||station_id||' ON station_minutes_'||station_id||' USING btree (uniq_minute(at)) ';
 END;
$BODY$
  LANGUAGE plpgsql;

-- Update script
CREATE OR REPLACE FUNCTION "public"."fn_ai_station_minutes"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
   declare
     new_table_name text;
     is_exist boolean;
   BEGIN
      new_table_name := 'station_minutes_'||new.sid;
      select check_table_exist(new_table_name) into is_exist;
      if(not is_exist) then
        perform create_station_minutes_station(new.sid);
      end if;
      EXECUTE format('INSERT INTO %I SELECT $1.*', new_table_name) USING NEW;
      RETURN NULL;
   END;
$BODY$
  LANGUAGE plpgsql;


--
CREATE OR REPLACE FUNCTION "public"."fn_ai_station_hours"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
   declare
     new_table_name text;
     is_exist boolean;
   BEGIN
      new_table_name := 'station_hours_'||new.sid;
      select check_table_exist(new_table_name) into is_exist;
      if(not is_exist) then
        perform create_station_hours_station(new.sid);
      end if;
      EXECUTE format('INSERT INTO %I SELECT $1.*', new_table_name) USING NEW;
      RETURN NULL;
   END;
$BODY$
  LANGUAGE plpgsql;

--
CREATE OR REPLACE FUNCTION "public"."fn_ai_station_logs"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
   declare
     new_table_name text;
     is_exist boolean;
   BEGIN
      new_table_name := 'station_logs_'||new.station_id;
      select check_table_exist(new_table_name) into is_exist;
      if(not is_exist) then
        perform create_station_logs_station(new.station_id);
      end if;
      EXECUTE format('INSERT INTO %I SELECT $1.*', new_table_name) USING NEW;
      RETURN NULL;
   END;
$BODY$
  LANGUAGE plpgsql;

--
CREATE OR REPLACE FUNCTION "public"."move_station_hours_station"()
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE
    is_exist boolean;
    new_table_name text;
    station_id_temp int;
BEGIN
    FOR station_id_temp in select id from stations where is_deleted = true loop
        new_table_name := 'station_hours_'||station_id_temp;
        select check_table_exist(new_table_name) into is_exist;
        if(not is_exist) then
            perform create_station_hours_station(station_id_temp);
        end if;
        execute 'insert into '||new_table_name||' select * from station_hours where sid = '||station_id_temp||' ON CONFLICT DO NOTHING';
    end loop;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--
CREATE OR REPLACE FUNCTION "public"."move_station_logs_station"()
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE
    is_exist boolean;
    new_table_name text;
    station_id_temp int;
BEGIN
    FOR station_id_temp in select id from stations where is_deleted = true loop
        new_table_name := 'station_logs_'||station_id_temp;
        select check_table_exist(new_table_name) into is_exist;
        if(not is_exist) then
            perform create_station_logs_station(station_id_temp);
        end if;
        execute 'insert into '||new_table_name||' select * from station_logs where station_id = '||station_id_temp ||' ON CONFLICT DO NOTHING' ;
        --execute 'delete from station_logs where station_id = '||station_id_temp;
        -- Update submitted_at, level_sensor from station_logs into station
        execute 'update stations set (last_submitted_at, last_level_sensor) =
        (SELECT submitted_at, level_sensor FROM '||new_table_name||
        ' ORDER BY submitted_at DESC NULLS LAST
        LIMIT 1)
        where id = '||station_id_temp;
    end loop;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--
CREATE OR REPLACE FUNCTION "public"."move_station_minutes_station"()
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE
    is_exist boolean;
    new_table_name text;
    station_id_temp int;
BEGIN
    FOR station_id_temp in select id from stations where is_deleted = true loop
        new_table_name := 'station_minutes_'||station_id_temp;
        select check_table_exist(new_table_name) into is_exist;
        if(not is_exist) then
            perform create_station_minutes_station(station_id_temp);
        end if;
        execute 'insert into '||new_table_name||' select * from station_minutes where sid = '||station_id_temp||' ON CONFLICT DO NOTHING';
    end loop;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--
CREATE TRIGGER trigger_ai_station_logs AFTER INSERT ON station_logs
FOR EACH ROW EXECUTE PROCEDURE fn_ai_station_logs();
--
CREATE TRIGGER trigger_ai_station_minutes AFTER INSERT ON station_minutes
FOR EACH ROW EXECUTE PROCEDURE fn_ai_station_minutes();
--
CREATE TRIGGER trigger_ai_station_hours AFTER INSERT ON station_hours
FOR EACH ROW EXECUTE PROCEDURE fn_ai_station_hours();


-- migrate last 1 month
-- NOT in (359,259,341,318,326,328,413,449,437,452,432,274,330,332,334,349,453,342,344,443,346,347,350,351,354,355,356,358,360,361,362,361,362,363,364,365,370,377,340,378,383,407,435,416,388,367,319,386,424,403,329,352,444,353,316,357,391,412,374,375,376,425,442,325,369,421,249,423,427,373,382,438,454,455,456,371,372,450,380,404,394,428,440,436,429,439,445,431,446,457,313,408,448,384,441,430,285,323,167,296,307,314,339,261,336,298,387,333,331,385,337,338,343,345,284,110,395,309,308,317,399,398,396,410,310,411,409,397,389,415,414,320,348,379,392,400,405,419,418,406,245,434,426,422,420,433,417,247,99,390,327,447,451)
do
$BODY$
DECLARE
    is_exist boolean;
    new_table_name text;
    station_id_temp int;
BEGIN
    FOR station_id_temp in select id from stations where id IN(629,630) loop -- last_submitted_at IS NULL loop
        new_table_name := 'station_logs_'||station_id_temp;
        
        select check_table_exist(new_table_name) into is_exist;
        if(not is_exist) then
            perform create_station_logs_station(station_id_temp);
        end if;
        raise notice 'Processing: %', new_table_name;
        execute 'insert into '||new_table_name||' select * from station_logs where station_id = '||station_id_temp ||'  ON CONFLICT DO NOTHING' ;
        --execute 'delete from station_logs where station_id = '||station_id_temp;
        -- Update submitted_at, level_sensor from station_logs into station
        execute 'update stations set (last_submitted_at, last_level_sensor) = (SELECT submitted_at, level_sensor FROM '
        ||new_table_name
        ||' ORDER BY submitted_at DESC NULLS LAST LIMIT 1) where id = '
        ||station_id_temp;
    end loop;
  END;
$BODY$
  LANGUAGE plpgsql ;

do
$BODY$
DECLARE
    is_exist boolean;
    new_table_name text;
    station_id_temp int;
BEGIN
    FOR station_id_temp in select id from stations where id IN(629,630) loop --is_deleted = false loop
        new_table_name := 'station_hours_'||station_id_temp;
        select check_table_exist(new_table_name) into is_exist;
        if(not is_exist) then
            perform create_station_hours_station(station_id_temp);
        end if;
        raise notice 'Processing: %', new_table_name;
        execute 'insert into '||new_table_name||' select * from station_hours where sid = '||station_id_temp||' ON CONFLICT DO NOTHING'; -- and at <= ''2019-12-14'' 
    end loop;
  END;
$BODY$
  LANGUAGE plpgsql;

-- create index for faster station_minutes for faster migration
CREATE INDEX station_minutes_sid_at ON station_minutes(sid, at) ;

do
$BODY$
DECLARE
    is_exist boolean;
    new_table_name text;
    station_id_temp int;
BEGIN
    FOR station_id_temp in select id from stations where id IN(629,630) loop --is_deleted = false loop
        new_table_name := 'station_minutes_'||station_id_temp;
        select check_table_exist(new_table_name) into is_exist;
        if(not is_exist) then
            perform create_station_minutes_station(station_id_temp);
        end if;
        raise notice 'Processing: %', new_table_name;
        execute 'insert into '||new_table_name||' select * from station_minutes where sid = '||station_id_temp||' ON CONFLICT DO NOTHING'; -- and at <= ''2019-12-14'' 
    end loop;
  END;
$BODY$
  LANGUAGE plpgsql;

-- 
do
$BODY$
DECLARE
BEGIN
  perform move_station_logs_station();
    perform move_station_hours_station();
    perform move_station_minutes_station();
  END;
$BODY$
  LANGUAGE plpgsql;

-- create index on station_logs submitted at
do 
$BODY$
DECLARE
    new_table_name text;
    station_id_temp int;
BEGIN
   FOR station_id_temp in select id from stations where is_deleted = false order by last_submitted_at asc nulls first loop
      new_table_name := 'station_logs_'||station_id_temp;
        raise notice 'Processing: %', new_table_name;      
      execute 'CREATE INDEX IF NOT EXISTS '||new_table_name||'_submitted_at ON ' ||new_table_name||'(submitted_at) ' ;
      -- CREATE INDEX IF NOT EXISTS station_logs_450_epoch ON station_logs_450(EXTRACT(EPOCH FROM submitted_at)) ' ;
      execute 'CREATE INDEX IF NOT EXISTS '||new_table_name||'_epoch ON ' ||new_table_name||'(EXTRACT(EPOCH FROM submitted_at)) ' ;
      execute 'DROP INDEX IF EXISTS '||new_table_name||'_station_id' ;
   end loop;
END;
$BODY$
	LANGUAGE plpgsql;

-- slow index station minutes station hours epoch
do 
$BODY$
DECLARE
    new_table_name text;
    station_id_temp int;
BEGIN
   FOR station_id_temp in select id from stations where is_deleted = false loop
        raise notice 'Processing: epoch_%', station_id_temp;      
      execute 'DROP INDEX IF EXISTS station_hours_epoch_'||station_id_temp||'_epoch';
      execute 'DROP INDEX IF EXISTS station_hours_epoch_'||station_id_temp;
      execute 'DROP INDEX IF EXISTS station_minutes_epoch_'||station_id_temp||'_epoch';
      execute 'CREATE INDEX IF NOT EXISTS station_minutes_epoch_'||station_id_temp||' ON station_minutes_' ||station_id_temp||'(EXTRACT(EPOCH FROM at)) ' ;
   end loop;
END;
$BODY$
	LANGUAGE plpgsql;

-- template to do mass manipulation on station tables
do 
$BODY$
DECLARE
    new_table_name text;
    station_id_temp int;
BEGIN
   FOR station_id_temp in select id from stations where is_deleted = false loop
      new_table_name := 'station_logs_'||station_id_temp;
      execute 'ALTER TABLE station_logs_ '||new_table_name||' ' ; -- TODO: modify this
   end loop;
END;
$BODY$
	LANGUAGE plpgsql;

-- import 458 and 451
INSERT INTO station_hours(at, slid, sid) SELECT submitted_at, id, station_id FROM station_logs WHERE station_id IN(629,630) ON CONFLICT DO NOTHING;
INSERT INTO station_minutes(at, slid, sid) SELECT submitted_at, id, station_id FROM station_logs WHERE station_id IN(629,630) ON CONFLICT DO NOTHING;
