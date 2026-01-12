--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2 (Debian 16.2-1.pgdg120+2)
-- Dumped by pg_dump version 16.2 (Debian 16.2-1.pgdg120+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: check_table_exist(text); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.check_table_exist(table_name text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.check_table_exist(table_name text) OWNER TO geo;

--
-- Name: create_station_hours_station(integer); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.create_station_hours_station(station_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.create_station_hours_station(station_id integer) OWNER TO geo;

--
-- Name: create_station_logs_station(integer); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.create_station_logs_station(station_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.create_station_logs_station(station_id integer) OWNER TO geo;

--
-- Name: create_station_minutes_station(integer); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.create_station_minutes_station(station_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.create_station_minutes_station(station_id integer) OWNER TO geo;

--
-- Name: drop_tables_with_name(); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.drop_tables_with_name() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN (SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%station%')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || table_name || ' CASCADE';
    END LOOP;
END;
$$;


ALTER FUNCTION public.drop_tables_with_name() OWNER TO geo;

--
-- Name: fn_ai_station_hours(); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.fn_ai_station_hours() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.fn_ai_station_hours() OWNER TO geo;

--
-- Name: fn_ai_station_logs(); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.fn_ai_station_logs() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.fn_ai_station_logs() OWNER TO geo;

--
-- Name: fn_ai_station_minutes(); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.fn_ai_station_minutes() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.fn_ai_station_minutes() OWNER TO geo;

--
-- Name: move_station_hours_station(); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.move_station_hours_station() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.move_station_hours_station() OWNER TO geo;

--
-- Name: move_station_logs_station(); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.move_station_logs_station() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.move_station_logs_station() OWNER TO geo;

--
-- Name: move_station_minutes_station(); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.move_station_minutes_station() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.move_station_minutes_station() OWNER TO geo;

--
-- Name: uniq_hours(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.uniq_hours(some_time timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
select to_char($1, 'YYYYDDDHH24');
$_$;


ALTER FUNCTION public.uniq_hours(some_time timestamp without time zone) OWNER TO geo;

--
-- Name: uniq_minute(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION public.uniq_minute(some_time timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
select to_char($1, 'YYYYDDDHH24MI');
$_$;


ALTER FUNCTION public.uniq_minute(some_time timestamp without time zone) OWNER TO geo;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: groups; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.groups (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    name character varying(50),
    note text,
    updated_by bigint,
    deleted_by bigint,
    restored_by bigint,
    created_by bigint,
    unique_id character varying(240),
    is_deleted boolean DEFAULT false NOT NULL,
    data jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.groups OWNER TO geo;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.groups_id_seq OWNER TO geo;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: predictions; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.predictions (
    id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    predict_epoch double precision,
    station_id integer NOT NULL,
    level double precision NOT NULL
);


ALTER TABLE public.predictions OWNER TO geo;

--
-- Name: predictions_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE public.predictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.predictions_id_seq OWNER TO geo;

--
-- Name: predictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE public.predictions_id_seq OWNED BY public.predictions.id;


--
-- Name: station_hours; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours (
    at timestamp without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours OWNER TO geo;

--
-- Name: station_hours_110; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_110 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_110 OWNER TO geo;

--
-- Name: station_hours_167; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_167 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_167 OWNER TO geo;

--
-- Name: station_hours_245; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_245 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_245 OWNER TO geo;

--
-- Name: station_hours_247; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_247 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_247 OWNER TO geo;

--
-- Name: station_hours_249; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_249 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_249 OWNER TO geo;

--
-- Name: station_hours_259; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_259 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_259 OWNER TO geo;

--
-- Name: station_hours_261; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_261 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_261 OWNER TO geo;

--
-- Name: station_hours_284; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_284 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_284 OWNER TO geo;

--
-- Name: station_hours_285; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_285 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_285 OWNER TO geo;

--
-- Name: station_hours_296; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_296 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_296 OWNER TO geo;

--
-- Name: station_hours_298; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_298 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_298 OWNER TO geo;

--
-- Name: station_hours_307; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_307 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_307 OWNER TO geo;

--
-- Name: station_hours_308; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_308 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_308 OWNER TO geo;

--
-- Name: station_hours_309; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_309 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_309 OWNER TO geo;

--
-- Name: station_hours_310; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_310 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_310 OWNER TO geo;

--
-- Name: station_hours_314; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_314 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_314 OWNER TO geo;

--
-- Name: station_hours_316; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_316 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_316 OWNER TO geo;

--
-- Name: station_hours_317; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_317 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_317 OWNER TO geo;

--
-- Name: station_hours_319; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_319 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_319 OWNER TO geo;

--
-- Name: station_hours_320; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_320 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_320 OWNER TO geo;

--
-- Name: station_hours_323; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_323 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_323 OWNER TO geo;

--
-- Name: station_hours_326; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_326 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_326 OWNER TO geo;

--
-- Name: station_hours_327; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_327 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_327 OWNER TO geo;

--
-- Name: station_hours_329; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_329 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_329 OWNER TO geo;

--
-- Name: station_hours_330; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_330 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_330 OWNER TO geo;

--
-- Name: station_hours_331; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_331 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_331 OWNER TO geo;

--
-- Name: station_hours_333; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_333 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_333 OWNER TO geo;

--
-- Name: station_hours_334; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_334 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_334 OWNER TO geo;

--
-- Name: station_hours_336; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_336 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_336 OWNER TO geo;

--
-- Name: station_hours_337; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_337 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_337 OWNER TO geo;

--
-- Name: station_hours_338; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_338 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_338 OWNER TO geo;

--
-- Name: station_hours_339; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_339 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_339 OWNER TO geo;

--
-- Name: station_hours_343; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_343 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_343 OWNER TO geo;

--
-- Name: station_hours_346; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_346 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_346 OWNER TO geo;

--
-- Name: station_hours_347; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_347 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_347 OWNER TO geo;

--
-- Name: station_hours_348; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_348 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_348 OWNER TO geo;

--
-- Name: station_hours_349; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_349 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_349 OWNER TO geo;

--
-- Name: station_hours_350; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_350 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_350 OWNER TO geo;

--
-- Name: station_hours_351; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_351 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_351 OWNER TO geo;

--
-- Name: station_hours_352; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_352 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_352 OWNER TO geo;

--
-- Name: station_hours_353; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_353 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_353 OWNER TO geo;

--
-- Name: station_hours_354; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_354 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_354 OWNER TO geo;

--
-- Name: station_hours_355; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_355 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_355 OWNER TO geo;

--
-- Name: station_hours_356; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_356 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_356 OWNER TO geo;

--
-- Name: station_hours_357; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_357 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_357 OWNER TO geo;

--
-- Name: station_hours_358; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_358 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_358 OWNER TO geo;

--
-- Name: station_hours_359; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_359 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_359 OWNER TO geo;

--
-- Name: station_hours_360; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_360 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_360 OWNER TO geo;

--
-- Name: station_hours_361; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_361 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_361 OWNER TO geo;

--
-- Name: station_hours_362; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_362 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_362 OWNER TO geo;

--
-- Name: station_hours_363; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_363 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_363 OWNER TO geo;

--
-- Name: station_hours_364; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_364 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_364 OWNER TO geo;

--
-- Name: station_hours_365; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_365 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_365 OWNER TO geo;

--
-- Name: station_hours_370; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_370 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_370 OWNER TO geo;

--
-- Name: station_hours_371; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_371 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_371 OWNER TO geo;

--
-- Name: station_hours_372; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_372 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_372 OWNER TO geo;

--
-- Name: station_hours_373; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_373 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_373 OWNER TO geo;

--
-- Name: station_hours_374; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_374 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_374 OWNER TO geo;

--
-- Name: station_hours_375; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_375 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_375 OWNER TO geo;

--
-- Name: station_hours_376; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_376 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_376 OWNER TO geo;

--
-- Name: station_hours_377; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_377 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_377 OWNER TO geo;

--
-- Name: station_hours_378; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_378 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_378 OWNER TO geo;

--
-- Name: station_hours_379; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_379 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_379 OWNER TO geo;

--
-- Name: station_hours_380; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_380 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_380 OWNER TO geo;

--
-- Name: station_hours_382; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_382 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_382 OWNER TO geo;

--
-- Name: station_hours_383; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_383 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_383 OWNER TO geo;

--
-- Name: station_hours_385; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_385 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_385 OWNER TO geo;

--
-- Name: station_hours_387; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_387 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_387 OWNER TO geo;

--
-- Name: station_hours_389; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_389 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_389 OWNER TO geo;

--
-- Name: station_hours_390; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_390 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_390 OWNER TO geo;

--
-- Name: station_hours_391; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_391 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_391 OWNER TO geo;

--
-- Name: station_hours_392; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_392 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_392 OWNER TO geo;

--
-- Name: station_hours_395; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_395 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_395 OWNER TO geo;

--
-- Name: station_hours_396; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_396 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_396 OWNER TO geo;

--
-- Name: station_hours_397; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_397 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_397 OWNER TO geo;

--
-- Name: station_hours_398; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_398 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_398 OWNER TO geo;

--
-- Name: station_hours_399; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_399 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_399 OWNER TO geo;

--
-- Name: station_hours_400; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_400 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_400 OWNER TO geo;

--
-- Name: station_hours_403; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_403 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_403 OWNER TO geo;

--
-- Name: station_hours_404; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_404 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_404 OWNER TO geo;

--
-- Name: station_hours_405; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_405 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_405 OWNER TO geo;

--
-- Name: station_hours_406; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_406 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_406 OWNER TO geo;

--
-- Name: station_hours_407; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_407 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_407 OWNER TO geo;

--
-- Name: station_hours_409; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_409 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_409 OWNER TO geo;

--
-- Name: station_hours_410; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_410 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_410 OWNER TO geo;

--
-- Name: station_hours_411; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_411 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_411 OWNER TO geo;

--
-- Name: station_hours_412; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_412 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_412 OWNER TO geo;

--
-- Name: station_hours_413; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_413 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_413 OWNER TO geo;

--
-- Name: station_hours_414; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_414 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_414 OWNER TO geo;

--
-- Name: station_hours_415; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_415 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_415 OWNER TO geo;

--
-- Name: station_hours_417; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_417 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_417 OWNER TO geo;

--
-- Name: station_hours_418; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_418 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_418 OWNER TO geo;

--
-- Name: station_hours_419; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_419 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_419 OWNER TO geo;

--
-- Name: station_hours_420; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_420 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_420 OWNER TO geo;

--
-- Name: station_hours_422; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_422 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_422 OWNER TO geo;

--
-- Name: station_hours_423; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_423 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_423 OWNER TO geo;

--
-- Name: station_hours_425; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_425 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_425 OWNER TO geo;

--
-- Name: station_hours_428; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_428 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_428 OWNER TO geo;

--
-- Name: station_hours_429; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_429 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_429 OWNER TO geo;

--
-- Name: station_hours_430; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_430 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_430 OWNER TO geo;

--
-- Name: station_hours_433; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_433 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_433 OWNER TO geo;

--
-- Name: station_hours_434; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_434 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_434 OWNER TO geo;

--
-- Name: station_hours_435; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_435 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_435 OWNER TO geo;

--
-- Name: station_hours_436; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_436 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_436 OWNER TO geo;

--
-- Name: station_hours_437; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_437 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_437 OWNER TO geo;

--
-- Name: station_hours_443; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_443 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_443 OWNER TO geo;

--
-- Name: station_hours_447; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_447 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_447 OWNER TO geo;

--
-- Name: station_hours_451; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_451 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_451 OWNER TO geo;

--
-- Name: station_hours_452; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_452 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_452 OWNER TO geo;

--
-- Name: station_hours_453; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_453 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_453 OWNER TO geo;

--
-- Name: station_hours_454; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_454 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_454 OWNER TO geo;

--
-- Name: station_hours_455; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_455 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_455 OWNER TO geo;

--
-- Name: station_hours_459; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_459 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_459 OWNER TO geo;

--
-- Name: station_hours_460; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_460 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_460 OWNER TO geo;

--
-- Name: station_hours_461; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_461 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_461 OWNER TO geo;

--
-- Name: station_hours_462; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_462 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_462 OWNER TO geo;

--
-- Name: station_hours_463; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_463 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_463 OWNER TO geo;

--
-- Name: station_hours_464; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_464 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_464 OWNER TO geo;

--
-- Name: station_hours_465; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_465 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_465 OWNER TO geo;

--
-- Name: station_hours_466; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_466 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_466 OWNER TO geo;

--
-- Name: station_hours_467; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_467 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_467 OWNER TO geo;

--
-- Name: station_hours_469; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_469 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_469 OWNER TO geo;

--
-- Name: station_hours_470; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_470 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_470 OWNER TO geo;

--
-- Name: station_hours_473; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_473 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_473 OWNER TO geo;

--
-- Name: station_hours_474; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_474 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_474 OWNER TO geo;

--
-- Name: station_hours_500; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_500 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_500 OWNER TO geo;

--
-- Name: station_hours_501; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_501 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_501 OWNER TO geo;

--
-- Name: station_hours_502; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_502 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_502 OWNER TO geo;

--
-- Name: station_hours_503; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_503 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_503 OWNER TO geo;

--
-- Name: station_hours_504; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_504 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_504 OWNER TO geo;

--
-- Name: station_hours_505; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_505 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_505 OWNER TO geo;

--
-- Name: station_hours_514; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_514 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_514 OWNER TO geo;

--
-- Name: station_hours_530; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_530 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_530 OWNER TO geo;

--
-- Name: station_hours_533; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_533 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_533 OWNER TO geo;

--
-- Name: station_hours_537; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_537 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_537 OWNER TO geo;

--
-- Name: station_hours_539; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_539 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_539 OWNER TO geo;

--
-- Name: station_hours_553; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_553 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_553 OWNER TO geo;

--
-- Name: station_hours_556; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_556 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_556 OWNER TO geo;

--
-- Name: station_hours_561; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_561 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_561 OWNER TO geo;

--
-- Name: station_hours_565; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_565 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_565 OWNER TO geo;

--
-- Name: station_hours_575; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_575 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_575 OWNER TO geo;

--
-- Name: station_hours_577; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_577 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_577 OWNER TO geo;

--
-- Name: station_hours_578; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_578 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_578 OWNER TO geo;

--
-- Name: station_hours_594; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_594 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_594 OWNER TO geo;

--
-- Name: station_hours_595; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_595 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_595 OWNER TO geo;

--
-- Name: station_hours_597; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_597 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_597 OWNER TO geo;

--
-- Name: station_hours_601; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_601 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_601 OWNER TO geo;

--
-- Name: station_hours_602; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_602 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_602 OWNER TO geo;

--
-- Name: station_hours_603; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_603 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_603 OWNER TO geo;

--
-- Name: station_hours_604; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_604 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_604 OWNER TO geo;

--
-- Name: station_hours_605; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_605 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_605 OWNER TO geo;

--
-- Name: station_hours_606; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_606 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_606 OWNER TO geo;

--
-- Name: station_hours_607; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_607 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_607 OWNER TO geo;

--
-- Name: station_hours_608; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_608 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_608 OWNER TO geo;

--
-- Name: station_hours_609; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_609 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_609 OWNER TO geo;

--
-- Name: station_hours_610; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_610 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_610 OWNER TO geo;

--
-- Name: station_hours_611; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_611 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_611 OWNER TO geo;

--
-- Name: station_hours_615; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_615 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_615 OWNER TO geo;

--
-- Name: station_hours_616; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_616 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_616 OWNER TO geo;

--
-- Name: station_hours_617; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_617 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_617 OWNER TO geo;

--
-- Name: station_hours_618; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_618 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_618 OWNER TO geo;

--
-- Name: station_hours_619; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_619 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_619 OWNER TO geo;

--
-- Name: station_hours_620; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_620 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_620 OWNER TO geo;

--
-- Name: station_hours_622; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_622 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_622 OWNER TO geo;

--
-- Name: station_hours_624; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_624 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_624 OWNER TO geo;

--
-- Name: station_hours_625; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_625 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_625 OWNER TO geo;

--
-- Name: station_hours_628; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_628 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_628 OWNER TO geo;

--
-- Name: station_hours_631; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_631 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_631 OWNER TO geo;

--
-- Name: station_hours_632; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_632 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_632 OWNER TO geo;

--
-- Name: station_hours_633; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_633 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_633 OWNER TO geo;

--
-- Name: station_hours_636; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_636 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_636 OWNER TO geo;

--
-- Name: station_hours_99; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_hours_99 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_hours_99 OWNER TO geo;

--
-- Name: station_logs; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    submitted_at timestamp without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs OWNER TO geo;

--
-- Name: station_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE public.station_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.station_logs_id_seq OWNER TO geo;

--
-- Name: station_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE public.station_logs_id_seq OWNED BY public.station_logs.id;


--
-- Name: station_logs_110; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_110 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_110 OWNER TO geo;

--
-- Name: station_logs_167; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_167 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_167 OWNER TO geo;

--
-- Name: station_logs_245; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_245 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_245 OWNER TO geo;

--
-- Name: station_logs_247; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_247 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_247 OWNER TO geo;

--
-- Name: station_logs_249; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_249 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_249 OWNER TO geo;

--
-- Name: station_logs_259; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_259 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_259 OWNER TO geo;

--
-- Name: station_logs_261; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_261 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_261 OWNER TO geo;

--
-- Name: station_logs_284; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_284 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_284 OWNER TO geo;

--
-- Name: station_logs_285; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_285 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_285 OWNER TO geo;

--
-- Name: station_logs_296; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_296 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_296 OWNER TO geo;

--
-- Name: station_logs_298; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_298 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_298 OWNER TO geo;

--
-- Name: station_logs_307; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_307 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_307 OWNER TO geo;

--
-- Name: station_logs_308; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_308 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_308 OWNER TO geo;

--
-- Name: station_logs_309; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_309 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_309 OWNER TO geo;

--
-- Name: station_logs_310; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_310 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_310 OWNER TO geo;

--
-- Name: station_logs_314; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_314 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_314 OWNER TO geo;

--
-- Name: station_logs_316; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_316 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_316 OWNER TO geo;

--
-- Name: station_logs_317; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_317 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_317 OWNER TO geo;

--
-- Name: station_logs_319; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_319 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_319 OWNER TO geo;

--
-- Name: station_logs_320; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_320 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_320 OWNER TO geo;

--
-- Name: station_logs_323; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_323 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_323 OWNER TO geo;

--
-- Name: station_logs_326; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_326 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_326 OWNER TO geo;

--
-- Name: station_logs_327; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_327 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_327 OWNER TO geo;

--
-- Name: station_logs_329; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_329 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_329 OWNER TO geo;

--
-- Name: station_logs_330; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_330 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_330 OWNER TO geo;

--
-- Name: station_logs_331; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_331 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_331 OWNER TO geo;

--
-- Name: station_logs_333; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_333 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_333 OWNER TO geo;

--
-- Name: station_logs_334; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_334 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_334 OWNER TO geo;

--
-- Name: station_logs_336; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_336 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_336 OWNER TO geo;

--
-- Name: station_logs_337; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_337 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_337 OWNER TO geo;

--
-- Name: station_logs_338; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_338 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_338 OWNER TO geo;

--
-- Name: station_logs_339; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_339 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_339 OWNER TO geo;

--
-- Name: station_logs_343; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_343 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_343 OWNER TO geo;

--
-- Name: station_logs_346; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_346 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_346 OWNER TO geo;

--
-- Name: station_logs_347; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_347 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_347 OWNER TO geo;

--
-- Name: station_logs_348; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_348 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_348 OWNER TO geo;

--
-- Name: station_logs_349; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_349 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_349 OWNER TO geo;

--
-- Name: station_logs_350; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_350 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_350 OWNER TO geo;

--
-- Name: station_logs_351; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_351 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_351 OWNER TO geo;

--
-- Name: station_logs_352; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_352 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_352 OWNER TO geo;

--
-- Name: station_logs_353; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_353 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_353 OWNER TO geo;

--
-- Name: station_logs_354; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_354 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_354 OWNER TO geo;

--
-- Name: station_logs_355; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_355 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_355 OWNER TO geo;

--
-- Name: station_logs_356; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_356 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_356 OWNER TO geo;

--
-- Name: station_logs_357; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_357 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_357 OWNER TO geo;

--
-- Name: station_logs_358; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_358 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_358 OWNER TO geo;

--
-- Name: station_logs_359; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_359 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_359 OWNER TO geo;

--
-- Name: station_logs_360; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_360 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_360 OWNER TO geo;

--
-- Name: station_logs_361; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_361 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_361 OWNER TO geo;

--
-- Name: station_logs_362; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_362 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_362 OWNER TO geo;

--
-- Name: station_logs_363; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_363 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_363 OWNER TO geo;

--
-- Name: station_logs_364; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_364 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_364 OWNER TO geo;

--
-- Name: station_logs_365; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_365 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_365 OWNER TO geo;

--
-- Name: station_logs_370; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_370 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_370 OWNER TO geo;

--
-- Name: station_logs_371; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_371 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_371 OWNER TO geo;

--
-- Name: station_logs_372; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_372 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_372 OWNER TO geo;

--
-- Name: station_logs_373; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_373 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_373 OWNER TO geo;

--
-- Name: station_logs_374; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_374 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_374 OWNER TO geo;

--
-- Name: station_logs_375; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_375 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_375 OWNER TO geo;

--
-- Name: station_logs_376; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_376 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_376 OWNER TO geo;

--
-- Name: station_logs_377; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_377 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_377 OWNER TO geo;

--
-- Name: station_logs_378; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_378 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_378 OWNER TO geo;

--
-- Name: station_logs_379; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_379 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_379 OWNER TO geo;

--
-- Name: station_logs_380; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_380 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_380 OWNER TO geo;

--
-- Name: station_logs_382; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_382 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_382 OWNER TO geo;

--
-- Name: station_logs_383; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_383 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_383 OWNER TO geo;

--
-- Name: station_logs_385; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_385 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_385 OWNER TO geo;

--
-- Name: station_logs_387; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_387 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_387 OWNER TO geo;

--
-- Name: station_logs_389; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_389 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_389 OWNER TO geo;

--
-- Name: station_logs_390; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_390 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_390 OWNER TO geo;

--
-- Name: station_logs_391; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_391 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_391 OWNER TO geo;

--
-- Name: station_logs_392; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_392 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_392 OWNER TO geo;

--
-- Name: station_logs_395; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_395 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_395 OWNER TO geo;

--
-- Name: station_logs_396; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_396 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_396 OWNER TO geo;

--
-- Name: station_logs_397; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_397 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_397 OWNER TO geo;

--
-- Name: station_logs_398; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_398 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_398 OWNER TO geo;

--
-- Name: station_logs_399; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_399 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_399 OWNER TO geo;

--
-- Name: station_logs_400; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_400 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_400 OWNER TO geo;

--
-- Name: station_logs_403; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_403 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_403 OWNER TO geo;

--
-- Name: station_logs_404; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_404 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_404 OWNER TO geo;

--
-- Name: station_logs_405; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_405 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_405 OWNER TO geo;

--
-- Name: station_logs_406; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_406 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_406 OWNER TO geo;

--
-- Name: station_logs_407; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_407 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_407 OWNER TO geo;

--
-- Name: station_logs_409; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_409 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_409 OWNER TO geo;

--
-- Name: station_logs_410; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_410 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_410 OWNER TO geo;

--
-- Name: station_logs_411; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_411 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_411 OWNER TO geo;

--
-- Name: station_logs_412; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_412 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_412 OWNER TO geo;

--
-- Name: station_logs_413; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_413 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_413 OWNER TO geo;

--
-- Name: station_logs_414; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_414 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_414 OWNER TO geo;

--
-- Name: station_logs_415; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_415 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_415 OWNER TO geo;

--
-- Name: station_logs_417; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_417 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_417 OWNER TO geo;

--
-- Name: station_logs_418; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_418 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_418 OWNER TO geo;

--
-- Name: station_logs_419; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_419 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_419 OWNER TO geo;

--
-- Name: station_logs_420; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_420 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_420 OWNER TO geo;

--
-- Name: station_logs_422; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_422 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_422 OWNER TO geo;

--
-- Name: station_logs_423; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_423 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_423 OWNER TO geo;

--
-- Name: station_logs_425; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_425 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_425 OWNER TO geo;

--
-- Name: station_logs_428; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_428 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_428 OWNER TO geo;

--
-- Name: station_logs_429; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_429 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_429 OWNER TO geo;

--
-- Name: station_logs_430; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_430 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_430 OWNER TO geo;

--
-- Name: station_logs_433; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_433 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_433 OWNER TO geo;

--
-- Name: station_logs_434; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_434 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_434 OWNER TO geo;

--
-- Name: station_logs_435; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_435 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_435 OWNER TO geo;

--
-- Name: station_logs_436; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_436 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_436 OWNER TO geo;

--
-- Name: station_logs_437; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_437 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_437 OWNER TO geo;

--
-- Name: station_logs_443; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_443 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_443 OWNER TO geo;

--
-- Name: station_logs_447; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_447 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_447 OWNER TO geo;

--
-- Name: station_logs_451; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_451 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_451 OWNER TO geo;

--
-- Name: station_logs_452; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_452 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_452 OWNER TO geo;

--
-- Name: station_logs_453; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_453 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_453 OWNER TO geo;

--
-- Name: station_logs_454; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_454 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_454 OWNER TO geo;

--
-- Name: station_logs_455; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_455 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_455 OWNER TO geo;

--
-- Name: station_logs_459; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_459 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_459 OWNER TO geo;

--
-- Name: station_logs_460; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_460 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_460 OWNER TO geo;

--
-- Name: station_logs_462; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_462 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_462 OWNER TO geo;

--
-- Name: station_logs_463; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_463 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_463 OWNER TO geo;

--
-- Name: station_logs_464; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_464 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_464 OWNER TO geo;

--
-- Name: station_logs_465; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_465 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_465 OWNER TO geo;

--
-- Name: station_logs_466; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_466 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_466 OWNER TO geo;

--
-- Name: station_logs_467; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_467 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_467 OWNER TO geo;

--
-- Name: station_logs_469; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_469 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_469 OWNER TO geo;

--
-- Name: station_logs_470; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_470 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_470 OWNER TO geo;

--
-- Name: station_logs_473; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_473 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_473 OWNER TO geo;

--
-- Name: station_logs_474; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_474 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_474 OWNER TO geo;

--
-- Name: station_logs_500; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_500 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_500 OWNER TO geo;

--
-- Name: station_logs_501; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_501 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_501 OWNER TO geo;

--
-- Name: station_logs_502; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_502 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_502 OWNER TO geo;

--
-- Name: station_logs_503; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_503 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_503 OWNER TO geo;

--
-- Name: station_logs_504; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_504 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_504 OWNER TO geo;

--
-- Name: station_logs_505; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_505 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_505 OWNER TO geo;

--
-- Name: station_logs_514; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_514 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_514 OWNER TO geo;

--
-- Name: station_logs_530; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_530 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_530 OWNER TO geo;

--
-- Name: station_logs_533; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_533 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_533 OWNER TO geo;

--
-- Name: station_logs_537; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_537 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_537 OWNER TO geo;

--
-- Name: station_logs_539; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_539 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_539 OWNER TO geo;

--
-- Name: station_logs_553; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_553 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_553 OWNER TO geo;

--
-- Name: station_logs_556; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_556 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_556 OWNER TO geo;

--
-- Name: station_logs_561; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_561 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_561 OWNER TO geo;

--
-- Name: station_logs_565; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_565 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_565 OWNER TO geo;

--
-- Name: station_logs_575; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_575 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_575 OWNER TO geo;

--
-- Name: station_logs_577; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_577 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_577 OWNER TO geo;

--
-- Name: station_logs_578; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_578 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_578 OWNER TO geo;

--
-- Name: station_logs_594; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_594 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_594 OWNER TO geo;

--
-- Name: station_logs_595; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_595 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_595 OWNER TO geo;

--
-- Name: station_logs_597; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_597 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_597 OWNER TO geo;

--
-- Name: station_logs_601; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_601 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_601 OWNER TO geo;

--
-- Name: station_logs_602; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_602 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_602 OWNER TO geo;

--
-- Name: station_logs_603; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_603 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_603 OWNER TO geo;

--
-- Name: station_logs_604; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_604 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_604 OWNER TO geo;

--
-- Name: station_logs_605; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_605 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_605 OWNER TO geo;

--
-- Name: station_logs_606; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_606 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_606 OWNER TO geo;

--
-- Name: station_logs_607; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_607 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_607 OWNER TO geo;

--
-- Name: station_logs_608; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_608 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_608 OWNER TO geo;

--
-- Name: station_logs_609; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_609 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_609 OWNER TO geo;

--
-- Name: station_logs_610; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_610 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_610 OWNER TO geo;

--
-- Name: station_logs_611; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_611 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_611 OWNER TO geo;

--
-- Name: station_logs_615; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_615 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_615 OWNER TO geo;

--
-- Name: station_logs_616; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_616 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_616 OWNER TO geo;

--
-- Name: station_logs_617; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_617 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_617 OWNER TO geo;

--
-- Name: station_logs_618; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_618 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_618 OWNER TO geo;

--
-- Name: station_logs_619; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_619 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_619 OWNER TO geo;

--
-- Name: station_logs_620; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_620 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_620 OWNER TO geo;

--
-- Name: station_logs_622; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_622 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_622 OWNER TO geo;

--
-- Name: station_logs_624; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_624 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_624 OWNER TO geo;

--
-- Name: station_logs_625; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_625 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_625 OWNER TO geo;

--
-- Name: station_logs_626; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_626 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_626 OWNER TO geo;

--
-- Name: station_logs_627; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_627 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_627 OWNER TO geo;

--
-- Name: station_logs_628; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_628 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_628 OWNER TO geo;

--
-- Name: station_logs_631; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_631 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_631 OWNER TO geo;

--
-- Name: station_logs_632; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_632 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_632 OWNER TO geo;

--
-- Name: station_logs_633; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_633 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_633 OWNER TO geo;

--
-- Name: station_logs_636; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_636 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_636 OWNER TO geo;

--
-- Name: station_logs_645; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_645 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_645 OWNER TO geo;

--
-- Name: station_logs_99; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_logs_99 (
    id integer DEFAULT nextval('public.station_logs_id_seq'::regclass) NOT NULL,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    submitted_at timestamp(6) without time zone NOT NULL,
    sequence integer,
    level_sensor double precision,
    accel_x double precision,
    accel_y double precision,
    accel_z double precision,
    power_current double precision,
    ip_address character varying(50),
    log_type integer,
    station_id integer NOT NULL,
    power_voltage double precision,
    data jsonb,
    is_deleted boolean DEFAULT false NOT NULL,
    temperature double precision,
    wind_speed double precision,
    soil_moisture double precision,
    wind_direction double precision,
    raindrop double precision,
    humidity integer,
    barometric_pressure double precision,
    wind_speed_average double precision,
    wind_gust double precision,
    wind_direction_average double precision,
    rain_rate double precision
);


ALTER TABLE public.station_logs_99 OWNER TO geo;

--
-- Name: station_minutes; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes (
    at timestamp without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes OWNER TO geo;

--
-- Name: station_minutes_110; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_110 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_110 OWNER TO geo;

--
-- Name: station_minutes_167; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_167 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_167 OWNER TO geo;

--
-- Name: station_minutes_245; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_245 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_245 OWNER TO geo;

--
-- Name: station_minutes_247; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_247 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_247 OWNER TO geo;

--
-- Name: station_minutes_249; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_249 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_249 OWNER TO geo;

--
-- Name: station_minutes_259; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_259 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_259 OWNER TO geo;

--
-- Name: station_minutes_261; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_261 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_261 OWNER TO geo;

--
-- Name: station_minutes_284; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_284 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_284 OWNER TO geo;

--
-- Name: station_minutes_285; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_285 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_285 OWNER TO geo;

--
-- Name: station_minutes_296; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_296 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_296 OWNER TO geo;

--
-- Name: station_minutes_298; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_298 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_298 OWNER TO geo;

--
-- Name: station_minutes_3001; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_3001 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_3001 OWNER TO geo;

--
-- Name: station_minutes_307; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_307 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_307 OWNER TO geo;

--
-- Name: station_minutes_308; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_308 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_308 OWNER TO geo;

--
-- Name: station_minutes_309; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_309 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_309 OWNER TO geo;

--
-- Name: station_minutes_310; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_310 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_310 OWNER TO geo;

--
-- Name: station_minutes_314; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_314 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_314 OWNER TO geo;

--
-- Name: station_minutes_316; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_316 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_316 OWNER TO geo;

--
-- Name: station_minutes_317; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_317 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_317 OWNER TO geo;

--
-- Name: station_minutes_319; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_319 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_319 OWNER TO geo;

--
-- Name: station_minutes_320; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_320 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_320 OWNER TO geo;

--
-- Name: station_minutes_323; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_323 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_323 OWNER TO geo;

--
-- Name: station_minutes_326; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_326 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_326 OWNER TO geo;

--
-- Name: station_minutes_327; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_327 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_327 OWNER TO geo;

--
-- Name: station_minutes_329; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_329 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_329 OWNER TO geo;

--
-- Name: station_minutes_330; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_330 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_330 OWNER TO geo;

--
-- Name: station_minutes_331; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_331 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_331 OWNER TO geo;

--
-- Name: station_minutes_333; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_333 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_333 OWNER TO geo;

--
-- Name: station_minutes_334; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_334 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_334 OWNER TO geo;

--
-- Name: station_minutes_336; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_336 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_336 OWNER TO geo;

--
-- Name: station_minutes_337; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_337 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_337 OWNER TO geo;

--
-- Name: station_minutes_338; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_338 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_338 OWNER TO geo;

--
-- Name: station_minutes_339; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_339 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_339 OWNER TO geo;

--
-- Name: station_minutes_343; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_343 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_343 OWNER TO geo;

--
-- Name: station_minutes_346; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_346 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_346 OWNER TO geo;

--
-- Name: station_minutes_347; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_347 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_347 OWNER TO geo;

--
-- Name: station_minutes_348; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_348 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_348 OWNER TO geo;

--
-- Name: station_minutes_349; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_349 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_349 OWNER TO geo;

--
-- Name: station_minutes_350; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_350 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_350 OWNER TO geo;

--
-- Name: station_minutes_351; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_351 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_351 OWNER TO geo;

--
-- Name: station_minutes_352; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_352 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_352 OWNER TO geo;

--
-- Name: station_minutes_353; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_353 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_353 OWNER TO geo;

--
-- Name: station_minutes_354; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_354 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_354 OWNER TO geo;

--
-- Name: station_minutes_355; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_355 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_355 OWNER TO geo;

--
-- Name: station_minutes_356; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_356 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_356 OWNER TO geo;

--
-- Name: station_minutes_357; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_357 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_357 OWNER TO geo;

--
-- Name: station_minutes_358; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_358 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_358 OWNER TO geo;

--
-- Name: station_minutes_359; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_359 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_359 OWNER TO geo;

--
-- Name: station_minutes_360; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_360 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_360 OWNER TO geo;

--
-- Name: station_minutes_361; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_361 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_361 OWNER TO geo;

--
-- Name: station_minutes_362; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_362 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_362 OWNER TO geo;

--
-- Name: station_minutes_363; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_363 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_363 OWNER TO geo;

--
-- Name: station_minutes_364; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_364 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_364 OWNER TO geo;

--
-- Name: station_minutes_365; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_365 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_365 OWNER TO geo;

--
-- Name: station_minutes_370; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_370 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_370 OWNER TO geo;

--
-- Name: station_minutes_371; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_371 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_371 OWNER TO geo;

--
-- Name: station_minutes_372; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_372 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_372 OWNER TO geo;

--
-- Name: station_minutes_373; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_373 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_373 OWNER TO geo;

--
-- Name: station_minutes_374; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_374 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_374 OWNER TO geo;

--
-- Name: station_minutes_375; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_375 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_375 OWNER TO geo;

--
-- Name: station_minutes_376; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_376 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_376 OWNER TO geo;

--
-- Name: station_minutes_377; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_377 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_377 OWNER TO geo;

--
-- Name: station_minutes_378; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_378 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_378 OWNER TO geo;

--
-- Name: station_minutes_379; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_379 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_379 OWNER TO geo;

--
-- Name: station_minutes_380; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_380 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_380 OWNER TO geo;

--
-- Name: station_minutes_382; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_382 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_382 OWNER TO geo;

--
-- Name: station_minutes_383; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_383 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_383 OWNER TO geo;

--
-- Name: station_minutes_385; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_385 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_385 OWNER TO geo;

--
-- Name: station_minutes_387; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_387 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_387 OWNER TO geo;

--
-- Name: station_minutes_389; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_389 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_389 OWNER TO geo;

--
-- Name: station_minutes_390; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_390 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_390 OWNER TO geo;

--
-- Name: station_minutes_391; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_391 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_391 OWNER TO geo;

--
-- Name: station_minutes_392; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_392 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_392 OWNER TO geo;

--
-- Name: station_minutes_395; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_395 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_395 OWNER TO geo;

--
-- Name: station_minutes_396; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_396 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_396 OWNER TO geo;

--
-- Name: station_minutes_397; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_397 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_397 OWNER TO geo;

--
-- Name: station_minutes_398; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_398 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_398 OWNER TO geo;

--
-- Name: station_minutes_399; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_399 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_399 OWNER TO geo;

--
-- Name: station_minutes_400; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_400 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_400 OWNER TO geo;

--
-- Name: station_minutes_403; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_403 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_403 OWNER TO geo;

--
-- Name: station_minutes_404; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_404 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_404 OWNER TO geo;

--
-- Name: station_minutes_405; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_405 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_405 OWNER TO geo;

--
-- Name: station_minutes_406; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_406 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_406 OWNER TO geo;

--
-- Name: station_minutes_407; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_407 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_407 OWNER TO geo;

--
-- Name: station_minutes_409; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_409 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_409 OWNER TO geo;

--
-- Name: station_minutes_410; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_410 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_410 OWNER TO geo;

--
-- Name: station_minutes_411; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_411 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_411 OWNER TO geo;

--
-- Name: station_minutes_412; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_412 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_412 OWNER TO geo;

--
-- Name: station_minutes_413; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_413 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_413 OWNER TO geo;

--
-- Name: station_minutes_414; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_414 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_414 OWNER TO geo;

--
-- Name: station_minutes_415; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_415 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_415 OWNER TO geo;

--
-- Name: station_minutes_417; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_417 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_417 OWNER TO geo;

--
-- Name: station_minutes_418; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_418 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_418 OWNER TO geo;

--
-- Name: station_minutes_419; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_419 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_419 OWNER TO geo;

--
-- Name: station_minutes_420; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_420 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_420 OWNER TO geo;

--
-- Name: station_minutes_422; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_422 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_422 OWNER TO geo;

--
-- Name: station_minutes_423; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_423 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_423 OWNER TO geo;

--
-- Name: station_minutes_425; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_425 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_425 OWNER TO geo;

--
-- Name: station_minutes_428; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_428 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_428 OWNER TO geo;

--
-- Name: station_minutes_429; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_429 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_429 OWNER TO geo;

--
-- Name: station_minutes_430; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_430 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_430 OWNER TO geo;

--
-- Name: station_minutes_433; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_433 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_433 OWNER TO geo;

--
-- Name: station_minutes_434; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_434 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_434 OWNER TO geo;

--
-- Name: station_minutes_435; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_435 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_435 OWNER TO geo;

--
-- Name: station_minutes_436; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_436 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_436 OWNER TO geo;

--
-- Name: station_minutes_437; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_437 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_437 OWNER TO geo;

--
-- Name: station_minutes_443; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_443 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_443 OWNER TO geo;

--
-- Name: station_minutes_447; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_447 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_447 OWNER TO geo;

--
-- Name: station_minutes_451; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_451 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_451 OWNER TO geo;

--
-- Name: station_minutes_452; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_452 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_452 OWNER TO geo;

--
-- Name: station_minutes_453; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_453 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_453 OWNER TO geo;

--
-- Name: station_minutes_454; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_454 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_454 OWNER TO geo;

--
-- Name: station_minutes_455; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_455 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_455 OWNER TO geo;

--
-- Name: station_minutes_459; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_459 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_459 OWNER TO geo;

--
-- Name: station_minutes_460; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_460 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_460 OWNER TO geo;

--
-- Name: station_minutes_461; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_461 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_461 OWNER TO geo;

--
-- Name: station_minutes_462; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_462 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_462 OWNER TO geo;

--
-- Name: station_minutes_463; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_463 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_463 OWNER TO geo;

--
-- Name: station_minutes_464; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_464 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_464 OWNER TO geo;

--
-- Name: station_minutes_465; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_465 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_465 OWNER TO geo;

--
-- Name: station_minutes_466; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_466 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_466 OWNER TO geo;

--
-- Name: station_minutes_467; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_467 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_467 OWNER TO geo;

--
-- Name: station_minutes_469; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_469 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_469 OWNER TO geo;

--
-- Name: station_minutes_470; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_470 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_470 OWNER TO geo;

--
-- Name: station_minutes_473; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_473 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_473 OWNER TO geo;

--
-- Name: station_minutes_474; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_474 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_474 OWNER TO geo;

--
-- Name: station_minutes_500; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_500 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_500 OWNER TO geo;

--
-- Name: station_minutes_501; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_501 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_501 OWNER TO geo;

--
-- Name: station_minutes_502; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_502 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_502 OWNER TO geo;

--
-- Name: station_minutes_503; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_503 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_503 OWNER TO geo;

--
-- Name: station_minutes_504; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_504 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_504 OWNER TO geo;

--
-- Name: station_minutes_505; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_505 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_505 OWNER TO geo;

--
-- Name: station_minutes_514; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_514 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_514 OWNER TO geo;

--
-- Name: station_minutes_530; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_530 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_530 OWNER TO geo;

--
-- Name: station_minutes_533; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_533 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_533 OWNER TO geo;

--
-- Name: station_minutes_537; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_537 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_537 OWNER TO geo;

--
-- Name: station_minutes_539; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_539 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_539 OWNER TO geo;

--
-- Name: station_minutes_553; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_553 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_553 OWNER TO geo;

--
-- Name: station_minutes_556; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_556 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_556 OWNER TO geo;

--
-- Name: station_minutes_561; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_561 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_561 OWNER TO geo;

--
-- Name: station_minutes_565; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_565 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_565 OWNER TO geo;

--
-- Name: station_minutes_575; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_575 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_575 OWNER TO geo;

--
-- Name: station_minutes_577; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_577 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_577 OWNER TO geo;

--
-- Name: station_minutes_578; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_578 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_578 OWNER TO geo;

--
-- Name: station_minutes_594; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_594 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_594 OWNER TO geo;

--
-- Name: station_minutes_595; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_595 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_595 OWNER TO geo;

--
-- Name: station_minutes_597; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_597 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_597 OWNER TO geo;

--
-- Name: station_minutes_601; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_601 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_601 OWNER TO geo;

--
-- Name: station_minutes_602; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_602 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_602 OWNER TO geo;

--
-- Name: station_minutes_603; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_603 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_603 OWNER TO geo;

--
-- Name: station_minutes_604; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_604 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_604 OWNER TO geo;

--
-- Name: station_minutes_605; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_605 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_605 OWNER TO geo;

--
-- Name: station_minutes_606; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_606 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_606 OWNER TO geo;

--
-- Name: station_minutes_607; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_607 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_607 OWNER TO geo;

--
-- Name: station_minutes_608; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_608 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_608 OWNER TO geo;

--
-- Name: station_minutes_609; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_609 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_609 OWNER TO geo;

--
-- Name: station_minutes_610; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_610 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_610 OWNER TO geo;

--
-- Name: station_minutes_611; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_611 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_611 OWNER TO geo;

--
-- Name: station_minutes_615; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_615 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_615 OWNER TO geo;

--
-- Name: station_minutes_616; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_616 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_616 OWNER TO geo;

--
-- Name: station_minutes_617; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_617 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_617 OWNER TO geo;

--
-- Name: station_minutes_618; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_618 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_618 OWNER TO geo;

--
-- Name: station_minutes_619; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_619 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_619 OWNER TO geo;

--
-- Name: station_minutes_620; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_620 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_620 OWNER TO geo;

--
-- Name: station_minutes_622; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_622 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_622 OWNER TO geo;

--
-- Name: station_minutes_624; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_624 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_624 OWNER TO geo;

--
-- Name: station_minutes_625; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_625 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_625 OWNER TO geo;

--
-- Name: station_minutes_628; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_628 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_628 OWNER TO geo;

--
-- Name: station_minutes_631; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_631 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_631 OWNER TO geo;

--
-- Name: station_minutes_632; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_632 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_632 OWNER TO geo;

--
-- Name: station_minutes_633; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_633 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_633 OWNER TO geo;

--
-- Name: station_minutes_636; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_636 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_636 OWNER TO geo;

--
-- Name: station_minutes_99; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.station_minutes_99 (
    at timestamp(6) without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE public.station_minutes_99 OWNER TO geo;

--
-- Name: stations; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.stations (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    name character varying(50),
    long double precision,
    lat double precision,
    imei character varying(15),
    location character varying(50),
    public boolean,
    history text,
    hist_count integer,
    group_id integer NOT NULL,
    min_filter double precision DEFAULT '-2'::integer,
    max_filter double precision DEFAULT 2,
    updated_by bigint,
    deleted_by bigint,
    restored_by bigint,
    created_by bigint,
    unique_id character varying(240),
    is_deleted boolean DEFAULT false NOT NULL,
    data jsonb DEFAULT '{}'::jsonb,
    public_dl boolean DEFAULT false,
    last_submitted_at timestamp without time zone,
    last_level_sensor double precision
);


ALTER TABLE public.stations OWNER TO geo;

--
-- Name: stations_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE public.stations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stations_id_seq OWNER TO geo;

--
-- Name: stations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE public.stations_id_seq OWNED BY public.stations.id;


--
-- Name: user_auths; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.user_auths (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    authid character varying(50),
    remote_addr character varying(50),
    http_x_forwarded_for character varying(50),
    user_agent character varying(50),
    history text,
    hist_count integer,
    user_id integer NOT NULL
);


ALTER TABLE public.user_auths OWNER TO geo;

--
-- Name: user_auths_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE public.user_auths_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_auths_id_seq OWNER TO geo;

--
-- Name: user_auths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE public.user_auths_id_seq OWNED BY public.user_auths.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE public.users (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    email character varying(50),
    password character varying(88),
    reset_id character varying(88),
    verified boolean DEFAULT false,
    note text,
    group_id integer NOT NULL,
    phone character varying(24),
    full_name character varying(50),
    updated_by bigint,
    deleted_by bigint,
    restored_by bigint,
    created_by bigint,
    unique_id character varying(240),
    is_deleted boolean DEFAULT false NOT NULL,
    data jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.users OWNER TO geo;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO geo;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: predictions id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.predictions ALTER COLUMN id SET DEFAULT nextval('public.predictions_id_seq'::regclass);


--
-- Name: station_logs id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs ALTER COLUMN id SET DEFAULT nextval('public.station_logs_id_seq'::regclass);


--
-- Name: stations id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.stations ALTER COLUMN id SET DEFAULT nextval('public.stations_id_seq'::regclass);


--
-- Name: user_auths id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.user_auths ALTER COLUMN id SET DEFAULT nextval('public.user_auths_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: groups groups_unique_id_key; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_unique_id_key UNIQUE (unique_id);


--
-- Name: predictions predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (id);


--
-- Name: predictions sta_id__predict_epoch; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT sta_id__predict_epoch UNIQUE (station_id, predict_epoch);


--
-- Name: station_hours station_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours
    ADD CONSTRAINT station_hours_pkey PRIMARY KEY (slid, sid);


--
-- Name: station_hours_110 station_hours_pkey_110; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_110
    ADD CONSTRAINT station_hours_pkey_110 PRIMARY KEY (slid);


--
-- Name: station_hours_167 station_hours_pkey_167; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_167
    ADD CONSTRAINT station_hours_pkey_167 PRIMARY KEY (slid);


--
-- Name: station_hours_245 station_hours_pkey_245; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_245
    ADD CONSTRAINT station_hours_pkey_245 PRIMARY KEY (slid);


--
-- Name: station_hours_247 station_hours_pkey_247; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_247
    ADD CONSTRAINT station_hours_pkey_247 PRIMARY KEY (slid);


--
-- Name: station_hours_249 station_hours_pkey_249; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_249
    ADD CONSTRAINT station_hours_pkey_249 PRIMARY KEY (slid);


--
-- Name: station_hours_259 station_hours_pkey_259; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_259
    ADD CONSTRAINT station_hours_pkey_259 PRIMARY KEY (slid);


--
-- Name: station_hours_261 station_hours_pkey_261; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_261
    ADD CONSTRAINT station_hours_pkey_261 PRIMARY KEY (slid);


--
-- Name: station_hours_284 station_hours_pkey_284; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_284
    ADD CONSTRAINT station_hours_pkey_284 PRIMARY KEY (slid);


--
-- Name: station_hours_285 station_hours_pkey_285; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_285
    ADD CONSTRAINT station_hours_pkey_285 PRIMARY KEY (slid);


--
-- Name: station_hours_296 station_hours_pkey_296; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_296
    ADD CONSTRAINT station_hours_pkey_296 PRIMARY KEY (slid);


--
-- Name: station_hours_298 station_hours_pkey_298; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_298
    ADD CONSTRAINT station_hours_pkey_298 PRIMARY KEY (slid);


--
-- Name: station_hours_307 station_hours_pkey_307; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_307
    ADD CONSTRAINT station_hours_pkey_307 PRIMARY KEY (slid);


--
-- Name: station_hours_308 station_hours_pkey_308; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_308
    ADD CONSTRAINT station_hours_pkey_308 PRIMARY KEY (slid);


--
-- Name: station_hours_309 station_hours_pkey_309; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_309
    ADD CONSTRAINT station_hours_pkey_309 PRIMARY KEY (slid);


--
-- Name: station_hours_310 station_hours_pkey_310; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_310
    ADD CONSTRAINT station_hours_pkey_310 PRIMARY KEY (slid);


--
-- Name: station_hours_314 station_hours_pkey_314; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_314
    ADD CONSTRAINT station_hours_pkey_314 PRIMARY KEY (slid);


--
-- Name: station_hours_316 station_hours_pkey_316; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_316
    ADD CONSTRAINT station_hours_pkey_316 PRIMARY KEY (slid);


--
-- Name: station_hours_317 station_hours_pkey_317; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_317
    ADD CONSTRAINT station_hours_pkey_317 PRIMARY KEY (slid);


--
-- Name: station_hours_319 station_hours_pkey_319; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_319
    ADD CONSTRAINT station_hours_pkey_319 PRIMARY KEY (slid);


--
-- Name: station_hours_320 station_hours_pkey_320; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_320
    ADD CONSTRAINT station_hours_pkey_320 PRIMARY KEY (slid);


--
-- Name: station_hours_323 station_hours_pkey_323; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_323
    ADD CONSTRAINT station_hours_pkey_323 PRIMARY KEY (slid);


--
-- Name: station_hours_326 station_hours_pkey_326; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_326
    ADD CONSTRAINT station_hours_pkey_326 PRIMARY KEY (slid);


--
-- Name: station_hours_327 station_hours_pkey_327; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_327
    ADD CONSTRAINT station_hours_pkey_327 PRIMARY KEY (slid);


--
-- Name: station_hours_329 station_hours_pkey_329; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_329
    ADD CONSTRAINT station_hours_pkey_329 PRIMARY KEY (slid);


--
-- Name: station_hours_330 station_hours_pkey_330; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_330
    ADD CONSTRAINT station_hours_pkey_330 PRIMARY KEY (slid);


--
-- Name: station_hours_331 station_hours_pkey_331; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_331
    ADD CONSTRAINT station_hours_pkey_331 PRIMARY KEY (slid);


--
-- Name: station_hours_333 station_hours_pkey_333; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_333
    ADD CONSTRAINT station_hours_pkey_333 PRIMARY KEY (slid);


--
-- Name: station_hours_334 station_hours_pkey_334; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_334
    ADD CONSTRAINT station_hours_pkey_334 PRIMARY KEY (slid);


--
-- Name: station_hours_336 station_hours_pkey_336; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_336
    ADD CONSTRAINT station_hours_pkey_336 PRIMARY KEY (slid);


--
-- Name: station_hours_337 station_hours_pkey_337; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_337
    ADD CONSTRAINT station_hours_pkey_337 PRIMARY KEY (slid);


--
-- Name: station_hours_338 station_hours_pkey_338; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_338
    ADD CONSTRAINT station_hours_pkey_338 PRIMARY KEY (slid);


--
-- Name: station_hours_339 station_hours_pkey_339; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_339
    ADD CONSTRAINT station_hours_pkey_339 PRIMARY KEY (slid);


--
-- Name: station_hours_343 station_hours_pkey_343; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_343
    ADD CONSTRAINT station_hours_pkey_343 PRIMARY KEY (slid);


--
-- Name: station_hours_346 station_hours_pkey_346; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_346
    ADD CONSTRAINT station_hours_pkey_346 PRIMARY KEY (slid);


--
-- Name: station_hours_347 station_hours_pkey_347; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_347
    ADD CONSTRAINT station_hours_pkey_347 PRIMARY KEY (slid);


--
-- Name: station_hours_348 station_hours_pkey_348; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_348
    ADD CONSTRAINT station_hours_pkey_348 PRIMARY KEY (slid);


--
-- Name: station_hours_349 station_hours_pkey_349; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_349
    ADD CONSTRAINT station_hours_pkey_349 PRIMARY KEY (slid);


--
-- Name: station_hours_350 station_hours_pkey_350; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_350
    ADD CONSTRAINT station_hours_pkey_350 PRIMARY KEY (slid);


--
-- Name: station_hours_351 station_hours_pkey_351; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_351
    ADD CONSTRAINT station_hours_pkey_351 PRIMARY KEY (slid);


--
-- Name: station_hours_352 station_hours_pkey_352; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_352
    ADD CONSTRAINT station_hours_pkey_352 PRIMARY KEY (slid);


--
-- Name: station_hours_353 station_hours_pkey_353; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_353
    ADD CONSTRAINT station_hours_pkey_353 PRIMARY KEY (slid);


--
-- Name: station_hours_354 station_hours_pkey_354; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_354
    ADD CONSTRAINT station_hours_pkey_354 PRIMARY KEY (slid);


--
-- Name: station_hours_355 station_hours_pkey_355; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_355
    ADD CONSTRAINT station_hours_pkey_355 PRIMARY KEY (slid);


--
-- Name: station_hours_356 station_hours_pkey_356; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_356
    ADD CONSTRAINT station_hours_pkey_356 PRIMARY KEY (slid);


--
-- Name: station_hours_357 station_hours_pkey_357; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_357
    ADD CONSTRAINT station_hours_pkey_357 PRIMARY KEY (slid);


--
-- Name: station_hours_358 station_hours_pkey_358; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_358
    ADD CONSTRAINT station_hours_pkey_358 PRIMARY KEY (slid);


--
-- Name: station_hours_359 station_hours_pkey_359; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_359
    ADD CONSTRAINT station_hours_pkey_359 PRIMARY KEY (slid);


--
-- Name: station_hours_360 station_hours_pkey_360; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_360
    ADD CONSTRAINT station_hours_pkey_360 PRIMARY KEY (slid);


--
-- Name: station_hours_361 station_hours_pkey_361; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_361
    ADD CONSTRAINT station_hours_pkey_361 PRIMARY KEY (slid);


--
-- Name: station_hours_362 station_hours_pkey_362; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_362
    ADD CONSTRAINT station_hours_pkey_362 PRIMARY KEY (slid);


--
-- Name: station_hours_363 station_hours_pkey_363; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_363
    ADD CONSTRAINT station_hours_pkey_363 PRIMARY KEY (slid);


--
-- Name: station_hours_364 station_hours_pkey_364; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_364
    ADD CONSTRAINT station_hours_pkey_364 PRIMARY KEY (slid);


--
-- Name: station_hours_365 station_hours_pkey_365; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_365
    ADD CONSTRAINT station_hours_pkey_365 PRIMARY KEY (slid);


--
-- Name: station_hours_370 station_hours_pkey_370; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_370
    ADD CONSTRAINT station_hours_pkey_370 PRIMARY KEY (slid);


--
-- Name: station_hours_371 station_hours_pkey_371; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_371
    ADD CONSTRAINT station_hours_pkey_371 PRIMARY KEY (slid);


--
-- Name: station_hours_372 station_hours_pkey_372; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_372
    ADD CONSTRAINT station_hours_pkey_372 PRIMARY KEY (slid);


--
-- Name: station_hours_373 station_hours_pkey_373; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_373
    ADD CONSTRAINT station_hours_pkey_373 PRIMARY KEY (slid);


--
-- Name: station_hours_374 station_hours_pkey_374; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_374
    ADD CONSTRAINT station_hours_pkey_374 PRIMARY KEY (slid);


--
-- Name: station_hours_375 station_hours_pkey_375; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_375
    ADD CONSTRAINT station_hours_pkey_375 PRIMARY KEY (slid);


--
-- Name: station_hours_376 station_hours_pkey_376; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_376
    ADD CONSTRAINT station_hours_pkey_376 PRIMARY KEY (slid);


--
-- Name: station_hours_377 station_hours_pkey_377; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_377
    ADD CONSTRAINT station_hours_pkey_377 PRIMARY KEY (slid);


--
-- Name: station_hours_378 station_hours_pkey_378; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_378
    ADD CONSTRAINT station_hours_pkey_378 PRIMARY KEY (slid);


--
-- Name: station_hours_379 station_hours_pkey_379; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_379
    ADD CONSTRAINT station_hours_pkey_379 PRIMARY KEY (slid);


--
-- Name: station_hours_380 station_hours_pkey_380; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_380
    ADD CONSTRAINT station_hours_pkey_380 PRIMARY KEY (slid);


--
-- Name: station_hours_382 station_hours_pkey_382; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_382
    ADD CONSTRAINT station_hours_pkey_382 PRIMARY KEY (slid);


--
-- Name: station_hours_383 station_hours_pkey_383; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_383
    ADD CONSTRAINT station_hours_pkey_383 PRIMARY KEY (slid);


--
-- Name: station_hours_385 station_hours_pkey_385; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_385
    ADD CONSTRAINT station_hours_pkey_385 PRIMARY KEY (slid);


--
-- Name: station_hours_387 station_hours_pkey_387; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_387
    ADD CONSTRAINT station_hours_pkey_387 PRIMARY KEY (slid);


--
-- Name: station_hours_389 station_hours_pkey_389; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_389
    ADD CONSTRAINT station_hours_pkey_389 PRIMARY KEY (slid);


--
-- Name: station_hours_390 station_hours_pkey_390; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_390
    ADD CONSTRAINT station_hours_pkey_390 PRIMARY KEY (slid);


--
-- Name: station_hours_391 station_hours_pkey_391; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_391
    ADD CONSTRAINT station_hours_pkey_391 PRIMARY KEY (slid);


--
-- Name: station_hours_392 station_hours_pkey_392; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_392
    ADD CONSTRAINT station_hours_pkey_392 PRIMARY KEY (slid);


--
-- Name: station_hours_395 station_hours_pkey_395; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_395
    ADD CONSTRAINT station_hours_pkey_395 PRIMARY KEY (slid);


--
-- Name: station_hours_396 station_hours_pkey_396; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_396
    ADD CONSTRAINT station_hours_pkey_396 PRIMARY KEY (slid);


--
-- Name: station_hours_397 station_hours_pkey_397; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_397
    ADD CONSTRAINT station_hours_pkey_397 PRIMARY KEY (slid);


--
-- Name: station_hours_398 station_hours_pkey_398; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_398
    ADD CONSTRAINT station_hours_pkey_398 PRIMARY KEY (slid);


--
-- Name: station_hours_399 station_hours_pkey_399; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_399
    ADD CONSTRAINT station_hours_pkey_399 PRIMARY KEY (slid);


--
-- Name: station_hours_400 station_hours_pkey_400; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_400
    ADD CONSTRAINT station_hours_pkey_400 PRIMARY KEY (slid);


--
-- Name: station_hours_403 station_hours_pkey_403; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_403
    ADD CONSTRAINT station_hours_pkey_403 PRIMARY KEY (slid);


--
-- Name: station_hours_404 station_hours_pkey_404; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_404
    ADD CONSTRAINT station_hours_pkey_404 PRIMARY KEY (slid);


--
-- Name: station_hours_405 station_hours_pkey_405; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_405
    ADD CONSTRAINT station_hours_pkey_405 PRIMARY KEY (slid);


--
-- Name: station_hours_406 station_hours_pkey_406; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_406
    ADD CONSTRAINT station_hours_pkey_406 PRIMARY KEY (slid);


--
-- Name: station_hours_407 station_hours_pkey_407; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_407
    ADD CONSTRAINT station_hours_pkey_407 PRIMARY KEY (slid);


--
-- Name: station_hours_409 station_hours_pkey_409; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_409
    ADD CONSTRAINT station_hours_pkey_409 PRIMARY KEY (slid);


--
-- Name: station_hours_410 station_hours_pkey_410; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_410
    ADD CONSTRAINT station_hours_pkey_410 PRIMARY KEY (slid);


--
-- Name: station_hours_411 station_hours_pkey_411; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_411
    ADD CONSTRAINT station_hours_pkey_411 PRIMARY KEY (slid);


--
-- Name: station_hours_412 station_hours_pkey_412; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_412
    ADD CONSTRAINT station_hours_pkey_412 PRIMARY KEY (slid);


--
-- Name: station_hours_413 station_hours_pkey_413; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_413
    ADD CONSTRAINT station_hours_pkey_413 PRIMARY KEY (slid);


--
-- Name: station_hours_414 station_hours_pkey_414; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_414
    ADD CONSTRAINT station_hours_pkey_414 PRIMARY KEY (slid);


--
-- Name: station_hours_415 station_hours_pkey_415; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_415
    ADD CONSTRAINT station_hours_pkey_415 PRIMARY KEY (slid);


--
-- Name: station_hours_417 station_hours_pkey_417; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_417
    ADD CONSTRAINT station_hours_pkey_417 PRIMARY KEY (slid);


--
-- Name: station_hours_418 station_hours_pkey_418; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_418
    ADD CONSTRAINT station_hours_pkey_418 PRIMARY KEY (slid);


--
-- Name: station_hours_419 station_hours_pkey_419; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_419
    ADD CONSTRAINT station_hours_pkey_419 PRIMARY KEY (slid);


--
-- Name: station_hours_420 station_hours_pkey_420; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_420
    ADD CONSTRAINT station_hours_pkey_420 PRIMARY KEY (slid);


--
-- Name: station_hours_422 station_hours_pkey_422; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_422
    ADD CONSTRAINT station_hours_pkey_422 PRIMARY KEY (slid);


--
-- Name: station_hours_423 station_hours_pkey_423; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_423
    ADD CONSTRAINT station_hours_pkey_423 PRIMARY KEY (slid);


--
-- Name: station_hours_425 station_hours_pkey_425; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_425
    ADD CONSTRAINT station_hours_pkey_425 PRIMARY KEY (slid);


--
-- Name: station_hours_428 station_hours_pkey_428; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_428
    ADD CONSTRAINT station_hours_pkey_428 PRIMARY KEY (slid);


--
-- Name: station_hours_429 station_hours_pkey_429; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_429
    ADD CONSTRAINT station_hours_pkey_429 PRIMARY KEY (slid);


--
-- Name: station_hours_430 station_hours_pkey_430; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_430
    ADD CONSTRAINT station_hours_pkey_430 PRIMARY KEY (slid);


--
-- Name: station_hours_433 station_hours_pkey_433; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_433
    ADD CONSTRAINT station_hours_pkey_433 PRIMARY KEY (slid);


--
-- Name: station_hours_434 station_hours_pkey_434; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_434
    ADD CONSTRAINT station_hours_pkey_434 PRIMARY KEY (slid);


--
-- Name: station_hours_435 station_hours_pkey_435; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_435
    ADD CONSTRAINT station_hours_pkey_435 PRIMARY KEY (slid);


--
-- Name: station_hours_436 station_hours_pkey_436; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_436
    ADD CONSTRAINT station_hours_pkey_436 PRIMARY KEY (slid);


--
-- Name: station_hours_437 station_hours_pkey_437; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_437
    ADD CONSTRAINT station_hours_pkey_437 PRIMARY KEY (slid);


--
-- Name: station_hours_443 station_hours_pkey_443; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_443
    ADD CONSTRAINT station_hours_pkey_443 PRIMARY KEY (slid);


--
-- Name: station_hours_447 station_hours_pkey_447; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_447
    ADD CONSTRAINT station_hours_pkey_447 PRIMARY KEY (slid);


--
-- Name: station_hours_451 station_hours_pkey_451; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_451
    ADD CONSTRAINT station_hours_pkey_451 PRIMARY KEY (slid);


--
-- Name: station_hours_452 station_hours_pkey_452; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_452
    ADD CONSTRAINT station_hours_pkey_452 PRIMARY KEY (slid);


--
-- Name: station_hours_453 station_hours_pkey_453; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_453
    ADD CONSTRAINT station_hours_pkey_453 PRIMARY KEY (slid);


--
-- Name: station_hours_454 station_hours_pkey_454; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_454
    ADD CONSTRAINT station_hours_pkey_454 PRIMARY KEY (slid);


--
-- Name: station_hours_455 station_hours_pkey_455; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_455
    ADD CONSTRAINT station_hours_pkey_455 PRIMARY KEY (slid);


--
-- Name: station_hours_459 station_hours_pkey_459; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_459
    ADD CONSTRAINT station_hours_pkey_459 PRIMARY KEY (slid);


--
-- Name: station_hours_460 station_hours_pkey_460; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_460
    ADD CONSTRAINT station_hours_pkey_460 PRIMARY KEY (slid);


--
-- Name: station_hours_461 station_hours_pkey_461; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_461
    ADD CONSTRAINT station_hours_pkey_461 PRIMARY KEY (slid);


--
-- Name: station_hours_462 station_hours_pkey_462; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_462
    ADD CONSTRAINT station_hours_pkey_462 PRIMARY KEY (slid);


--
-- Name: station_hours_463 station_hours_pkey_463; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_463
    ADD CONSTRAINT station_hours_pkey_463 PRIMARY KEY (slid);


--
-- Name: station_hours_464 station_hours_pkey_464; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_464
    ADD CONSTRAINT station_hours_pkey_464 PRIMARY KEY (slid);


--
-- Name: station_hours_465 station_hours_pkey_465; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_465
    ADD CONSTRAINT station_hours_pkey_465 PRIMARY KEY (slid);


--
-- Name: station_hours_466 station_hours_pkey_466; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_466
    ADD CONSTRAINT station_hours_pkey_466 PRIMARY KEY (slid);


--
-- Name: station_hours_467 station_hours_pkey_467; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_467
    ADD CONSTRAINT station_hours_pkey_467 PRIMARY KEY (slid);


--
-- Name: station_hours_469 station_hours_pkey_469; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_469
    ADD CONSTRAINT station_hours_pkey_469 PRIMARY KEY (slid);


--
-- Name: station_hours_470 station_hours_pkey_470; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_470
    ADD CONSTRAINT station_hours_pkey_470 PRIMARY KEY (slid);


--
-- Name: station_hours_473 station_hours_pkey_473; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_473
    ADD CONSTRAINT station_hours_pkey_473 PRIMARY KEY (slid);


--
-- Name: station_hours_474 station_hours_pkey_474; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_474
    ADD CONSTRAINT station_hours_pkey_474 PRIMARY KEY (slid);


--
-- Name: station_hours_500 station_hours_pkey_500; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_500
    ADD CONSTRAINT station_hours_pkey_500 PRIMARY KEY (slid);


--
-- Name: station_hours_501 station_hours_pkey_501; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_501
    ADD CONSTRAINT station_hours_pkey_501 PRIMARY KEY (slid);


--
-- Name: station_hours_502 station_hours_pkey_502; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_502
    ADD CONSTRAINT station_hours_pkey_502 PRIMARY KEY (slid);


--
-- Name: station_hours_503 station_hours_pkey_503; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_503
    ADD CONSTRAINT station_hours_pkey_503 PRIMARY KEY (slid);


--
-- Name: station_hours_504 station_hours_pkey_504; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_504
    ADD CONSTRAINT station_hours_pkey_504 PRIMARY KEY (slid);


--
-- Name: station_hours_505 station_hours_pkey_505; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_505
    ADD CONSTRAINT station_hours_pkey_505 PRIMARY KEY (slid);


--
-- Name: station_hours_514 station_hours_pkey_514; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_514
    ADD CONSTRAINT station_hours_pkey_514 PRIMARY KEY (slid);


--
-- Name: station_hours_530 station_hours_pkey_530; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_530
    ADD CONSTRAINT station_hours_pkey_530 PRIMARY KEY (slid);


--
-- Name: station_hours_533 station_hours_pkey_533; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_533
    ADD CONSTRAINT station_hours_pkey_533 PRIMARY KEY (slid);


--
-- Name: station_hours_537 station_hours_pkey_537; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_537
    ADD CONSTRAINT station_hours_pkey_537 PRIMARY KEY (slid);


--
-- Name: station_hours_539 station_hours_pkey_539; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_539
    ADD CONSTRAINT station_hours_pkey_539 PRIMARY KEY (slid);


--
-- Name: station_hours_553 station_hours_pkey_553; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_553
    ADD CONSTRAINT station_hours_pkey_553 PRIMARY KEY (slid);


--
-- Name: station_hours_556 station_hours_pkey_556; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_556
    ADD CONSTRAINT station_hours_pkey_556 PRIMARY KEY (slid);


--
-- Name: station_hours_561 station_hours_pkey_561; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_561
    ADD CONSTRAINT station_hours_pkey_561 PRIMARY KEY (slid);


--
-- Name: station_hours_565 station_hours_pkey_565; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_565
    ADD CONSTRAINT station_hours_pkey_565 PRIMARY KEY (slid);


--
-- Name: station_hours_575 station_hours_pkey_575; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_575
    ADD CONSTRAINT station_hours_pkey_575 PRIMARY KEY (slid);


--
-- Name: station_hours_577 station_hours_pkey_577; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_577
    ADD CONSTRAINT station_hours_pkey_577 PRIMARY KEY (slid);


--
-- Name: station_hours_578 station_hours_pkey_578; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_578
    ADD CONSTRAINT station_hours_pkey_578 PRIMARY KEY (slid);


--
-- Name: station_hours_594 station_hours_pkey_594; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_594
    ADD CONSTRAINT station_hours_pkey_594 PRIMARY KEY (slid);


--
-- Name: station_hours_595 station_hours_pkey_595; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_595
    ADD CONSTRAINT station_hours_pkey_595 PRIMARY KEY (slid);


--
-- Name: station_hours_597 station_hours_pkey_597; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_597
    ADD CONSTRAINT station_hours_pkey_597 PRIMARY KEY (slid);


--
-- Name: station_hours_601 station_hours_pkey_601; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_601
    ADD CONSTRAINT station_hours_pkey_601 PRIMARY KEY (slid);


--
-- Name: station_hours_602 station_hours_pkey_602; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_602
    ADD CONSTRAINT station_hours_pkey_602 PRIMARY KEY (slid);


--
-- Name: station_hours_603 station_hours_pkey_603; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_603
    ADD CONSTRAINT station_hours_pkey_603 PRIMARY KEY (slid);


--
-- Name: station_hours_604 station_hours_pkey_604; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_604
    ADD CONSTRAINT station_hours_pkey_604 PRIMARY KEY (slid);


--
-- Name: station_hours_605 station_hours_pkey_605; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_605
    ADD CONSTRAINT station_hours_pkey_605 PRIMARY KEY (slid);


--
-- Name: station_hours_606 station_hours_pkey_606; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_606
    ADD CONSTRAINT station_hours_pkey_606 PRIMARY KEY (slid);


--
-- Name: station_hours_607 station_hours_pkey_607; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_607
    ADD CONSTRAINT station_hours_pkey_607 PRIMARY KEY (slid);


--
-- Name: station_hours_608 station_hours_pkey_608; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_608
    ADD CONSTRAINT station_hours_pkey_608 PRIMARY KEY (slid);


--
-- Name: station_hours_609 station_hours_pkey_609; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_609
    ADD CONSTRAINT station_hours_pkey_609 PRIMARY KEY (slid);


--
-- Name: station_hours_610 station_hours_pkey_610; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_610
    ADD CONSTRAINT station_hours_pkey_610 PRIMARY KEY (slid);


--
-- Name: station_hours_611 station_hours_pkey_611; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_611
    ADD CONSTRAINT station_hours_pkey_611 PRIMARY KEY (slid);


--
-- Name: station_hours_615 station_hours_pkey_615; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_615
    ADD CONSTRAINT station_hours_pkey_615 PRIMARY KEY (slid);


--
-- Name: station_hours_616 station_hours_pkey_616; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_616
    ADD CONSTRAINT station_hours_pkey_616 PRIMARY KEY (slid);


--
-- Name: station_hours_617 station_hours_pkey_617; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_617
    ADD CONSTRAINT station_hours_pkey_617 PRIMARY KEY (slid);


--
-- Name: station_hours_618 station_hours_pkey_618; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_618
    ADD CONSTRAINT station_hours_pkey_618 PRIMARY KEY (slid);


--
-- Name: station_hours_619 station_hours_pkey_619; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_619
    ADD CONSTRAINT station_hours_pkey_619 PRIMARY KEY (slid);


--
-- Name: station_hours_620 station_hours_pkey_620; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_620
    ADD CONSTRAINT station_hours_pkey_620 PRIMARY KEY (slid);


--
-- Name: station_hours_622 station_hours_pkey_622; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_622
    ADD CONSTRAINT station_hours_pkey_622 PRIMARY KEY (slid);


--
-- Name: station_hours_624 station_hours_pkey_624; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_624
    ADD CONSTRAINT station_hours_pkey_624 PRIMARY KEY (slid);


--
-- Name: station_hours_625 station_hours_pkey_625; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_625
    ADD CONSTRAINT station_hours_pkey_625 PRIMARY KEY (slid);


--
-- Name: station_hours_628 station_hours_pkey_628; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_628
    ADD CONSTRAINT station_hours_pkey_628 PRIMARY KEY (slid);


--
-- Name: station_hours_631 station_hours_pkey_631; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_631
    ADD CONSTRAINT station_hours_pkey_631 PRIMARY KEY (slid);


--
-- Name: station_hours_632 station_hours_pkey_632; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_632
    ADD CONSTRAINT station_hours_pkey_632 PRIMARY KEY (slid);


--
-- Name: station_hours_633 station_hours_pkey_633; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_633
    ADD CONSTRAINT station_hours_pkey_633 PRIMARY KEY (slid);


--
-- Name: station_hours_636 station_hours_pkey_636; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_636
    ADD CONSTRAINT station_hours_pkey_636 PRIMARY KEY (slid);


--
-- Name: station_hours_99 station_hours_pkey_99; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_hours_99
    ADD CONSTRAINT station_hours_pkey_99 PRIMARY KEY (slid);


--
-- Name: station_logs station_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs
    ADD CONSTRAINT station_logs_pkey PRIMARY KEY (id);


--
-- Name: station_minutes station_minutes_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes
    ADD CONSTRAINT station_minutes_pkey PRIMARY KEY (slid, sid);


--
-- Name: station_minutes_110 station_minutes_pkey_110; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_110
    ADD CONSTRAINT station_minutes_pkey_110 PRIMARY KEY (slid);


--
-- Name: station_minutes_167 station_minutes_pkey_167; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_167
    ADD CONSTRAINT station_minutes_pkey_167 PRIMARY KEY (slid);


--
-- Name: station_minutes_245 station_minutes_pkey_245; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_245
    ADD CONSTRAINT station_minutes_pkey_245 PRIMARY KEY (slid);


--
-- Name: station_minutes_247 station_minutes_pkey_247; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_247
    ADD CONSTRAINT station_minutes_pkey_247 PRIMARY KEY (slid);


--
-- Name: station_minutes_249 station_minutes_pkey_249; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_249
    ADD CONSTRAINT station_minutes_pkey_249 PRIMARY KEY (slid);


--
-- Name: station_minutes_259 station_minutes_pkey_259; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_259
    ADD CONSTRAINT station_minutes_pkey_259 PRIMARY KEY (slid);


--
-- Name: station_minutes_261 station_minutes_pkey_261; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_261
    ADD CONSTRAINT station_minutes_pkey_261 PRIMARY KEY (slid);


--
-- Name: station_minutes_284 station_minutes_pkey_284; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_284
    ADD CONSTRAINT station_minutes_pkey_284 PRIMARY KEY (slid);


--
-- Name: station_minutes_285 station_minutes_pkey_285; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_285
    ADD CONSTRAINT station_minutes_pkey_285 PRIMARY KEY (slid);


--
-- Name: station_minutes_296 station_minutes_pkey_296; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_296
    ADD CONSTRAINT station_minutes_pkey_296 PRIMARY KEY (slid);


--
-- Name: station_minutes_298 station_minutes_pkey_298; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_298
    ADD CONSTRAINT station_minutes_pkey_298 PRIMARY KEY (slid);


--
-- Name: station_minutes_3001 station_minutes_pkey_3001; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_3001
    ADD CONSTRAINT station_minutes_pkey_3001 PRIMARY KEY (slid);


--
-- Name: station_minutes_307 station_minutes_pkey_307; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_307
    ADD CONSTRAINT station_minutes_pkey_307 PRIMARY KEY (slid);


--
-- Name: station_minutes_308 station_minutes_pkey_308; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_308
    ADD CONSTRAINT station_minutes_pkey_308 PRIMARY KEY (slid);


--
-- Name: station_minutes_309 station_minutes_pkey_309; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_309
    ADD CONSTRAINT station_minutes_pkey_309 PRIMARY KEY (slid);


--
-- Name: station_minutes_310 station_minutes_pkey_310; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_310
    ADD CONSTRAINT station_minutes_pkey_310 PRIMARY KEY (slid);


--
-- Name: station_minutes_314 station_minutes_pkey_314; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_314
    ADD CONSTRAINT station_minutes_pkey_314 PRIMARY KEY (slid);


--
-- Name: station_minutes_316 station_minutes_pkey_316; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_316
    ADD CONSTRAINT station_minutes_pkey_316 PRIMARY KEY (slid);


--
-- Name: station_minutes_317 station_minutes_pkey_317; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_317
    ADD CONSTRAINT station_minutes_pkey_317 PRIMARY KEY (slid);


--
-- Name: station_minutes_319 station_minutes_pkey_319; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_319
    ADD CONSTRAINT station_minutes_pkey_319 PRIMARY KEY (slid);


--
-- Name: station_minutes_320 station_minutes_pkey_320; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_320
    ADD CONSTRAINT station_minutes_pkey_320 PRIMARY KEY (slid);


--
-- Name: station_minutes_323 station_minutes_pkey_323; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_323
    ADD CONSTRAINT station_minutes_pkey_323 PRIMARY KEY (slid);


--
-- Name: station_minutes_326 station_minutes_pkey_326; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_326
    ADD CONSTRAINT station_minutes_pkey_326 PRIMARY KEY (slid);


--
-- Name: station_minutes_327 station_minutes_pkey_327; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_327
    ADD CONSTRAINT station_minutes_pkey_327 PRIMARY KEY (slid);


--
-- Name: station_minutes_329 station_minutes_pkey_329; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_329
    ADD CONSTRAINT station_minutes_pkey_329 PRIMARY KEY (slid);


--
-- Name: station_minutes_330 station_minutes_pkey_330; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_330
    ADD CONSTRAINT station_minutes_pkey_330 PRIMARY KEY (slid);


--
-- Name: station_minutes_331 station_minutes_pkey_331; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_331
    ADD CONSTRAINT station_minutes_pkey_331 PRIMARY KEY (slid);


--
-- Name: station_minutes_333 station_minutes_pkey_333; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_333
    ADD CONSTRAINT station_minutes_pkey_333 PRIMARY KEY (slid);


--
-- Name: station_minutes_334 station_minutes_pkey_334; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_334
    ADD CONSTRAINT station_minutes_pkey_334 PRIMARY KEY (slid);


--
-- Name: station_minutes_336 station_minutes_pkey_336; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_336
    ADD CONSTRAINT station_minutes_pkey_336 PRIMARY KEY (slid);


--
-- Name: station_minutes_337 station_minutes_pkey_337; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_337
    ADD CONSTRAINT station_minutes_pkey_337 PRIMARY KEY (slid);


--
-- Name: station_minutes_338 station_minutes_pkey_338; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_338
    ADD CONSTRAINT station_minutes_pkey_338 PRIMARY KEY (slid);


--
-- Name: station_minutes_339 station_minutes_pkey_339; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_339
    ADD CONSTRAINT station_minutes_pkey_339 PRIMARY KEY (slid);


--
-- Name: station_minutes_343 station_minutes_pkey_343; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_343
    ADD CONSTRAINT station_minutes_pkey_343 PRIMARY KEY (slid);


--
-- Name: station_minutes_346 station_minutes_pkey_346; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_346
    ADD CONSTRAINT station_minutes_pkey_346 PRIMARY KEY (slid);


--
-- Name: station_minutes_347 station_minutes_pkey_347; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_347
    ADD CONSTRAINT station_minutes_pkey_347 PRIMARY KEY (slid);


--
-- Name: station_minutes_348 station_minutes_pkey_348; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_348
    ADD CONSTRAINT station_minutes_pkey_348 PRIMARY KEY (slid);


--
-- Name: station_minutes_349 station_minutes_pkey_349; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_349
    ADD CONSTRAINT station_minutes_pkey_349 PRIMARY KEY (slid);


--
-- Name: station_minutes_350 station_minutes_pkey_350; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_350
    ADD CONSTRAINT station_minutes_pkey_350 PRIMARY KEY (slid);


--
-- Name: station_minutes_351 station_minutes_pkey_351; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_351
    ADD CONSTRAINT station_minutes_pkey_351 PRIMARY KEY (slid);


--
-- Name: station_minutes_352 station_minutes_pkey_352; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_352
    ADD CONSTRAINT station_minutes_pkey_352 PRIMARY KEY (slid);


--
-- Name: station_minutes_353 station_minutes_pkey_353; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_353
    ADD CONSTRAINT station_minutes_pkey_353 PRIMARY KEY (slid);


--
-- Name: station_minutes_354 station_minutes_pkey_354; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_354
    ADD CONSTRAINT station_minutes_pkey_354 PRIMARY KEY (slid);


--
-- Name: station_minutes_355 station_minutes_pkey_355; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_355
    ADD CONSTRAINT station_minutes_pkey_355 PRIMARY KEY (slid);


--
-- Name: station_minutes_356 station_minutes_pkey_356; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_356
    ADD CONSTRAINT station_minutes_pkey_356 PRIMARY KEY (slid);


--
-- Name: station_minutes_357 station_minutes_pkey_357; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_357
    ADD CONSTRAINT station_minutes_pkey_357 PRIMARY KEY (slid);


--
-- Name: station_minutes_358 station_minutes_pkey_358; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_358
    ADD CONSTRAINT station_minutes_pkey_358 PRIMARY KEY (slid);


--
-- Name: station_minutes_359 station_minutes_pkey_359; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_359
    ADD CONSTRAINT station_minutes_pkey_359 PRIMARY KEY (slid);


--
-- Name: station_minutes_360 station_minutes_pkey_360; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_360
    ADD CONSTRAINT station_minutes_pkey_360 PRIMARY KEY (slid);


--
-- Name: station_minutes_361 station_minutes_pkey_361; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_361
    ADD CONSTRAINT station_minutes_pkey_361 PRIMARY KEY (slid);


--
-- Name: station_minutes_362 station_minutes_pkey_362; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_362
    ADD CONSTRAINT station_minutes_pkey_362 PRIMARY KEY (slid);


--
-- Name: station_minutes_363 station_minutes_pkey_363; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_363
    ADD CONSTRAINT station_minutes_pkey_363 PRIMARY KEY (slid);


--
-- Name: station_minutes_364 station_minutes_pkey_364; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_364
    ADD CONSTRAINT station_minutes_pkey_364 PRIMARY KEY (slid);


--
-- Name: station_minutes_365 station_minutes_pkey_365; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_365
    ADD CONSTRAINT station_minutes_pkey_365 PRIMARY KEY (slid);


--
-- Name: station_minutes_370 station_minutes_pkey_370; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_370
    ADD CONSTRAINT station_minutes_pkey_370 PRIMARY KEY (slid);


--
-- Name: station_minutes_371 station_minutes_pkey_371; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_371
    ADD CONSTRAINT station_minutes_pkey_371 PRIMARY KEY (slid);


--
-- Name: station_minutes_372 station_minutes_pkey_372; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_372
    ADD CONSTRAINT station_minutes_pkey_372 PRIMARY KEY (slid);


--
-- Name: station_minutes_373 station_minutes_pkey_373; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_373
    ADD CONSTRAINT station_minutes_pkey_373 PRIMARY KEY (slid);


--
-- Name: station_minutes_374 station_minutes_pkey_374; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_374
    ADD CONSTRAINT station_minutes_pkey_374 PRIMARY KEY (slid);


--
-- Name: station_minutes_375 station_minutes_pkey_375; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_375
    ADD CONSTRAINT station_minutes_pkey_375 PRIMARY KEY (slid);


--
-- Name: station_minutes_376 station_minutes_pkey_376; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_376
    ADD CONSTRAINT station_minutes_pkey_376 PRIMARY KEY (slid);


--
-- Name: station_minutes_377 station_minutes_pkey_377; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_377
    ADD CONSTRAINT station_minutes_pkey_377 PRIMARY KEY (slid);


--
-- Name: station_minutes_378 station_minutes_pkey_378; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_378
    ADD CONSTRAINT station_minutes_pkey_378 PRIMARY KEY (slid);


--
-- Name: station_minutes_379 station_minutes_pkey_379; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_379
    ADD CONSTRAINT station_minutes_pkey_379 PRIMARY KEY (slid);


--
-- Name: station_minutes_380 station_minutes_pkey_380; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_380
    ADD CONSTRAINT station_minutes_pkey_380 PRIMARY KEY (slid);


--
-- Name: station_minutes_382 station_minutes_pkey_382; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_382
    ADD CONSTRAINT station_minutes_pkey_382 PRIMARY KEY (slid);


--
-- Name: station_minutes_383 station_minutes_pkey_383; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_383
    ADD CONSTRAINT station_minutes_pkey_383 PRIMARY KEY (slid);


--
-- Name: station_minutes_385 station_minutes_pkey_385; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_385
    ADD CONSTRAINT station_minutes_pkey_385 PRIMARY KEY (slid);


--
-- Name: station_minutes_387 station_minutes_pkey_387; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_387
    ADD CONSTRAINT station_minutes_pkey_387 PRIMARY KEY (slid);


--
-- Name: station_minutes_389 station_minutes_pkey_389; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_389
    ADD CONSTRAINT station_minutes_pkey_389 PRIMARY KEY (slid);


--
-- Name: station_minutes_390 station_minutes_pkey_390; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_390
    ADD CONSTRAINT station_minutes_pkey_390 PRIMARY KEY (slid);


--
-- Name: station_minutes_391 station_minutes_pkey_391; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_391
    ADD CONSTRAINT station_minutes_pkey_391 PRIMARY KEY (slid);


--
-- Name: station_minutes_392 station_minutes_pkey_392; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_392
    ADD CONSTRAINT station_minutes_pkey_392 PRIMARY KEY (slid);


--
-- Name: station_minutes_395 station_minutes_pkey_395; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_395
    ADD CONSTRAINT station_minutes_pkey_395 PRIMARY KEY (slid);


--
-- Name: station_minutes_396 station_minutes_pkey_396; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_396
    ADD CONSTRAINT station_minutes_pkey_396 PRIMARY KEY (slid);


--
-- Name: station_minutes_397 station_minutes_pkey_397; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_397
    ADD CONSTRAINT station_minutes_pkey_397 PRIMARY KEY (slid);


--
-- Name: station_minutes_398 station_minutes_pkey_398; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_398
    ADD CONSTRAINT station_minutes_pkey_398 PRIMARY KEY (slid);


--
-- Name: station_minutes_399 station_minutes_pkey_399; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_399
    ADD CONSTRAINT station_minutes_pkey_399 PRIMARY KEY (slid);


--
-- Name: station_minutes_400 station_minutes_pkey_400; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_400
    ADD CONSTRAINT station_minutes_pkey_400 PRIMARY KEY (slid);


--
-- Name: station_minutes_403 station_minutes_pkey_403; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_403
    ADD CONSTRAINT station_minutes_pkey_403 PRIMARY KEY (slid);


--
-- Name: station_minutes_404 station_minutes_pkey_404; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_404
    ADD CONSTRAINT station_minutes_pkey_404 PRIMARY KEY (slid);


--
-- Name: station_minutes_405 station_minutes_pkey_405; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_405
    ADD CONSTRAINT station_minutes_pkey_405 PRIMARY KEY (slid);


--
-- Name: station_minutes_406 station_minutes_pkey_406; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_406
    ADD CONSTRAINT station_minutes_pkey_406 PRIMARY KEY (slid);


--
-- Name: station_minutes_407 station_minutes_pkey_407; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_407
    ADD CONSTRAINT station_minutes_pkey_407 PRIMARY KEY (slid);


--
-- Name: station_minutes_409 station_minutes_pkey_409; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_409
    ADD CONSTRAINT station_minutes_pkey_409 PRIMARY KEY (slid);


--
-- Name: station_minutes_410 station_minutes_pkey_410; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_410
    ADD CONSTRAINT station_minutes_pkey_410 PRIMARY KEY (slid);


--
-- Name: station_minutes_411 station_minutes_pkey_411; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_411
    ADD CONSTRAINT station_minutes_pkey_411 PRIMARY KEY (slid);


--
-- Name: station_minutes_412 station_minutes_pkey_412; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_412
    ADD CONSTRAINT station_minutes_pkey_412 PRIMARY KEY (slid);


--
-- Name: station_minutes_413 station_minutes_pkey_413; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_413
    ADD CONSTRAINT station_minutes_pkey_413 PRIMARY KEY (slid);


--
-- Name: station_minutes_414 station_minutes_pkey_414; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_414
    ADD CONSTRAINT station_minutes_pkey_414 PRIMARY KEY (slid);


--
-- Name: station_minutes_415 station_minutes_pkey_415; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_415
    ADD CONSTRAINT station_minutes_pkey_415 PRIMARY KEY (slid);


--
-- Name: station_minutes_417 station_minutes_pkey_417; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_417
    ADD CONSTRAINT station_minutes_pkey_417 PRIMARY KEY (slid);


--
-- Name: station_minutes_418 station_minutes_pkey_418; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_418
    ADD CONSTRAINT station_minutes_pkey_418 PRIMARY KEY (slid);


--
-- Name: station_minutes_419 station_minutes_pkey_419; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_419
    ADD CONSTRAINT station_minutes_pkey_419 PRIMARY KEY (slid);


--
-- Name: station_minutes_420 station_minutes_pkey_420; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_420
    ADD CONSTRAINT station_minutes_pkey_420 PRIMARY KEY (slid);


--
-- Name: station_minutes_422 station_minutes_pkey_422; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_422
    ADD CONSTRAINT station_minutes_pkey_422 PRIMARY KEY (slid);


--
-- Name: station_minutes_423 station_minutes_pkey_423; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_423
    ADD CONSTRAINT station_minutes_pkey_423 PRIMARY KEY (slid);


--
-- Name: station_minutes_425 station_minutes_pkey_425; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_425
    ADD CONSTRAINT station_minutes_pkey_425 PRIMARY KEY (slid);


--
-- Name: station_minutes_428 station_minutes_pkey_428; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_428
    ADD CONSTRAINT station_minutes_pkey_428 PRIMARY KEY (slid);


--
-- Name: station_minutes_429 station_minutes_pkey_429; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_429
    ADD CONSTRAINT station_minutes_pkey_429 PRIMARY KEY (slid);


--
-- Name: station_minutes_430 station_minutes_pkey_430; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_430
    ADD CONSTRAINT station_minutes_pkey_430 PRIMARY KEY (slid);


--
-- Name: station_minutes_433 station_minutes_pkey_433; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_433
    ADD CONSTRAINT station_minutes_pkey_433 PRIMARY KEY (slid);


--
-- Name: station_minutes_434 station_minutes_pkey_434; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_434
    ADD CONSTRAINT station_minutes_pkey_434 PRIMARY KEY (slid);


--
-- Name: station_minutes_435 station_minutes_pkey_435; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_435
    ADD CONSTRAINT station_minutes_pkey_435 PRIMARY KEY (slid);


--
-- Name: station_minutes_436 station_minutes_pkey_436; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_436
    ADD CONSTRAINT station_minutes_pkey_436 PRIMARY KEY (slid);


--
-- Name: station_minutes_437 station_minutes_pkey_437; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_437
    ADD CONSTRAINT station_minutes_pkey_437 PRIMARY KEY (slid);


--
-- Name: station_minutes_443 station_minutes_pkey_443; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_443
    ADD CONSTRAINT station_minutes_pkey_443 PRIMARY KEY (slid);


--
-- Name: station_minutes_447 station_minutes_pkey_447; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_447
    ADD CONSTRAINT station_minutes_pkey_447 PRIMARY KEY (slid);


--
-- Name: station_minutes_451 station_minutes_pkey_451; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_451
    ADD CONSTRAINT station_minutes_pkey_451 PRIMARY KEY (slid);


--
-- Name: station_minutes_452 station_minutes_pkey_452; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_452
    ADD CONSTRAINT station_minutes_pkey_452 PRIMARY KEY (slid);


--
-- Name: station_minutes_453 station_minutes_pkey_453; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_453
    ADD CONSTRAINT station_minutes_pkey_453 PRIMARY KEY (slid);


--
-- Name: station_minutes_454 station_minutes_pkey_454; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_454
    ADD CONSTRAINT station_minutes_pkey_454 PRIMARY KEY (slid);


--
-- Name: station_minutes_455 station_minutes_pkey_455; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_455
    ADD CONSTRAINT station_minutes_pkey_455 PRIMARY KEY (slid);


--
-- Name: station_minutes_459 station_minutes_pkey_459; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_459
    ADD CONSTRAINT station_minutes_pkey_459 PRIMARY KEY (slid);


--
-- Name: station_minutes_460 station_minutes_pkey_460; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_460
    ADD CONSTRAINT station_minutes_pkey_460 PRIMARY KEY (slid);


--
-- Name: station_minutes_461 station_minutes_pkey_461; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_461
    ADD CONSTRAINT station_minutes_pkey_461 PRIMARY KEY (slid);


--
-- Name: station_minutes_462 station_minutes_pkey_462; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_462
    ADD CONSTRAINT station_minutes_pkey_462 PRIMARY KEY (slid);


--
-- Name: station_minutes_463 station_minutes_pkey_463; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_463
    ADD CONSTRAINT station_minutes_pkey_463 PRIMARY KEY (slid);


--
-- Name: station_minutes_464 station_minutes_pkey_464; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_464
    ADD CONSTRAINT station_minutes_pkey_464 PRIMARY KEY (slid);


--
-- Name: station_minutes_465 station_minutes_pkey_465; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_465
    ADD CONSTRAINT station_minutes_pkey_465 PRIMARY KEY (slid);


--
-- Name: station_minutes_466 station_minutes_pkey_466; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_466
    ADD CONSTRAINT station_minutes_pkey_466 PRIMARY KEY (slid);


--
-- Name: station_minutes_467 station_minutes_pkey_467; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_467
    ADD CONSTRAINT station_minutes_pkey_467 PRIMARY KEY (slid);


--
-- Name: station_minutes_469 station_minutes_pkey_469; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_469
    ADD CONSTRAINT station_minutes_pkey_469 PRIMARY KEY (slid);


--
-- Name: station_minutes_470 station_minutes_pkey_470; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_470
    ADD CONSTRAINT station_minutes_pkey_470 PRIMARY KEY (slid);


--
-- Name: station_minutes_473 station_minutes_pkey_473; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_473
    ADD CONSTRAINT station_minutes_pkey_473 PRIMARY KEY (slid);


--
-- Name: station_minutes_474 station_minutes_pkey_474; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_474
    ADD CONSTRAINT station_minutes_pkey_474 PRIMARY KEY (slid);


--
-- Name: station_minutes_500 station_minutes_pkey_500; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_500
    ADD CONSTRAINT station_minutes_pkey_500 PRIMARY KEY (slid);


--
-- Name: station_minutes_501 station_minutes_pkey_501; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_501
    ADD CONSTRAINT station_minutes_pkey_501 PRIMARY KEY (slid);


--
-- Name: station_minutes_502 station_minutes_pkey_502; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_502
    ADD CONSTRAINT station_minutes_pkey_502 PRIMARY KEY (slid);


--
-- Name: station_minutes_503 station_minutes_pkey_503; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_503
    ADD CONSTRAINT station_minutes_pkey_503 PRIMARY KEY (slid);


--
-- Name: station_minutes_504 station_minutes_pkey_504; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_504
    ADD CONSTRAINT station_minutes_pkey_504 PRIMARY KEY (slid);


--
-- Name: station_minutes_505 station_minutes_pkey_505; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_505
    ADD CONSTRAINT station_minutes_pkey_505 PRIMARY KEY (slid);


--
-- Name: station_minutes_514 station_minutes_pkey_514; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_514
    ADD CONSTRAINT station_minutes_pkey_514 PRIMARY KEY (slid);


--
-- Name: station_minutes_530 station_minutes_pkey_530; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_530
    ADD CONSTRAINT station_minutes_pkey_530 PRIMARY KEY (slid);


--
-- Name: station_minutes_533 station_minutes_pkey_533; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_533
    ADD CONSTRAINT station_minutes_pkey_533 PRIMARY KEY (slid);


--
-- Name: station_minutes_537 station_minutes_pkey_537; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_537
    ADD CONSTRAINT station_minutes_pkey_537 PRIMARY KEY (slid);


--
-- Name: station_minutes_539 station_minutes_pkey_539; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_539
    ADD CONSTRAINT station_minutes_pkey_539 PRIMARY KEY (slid);


--
-- Name: station_minutes_553 station_minutes_pkey_553; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_553
    ADD CONSTRAINT station_minutes_pkey_553 PRIMARY KEY (slid);


--
-- Name: station_minutes_556 station_minutes_pkey_556; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_556
    ADD CONSTRAINT station_minutes_pkey_556 PRIMARY KEY (slid);


--
-- Name: station_minutes_561 station_minutes_pkey_561; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_561
    ADD CONSTRAINT station_minutes_pkey_561 PRIMARY KEY (slid);


--
-- Name: station_minutes_565 station_minutes_pkey_565; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_565
    ADD CONSTRAINT station_minutes_pkey_565 PRIMARY KEY (slid);


--
-- Name: station_minutes_575 station_minutes_pkey_575; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_575
    ADD CONSTRAINT station_minutes_pkey_575 PRIMARY KEY (slid);


--
-- Name: station_minutes_577 station_minutes_pkey_577; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_577
    ADD CONSTRAINT station_minutes_pkey_577 PRIMARY KEY (slid);


--
-- Name: station_minutes_578 station_minutes_pkey_578; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_578
    ADD CONSTRAINT station_minutes_pkey_578 PRIMARY KEY (slid);


--
-- Name: station_minutes_594 station_minutes_pkey_594; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_594
    ADD CONSTRAINT station_minutes_pkey_594 PRIMARY KEY (slid);


--
-- Name: station_minutes_595 station_minutes_pkey_595; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_595
    ADD CONSTRAINT station_minutes_pkey_595 PRIMARY KEY (slid);


--
-- Name: station_minutes_597 station_minutes_pkey_597; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_597
    ADD CONSTRAINT station_minutes_pkey_597 PRIMARY KEY (slid);


--
-- Name: station_minutes_601 station_minutes_pkey_601; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_601
    ADD CONSTRAINT station_minutes_pkey_601 PRIMARY KEY (slid);


--
-- Name: station_minutes_602 station_minutes_pkey_602; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_602
    ADD CONSTRAINT station_minutes_pkey_602 PRIMARY KEY (slid);


--
-- Name: station_minutes_603 station_minutes_pkey_603; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_603
    ADD CONSTRAINT station_minutes_pkey_603 PRIMARY KEY (slid);


--
-- Name: station_minutes_604 station_minutes_pkey_604; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_604
    ADD CONSTRAINT station_minutes_pkey_604 PRIMARY KEY (slid);


--
-- Name: station_minutes_605 station_minutes_pkey_605; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_605
    ADD CONSTRAINT station_minutes_pkey_605 PRIMARY KEY (slid);


--
-- Name: station_minutes_606 station_minutes_pkey_606; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_606
    ADD CONSTRAINT station_minutes_pkey_606 PRIMARY KEY (slid);


--
-- Name: station_minutes_607 station_minutes_pkey_607; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_607
    ADD CONSTRAINT station_minutes_pkey_607 PRIMARY KEY (slid);


--
-- Name: station_minutes_608 station_minutes_pkey_608; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_608
    ADD CONSTRAINT station_minutes_pkey_608 PRIMARY KEY (slid);


--
-- Name: station_minutes_609 station_minutes_pkey_609; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_609
    ADD CONSTRAINT station_minutes_pkey_609 PRIMARY KEY (slid);


--
-- Name: station_minutes_610 station_minutes_pkey_610; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_610
    ADD CONSTRAINT station_minutes_pkey_610 PRIMARY KEY (slid);


--
-- Name: station_minutes_611 station_minutes_pkey_611; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_611
    ADD CONSTRAINT station_minutes_pkey_611 PRIMARY KEY (slid);


--
-- Name: station_minutes_615 station_minutes_pkey_615; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_615
    ADD CONSTRAINT station_minutes_pkey_615 PRIMARY KEY (slid);


--
-- Name: station_minutes_616 station_minutes_pkey_616; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_616
    ADD CONSTRAINT station_minutes_pkey_616 PRIMARY KEY (slid);


--
-- Name: station_minutes_617 station_minutes_pkey_617; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_617
    ADD CONSTRAINT station_minutes_pkey_617 PRIMARY KEY (slid);


--
-- Name: station_minutes_618 station_minutes_pkey_618; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_618
    ADD CONSTRAINT station_minutes_pkey_618 PRIMARY KEY (slid);


--
-- Name: station_minutes_619 station_minutes_pkey_619; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_619
    ADD CONSTRAINT station_minutes_pkey_619 PRIMARY KEY (slid);


--
-- Name: station_minutes_620 station_minutes_pkey_620; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_620
    ADD CONSTRAINT station_minutes_pkey_620 PRIMARY KEY (slid);


--
-- Name: station_minutes_622 station_minutes_pkey_622; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_622
    ADD CONSTRAINT station_minutes_pkey_622 PRIMARY KEY (slid);


--
-- Name: station_minutes_624 station_minutes_pkey_624; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_624
    ADD CONSTRAINT station_minutes_pkey_624 PRIMARY KEY (slid);


--
-- Name: station_minutes_625 station_minutes_pkey_625; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_625
    ADD CONSTRAINT station_minutes_pkey_625 PRIMARY KEY (slid);


--
-- Name: station_minutes_628 station_minutes_pkey_628; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_628
    ADD CONSTRAINT station_minutes_pkey_628 PRIMARY KEY (slid);


--
-- Name: station_minutes_631 station_minutes_pkey_631; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_631
    ADD CONSTRAINT station_minutes_pkey_631 PRIMARY KEY (slid);


--
-- Name: station_minutes_632 station_minutes_pkey_632; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_632
    ADD CONSTRAINT station_minutes_pkey_632 PRIMARY KEY (slid);


--
-- Name: station_minutes_633 station_minutes_pkey_633; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_633
    ADD CONSTRAINT station_minutes_pkey_633 PRIMARY KEY (slid);


--
-- Name: station_minutes_636 station_minutes_pkey_636; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_636
    ADD CONSTRAINT station_minutes_pkey_636 PRIMARY KEY (slid);


--
-- Name: station_minutes_99 station_minutes_pkey_99; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_minutes_99
    ADD CONSTRAINT station_minutes_pkey_99 PRIMARY KEY (slid);


--
-- Name: stations stations_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (id);


--
-- Name: stations stations_unique_id_key; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_unique_id_key UNIQUE (unique_id);


--
-- Name: station_logs uniq_sid_sat; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs
    ADD CONSTRAINT uniq_sid_sat UNIQUE (station_id, submitted_at);


--
-- Name: station_logs_110 uniq_sid_sat_110; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_110
    ADD CONSTRAINT uniq_sid_sat_110 UNIQUE (submitted_at);


--
-- Name: station_logs_167 uniq_sid_sat_167; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_167
    ADD CONSTRAINT uniq_sid_sat_167 UNIQUE (submitted_at);


--
-- Name: station_logs_245 uniq_sid_sat_245; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_245
    ADD CONSTRAINT uniq_sid_sat_245 UNIQUE (submitted_at);


--
-- Name: station_logs_247 uniq_sid_sat_247; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_247
    ADD CONSTRAINT uniq_sid_sat_247 UNIQUE (submitted_at);


--
-- Name: station_logs_249 uniq_sid_sat_249; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_249
    ADD CONSTRAINT uniq_sid_sat_249 UNIQUE (submitted_at);


--
-- Name: station_logs_259 uniq_sid_sat_259; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_259
    ADD CONSTRAINT uniq_sid_sat_259 UNIQUE (submitted_at);


--
-- Name: station_logs_261 uniq_sid_sat_261; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_261
    ADD CONSTRAINT uniq_sid_sat_261 UNIQUE (submitted_at);


--
-- Name: station_logs_284 uniq_sid_sat_284; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_284
    ADD CONSTRAINT uniq_sid_sat_284 UNIQUE (submitted_at);


--
-- Name: station_logs_285 uniq_sid_sat_285; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_285
    ADD CONSTRAINT uniq_sid_sat_285 UNIQUE (submitted_at);


--
-- Name: station_logs_296 uniq_sid_sat_296; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_296
    ADD CONSTRAINT uniq_sid_sat_296 UNIQUE (submitted_at);


--
-- Name: station_logs_298 uniq_sid_sat_298; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_298
    ADD CONSTRAINT uniq_sid_sat_298 UNIQUE (submitted_at);


--
-- Name: station_logs_307 uniq_sid_sat_307; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_307
    ADD CONSTRAINT uniq_sid_sat_307 UNIQUE (submitted_at);


--
-- Name: station_logs_308 uniq_sid_sat_308; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_308
    ADD CONSTRAINT uniq_sid_sat_308 UNIQUE (submitted_at);


--
-- Name: station_logs_309 uniq_sid_sat_309; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_309
    ADD CONSTRAINT uniq_sid_sat_309 UNIQUE (submitted_at);


--
-- Name: station_logs_310 uniq_sid_sat_310; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_310
    ADD CONSTRAINT uniq_sid_sat_310 UNIQUE (submitted_at);


--
-- Name: station_logs_314 uniq_sid_sat_314; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_314
    ADD CONSTRAINT uniq_sid_sat_314 UNIQUE (submitted_at);


--
-- Name: station_logs_316 uniq_sid_sat_316; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_316
    ADD CONSTRAINT uniq_sid_sat_316 UNIQUE (submitted_at);


--
-- Name: station_logs_317 uniq_sid_sat_317; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_317
    ADD CONSTRAINT uniq_sid_sat_317 UNIQUE (submitted_at);


--
-- Name: station_logs_319 uniq_sid_sat_319; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_319
    ADD CONSTRAINT uniq_sid_sat_319 UNIQUE (submitted_at);


--
-- Name: station_logs_320 uniq_sid_sat_320; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_320
    ADD CONSTRAINT uniq_sid_sat_320 UNIQUE (submitted_at);


--
-- Name: station_logs_323 uniq_sid_sat_323; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_323
    ADD CONSTRAINT uniq_sid_sat_323 UNIQUE (submitted_at);


--
-- Name: station_logs_326 uniq_sid_sat_326; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_326
    ADD CONSTRAINT uniq_sid_sat_326 UNIQUE (submitted_at);


--
-- Name: station_logs_327 uniq_sid_sat_327; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_327
    ADD CONSTRAINT uniq_sid_sat_327 UNIQUE (submitted_at);


--
-- Name: station_logs_329 uniq_sid_sat_329; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_329
    ADD CONSTRAINT uniq_sid_sat_329 UNIQUE (submitted_at);


--
-- Name: station_logs_330 uniq_sid_sat_330; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_330
    ADD CONSTRAINT uniq_sid_sat_330 UNIQUE (submitted_at);


--
-- Name: station_logs_331 uniq_sid_sat_331; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_331
    ADD CONSTRAINT uniq_sid_sat_331 UNIQUE (submitted_at);


--
-- Name: station_logs_333 uniq_sid_sat_333; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_333
    ADD CONSTRAINT uniq_sid_sat_333 UNIQUE (submitted_at);


--
-- Name: station_logs_334 uniq_sid_sat_334; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_334
    ADD CONSTRAINT uniq_sid_sat_334 UNIQUE (submitted_at);


--
-- Name: station_logs_336 uniq_sid_sat_336; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_336
    ADD CONSTRAINT uniq_sid_sat_336 UNIQUE (submitted_at);


--
-- Name: station_logs_337 uniq_sid_sat_337; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_337
    ADD CONSTRAINT uniq_sid_sat_337 UNIQUE (submitted_at);


--
-- Name: station_logs_338 uniq_sid_sat_338; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_338
    ADD CONSTRAINT uniq_sid_sat_338 UNIQUE (submitted_at);


--
-- Name: station_logs_339 uniq_sid_sat_339; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_339
    ADD CONSTRAINT uniq_sid_sat_339 UNIQUE (submitted_at);


--
-- Name: station_logs_343 uniq_sid_sat_343; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_343
    ADD CONSTRAINT uniq_sid_sat_343 UNIQUE (submitted_at);


--
-- Name: station_logs_346 uniq_sid_sat_346; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_346
    ADD CONSTRAINT uniq_sid_sat_346 UNIQUE (submitted_at);


--
-- Name: station_logs_347 uniq_sid_sat_347; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_347
    ADD CONSTRAINT uniq_sid_sat_347 UNIQUE (submitted_at);


--
-- Name: station_logs_348 uniq_sid_sat_348; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_348
    ADD CONSTRAINT uniq_sid_sat_348 UNIQUE (submitted_at);


--
-- Name: station_logs_349 uniq_sid_sat_349; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_349
    ADD CONSTRAINT uniq_sid_sat_349 UNIQUE (submitted_at);


--
-- Name: station_logs_350 uniq_sid_sat_350; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_350
    ADD CONSTRAINT uniq_sid_sat_350 UNIQUE (submitted_at);


--
-- Name: station_logs_351 uniq_sid_sat_351; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_351
    ADD CONSTRAINT uniq_sid_sat_351 UNIQUE (submitted_at);


--
-- Name: station_logs_352 uniq_sid_sat_352; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_352
    ADD CONSTRAINT uniq_sid_sat_352 UNIQUE (submitted_at);


--
-- Name: station_logs_353 uniq_sid_sat_353; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_353
    ADD CONSTRAINT uniq_sid_sat_353 UNIQUE (submitted_at);


--
-- Name: station_logs_354 uniq_sid_sat_354; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_354
    ADD CONSTRAINT uniq_sid_sat_354 UNIQUE (submitted_at);


--
-- Name: station_logs_355 uniq_sid_sat_355; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_355
    ADD CONSTRAINT uniq_sid_sat_355 UNIQUE (submitted_at);


--
-- Name: station_logs_356 uniq_sid_sat_356; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_356
    ADD CONSTRAINT uniq_sid_sat_356 UNIQUE (submitted_at);


--
-- Name: station_logs_357 uniq_sid_sat_357; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_357
    ADD CONSTRAINT uniq_sid_sat_357 UNIQUE (submitted_at);


--
-- Name: station_logs_358 uniq_sid_sat_358; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_358
    ADD CONSTRAINT uniq_sid_sat_358 UNIQUE (submitted_at);


--
-- Name: station_logs_359 uniq_sid_sat_359; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_359
    ADD CONSTRAINT uniq_sid_sat_359 UNIQUE (submitted_at);


--
-- Name: station_logs_360 uniq_sid_sat_360; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_360
    ADD CONSTRAINT uniq_sid_sat_360 UNIQUE (submitted_at);


--
-- Name: station_logs_361 uniq_sid_sat_361; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_361
    ADD CONSTRAINT uniq_sid_sat_361 UNIQUE (submitted_at);


--
-- Name: station_logs_362 uniq_sid_sat_362; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_362
    ADD CONSTRAINT uniq_sid_sat_362 UNIQUE (submitted_at);


--
-- Name: station_logs_363 uniq_sid_sat_363; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_363
    ADD CONSTRAINT uniq_sid_sat_363 UNIQUE (submitted_at);


--
-- Name: station_logs_364 uniq_sid_sat_364; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_364
    ADD CONSTRAINT uniq_sid_sat_364 UNIQUE (submitted_at);


--
-- Name: station_logs_365 uniq_sid_sat_365; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_365
    ADD CONSTRAINT uniq_sid_sat_365 UNIQUE (submitted_at);


--
-- Name: station_logs_370 uniq_sid_sat_370; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_370
    ADD CONSTRAINT uniq_sid_sat_370 UNIQUE (submitted_at);


--
-- Name: station_logs_371 uniq_sid_sat_371; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_371
    ADD CONSTRAINT uniq_sid_sat_371 UNIQUE (submitted_at);


--
-- Name: station_logs_372 uniq_sid_sat_372; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_372
    ADD CONSTRAINT uniq_sid_sat_372 UNIQUE (submitted_at);


--
-- Name: station_logs_373 uniq_sid_sat_373; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_373
    ADD CONSTRAINT uniq_sid_sat_373 UNIQUE (submitted_at);


--
-- Name: station_logs_374 uniq_sid_sat_374; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_374
    ADD CONSTRAINT uniq_sid_sat_374 UNIQUE (submitted_at);


--
-- Name: station_logs_375 uniq_sid_sat_375; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_375
    ADD CONSTRAINT uniq_sid_sat_375 UNIQUE (submitted_at);


--
-- Name: station_logs_376 uniq_sid_sat_376; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_376
    ADD CONSTRAINT uniq_sid_sat_376 UNIQUE (submitted_at);


--
-- Name: station_logs_377 uniq_sid_sat_377; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_377
    ADD CONSTRAINT uniq_sid_sat_377 UNIQUE (submitted_at);


--
-- Name: station_logs_378 uniq_sid_sat_378; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_378
    ADD CONSTRAINT uniq_sid_sat_378 UNIQUE (submitted_at);


--
-- Name: station_logs_379 uniq_sid_sat_379; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_379
    ADD CONSTRAINT uniq_sid_sat_379 UNIQUE (submitted_at);


--
-- Name: station_logs_380 uniq_sid_sat_380; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_380
    ADD CONSTRAINT uniq_sid_sat_380 UNIQUE (submitted_at);


--
-- Name: station_logs_382 uniq_sid_sat_382; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_382
    ADD CONSTRAINT uniq_sid_sat_382 UNIQUE (submitted_at);


--
-- Name: station_logs_383 uniq_sid_sat_383; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_383
    ADD CONSTRAINT uniq_sid_sat_383 UNIQUE (submitted_at);


--
-- Name: station_logs_385 uniq_sid_sat_385; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_385
    ADD CONSTRAINT uniq_sid_sat_385 UNIQUE (submitted_at);


--
-- Name: station_logs_387 uniq_sid_sat_387; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_387
    ADD CONSTRAINT uniq_sid_sat_387 UNIQUE (submitted_at);


--
-- Name: station_logs_389 uniq_sid_sat_389; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_389
    ADD CONSTRAINT uniq_sid_sat_389 UNIQUE (submitted_at);


--
-- Name: station_logs_390 uniq_sid_sat_390; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_390
    ADD CONSTRAINT uniq_sid_sat_390 UNIQUE (submitted_at);


--
-- Name: station_logs_391 uniq_sid_sat_391; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_391
    ADD CONSTRAINT uniq_sid_sat_391 UNIQUE (submitted_at);


--
-- Name: station_logs_392 uniq_sid_sat_392; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_392
    ADD CONSTRAINT uniq_sid_sat_392 UNIQUE (submitted_at);


--
-- Name: station_logs_395 uniq_sid_sat_395; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_395
    ADD CONSTRAINT uniq_sid_sat_395 UNIQUE (submitted_at);


--
-- Name: station_logs_396 uniq_sid_sat_396; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_396
    ADD CONSTRAINT uniq_sid_sat_396 UNIQUE (submitted_at);


--
-- Name: station_logs_397 uniq_sid_sat_397; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_397
    ADD CONSTRAINT uniq_sid_sat_397 UNIQUE (submitted_at);


--
-- Name: station_logs_398 uniq_sid_sat_398; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_398
    ADD CONSTRAINT uniq_sid_sat_398 UNIQUE (submitted_at);


--
-- Name: station_logs_399 uniq_sid_sat_399; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_399
    ADD CONSTRAINT uniq_sid_sat_399 UNIQUE (submitted_at);


--
-- Name: station_logs_400 uniq_sid_sat_400; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_400
    ADD CONSTRAINT uniq_sid_sat_400 UNIQUE (submitted_at);


--
-- Name: station_logs_403 uniq_sid_sat_403; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_403
    ADD CONSTRAINT uniq_sid_sat_403 UNIQUE (submitted_at);


--
-- Name: station_logs_404 uniq_sid_sat_404; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_404
    ADD CONSTRAINT uniq_sid_sat_404 UNIQUE (submitted_at);


--
-- Name: station_logs_405 uniq_sid_sat_405; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_405
    ADD CONSTRAINT uniq_sid_sat_405 UNIQUE (submitted_at);


--
-- Name: station_logs_406 uniq_sid_sat_406; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_406
    ADD CONSTRAINT uniq_sid_sat_406 UNIQUE (submitted_at);


--
-- Name: station_logs_407 uniq_sid_sat_407; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_407
    ADD CONSTRAINT uniq_sid_sat_407 UNIQUE (submitted_at);


--
-- Name: station_logs_409 uniq_sid_sat_409; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_409
    ADD CONSTRAINT uniq_sid_sat_409 UNIQUE (submitted_at);


--
-- Name: station_logs_410 uniq_sid_sat_410; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_410
    ADD CONSTRAINT uniq_sid_sat_410 UNIQUE (submitted_at);


--
-- Name: station_logs_411 uniq_sid_sat_411; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_411
    ADD CONSTRAINT uniq_sid_sat_411 UNIQUE (submitted_at);


--
-- Name: station_logs_412 uniq_sid_sat_412; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_412
    ADD CONSTRAINT uniq_sid_sat_412 UNIQUE (submitted_at);


--
-- Name: station_logs_413 uniq_sid_sat_413; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_413
    ADD CONSTRAINT uniq_sid_sat_413 UNIQUE (submitted_at);


--
-- Name: station_logs_414 uniq_sid_sat_414; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_414
    ADD CONSTRAINT uniq_sid_sat_414 UNIQUE (submitted_at);


--
-- Name: station_logs_415 uniq_sid_sat_415; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_415
    ADD CONSTRAINT uniq_sid_sat_415 UNIQUE (submitted_at);


--
-- Name: station_logs_417 uniq_sid_sat_417; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_417
    ADD CONSTRAINT uniq_sid_sat_417 UNIQUE (submitted_at);


--
-- Name: station_logs_418 uniq_sid_sat_418; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_418
    ADD CONSTRAINT uniq_sid_sat_418 UNIQUE (submitted_at);


--
-- Name: station_logs_419 uniq_sid_sat_419; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_419
    ADD CONSTRAINT uniq_sid_sat_419 UNIQUE (submitted_at);


--
-- Name: station_logs_420 uniq_sid_sat_420; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_420
    ADD CONSTRAINT uniq_sid_sat_420 UNIQUE (submitted_at);


--
-- Name: station_logs_422 uniq_sid_sat_422; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_422
    ADD CONSTRAINT uniq_sid_sat_422 UNIQUE (submitted_at);


--
-- Name: station_logs_423 uniq_sid_sat_423; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_423
    ADD CONSTRAINT uniq_sid_sat_423 UNIQUE (submitted_at);


--
-- Name: station_logs_425 uniq_sid_sat_425; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_425
    ADD CONSTRAINT uniq_sid_sat_425 UNIQUE (submitted_at);


--
-- Name: station_logs_428 uniq_sid_sat_428; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_428
    ADD CONSTRAINT uniq_sid_sat_428 UNIQUE (submitted_at);


--
-- Name: station_logs_429 uniq_sid_sat_429; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_429
    ADD CONSTRAINT uniq_sid_sat_429 UNIQUE (submitted_at);


--
-- Name: station_logs_430 uniq_sid_sat_430; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_430
    ADD CONSTRAINT uniq_sid_sat_430 UNIQUE (submitted_at);


--
-- Name: station_logs_433 uniq_sid_sat_433; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_433
    ADD CONSTRAINT uniq_sid_sat_433 UNIQUE (submitted_at);


--
-- Name: station_logs_434 uniq_sid_sat_434; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_434
    ADD CONSTRAINT uniq_sid_sat_434 UNIQUE (submitted_at);


--
-- Name: station_logs_435 uniq_sid_sat_435; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_435
    ADD CONSTRAINT uniq_sid_sat_435 UNIQUE (submitted_at);


--
-- Name: station_logs_436 uniq_sid_sat_436; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_436
    ADD CONSTRAINT uniq_sid_sat_436 UNIQUE (submitted_at);


--
-- Name: station_logs_437 uniq_sid_sat_437; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_437
    ADD CONSTRAINT uniq_sid_sat_437 UNIQUE (submitted_at);


--
-- Name: station_logs_443 uniq_sid_sat_443; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_443
    ADD CONSTRAINT uniq_sid_sat_443 UNIQUE (submitted_at);


--
-- Name: station_logs_447 uniq_sid_sat_447; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_447
    ADD CONSTRAINT uniq_sid_sat_447 UNIQUE (submitted_at);


--
-- Name: station_logs_451 uniq_sid_sat_451; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_451
    ADD CONSTRAINT uniq_sid_sat_451 UNIQUE (submitted_at);


--
-- Name: station_logs_452 uniq_sid_sat_452; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_452
    ADD CONSTRAINT uniq_sid_sat_452 UNIQUE (submitted_at);


--
-- Name: station_logs_453 uniq_sid_sat_453; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_453
    ADD CONSTRAINT uniq_sid_sat_453 UNIQUE (submitted_at);


--
-- Name: station_logs_454 uniq_sid_sat_454; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_454
    ADD CONSTRAINT uniq_sid_sat_454 UNIQUE (submitted_at);


--
-- Name: station_logs_455 uniq_sid_sat_455; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_455
    ADD CONSTRAINT uniq_sid_sat_455 UNIQUE (submitted_at);


--
-- Name: station_logs_459 uniq_sid_sat_459; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_459
    ADD CONSTRAINT uniq_sid_sat_459 UNIQUE (submitted_at);


--
-- Name: station_logs_460 uniq_sid_sat_460; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_460
    ADD CONSTRAINT uniq_sid_sat_460 UNIQUE (submitted_at);


--
-- Name: station_logs_462 uniq_sid_sat_462; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_462
    ADD CONSTRAINT uniq_sid_sat_462 UNIQUE (submitted_at);


--
-- Name: station_logs_463 uniq_sid_sat_463; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_463
    ADD CONSTRAINT uniq_sid_sat_463 UNIQUE (submitted_at);


--
-- Name: station_logs_464 uniq_sid_sat_464; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_464
    ADD CONSTRAINT uniq_sid_sat_464 UNIQUE (submitted_at);


--
-- Name: station_logs_465 uniq_sid_sat_465; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_465
    ADD CONSTRAINT uniq_sid_sat_465 UNIQUE (submitted_at);


--
-- Name: station_logs_466 uniq_sid_sat_466; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_466
    ADD CONSTRAINT uniq_sid_sat_466 UNIQUE (submitted_at);


--
-- Name: station_logs_467 uniq_sid_sat_467; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_467
    ADD CONSTRAINT uniq_sid_sat_467 UNIQUE (submitted_at);


--
-- Name: station_logs_469 uniq_sid_sat_469; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_469
    ADD CONSTRAINT uniq_sid_sat_469 UNIQUE (submitted_at);


--
-- Name: station_logs_470 uniq_sid_sat_470; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_470
    ADD CONSTRAINT uniq_sid_sat_470 UNIQUE (submitted_at);


--
-- Name: station_logs_473 uniq_sid_sat_473; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_473
    ADD CONSTRAINT uniq_sid_sat_473 UNIQUE (submitted_at);


--
-- Name: station_logs_474 uniq_sid_sat_474; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_474
    ADD CONSTRAINT uniq_sid_sat_474 UNIQUE (submitted_at);


--
-- Name: station_logs_500 uniq_sid_sat_500; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_500
    ADD CONSTRAINT uniq_sid_sat_500 UNIQUE (submitted_at);


--
-- Name: station_logs_501 uniq_sid_sat_501; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_501
    ADD CONSTRAINT uniq_sid_sat_501 UNIQUE (submitted_at);


--
-- Name: station_logs_502 uniq_sid_sat_502; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_502
    ADD CONSTRAINT uniq_sid_sat_502 UNIQUE (submitted_at);


--
-- Name: station_logs_503 uniq_sid_sat_503; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_503
    ADD CONSTRAINT uniq_sid_sat_503 UNIQUE (submitted_at);


--
-- Name: station_logs_504 uniq_sid_sat_504; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_504
    ADD CONSTRAINT uniq_sid_sat_504 UNIQUE (submitted_at);


--
-- Name: station_logs_505 uniq_sid_sat_505; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_505
    ADD CONSTRAINT uniq_sid_sat_505 UNIQUE (submitted_at);


--
-- Name: station_logs_514 uniq_sid_sat_514; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_514
    ADD CONSTRAINT uniq_sid_sat_514 UNIQUE (submitted_at);


--
-- Name: station_logs_530 uniq_sid_sat_530; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_530
    ADD CONSTRAINT uniq_sid_sat_530 UNIQUE (submitted_at);


--
-- Name: station_logs_533 uniq_sid_sat_533; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_533
    ADD CONSTRAINT uniq_sid_sat_533 UNIQUE (submitted_at);


--
-- Name: station_logs_537 uniq_sid_sat_537; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_537
    ADD CONSTRAINT uniq_sid_sat_537 UNIQUE (submitted_at);


--
-- Name: station_logs_539 uniq_sid_sat_539; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_539
    ADD CONSTRAINT uniq_sid_sat_539 UNIQUE (submitted_at);


--
-- Name: station_logs_553 uniq_sid_sat_553; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_553
    ADD CONSTRAINT uniq_sid_sat_553 UNIQUE (submitted_at);


--
-- Name: station_logs_556 uniq_sid_sat_556; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_556
    ADD CONSTRAINT uniq_sid_sat_556 UNIQUE (submitted_at);


--
-- Name: station_logs_561 uniq_sid_sat_561; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_561
    ADD CONSTRAINT uniq_sid_sat_561 UNIQUE (submitted_at);


--
-- Name: station_logs_565 uniq_sid_sat_565; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_565
    ADD CONSTRAINT uniq_sid_sat_565 UNIQUE (submitted_at);


--
-- Name: station_logs_575 uniq_sid_sat_575; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_575
    ADD CONSTRAINT uniq_sid_sat_575 UNIQUE (submitted_at);


--
-- Name: station_logs_577 uniq_sid_sat_577; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_577
    ADD CONSTRAINT uniq_sid_sat_577 UNIQUE (submitted_at);


--
-- Name: station_logs_578 uniq_sid_sat_578; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_578
    ADD CONSTRAINT uniq_sid_sat_578 UNIQUE (submitted_at);


--
-- Name: station_logs_594 uniq_sid_sat_594; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_594
    ADD CONSTRAINT uniq_sid_sat_594 UNIQUE (submitted_at);


--
-- Name: station_logs_595 uniq_sid_sat_595; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_595
    ADD CONSTRAINT uniq_sid_sat_595 UNIQUE (submitted_at);


--
-- Name: station_logs_597 uniq_sid_sat_597; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_597
    ADD CONSTRAINT uniq_sid_sat_597 UNIQUE (submitted_at);


--
-- Name: station_logs_601 uniq_sid_sat_601; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_601
    ADD CONSTRAINT uniq_sid_sat_601 UNIQUE (submitted_at);


--
-- Name: station_logs_602 uniq_sid_sat_602; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_602
    ADD CONSTRAINT uniq_sid_sat_602 UNIQUE (submitted_at);


--
-- Name: station_logs_603 uniq_sid_sat_603; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_603
    ADD CONSTRAINT uniq_sid_sat_603 UNIQUE (submitted_at);


--
-- Name: station_logs_604 uniq_sid_sat_604; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_604
    ADD CONSTRAINT uniq_sid_sat_604 UNIQUE (submitted_at);


--
-- Name: station_logs_605 uniq_sid_sat_605; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_605
    ADD CONSTRAINT uniq_sid_sat_605 UNIQUE (submitted_at);


--
-- Name: station_logs_606 uniq_sid_sat_606; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_606
    ADD CONSTRAINT uniq_sid_sat_606 UNIQUE (submitted_at);


--
-- Name: station_logs_607 uniq_sid_sat_607; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_607
    ADD CONSTRAINT uniq_sid_sat_607 UNIQUE (submitted_at);


--
-- Name: station_logs_608 uniq_sid_sat_608; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_608
    ADD CONSTRAINT uniq_sid_sat_608 UNIQUE (submitted_at);


--
-- Name: station_logs_609 uniq_sid_sat_609; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_609
    ADD CONSTRAINT uniq_sid_sat_609 UNIQUE (submitted_at);


--
-- Name: station_logs_610 uniq_sid_sat_610; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_610
    ADD CONSTRAINT uniq_sid_sat_610 UNIQUE (submitted_at);


--
-- Name: station_logs_611 uniq_sid_sat_611; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_611
    ADD CONSTRAINT uniq_sid_sat_611 UNIQUE (submitted_at);


--
-- Name: station_logs_615 uniq_sid_sat_615; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_615
    ADD CONSTRAINT uniq_sid_sat_615 UNIQUE (submitted_at);


--
-- Name: station_logs_616 uniq_sid_sat_616; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_616
    ADD CONSTRAINT uniq_sid_sat_616 UNIQUE (submitted_at);


--
-- Name: station_logs_617 uniq_sid_sat_617; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_617
    ADD CONSTRAINT uniq_sid_sat_617 UNIQUE (submitted_at);


--
-- Name: station_logs_618 uniq_sid_sat_618; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_618
    ADD CONSTRAINT uniq_sid_sat_618 UNIQUE (submitted_at);


--
-- Name: station_logs_619 uniq_sid_sat_619; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_619
    ADD CONSTRAINT uniq_sid_sat_619 UNIQUE (submitted_at);


--
-- Name: station_logs_620 uniq_sid_sat_620; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_620
    ADD CONSTRAINT uniq_sid_sat_620 UNIQUE (submitted_at);


--
-- Name: station_logs_622 uniq_sid_sat_622; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_622
    ADD CONSTRAINT uniq_sid_sat_622 UNIQUE (submitted_at);


--
-- Name: station_logs_624 uniq_sid_sat_624; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_624
    ADD CONSTRAINT uniq_sid_sat_624 UNIQUE (submitted_at);


--
-- Name: station_logs_625 uniq_sid_sat_625; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_625
    ADD CONSTRAINT uniq_sid_sat_625 UNIQUE (submitted_at);


--
-- Name: station_logs_626 uniq_sid_sat_626; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_626
    ADD CONSTRAINT uniq_sid_sat_626 UNIQUE (submitted_at);


--
-- Name: station_logs_627 uniq_sid_sat_627; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_627
    ADD CONSTRAINT uniq_sid_sat_627 UNIQUE (submitted_at);


--
-- Name: station_logs_628 uniq_sid_sat_628; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_628
    ADD CONSTRAINT uniq_sid_sat_628 UNIQUE (submitted_at);


--
-- Name: station_logs_631 uniq_sid_sat_631; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_631
    ADD CONSTRAINT uniq_sid_sat_631 UNIQUE (submitted_at);


--
-- Name: station_logs_632 uniq_sid_sat_632; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_632
    ADD CONSTRAINT uniq_sid_sat_632 UNIQUE (submitted_at);


--
-- Name: station_logs_633 uniq_sid_sat_633; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_633
    ADD CONSTRAINT uniq_sid_sat_633 UNIQUE (submitted_at);


--
-- Name: station_logs_636 uniq_sid_sat_636; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_636
    ADD CONSTRAINT uniq_sid_sat_636 UNIQUE (submitted_at);


--
-- Name: station_logs_645 uniq_sid_sat_645; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_645
    ADD CONSTRAINT uniq_sid_sat_645 UNIQUE (submitted_at);


--
-- Name: station_logs_99 uniq_sid_sat_99; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_99
    ADD CONSTRAINT uniq_sid_sat_99 UNIQUE (submitted_at);


--
-- Name: groups unique_groups_name; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT unique_groups_name UNIQUE (name);


--
-- Name: user_auths user_auths_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.user_auths
    ADD CONSTRAINT user_auths_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_unique_id_key; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_unique_id_key UNIQUE (unique_id);


--
-- Name: email_unique; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX email_unique ON public.users USING btree (email);


--
-- Name: index_station_hours_sid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_hours_sid ON public.station_hours USING btree (sid);

ALTER TABLE public.station_hours CLUSTER ON index_station_hours_sid;


--
-- Name: index_station_minutes_sid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_minutes_sid ON public.station_minutes USING btree (sid);


--
-- Name: index_station_minutes_slid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_minutes_slid ON public.station_minutes USING btree (slid);


--
-- Name: order_sid_sat; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX order_sid_sat ON public.station_logs USING btree (station_id, submitted_at);


--
-- Name: predictions_sta; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX predictions_sta ON public.predictions USING btree (station_id);


--
-- Name: station_hours_at_idx_110; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_110 ON public.station_hours_110 USING btree (at);


--
-- Name: station_hours_at_idx_167; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_167 ON public.station_hours_167 USING btree (at);


--
-- Name: station_hours_at_idx_245; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_245 ON public.station_hours_245 USING btree (at);


--
-- Name: station_hours_at_idx_247; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_247 ON public.station_hours_247 USING btree (at);


--
-- Name: station_hours_at_idx_249; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_249 ON public.station_hours_249 USING btree (at);


--
-- Name: station_hours_at_idx_259; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_259 ON public.station_hours_259 USING btree (at);


--
-- Name: station_hours_at_idx_261; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_261 ON public.station_hours_261 USING btree (at);


--
-- Name: station_hours_at_idx_284; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_284 ON public.station_hours_284 USING btree (at);


--
-- Name: station_hours_at_idx_285; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_285 ON public.station_hours_285 USING btree (at);


--
-- Name: station_hours_at_idx_296; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_296 ON public.station_hours_296 USING btree (at);


--
-- Name: station_hours_at_idx_298; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_298 ON public.station_hours_298 USING btree (at);


--
-- Name: station_hours_at_idx_307; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_307 ON public.station_hours_307 USING btree (at);


--
-- Name: station_hours_at_idx_308; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_308 ON public.station_hours_308 USING btree (at);


--
-- Name: station_hours_at_idx_309; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_309 ON public.station_hours_309 USING btree (at);


--
-- Name: station_hours_at_idx_310; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_310 ON public.station_hours_310 USING btree (at);


--
-- Name: station_hours_at_idx_314; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_314 ON public.station_hours_314 USING btree (at);


--
-- Name: station_hours_at_idx_316; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_316 ON public.station_hours_316 USING btree (at);


--
-- Name: station_hours_at_idx_317; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_317 ON public.station_hours_317 USING btree (at);


--
-- Name: station_hours_at_idx_319; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_319 ON public.station_hours_319 USING btree (at);


--
-- Name: station_hours_at_idx_320; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_320 ON public.station_hours_320 USING btree (at);


--
-- Name: station_hours_at_idx_323; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_323 ON public.station_hours_323 USING btree (at);


--
-- Name: station_hours_at_idx_326; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_326 ON public.station_hours_326 USING btree (at);


--
-- Name: station_hours_at_idx_327; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_327 ON public.station_hours_327 USING btree (at);


--
-- Name: station_hours_at_idx_329; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_329 ON public.station_hours_329 USING btree (at);


--
-- Name: station_hours_at_idx_330; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_330 ON public.station_hours_330 USING btree (at);


--
-- Name: station_hours_at_idx_331; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_331 ON public.station_hours_331 USING btree (at);


--
-- Name: station_hours_at_idx_333; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_333 ON public.station_hours_333 USING btree (at);


--
-- Name: station_hours_at_idx_334; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_334 ON public.station_hours_334 USING btree (at);


--
-- Name: station_hours_at_idx_336; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_336 ON public.station_hours_336 USING btree (at);


--
-- Name: station_hours_at_idx_337; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_337 ON public.station_hours_337 USING btree (at);


--
-- Name: station_hours_at_idx_338; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_338 ON public.station_hours_338 USING btree (at);


--
-- Name: station_hours_at_idx_339; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_339 ON public.station_hours_339 USING btree (at);


--
-- Name: station_hours_at_idx_343; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_343 ON public.station_hours_343 USING btree (at);


--
-- Name: station_hours_at_idx_346; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_346 ON public.station_hours_346 USING btree (at);


--
-- Name: station_hours_at_idx_347; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_347 ON public.station_hours_347 USING btree (at);


--
-- Name: station_hours_at_idx_348; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_348 ON public.station_hours_348 USING btree (at);


--
-- Name: station_hours_at_idx_349; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_349 ON public.station_hours_349 USING btree (at);


--
-- Name: station_hours_at_idx_350; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_350 ON public.station_hours_350 USING btree (at);


--
-- Name: station_hours_at_idx_351; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_351 ON public.station_hours_351 USING btree (at);


--
-- Name: station_hours_at_idx_352; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_352 ON public.station_hours_352 USING btree (at);


--
-- Name: station_hours_at_idx_353; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_353 ON public.station_hours_353 USING btree (at);


--
-- Name: station_hours_at_idx_354; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_354 ON public.station_hours_354 USING btree (at);


--
-- Name: station_hours_at_idx_355; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_355 ON public.station_hours_355 USING btree (at);


--
-- Name: station_hours_at_idx_356; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_356 ON public.station_hours_356 USING btree (at);


--
-- Name: station_hours_at_idx_357; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_357 ON public.station_hours_357 USING btree (at);


--
-- Name: station_hours_at_idx_358; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_358 ON public.station_hours_358 USING btree (at);


--
-- Name: station_hours_at_idx_359; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_359 ON public.station_hours_359 USING btree (at);


--
-- Name: station_hours_at_idx_360; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_360 ON public.station_hours_360 USING btree (at);


--
-- Name: station_hours_at_idx_361; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_361 ON public.station_hours_361 USING btree (at);


--
-- Name: station_hours_at_idx_362; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_362 ON public.station_hours_362 USING btree (at);


--
-- Name: station_hours_at_idx_363; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_363 ON public.station_hours_363 USING btree (at);


--
-- Name: station_hours_at_idx_364; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_364 ON public.station_hours_364 USING btree (at);


--
-- Name: station_hours_at_idx_365; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_365 ON public.station_hours_365 USING btree (at);


--
-- Name: station_hours_at_idx_370; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_370 ON public.station_hours_370 USING btree (at);


--
-- Name: station_hours_at_idx_371; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_371 ON public.station_hours_371 USING btree (at);


--
-- Name: station_hours_at_idx_372; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_372 ON public.station_hours_372 USING btree (at);


--
-- Name: station_hours_at_idx_373; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_373 ON public.station_hours_373 USING btree (at);


--
-- Name: station_hours_at_idx_374; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_374 ON public.station_hours_374 USING btree (at);


--
-- Name: station_hours_at_idx_375; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_375 ON public.station_hours_375 USING btree (at);


--
-- Name: station_hours_at_idx_376; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_376 ON public.station_hours_376 USING btree (at);


--
-- Name: station_hours_at_idx_377; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_377 ON public.station_hours_377 USING btree (at);


--
-- Name: station_hours_at_idx_378; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_378 ON public.station_hours_378 USING btree (at);


--
-- Name: station_hours_at_idx_379; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_379 ON public.station_hours_379 USING btree (at);


--
-- Name: station_hours_at_idx_380; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_380 ON public.station_hours_380 USING btree (at);


--
-- Name: station_hours_at_idx_382; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_382 ON public.station_hours_382 USING btree (at);


--
-- Name: station_hours_at_idx_383; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_383 ON public.station_hours_383 USING btree (at);


--
-- Name: station_hours_at_idx_385; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_385 ON public.station_hours_385 USING btree (at);


--
-- Name: station_hours_at_idx_387; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_387 ON public.station_hours_387 USING btree (at);


--
-- Name: station_hours_at_idx_389; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_389 ON public.station_hours_389 USING btree (at);


--
-- Name: station_hours_at_idx_390; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_390 ON public.station_hours_390 USING btree (at);


--
-- Name: station_hours_at_idx_391; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_391 ON public.station_hours_391 USING btree (at);


--
-- Name: station_hours_at_idx_392; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_392 ON public.station_hours_392 USING btree (at);


--
-- Name: station_hours_at_idx_395; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_395 ON public.station_hours_395 USING btree (at);


--
-- Name: station_hours_at_idx_396; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_396 ON public.station_hours_396 USING btree (at);


--
-- Name: station_hours_at_idx_397; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_397 ON public.station_hours_397 USING btree (at);


--
-- Name: station_hours_at_idx_398; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_398 ON public.station_hours_398 USING btree (at);


--
-- Name: station_hours_at_idx_399; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_399 ON public.station_hours_399 USING btree (at);


--
-- Name: station_hours_at_idx_400; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_400 ON public.station_hours_400 USING btree (at);


--
-- Name: station_hours_at_idx_403; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_403 ON public.station_hours_403 USING btree (at);


--
-- Name: station_hours_at_idx_404; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_404 ON public.station_hours_404 USING btree (at);


--
-- Name: station_hours_at_idx_405; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_405 ON public.station_hours_405 USING btree (at);


--
-- Name: station_hours_at_idx_406; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_406 ON public.station_hours_406 USING btree (at);


--
-- Name: station_hours_at_idx_407; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_407 ON public.station_hours_407 USING btree (at);


--
-- Name: station_hours_at_idx_409; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_409 ON public.station_hours_409 USING btree (at);


--
-- Name: station_hours_at_idx_410; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_410 ON public.station_hours_410 USING btree (at);


--
-- Name: station_hours_at_idx_411; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_411 ON public.station_hours_411 USING btree (at);


--
-- Name: station_hours_at_idx_412; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_412 ON public.station_hours_412 USING btree (at);


--
-- Name: station_hours_at_idx_413; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_413 ON public.station_hours_413 USING btree (at);


--
-- Name: station_hours_at_idx_414; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_414 ON public.station_hours_414 USING btree (at);


--
-- Name: station_hours_at_idx_415; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_415 ON public.station_hours_415 USING btree (at);


--
-- Name: station_hours_at_idx_417; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_417 ON public.station_hours_417 USING btree (at);


--
-- Name: station_hours_at_idx_418; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_418 ON public.station_hours_418 USING btree (at);


--
-- Name: station_hours_at_idx_419; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_419 ON public.station_hours_419 USING btree (at);


--
-- Name: station_hours_at_idx_420; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_420 ON public.station_hours_420 USING btree (at);


--
-- Name: station_hours_at_idx_422; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_422 ON public.station_hours_422 USING btree (at);


--
-- Name: station_hours_at_idx_423; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_423 ON public.station_hours_423 USING btree (at);


--
-- Name: station_hours_at_idx_425; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_425 ON public.station_hours_425 USING btree (at);


--
-- Name: station_hours_at_idx_428; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_428 ON public.station_hours_428 USING btree (at);


--
-- Name: station_hours_at_idx_429; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_429 ON public.station_hours_429 USING btree (at);


--
-- Name: station_hours_at_idx_430; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_430 ON public.station_hours_430 USING btree (at);


--
-- Name: station_hours_at_idx_433; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_433 ON public.station_hours_433 USING btree (at);


--
-- Name: station_hours_at_idx_434; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_434 ON public.station_hours_434 USING btree (at);


--
-- Name: station_hours_at_idx_435; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_435 ON public.station_hours_435 USING btree (at);


--
-- Name: station_hours_at_idx_436; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_436 ON public.station_hours_436 USING btree (at);


--
-- Name: station_hours_at_idx_437; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_437 ON public.station_hours_437 USING btree (at);


--
-- Name: station_hours_at_idx_443; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_443 ON public.station_hours_443 USING btree (at);


--
-- Name: station_hours_at_idx_447; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_447 ON public.station_hours_447 USING btree (at);


--
-- Name: station_hours_at_idx_451; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_451 ON public.station_hours_451 USING btree (at);


--
-- Name: station_hours_at_idx_452; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_452 ON public.station_hours_452 USING btree (at);


--
-- Name: station_hours_at_idx_453; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_453 ON public.station_hours_453 USING btree (at);


--
-- Name: station_hours_at_idx_454; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_454 ON public.station_hours_454 USING btree (at);


--
-- Name: station_hours_at_idx_455; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_455 ON public.station_hours_455 USING btree (at);


--
-- Name: station_hours_at_idx_459; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_459 ON public.station_hours_459 USING btree (at);


--
-- Name: station_hours_at_idx_460; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_460 ON public.station_hours_460 USING btree (at);


--
-- Name: station_hours_at_idx_461; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_461 ON public.station_hours_461 USING btree (at);


--
-- Name: station_hours_at_idx_462; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_462 ON public.station_hours_462 USING btree (at);


--
-- Name: station_hours_at_idx_463; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_463 ON public.station_hours_463 USING btree (at);


--
-- Name: station_hours_at_idx_464; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_464 ON public.station_hours_464 USING btree (at);


--
-- Name: station_hours_at_idx_465; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_465 ON public.station_hours_465 USING btree (at);


--
-- Name: station_hours_at_idx_466; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_466 ON public.station_hours_466 USING btree (at);


--
-- Name: station_hours_at_idx_467; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_467 ON public.station_hours_467 USING btree (at);


--
-- Name: station_hours_at_idx_469; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_469 ON public.station_hours_469 USING btree (at);


--
-- Name: station_hours_at_idx_470; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_470 ON public.station_hours_470 USING btree (at);


--
-- Name: station_hours_at_idx_473; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_473 ON public.station_hours_473 USING btree (at);


--
-- Name: station_hours_at_idx_474; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_474 ON public.station_hours_474 USING btree (at);


--
-- Name: station_hours_at_idx_500; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_500 ON public.station_hours_500 USING btree (at);


--
-- Name: station_hours_at_idx_501; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_501 ON public.station_hours_501 USING btree (at);


--
-- Name: station_hours_at_idx_502; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_502 ON public.station_hours_502 USING btree (at);


--
-- Name: station_hours_at_idx_503; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_503 ON public.station_hours_503 USING btree (at);


--
-- Name: station_hours_at_idx_504; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_504 ON public.station_hours_504 USING btree (at);


--
-- Name: station_hours_at_idx_505; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_505 ON public.station_hours_505 USING btree (at);


--
-- Name: station_hours_at_idx_514; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_514 ON public.station_hours_514 USING btree (at);


--
-- Name: station_hours_at_idx_530; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_530 ON public.station_hours_530 USING btree (at);


--
-- Name: station_hours_at_idx_533; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_533 ON public.station_hours_533 USING btree (at);


--
-- Name: station_hours_at_idx_537; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_537 ON public.station_hours_537 USING btree (at);


--
-- Name: station_hours_at_idx_539; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_539 ON public.station_hours_539 USING btree (at);


--
-- Name: station_hours_at_idx_553; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_553 ON public.station_hours_553 USING btree (at);


--
-- Name: station_hours_at_idx_556; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_556 ON public.station_hours_556 USING btree (at);


--
-- Name: station_hours_at_idx_561; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_561 ON public.station_hours_561 USING btree (at);


--
-- Name: station_hours_at_idx_565; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_565 ON public.station_hours_565 USING btree (at);


--
-- Name: station_hours_at_idx_575; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_575 ON public.station_hours_575 USING btree (at);


--
-- Name: station_hours_at_idx_577; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_577 ON public.station_hours_577 USING btree (at);


--
-- Name: station_hours_at_idx_578; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_578 ON public.station_hours_578 USING btree (at);


--
-- Name: station_hours_at_idx_594; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_594 ON public.station_hours_594 USING btree (at);


--
-- Name: station_hours_at_idx_595; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_595 ON public.station_hours_595 USING btree (at);


--
-- Name: station_hours_at_idx_597; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_597 ON public.station_hours_597 USING btree (at);


--
-- Name: station_hours_at_idx_601; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_601 ON public.station_hours_601 USING btree (at);


--
-- Name: station_hours_at_idx_602; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_602 ON public.station_hours_602 USING btree (at);


--
-- Name: station_hours_at_idx_603; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_603 ON public.station_hours_603 USING btree (at);


--
-- Name: station_hours_at_idx_604; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_604 ON public.station_hours_604 USING btree (at);


--
-- Name: station_hours_at_idx_605; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_605 ON public.station_hours_605 USING btree (at);


--
-- Name: station_hours_at_idx_606; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_606 ON public.station_hours_606 USING btree (at);


--
-- Name: station_hours_at_idx_607; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_607 ON public.station_hours_607 USING btree (at);


--
-- Name: station_hours_at_idx_608; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_608 ON public.station_hours_608 USING btree (at);


--
-- Name: station_hours_at_idx_609; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_609 ON public.station_hours_609 USING btree (at);


--
-- Name: station_hours_at_idx_610; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_610 ON public.station_hours_610 USING btree (at);


--
-- Name: station_hours_at_idx_611; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_611 ON public.station_hours_611 USING btree (at);


--
-- Name: station_hours_at_idx_615; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_615 ON public.station_hours_615 USING btree (at);


--
-- Name: station_hours_at_idx_616; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_616 ON public.station_hours_616 USING btree (at);


--
-- Name: station_hours_at_idx_617; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_617 ON public.station_hours_617 USING btree (at);


--
-- Name: station_hours_at_idx_618; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_618 ON public.station_hours_618 USING btree (at);


--
-- Name: station_hours_at_idx_619; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_619 ON public.station_hours_619 USING btree (at);


--
-- Name: station_hours_at_idx_620; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_620 ON public.station_hours_620 USING btree (at);


--
-- Name: station_hours_at_idx_622; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_622 ON public.station_hours_622 USING btree (at);


--
-- Name: station_hours_at_idx_624; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_624 ON public.station_hours_624 USING btree (at);


--
-- Name: station_hours_at_idx_625; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_625 ON public.station_hours_625 USING btree (at);


--
-- Name: station_hours_at_idx_628; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_628 ON public.station_hours_628 USING btree (at);


--
-- Name: station_hours_at_idx_631; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_631 ON public.station_hours_631 USING btree (at);


--
-- Name: station_hours_at_idx_632; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_632 ON public.station_hours_632 USING btree (at);


--
-- Name: station_hours_at_idx_633; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_633 ON public.station_hours_633 USING btree (at);


--
-- Name: station_hours_at_idx_636; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_636 ON public.station_hours_636 USING btree (at);


--
-- Name: station_hours_at_idx_99; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx_99 ON public.station_hours_99 USING btree (at);


--
-- Name: station_hours_at_sid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_sid ON public.station_hours USING btree (date_part('epoch'::text, at), sid);


--
-- Name: station_id__submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_id__submitted_at ON public.station_logs USING btree (station_id, submitted_at DESC NULLS LAST);


--
-- Name: station_logs_110_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_110_epoch ON public.station_logs_110 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_110_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_110_submitted_at ON public.station_logs_110 USING btree (submitted_at);


--
-- Name: station_logs_167_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_167_epoch ON public.station_logs_167 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_167_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_167_submitted_at ON public.station_logs_167 USING btree (submitted_at);


--
-- Name: station_logs_245_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_245_epoch ON public.station_logs_245 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_245_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_245_submitted_at ON public.station_logs_245 USING btree (submitted_at);


--
-- Name: station_logs_247_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_247_epoch ON public.station_logs_247 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_247_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_247_submitted_at ON public.station_logs_247 USING btree (submitted_at);


--
-- Name: station_logs_249_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_249_epoch ON public.station_logs_249 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_249_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_249_submitted_at ON public.station_logs_249 USING btree (submitted_at);


--
-- Name: station_logs_259_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_259_epoch ON public.station_logs_259 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_259_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_259_submitted_at ON public.station_logs_259 USING btree (submitted_at);


--
-- Name: station_logs_261_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_261_epoch ON public.station_logs_261 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_261_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_261_submitted_at ON public.station_logs_261 USING btree (submitted_at);


--
-- Name: station_logs_284_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_284_epoch ON public.station_logs_284 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_284_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_284_submitted_at ON public.station_logs_284 USING btree (submitted_at);


--
-- Name: station_logs_285_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_285_epoch ON public.station_logs_285 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_285_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_285_submitted_at ON public.station_logs_285 USING btree (submitted_at);


--
-- Name: station_logs_296_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_296_epoch ON public.station_logs_296 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_296_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_296_submitted_at ON public.station_logs_296 USING btree (submitted_at);


--
-- Name: station_logs_298_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_298_epoch ON public.station_logs_298 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_298_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_298_submitted_at ON public.station_logs_298 USING btree (submitted_at);


--
-- Name: station_logs_307_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_307_epoch ON public.station_logs_307 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_307_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_307_submitted_at ON public.station_logs_307 USING btree (submitted_at);


--
-- Name: station_logs_308_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_308_epoch ON public.station_logs_308 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_308_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_308_submitted_at ON public.station_logs_308 USING btree (submitted_at);


--
-- Name: station_logs_309_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_309_epoch ON public.station_logs_309 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_309_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_309_submitted_at ON public.station_logs_309 USING btree (submitted_at);


--
-- Name: station_logs_310_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_310_epoch ON public.station_logs_310 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_310_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_310_submitted_at ON public.station_logs_310 USING btree (submitted_at);


--
-- Name: station_logs_314_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_314_epoch ON public.station_logs_314 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_314_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_314_submitted_at ON public.station_logs_314 USING btree (submitted_at);


--
-- Name: station_logs_316_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_316_epoch ON public.station_logs_316 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_316_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_316_submitted_at ON public.station_logs_316 USING btree (submitted_at);


--
-- Name: station_logs_317_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_317_epoch ON public.station_logs_317 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_317_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_317_submitted_at ON public.station_logs_317 USING btree (submitted_at);


--
-- Name: station_logs_319_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_319_epoch ON public.station_logs_319 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_319_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_319_submitted_at ON public.station_logs_319 USING btree (submitted_at);


--
-- Name: station_logs_320_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_320_epoch ON public.station_logs_320 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_320_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_320_submitted_at ON public.station_logs_320 USING btree (submitted_at);


--
-- Name: station_logs_323_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_323_epoch ON public.station_logs_323 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_323_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_323_submitted_at ON public.station_logs_323 USING btree (submitted_at);


--
-- Name: station_logs_326_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_326_epoch ON public.station_logs_326 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_326_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_326_submitted_at ON public.station_logs_326 USING btree (submitted_at);


--
-- Name: station_logs_327_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_327_epoch ON public.station_logs_327 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_327_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_327_submitted_at ON public.station_logs_327 USING btree (submitted_at);


--
-- Name: station_logs_329_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_329_epoch ON public.station_logs_329 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_329_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_329_submitted_at ON public.station_logs_329 USING btree (submitted_at);


--
-- Name: station_logs_330_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_330_epoch ON public.station_logs_330 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_330_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_330_submitted_at ON public.station_logs_330 USING btree (submitted_at);


--
-- Name: station_logs_331_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_331_epoch ON public.station_logs_331 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_331_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_331_submitted_at ON public.station_logs_331 USING btree (submitted_at);


--
-- Name: station_logs_333_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_333_epoch ON public.station_logs_333 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_333_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_333_submitted_at ON public.station_logs_333 USING btree (submitted_at);


--
-- Name: station_logs_334_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_334_epoch ON public.station_logs_334 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_334_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_334_submitted_at ON public.station_logs_334 USING btree (submitted_at);


--
-- Name: station_logs_336_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_336_epoch ON public.station_logs_336 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_336_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_336_submitted_at ON public.station_logs_336 USING btree (submitted_at);


--
-- Name: station_logs_337_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_337_epoch ON public.station_logs_337 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_337_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_337_submitted_at ON public.station_logs_337 USING btree (submitted_at);


--
-- Name: station_logs_338_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_338_epoch ON public.station_logs_338 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_338_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_338_submitted_at ON public.station_logs_338 USING btree (submitted_at);


--
-- Name: station_logs_339_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_339_epoch ON public.station_logs_339 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_339_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_339_submitted_at ON public.station_logs_339 USING btree (submitted_at);


--
-- Name: station_logs_343_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_343_epoch ON public.station_logs_343 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_343_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_343_submitted_at ON public.station_logs_343 USING btree (submitted_at);


--
-- Name: station_logs_346_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_346_epoch ON public.station_logs_346 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_346_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_346_submitted_at ON public.station_logs_346 USING btree (submitted_at);


--
-- Name: station_logs_347_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_347_epoch ON public.station_logs_347 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_347_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_347_submitted_at ON public.station_logs_347 USING btree (submitted_at);


--
-- Name: station_logs_348_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_348_epoch ON public.station_logs_348 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_348_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_348_submitted_at ON public.station_logs_348 USING btree (submitted_at);


--
-- Name: station_logs_349_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_349_epoch ON public.station_logs_349 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_349_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_349_submitted_at ON public.station_logs_349 USING btree (submitted_at);


--
-- Name: station_logs_350_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_350_epoch ON public.station_logs_350 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_350_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_350_submitted_at ON public.station_logs_350 USING btree (submitted_at);


--
-- Name: station_logs_351_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_351_epoch ON public.station_logs_351 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_351_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_351_submitted_at ON public.station_logs_351 USING btree (submitted_at);


--
-- Name: station_logs_352_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_352_epoch ON public.station_logs_352 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_352_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_352_submitted_at ON public.station_logs_352 USING btree (submitted_at);


--
-- Name: station_logs_353_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_353_epoch ON public.station_logs_353 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_353_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_353_submitted_at ON public.station_logs_353 USING btree (submitted_at);


--
-- Name: station_logs_354_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_354_epoch ON public.station_logs_354 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_354_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_354_submitted_at ON public.station_logs_354 USING btree (submitted_at);


--
-- Name: station_logs_355_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_355_epoch ON public.station_logs_355 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_355_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_355_submitted_at ON public.station_logs_355 USING btree (submitted_at);


--
-- Name: station_logs_356_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_356_epoch ON public.station_logs_356 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_356_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_356_submitted_at ON public.station_logs_356 USING btree (submitted_at);


--
-- Name: station_logs_357_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_357_epoch ON public.station_logs_357 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_357_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_357_submitted_at ON public.station_logs_357 USING btree (submitted_at);


--
-- Name: station_logs_358_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_358_epoch ON public.station_logs_358 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_358_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_358_submitted_at ON public.station_logs_358 USING btree (submitted_at);


--
-- Name: station_logs_359_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_359_epoch ON public.station_logs_359 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_359_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_359_submitted_at ON public.station_logs_359 USING btree (submitted_at);


--
-- Name: station_logs_360_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_360_epoch ON public.station_logs_360 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_360_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_360_submitted_at ON public.station_logs_360 USING btree (submitted_at);


--
-- Name: station_logs_361_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_361_epoch ON public.station_logs_361 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_361_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_361_submitted_at ON public.station_logs_361 USING btree (submitted_at);


--
-- Name: station_logs_362_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_362_epoch ON public.station_logs_362 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_362_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_362_submitted_at ON public.station_logs_362 USING btree (submitted_at);


--
-- Name: station_logs_363_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_363_epoch ON public.station_logs_363 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_363_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_363_submitted_at ON public.station_logs_363 USING btree (submitted_at);


--
-- Name: station_logs_364_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_364_epoch ON public.station_logs_364 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_364_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_364_submitted_at ON public.station_logs_364 USING btree (submitted_at);


--
-- Name: station_logs_365_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_365_epoch ON public.station_logs_365 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_365_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_365_submitted_at ON public.station_logs_365 USING btree (submitted_at);


--
-- Name: station_logs_370_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_370_epoch ON public.station_logs_370 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_370_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_370_submitted_at ON public.station_logs_370 USING btree (submitted_at);


--
-- Name: station_logs_371_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_371_epoch ON public.station_logs_371 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_371_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_371_submitted_at ON public.station_logs_371 USING btree (submitted_at);


--
-- Name: station_logs_372_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_372_epoch ON public.station_logs_372 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_372_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_372_submitted_at ON public.station_logs_372 USING btree (submitted_at);


--
-- Name: station_logs_373_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_373_epoch ON public.station_logs_373 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_373_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_373_submitted_at ON public.station_logs_373 USING btree (submitted_at);


--
-- Name: station_logs_374_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_374_epoch ON public.station_logs_374 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_374_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_374_submitted_at ON public.station_logs_374 USING btree (submitted_at);


--
-- Name: station_logs_375_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_375_epoch ON public.station_logs_375 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_375_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_375_submitted_at ON public.station_logs_375 USING btree (submitted_at);


--
-- Name: station_logs_376_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_376_epoch ON public.station_logs_376 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_376_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_376_submitted_at ON public.station_logs_376 USING btree (submitted_at);


--
-- Name: station_logs_377_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_377_epoch ON public.station_logs_377 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_377_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_377_submitted_at ON public.station_logs_377 USING btree (submitted_at);


--
-- Name: station_logs_378_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_378_epoch ON public.station_logs_378 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_378_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_378_submitted_at ON public.station_logs_378 USING btree (submitted_at);


--
-- Name: station_logs_379_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_379_epoch ON public.station_logs_379 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_379_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_379_submitted_at ON public.station_logs_379 USING btree (submitted_at);


--
-- Name: station_logs_380_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_380_epoch ON public.station_logs_380 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_380_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_380_submitted_at ON public.station_logs_380 USING btree (submitted_at);


--
-- Name: station_logs_382_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_382_epoch ON public.station_logs_382 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_382_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_382_submitted_at ON public.station_logs_382 USING btree (submitted_at);


--
-- Name: station_logs_383_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_383_epoch ON public.station_logs_383 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_383_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_383_submitted_at ON public.station_logs_383 USING btree (submitted_at);


--
-- Name: station_logs_385_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_385_epoch ON public.station_logs_385 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_385_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_385_submitted_at ON public.station_logs_385 USING btree (submitted_at);


--
-- Name: station_logs_387_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_387_epoch ON public.station_logs_387 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_387_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_387_submitted_at ON public.station_logs_387 USING btree (submitted_at);


--
-- Name: station_logs_389_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_389_epoch ON public.station_logs_389 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_389_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_389_submitted_at ON public.station_logs_389 USING btree (submitted_at);


--
-- Name: station_logs_390_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_390_epoch ON public.station_logs_390 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_390_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_390_submitted_at ON public.station_logs_390 USING btree (submitted_at);


--
-- Name: station_logs_391_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_391_epoch ON public.station_logs_391 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_391_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_391_submitted_at ON public.station_logs_391 USING btree (submitted_at);


--
-- Name: station_logs_392_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_392_epoch ON public.station_logs_392 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_392_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_392_submitted_at ON public.station_logs_392 USING btree (submitted_at);


--
-- Name: station_logs_395_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_395_epoch ON public.station_logs_395 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_395_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_395_submitted_at ON public.station_logs_395 USING btree (submitted_at);


--
-- Name: station_logs_396_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_396_epoch ON public.station_logs_396 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_396_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_396_submitted_at ON public.station_logs_396 USING btree (submitted_at);


--
-- Name: station_logs_397_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_397_epoch ON public.station_logs_397 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_397_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_397_submitted_at ON public.station_logs_397 USING btree (submitted_at);


--
-- Name: station_logs_398_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_398_epoch ON public.station_logs_398 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_398_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_398_submitted_at ON public.station_logs_398 USING btree (submitted_at);


--
-- Name: station_logs_399_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_399_epoch ON public.station_logs_399 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_399_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_399_submitted_at ON public.station_logs_399 USING btree (submitted_at);


--
-- Name: station_logs_400_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_400_epoch ON public.station_logs_400 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_400_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_400_submitted_at ON public.station_logs_400 USING btree (submitted_at);


--
-- Name: station_logs_403_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_403_epoch ON public.station_logs_403 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_403_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_403_submitted_at ON public.station_logs_403 USING btree (submitted_at);


--
-- Name: station_logs_404_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_404_epoch ON public.station_logs_404 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_404_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_404_submitted_at ON public.station_logs_404 USING btree (submitted_at);


--
-- Name: station_logs_405_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_405_epoch ON public.station_logs_405 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_405_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_405_submitted_at ON public.station_logs_405 USING btree (submitted_at);


--
-- Name: station_logs_406_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_406_epoch ON public.station_logs_406 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_406_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_406_submitted_at ON public.station_logs_406 USING btree (submitted_at);


--
-- Name: station_logs_407_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_407_epoch ON public.station_logs_407 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_407_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_407_submitted_at ON public.station_logs_407 USING btree (submitted_at);


--
-- Name: station_logs_409_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_409_epoch ON public.station_logs_409 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_409_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_409_submitted_at ON public.station_logs_409 USING btree (submitted_at);


--
-- Name: station_logs_410_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_410_epoch ON public.station_logs_410 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_410_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_410_submitted_at ON public.station_logs_410 USING btree (submitted_at);


--
-- Name: station_logs_411_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_411_epoch ON public.station_logs_411 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_411_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_411_submitted_at ON public.station_logs_411 USING btree (submitted_at);


--
-- Name: station_logs_412_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_412_epoch ON public.station_logs_412 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_412_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_412_submitted_at ON public.station_logs_412 USING btree (submitted_at);


--
-- Name: station_logs_413_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_413_epoch ON public.station_logs_413 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_413_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_413_submitted_at ON public.station_logs_413 USING btree (submitted_at);


--
-- Name: station_logs_414_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_414_epoch ON public.station_logs_414 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_414_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_414_submitted_at ON public.station_logs_414 USING btree (submitted_at);


--
-- Name: station_logs_415_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_415_epoch ON public.station_logs_415 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_415_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_415_submitted_at ON public.station_logs_415 USING btree (submitted_at);


--
-- Name: station_logs_417_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_417_epoch ON public.station_logs_417 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_417_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_417_submitted_at ON public.station_logs_417 USING btree (submitted_at);


--
-- Name: station_logs_418_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_418_epoch ON public.station_logs_418 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_418_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_418_submitted_at ON public.station_logs_418 USING btree (submitted_at);


--
-- Name: station_logs_419_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_419_epoch ON public.station_logs_419 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_419_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_419_submitted_at ON public.station_logs_419 USING btree (submitted_at);


--
-- Name: station_logs_420_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_420_epoch ON public.station_logs_420 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_420_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_420_submitted_at ON public.station_logs_420 USING btree (submitted_at);


--
-- Name: station_logs_422_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_422_epoch ON public.station_logs_422 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_422_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_422_submitted_at ON public.station_logs_422 USING btree (submitted_at);


--
-- Name: station_logs_423_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_423_epoch ON public.station_logs_423 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_423_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_423_submitted_at ON public.station_logs_423 USING btree (submitted_at);


--
-- Name: station_logs_425_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_425_epoch ON public.station_logs_425 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_425_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_425_submitted_at ON public.station_logs_425 USING btree (submitted_at);


--
-- Name: station_logs_428_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_428_epoch ON public.station_logs_428 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_428_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_428_submitted_at ON public.station_logs_428 USING btree (submitted_at);


--
-- Name: station_logs_429_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_429_epoch ON public.station_logs_429 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_429_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_429_submitted_at ON public.station_logs_429 USING btree (submitted_at);


--
-- Name: station_logs_430_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_430_epoch ON public.station_logs_430 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_430_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_430_submitted_at ON public.station_logs_430 USING btree (submitted_at);


--
-- Name: station_logs_433_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_433_epoch ON public.station_logs_433 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_433_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_433_submitted_at ON public.station_logs_433 USING btree (submitted_at);


--
-- Name: station_logs_434_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_434_epoch ON public.station_logs_434 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_434_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_434_submitted_at ON public.station_logs_434 USING btree (submitted_at);


--
-- Name: station_logs_435_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_435_epoch ON public.station_logs_435 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_435_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_435_submitted_at ON public.station_logs_435 USING btree (submitted_at);


--
-- Name: station_logs_436_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_436_epoch ON public.station_logs_436 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_436_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_436_submitted_at ON public.station_logs_436 USING btree (submitted_at);


--
-- Name: station_logs_437_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_437_epoch ON public.station_logs_437 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_437_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_437_submitted_at ON public.station_logs_437 USING btree (submitted_at);


--
-- Name: station_logs_443_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_443_epoch ON public.station_logs_443 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_443_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_443_submitted_at ON public.station_logs_443 USING btree (submitted_at);


--
-- Name: station_logs_447_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_447_epoch ON public.station_logs_447 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_447_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_447_submitted_at ON public.station_logs_447 USING btree (submitted_at);


--
-- Name: station_logs_451_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_451_epoch ON public.station_logs_451 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_451_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_451_submitted_at ON public.station_logs_451 USING btree (submitted_at);


--
-- Name: station_logs_452_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_452_epoch ON public.station_logs_452 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_452_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_452_submitted_at ON public.station_logs_452 USING btree (submitted_at);


--
-- Name: station_logs_453_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_453_epoch ON public.station_logs_453 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_453_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_453_submitted_at ON public.station_logs_453 USING btree (submitted_at);


--
-- Name: station_logs_454_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_454_epoch ON public.station_logs_454 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_454_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_454_submitted_at ON public.station_logs_454 USING btree (submitted_at);


--
-- Name: station_logs_455_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_455_epoch ON public.station_logs_455 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_455_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_455_submitted_at ON public.station_logs_455 USING btree (submitted_at);


--
-- Name: station_logs_459_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_459_epoch ON public.station_logs_459 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_459_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_459_submitted_at ON public.station_logs_459 USING btree (submitted_at);


--
-- Name: station_logs_460_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_460_epoch ON public.station_logs_460 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_460_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_460_submitted_at ON public.station_logs_460 USING btree (submitted_at);


--
-- Name: station_logs_462_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_462_epoch ON public.station_logs_462 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_462_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_462_submitted_at ON public.station_logs_462 USING btree (submitted_at);


--
-- Name: station_logs_463_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_463_epoch ON public.station_logs_463 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_463_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_463_submitted_at ON public.station_logs_463 USING btree (submitted_at);


--
-- Name: station_logs_464_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_464_epoch ON public.station_logs_464 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_464_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_464_submitted_at ON public.station_logs_464 USING btree (submitted_at);


--
-- Name: station_logs_465_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_465_epoch ON public.station_logs_465 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_465_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_465_submitted_at ON public.station_logs_465 USING btree (submitted_at);


--
-- Name: station_logs_466_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_466_epoch ON public.station_logs_466 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_466_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_466_submitted_at ON public.station_logs_466 USING btree (submitted_at);


--
-- Name: station_logs_467_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_467_epoch ON public.station_logs_467 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_467_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_467_submitted_at ON public.station_logs_467 USING btree (submitted_at);


--
-- Name: station_logs_469_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_469_epoch ON public.station_logs_469 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_469_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_469_submitted_at ON public.station_logs_469 USING btree (submitted_at);


--
-- Name: station_logs_470_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_470_epoch ON public.station_logs_470 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_470_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_470_submitted_at ON public.station_logs_470 USING btree (submitted_at);


--
-- Name: station_logs_473_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_473_epoch ON public.station_logs_473 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_473_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_473_submitted_at ON public.station_logs_473 USING btree (submitted_at);


--
-- Name: station_logs_474_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_474_epoch ON public.station_logs_474 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_474_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_474_submitted_at ON public.station_logs_474 USING btree (submitted_at);


--
-- Name: station_logs_500_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_500_epoch ON public.station_logs_500 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_500_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_500_submitted_at ON public.station_logs_500 USING btree (submitted_at);


--
-- Name: station_logs_501_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_501_epoch ON public.station_logs_501 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_501_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_501_submitted_at ON public.station_logs_501 USING btree (submitted_at);


--
-- Name: station_logs_502_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_502_epoch ON public.station_logs_502 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_502_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_502_submitted_at ON public.station_logs_502 USING btree (submitted_at);


--
-- Name: station_logs_503_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_503_epoch ON public.station_logs_503 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_503_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_503_submitted_at ON public.station_logs_503 USING btree (submitted_at);


--
-- Name: station_logs_504_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_504_epoch ON public.station_logs_504 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_504_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_504_submitted_at ON public.station_logs_504 USING btree (submitted_at);


--
-- Name: station_logs_505_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_505_epoch ON public.station_logs_505 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_505_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_505_submitted_at ON public.station_logs_505 USING btree (submitted_at);


--
-- Name: station_logs_514_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_514_epoch ON public.station_logs_514 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_514_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_514_submitted_at ON public.station_logs_514 USING btree (submitted_at);


--
-- Name: station_logs_530_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_530_epoch ON public.station_logs_530 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_530_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_530_submitted_at ON public.station_logs_530 USING btree (submitted_at);


--
-- Name: station_logs_533_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_533_epoch ON public.station_logs_533 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_533_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_533_submitted_at ON public.station_logs_533 USING btree (submitted_at);


--
-- Name: station_logs_537_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_537_epoch ON public.station_logs_537 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_537_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_537_submitted_at ON public.station_logs_537 USING btree (submitted_at);


--
-- Name: station_logs_539_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_539_epoch ON public.station_logs_539 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_539_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_539_submitted_at ON public.station_logs_539 USING btree (submitted_at);


--
-- Name: station_logs_553_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_553_epoch ON public.station_logs_553 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_553_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_553_submitted_at ON public.station_logs_553 USING btree (submitted_at);


--
-- Name: station_logs_556_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_556_epoch ON public.station_logs_556 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_556_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_556_submitted_at ON public.station_logs_556 USING btree (submitted_at);


--
-- Name: station_logs_561_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_561_epoch ON public.station_logs_561 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_561_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_561_submitted_at ON public.station_logs_561 USING btree (submitted_at);


--
-- Name: station_logs_565_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_565_epoch ON public.station_logs_565 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_565_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_565_submitted_at ON public.station_logs_565 USING btree (submitted_at);


--
-- Name: station_logs_575_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_575_epoch ON public.station_logs_575 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_575_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_575_submitted_at ON public.station_logs_575 USING btree (submitted_at);


--
-- Name: station_logs_577_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_577_epoch ON public.station_logs_577 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_577_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_577_submitted_at ON public.station_logs_577 USING btree (submitted_at);


--
-- Name: station_logs_578_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_578_epoch ON public.station_logs_578 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_578_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_578_submitted_at ON public.station_logs_578 USING btree (submitted_at);


--
-- Name: station_logs_594_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_594_epoch ON public.station_logs_594 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_594_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_594_submitted_at ON public.station_logs_594 USING btree (submitted_at);


--
-- Name: station_logs_595_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_595_epoch ON public.station_logs_595 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_595_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_595_submitted_at ON public.station_logs_595 USING btree (submitted_at);


--
-- Name: station_logs_597_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_597_epoch ON public.station_logs_597 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_597_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_597_submitted_at ON public.station_logs_597 USING btree (submitted_at);


--
-- Name: station_logs_601_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_601_epoch ON public.station_logs_601 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_601_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_601_submitted_at ON public.station_logs_601 USING btree (submitted_at);


--
-- Name: station_logs_602_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_602_epoch ON public.station_logs_602 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_602_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_602_submitted_at ON public.station_logs_602 USING btree (submitted_at);


--
-- Name: station_logs_603_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_603_epoch ON public.station_logs_603 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_603_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_603_submitted_at ON public.station_logs_603 USING btree (submitted_at);


--
-- Name: station_logs_604_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_604_epoch ON public.station_logs_604 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_604_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_604_submitted_at ON public.station_logs_604 USING btree (submitted_at);


--
-- Name: station_logs_605_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_605_epoch ON public.station_logs_605 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_605_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_605_submitted_at ON public.station_logs_605 USING btree (submitted_at);


--
-- Name: station_logs_606_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_606_epoch ON public.station_logs_606 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_606_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_606_submitted_at ON public.station_logs_606 USING btree (submitted_at);


--
-- Name: station_logs_607_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_607_epoch ON public.station_logs_607 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_607_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_607_submitted_at ON public.station_logs_607 USING btree (submitted_at);


--
-- Name: station_logs_608_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_608_epoch ON public.station_logs_608 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_608_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_608_submitted_at ON public.station_logs_608 USING btree (submitted_at);


--
-- Name: station_logs_609_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_609_epoch ON public.station_logs_609 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_609_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_609_submitted_at ON public.station_logs_609 USING btree (submitted_at);


--
-- Name: station_logs_610_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_610_epoch ON public.station_logs_610 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_610_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_610_submitted_at ON public.station_logs_610 USING btree (submitted_at);


--
-- Name: station_logs_611_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_611_epoch ON public.station_logs_611 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_611_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_611_submitted_at ON public.station_logs_611 USING btree (submitted_at);


--
-- Name: station_logs_615_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_615_epoch ON public.station_logs_615 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_615_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_615_submitted_at ON public.station_logs_615 USING btree (submitted_at);


--
-- Name: station_logs_616_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_616_epoch ON public.station_logs_616 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_616_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_616_submitted_at ON public.station_logs_616 USING btree (submitted_at);


--
-- Name: station_logs_617_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_617_epoch ON public.station_logs_617 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_617_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_617_submitted_at ON public.station_logs_617 USING btree (submitted_at);


--
-- Name: station_logs_618_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_618_epoch ON public.station_logs_618 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_618_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_618_submitted_at ON public.station_logs_618 USING btree (submitted_at);


--
-- Name: station_logs_619_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_619_epoch ON public.station_logs_619 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_619_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_619_submitted_at ON public.station_logs_619 USING btree (submitted_at);


--
-- Name: station_logs_620_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_620_epoch ON public.station_logs_620 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_620_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_620_submitted_at ON public.station_logs_620 USING btree (submitted_at);


--
-- Name: station_logs_622_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_622_epoch ON public.station_logs_622 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_622_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_622_submitted_at ON public.station_logs_622 USING btree (submitted_at);


--
-- Name: station_logs_624_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_624_epoch ON public.station_logs_624 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_624_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_624_submitted_at ON public.station_logs_624 USING btree (submitted_at);


--
-- Name: station_logs_625_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_625_epoch ON public.station_logs_625 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_625_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_625_submitted_at ON public.station_logs_625 USING btree (submitted_at);


--
-- Name: station_logs_626_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_626_epoch ON public.station_logs_626 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_626_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_626_submitted_at ON public.station_logs_626 USING btree (submitted_at);


--
-- Name: station_logs_627_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_627_epoch ON public.station_logs_627 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_627_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_627_submitted_at ON public.station_logs_627 USING btree (submitted_at);


--
-- Name: station_logs_628_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_628_epoch ON public.station_logs_628 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_628_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_628_submitted_at ON public.station_logs_628 USING btree (submitted_at);


--
-- Name: station_logs_631_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_631_epoch ON public.station_logs_631 USING btree (EXTRACT(epoch FROM submitted_at));


--
-- Name: station_logs_631_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_631_submitted_at ON public.station_logs_631 USING btree (submitted_at);


--
-- Name: station_logs_632_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_632_epoch ON public.station_logs_632 USING btree (EXTRACT(epoch FROM submitted_at));


--
-- Name: station_logs_632_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_632_submitted_at ON public.station_logs_632 USING btree (submitted_at);


--
-- Name: station_logs_633_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_633_epoch ON public.station_logs_633 USING btree (EXTRACT(epoch FROM submitted_at));


--
-- Name: station_logs_633_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_633_submitted_at ON public.station_logs_633 USING btree (submitted_at);


--
-- Name: station_logs_636_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_636_epoch ON public.station_logs_636 USING btree (EXTRACT(epoch FROM submitted_at));


--
-- Name: station_logs_636_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_636_submitted_at ON public.station_logs_636 USING btree (submitted_at);


--
-- Name: station_logs_645_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_645_epoch ON public.station_logs_645 USING btree (EXTRACT(epoch FROM submitted_at));


--
-- Name: station_logs_645_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_645_submitted_at ON public.station_logs_645 USING btree (submitted_at);


--
-- Name: station_logs_99_epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_99_epoch ON public.station_logs_99 USING btree (date_part('epoch'::text, submitted_at));


--
-- Name: station_logs_99_submitted_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs_99_submitted_at ON public.station_logs_99 USING btree (submitted_at);


--
-- Name: station_logs__sta_id__epoch; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs__sta_id__epoch ON public.station_logs USING btree (station_id, date_part('epoch'::text, submitted_at));

ALTER TABLE public.station_logs CLUSTER ON station_logs__sta_id__epoch;


--
-- Name: station_logs__sta_id__submit_date; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_logs__sta_id__submit_date ON public.station_logs USING btree (station_id, date_trunc('day'::text, submitted_at));


--
-- Name: station_minutes_at_idx_110; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_110 ON public.station_minutes_110 USING btree (at);


--
-- Name: station_minutes_at_idx_167; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_167 ON public.station_minutes_167 USING btree (at);


--
-- Name: station_minutes_at_idx_245; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_245 ON public.station_minutes_245 USING btree (at);


--
-- Name: station_minutes_at_idx_247; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_247 ON public.station_minutes_247 USING btree (at);


--
-- Name: station_minutes_at_idx_249; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_249 ON public.station_minutes_249 USING btree (at);


--
-- Name: station_minutes_at_idx_259; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_259 ON public.station_minutes_259 USING btree (at);


--
-- Name: station_minutes_at_idx_261; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_261 ON public.station_minutes_261 USING btree (at);


--
-- Name: station_minutes_at_idx_284; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_284 ON public.station_minutes_284 USING btree (at);


--
-- Name: station_minutes_at_idx_285; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_285 ON public.station_minutes_285 USING btree (at);


--
-- Name: station_minutes_at_idx_296; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_296 ON public.station_minutes_296 USING btree (at);


--
-- Name: station_minutes_at_idx_298; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_298 ON public.station_minutes_298 USING btree (at);


--
-- Name: station_minutes_at_idx_3001; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_3001 ON public.station_minutes_3001 USING btree (at);


--
-- Name: station_minutes_at_idx_307; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_307 ON public.station_minutes_307 USING btree (at);


--
-- Name: station_minutes_at_idx_308; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_308 ON public.station_minutes_308 USING btree (at);


--
-- Name: station_minutes_at_idx_309; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_309 ON public.station_minutes_309 USING btree (at);


--
-- Name: station_minutes_at_idx_310; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_310 ON public.station_minutes_310 USING btree (at);


--
-- Name: station_minutes_at_idx_314; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_314 ON public.station_minutes_314 USING btree (at);


--
-- Name: station_minutes_at_idx_316; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_316 ON public.station_minutes_316 USING btree (at);


--
-- Name: station_minutes_at_idx_317; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_317 ON public.station_minutes_317 USING btree (at);


--
-- Name: station_minutes_at_idx_319; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_319 ON public.station_minutes_319 USING btree (at);


--
-- Name: station_minutes_at_idx_320; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_320 ON public.station_minutes_320 USING btree (at);


--
-- Name: station_minutes_at_idx_323; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_323 ON public.station_minutes_323 USING btree (at);


--
-- Name: station_minutes_at_idx_326; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_326 ON public.station_minutes_326 USING btree (at);


--
-- Name: station_minutes_at_idx_327; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_327 ON public.station_minutes_327 USING btree (at);


--
-- Name: station_minutes_at_idx_329; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_329 ON public.station_minutes_329 USING btree (at);


--
-- Name: station_minutes_at_idx_330; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_330 ON public.station_minutes_330 USING btree (at);


--
-- Name: station_minutes_at_idx_331; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_331 ON public.station_minutes_331 USING btree (at);


--
-- Name: station_minutes_at_idx_333; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_333 ON public.station_minutes_333 USING btree (at);


--
-- Name: station_minutes_at_idx_334; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_334 ON public.station_minutes_334 USING btree (at);


--
-- Name: station_minutes_at_idx_336; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_336 ON public.station_minutes_336 USING btree (at);


--
-- Name: station_minutes_at_idx_337; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_337 ON public.station_minutes_337 USING btree (at);


--
-- Name: station_minutes_at_idx_338; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_338 ON public.station_minutes_338 USING btree (at);


--
-- Name: station_minutes_at_idx_339; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_339 ON public.station_minutes_339 USING btree (at);


--
-- Name: station_minutes_at_idx_343; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_343 ON public.station_minutes_343 USING btree (at);


--
-- Name: station_minutes_at_idx_346; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_346 ON public.station_minutes_346 USING btree (at);


--
-- Name: station_minutes_at_idx_347; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_347 ON public.station_minutes_347 USING btree (at);


--
-- Name: station_minutes_at_idx_348; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_348 ON public.station_minutes_348 USING btree (at);


--
-- Name: station_minutes_at_idx_349; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_349 ON public.station_minutes_349 USING btree (at);


--
-- Name: station_minutes_at_idx_350; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_350 ON public.station_minutes_350 USING btree (at);


--
-- Name: station_minutes_at_idx_351; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_351 ON public.station_minutes_351 USING btree (at);


--
-- Name: station_minutes_at_idx_352; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_352 ON public.station_minutes_352 USING btree (at);


--
-- Name: station_minutes_at_idx_353; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_353 ON public.station_minutes_353 USING btree (at);


--
-- Name: station_minutes_at_idx_354; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_354 ON public.station_minutes_354 USING btree (at);


--
-- Name: station_minutes_at_idx_355; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_355 ON public.station_minutes_355 USING btree (at);


--
-- Name: station_minutes_at_idx_356; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_356 ON public.station_minutes_356 USING btree (at);


--
-- Name: station_minutes_at_idx_357; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_357 ON public.station_minutes_357 USING btree (at);


--
-- Name: station_minutes_at_idx_358; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_358 ON public.station_minutes_358 USING btree (at);


--
-- Name: station_minutes_at_idx_359; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_359 ON public.station_minutes_359 USING btree (at);


--
-- Name: station_minutes_at_idx_360; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_360 ON public.station_minutes_360 USING btree (at);


--
-- Name: station_minutes_at_idx_361; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_361 ON public.station_minutes_361 USING btree (at);


--
-- Name: station_minutes_at_idx_362; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_362 ON public.station_minutes_362 USING btree (at);


--
-- Name: station_minutes_at_idx_363; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_363 ON public.station_minutes_363 USING btree (at);


--
-- Name: station_minutes_at_idx_364; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_364 ON public.station_minutes_364 USING btree (at);


--
-- Name: station_minutes_at_idx_365; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_365 ON public.station_minutes_365 USING btree (at);


--
-- Name: station_minutes_at_idx_370; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_370 ON public.station_minutes_370 USING btree (at);


--
-- Name: station_minutes_at_idx_371; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_371 ON public.station_minutes_371 USING btree (at);


--
-- Name: station_minutes_at_idx_372; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_372 ON public.station_minutes_372 USING btree (at);


--
-- Name: station_minutes_at_idx_373; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_373 ON public.station_minutes_373 USING btree (at);


--
-- Name: station_minutes_at_idx_374; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_374 ON public.station_minutes_374 USING btree (at);


--
-- Name: station_minutes_at_idx_375; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_375 ON public.station_minutes_375 USING btree (at);


--
-- Name: station_minutes_at_idx_376; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_376 ON public.station_minutes_376 USING btree (at);


--
-- Name: station_minutes_at_idx_377; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_377 ON public.station_minutes_377 USING btree (at);


--
-- Name: station_minutes_at_idx_378; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_378 ON public.station_minutes_378 USING btree (at);


--
-- Name: station_minutes_at_idx_379; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_379 ON public.station_minutes_379 USING btree (at);


--
-- Name: station_minutes_at_idx_380; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_380 ON public.station_minutes_380 USING btree (at);


--
-- Name: station_minutes_at_idx_382; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_382 ON public.station_minutes_382 USING btree (at);


--
-- Name: station_minutes_at_idx_383; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_383 ON public.station_minutes_383 USING btree (at);


--
-- Name: station_minutes_at_idx_385; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_385 ON public.station_minutes_385 USING btree (at);


--
-- Name: station_minutes_at_idx_387; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_387 ON public.station_minutes_387 USING btree (at);


--
-- Name: station_minutes_at_idx_389; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_389 ON public.station_minutes_389 USING btree (at);


--
-- Name: station_minutes_at_idx_390; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_390 ON public.station_minutes_390 USING btree (at);


--
-- Name: station_minutes_at_idx_391; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_391 ON public.station_minutes_391 USING btree (at);


--
-- Name: station_minutes_at_idx_392; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_392 ON public.station_minutes_392 USING btree (at);


--
-- Name: station_minutes_at_idx_395; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_395 ON public.station_minutes_395 USING btree (at);


--
-- Name: station_minutes_at_idx_396; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_396 ON public.station_minutes_396 USING btree (at);


--
-- Name: station_minutes_at_idx_397; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_397 ON public.station_minutes_397 USING btree (at);


--
-- Name: station_minutes_at_idx_398; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_398 ON public.station_minutes_398 USING btree (at);


--
-- Name: station_minutes_at_idx_399; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_399 ON public.station_minutes_399 USING btree (at);


--
-- Name: station_minutes_at_idx_400; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_400 ON public.station_minutes_400 USING btree (at);


--
-- Name: station_minutes_at_idx_403; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_403 ON public.station_minutes_403 USING btree (at);


--
-- Name: station_minutes_at_idx_404; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_404 ON public.station_minutes_404 USING btree (at);


--
-- Name: station_minutes_at_idx_405; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_405 ON public.station_minutes_405 USING btree (at);


--
-- Name: station_minutes_at_idx_406; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_406 ON public.station_minutes_406 USING btree (at);


--
-- Name: station_minutes_at_idx_407; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_407 ON public.station_minutes_407 USING btree (at);


--
-- Name: station_minutes_at_idx_409; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_409 ON public.station_minutes_409 USING btree (at);


--
-- Name: station_minutes_at_idx_410; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_410 ON public.station_minutes_410 USING btree (at);


--
-- Name: station_minutes_at_idx_411; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_411 ON public.station_minutes_411 USING btree (at);


--
-- Name: station_minutes_at_idx_412; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_412 ON public.station_minutes_412 USING btree (at);


--
-- Name: station_minutes_at_idx_413; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_413 ON public.station_minutes_413 USING btree (at);


--
-- Name: station_minutes_at_idx_414; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_414 ON public.station_minutes_414 USING btree (at);


--
-- Name: station_minutes_at_idx_415; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_415 ON public.station_minutes_415 USING btree (at);


--
-- Name: station_minutes_at_idx_417; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_417 ON public.station_minutes_417 USING btree (at);


--
-- Name: station_minutes_at_idx_418; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_418 ON public.station_minutes_418 USING btree (at);


--
-- Name: station_minutes_at_idx_419; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_419 ON public.station_minutes_419 USING btree (at);


--
-- Name: station_minutes_at_idx_420; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_420 ON public.station_minutes_420 USING btree (at);


--
-- Name: station_minutes_at_idx_422; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_422 ON public.station_minutes_422 USING btree (at);


--
-- Name: station_minutes_at_idx_423; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_423 ON public.station_minutes_423 USING btree (at);


--
-- Name: station_minutes_at_idx_425; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_425 ON public.station_minutes_425 USING btree (at);


--
-- Name: station_minutes_at_idx_428; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_428 ON public.station_minutes_428 USING btree (at);


--
-- Name: station_minutes_at_idx_429; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_429 ON public.station_minutes_429 USING btree (at);


--
-- Name: station_minutes_at_idx_430; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_430 ON public.station_minutes_430 USING btree (at);


--
-- Name: station_minutes_at_idx_433; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_433 ON public.station_minutes_433 USING btree (at);


--
-- Name: station_minutes_at_idx_434; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_434 ON public.station_minutes_434 USING btree (at);


--
-- Name: station_minutes_at_idx_435; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_435 ON public.station_minutes_435 USING btree (at);


--
-- Name: station_minutes_at_idx_436; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_436 ON public.station_minutes_436 USING btree (at);


--
-- Name: station_minutes_at_idx_437; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_437 ON public.station_minutes_437 USING btree (at);


--
-- Name: station_minutes_at_idx_443; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_443 ON public.station_minutes_443 USING btree (at);


--
-- Name: station_minutes_at_idx_447; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_447 ON public.station_minutes_447 USING btree (at);


--
-- Name: station_minutes_at_idx_451; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_451 ON public.station_minutes_451 USING btree (at);


--
-- Name: station_minutes_at_idx_452; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_452 ON public.station_minutes_452 USING btree (at);


--
-- Name: station_minutes_at_idx_453; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_453 ON public.station_minutes_453 USING btree (at);


--
-- Name: station_minutes_at_idx_454; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_454 ON public.station_minutes_454 USING btree (at);


--
-- Name: station_minutes_at_idx_455; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_455 ON public.station_minutes_455 USING btree (at);


--
-- Name: station_minutes_at_idx_459; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_459 ON public.station_minutes_459 USING btree (at);


--
-- Name: station_minutes_at_idx_460; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_460 ON public.station_minutes_460 USING btree (at);


--
-- Name: station_minutes_at_idx_461; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_461 ON public.station_minutes_461 USING btree (at);


--
-- Name: station_minutes_at_idx_462; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_462 ON public.station_minutes_462 USING btree (at);


--
-- Name: station_minutes_at_idx_463; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_463 ON public.station_minutes_463 USING btree (at);


--
-- Name: station_minutes_at_idx_464; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_464 ON public.station_minutes_464 USING btree (at);


--
-- Name: station_minutes_at_idx_465; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_465 ON public.station_minutes_465 USING btree (at);


--
-- Name: station_minutes_at_idx_466; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_466 ON public.station_minutes_466 USING btree (at);


--
-- Name: station_minutes_at_idx_467; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_467 ON public.station_minutes_467 USING btree (at);


--
-- Name: station_minutes_at_idx_469; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_469 ON public.station_minutes_469 USING btree (at);


--
-- Name: station_minutes_at_idx_470; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_470 ON public.station_minutes_470 USING btree (at);


--
-- Name: station_minutes_at_idx_473; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_473 ON public.station_minutes_473 USING btree (at);


--
-- Name: station_minutes_at_idx_474; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_474 ON public.station_minutes_474 USING btree (at);


--
-- Name: station_minutes_at_idx_500; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_500 ON public.station_minutes_500 USING btree (at);


--
-- Name: station_minutes_at_idx_501; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_501 ON public.station_minutes_501 USING btree (at);


--
-- Name: station_minutes_at_idx_502; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_502 ON public.station_minutes_502 USING btree (at);


--
-- Name: station_minutes_at_idx_503; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_503 ON public.station_minutes_503 USING btree (at);


--
-- Name: station_minutes_at_idx_504; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_504 ON public.station_minutes_504 USING btree (at);


--
-- Name: station_minutes_at_idx_505; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_505 ON public.station_minutes_505 USING btree (at);


--
-- Name: station_minutes_at_idx_514; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_514 ON public.station_minutes_514 USING btree (at);


--
-- Name: station_minutes_at_idx_530; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_530 ON public.station_minutes_530 USING btree (at);


--
-- Name: station_minutes_at_idx_533; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_533 ON public.station_minutes_533 USING btree (at);


--
-- Name: station_minutes_at_idx_537; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_537 ON public.station_minutes_537 USING btree (at);


--
-- Name: station_minutes_at_idx_539; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_539 ON public.station_minutes_539 USING btree (at);


--
-- Name: station_minutes_at_idx_553; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_553 ON public.station_minutes_553 USING btree (at);


--
-- Name: station_minutes_at_idx_556; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_556 ON public.station_minutes_556 USING btree (at);


--
-- Name: station_minutes_at_idx_561; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_561 ON public.station_minutes_561 USING btree (at);


--
-- Name: station_minutes_at_idx_565; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_565 ON public.station_minutes_565 USING btree (at);


--
-- Name: station_minutes_at_idx_575; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_575 ON public.station_minutes_575 USING btree (at);


--
-- Name: station_minutes_at_idx_577; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_577 ON public.station_minutes_577 USING btree (at);


--
-- Name: station_minutes_at_idx_578; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_578 ON public.station_minutes_578 USING btree (at);


--
-- Name: station_minutes_at_idx_594; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_594 ON public.station_minutes_594 USING btree (at);


--
-- Name: station_minutes_at_idx_595; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_595 ON public.station_minutes_595 USING btree (at);


--
-- Name: station_minutes_at_idx_597; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_597 ON public.station_minutes_597 USING btree (at);


--
-- Name: station_minutes_at_idx_601; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_601 ON public.station_minutes_601 USING btree (at);


--
-- Name: station_minutes_at_idx_602; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_602 ON public.station_minutes_602 USING btree (at);


--
-- Name: station_minutes_at_idx_603; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_603 ON public.station_minutes_603 USING btree (at);


--
-- Name: station_minutes_at_idx_604; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_604 ON public.station_minutes_604 USING btree (at);


--
-- Name: station_minutes_at_idx_605; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_605 ON public.station_minutes_605 USING btree (at);


--
-- Name: station_minutes_at_idx_606; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_606 ON public.station_minutes_606 USING btree (at);


--
-- Name: station_minutes_at_idx_607; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_607 ON public.station_minutes_607 USING btree (at);


--
-- Name: station_minutes_at_idx_608; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_608 ON public.station_minutes_608 USING btree (at);


--
-- Name: station_minutes_at_idx_609; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_609 ON public.station_minutes_609 USING btree (at);


--
-- Name: station_minutes_at_idx_610; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_610 ON public.station_minutes_610 USING btree (at);


--
-- Name: station_minutes_at_idx_611; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_611 ON public.station_minutes_611 USING btree (at);


--
-- Name: station_minutes_at_idx_615; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_615 ON public.station_minutes_615 USING btree (at);


--
-- Name: station_minutes_at_idx_616; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_616 ON public.station_minutes_616 USING btree (at);


--
-- Name: station_minutes_at_idx_617; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_617 ON public.station_minutes_617 USING btree (at);


--
-- Name: station_minutes_at_idx_618; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_618 ON public.station_minutes_618 USING btree (at);


--
-- Name: station_minutes_at_idx_619; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_619 ON public.station_minutes_619 USING btree (at);


--
-- Name: station_minutes_at_idx_620; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_620 ON public.station_minutes_620 USING btree (at);


--
-- Name: station_minutes_at_idx_622; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_622 ON public.station_minutes_622 USING btree (at);


--
-- Name: station_minutes_at_idx_624; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_624 ON public.station_minutes_624 USING btree (at);


--
-- Name: station_minutes_at_idx_625; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_625 ON public.station_minutes_625 USING btree (at);


--
-- Name: station_minutes_at_idx_628; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_628 ON public.station_minutes_628 USING btree (at);


--
-- Name: station_minutes_at_idx_631; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_631 ON public.station_minutes_631 USING btree (at);


--
-- Name: station_minutes_at_idx_632; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_632 ON public.station_minutes_632 USING btree (at);


--
-- Name: station_minutes_at_idx_633; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_633 ON public.station_minutes_633 USING btree (at);


--
-- Name: station_minutes_at_idx_636; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_636 ON public.station_minutes_636 USING btree (at);


--
-- Name: station_minutes_at_idx_99; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx_99 ON public.station_minutes_99 USING btree (at);


--
-- Name: station_minutes_at_sid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_sid ON public.station_minutes USING btree (date_part('epoch'::text, at), sid);

ALTER TABLE public.station_minutes CLUSTER ON station_minutes_at_sid;


--
-- Name: station_minutes_epoch_110; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_110 ON public.station_minutes_110 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_167; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_167 ON public.station_minutes_167 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_245; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_245 ON public.station_minutes_245 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_247; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_247 ON public.station_minutes_247 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_249; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_249 ON public.station_minutes_249 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_259; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_259 ON public.station_minutes_259 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_261; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_261 ON public.station_minutes_261 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_284; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_284 ON public.station_minutes_284 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_285; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_285 ON public.station_minutes_285 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_296; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_296 ON public.station_minutes_296 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_298; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_298 ON public.station_minutes_298 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_3001; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_3001 ON public.station_minutes_3001 USING btree (EXTRACT(epoch FROM at));


--
-- Name: station_minutes_epoch_307; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_307 ON public.station_minutes_307 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_308; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_308 ON public.station_minutes_308 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_309; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_309 ON public.station_minutes_309 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_310; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_310 ON public.station_minutes_310 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_314; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_314 ON public.station_minutes_314 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_316; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_316 ON public.station_minutes_316 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_317; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_317 ON public.station_minutes_317 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_319; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_319 ON public.station_minutes_319 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_320; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_320 ON public.station_minutes_320 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_323; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_323 ON public.station_minutes_323 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_326; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_326 ON public.station_minutes_326 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_327; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_327 ON public.station_minutes_327 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_329; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_329 ON public.station_minutes_329 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_330; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_330 ON public.station_minutes_330 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_331; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_331 ON public.station_minutes_331 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_333; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_333 ON public.station_minutes_333 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_334; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_334 ON public.station_minutes_334 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_336; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_336 ON public.station_minutes_336 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_337; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_337 ON public.station_minutes_337 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_338; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_338 ON public.station_minutes_338 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_339; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_339 ON public.station_minutes_339 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_343; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_343 ON public.station_minutes_343 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_346; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_346 ON public.station_minutes_346 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_347; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_347 ON public.station_minutes_347 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_348; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_348 ON public.station_minutes_348 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_349; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_349 ON public.station_minutes_349 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_350; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_350 ON public.station_minutes_350 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_351; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_351 ON public.station_minutes_351 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_352; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_352 ON public.station_minutes_352 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_353; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_353 ON public.station_minutes_353 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_354; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_354 ON public.station_minutes_354 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_355; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_355 ON public.station_minutes_355 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_356; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_356 ON public.station_minutes_356 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_357; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_357 ON public.station_minutes_357 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_358; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_358 ON public.station_minutes_358 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_359; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_359 ON public.station_minutes_359 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_360; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_360 ON public.station_minutes_360 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_361; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_361 ON public.station_minutes_361 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_362; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_362 ON public.station_minutes_362 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_363; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_363 ON public.station_minutes_363 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_364; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_364 ON public.station_minutes_364 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_365; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_365 ON public.station_minutes_365 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_370; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_370 ON public.station_minutes_370 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_371; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_371 ON public.station_minutes_371 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_372; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_372 ON public.station_minutes_372 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_373; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_373 ON public.station_minutes_373 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_374; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_374 ON public.station_minutes_374 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_375; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_375 ON public.station_minutes_375 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_376; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_376 ON public.station_minutes_376 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_377; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_377 ON public.station_minutes_377 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_378; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_378 ON public.station_minutes_378 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_379; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_379 ON public.station_minutes_379 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_380; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_380 ON public.station_minutes_380 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_382; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_382 ON public.station_minutes_382 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_383; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_383 ON public.station_minutes_383 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_385; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_385 ON public.station_minutes_385 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_387; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_387 ON public.station_minutes_387 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_389; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_389 ON public.station_minutes_389 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_390; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_390 ON public.station_minutes_390 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_391; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_391 ON public.station_minutes_391 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_392; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_392 ON public.station_minutes_392 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_395; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_395 ON public.station_minutes_395 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_396; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_396 ON public.station_minutes_396 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_397; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_397 ON public.station_minutes_397 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_398; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_398 ON public.station_minutes_398 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_399; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_399 ON public.station_minutes_399 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_400; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_400 ON public.station_minutes_400 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_403; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_403 ON public.station_minutes_403 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_404; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_404 ON public.station_minutes_404 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_405; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_405 ON public.station_minutes_405 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_406; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_406 ON public.station_minutes_406 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_407; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_407 ON public.station_minutes_407 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_409; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_409 ON public.station_minutes_409 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_410; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_410 ON public.station_minutes_410 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_411; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_411 ON public.station_minutes_411 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_412; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_412 ON public.station_minutes_412 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_413; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_413 ON public.station_minutes_413 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_414; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_414 ON public.station_minutes_414 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_415; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_415 ON public.station_minutes_415 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_417; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_417 ON public.station_minutes_417 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_418; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_418 ON public.station_minutes_418 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_419; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_419 ON public.station_minutes_419 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_420; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_420 ON public.station_minutes_420 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_422; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_422 ON public.station_minutes_422 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_423; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_423 ON public.station_minutes_423 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_425; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_425 ON public.station_minutes_425 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_428; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_428 ON public.station_minutes_428 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_429; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_429 ON public.station_minutes_429 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_430; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_430 ON public.station_minutes_430 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_433; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_433 ON public.station_minutes_433 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_434; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_434 ON public.station_minutes_434 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_435; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_435 ON public.station_minutes_435 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_436; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_436 ON public.station_minutes_436 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_437; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_437 ON public.station_minutes_437 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_443; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_443 ON public.station_minutes_443 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_447; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_447 ON public.station_minutes_447 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_451; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_451 ON public.station_minutes_451 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_452; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_452 ON public.station_minutes_452 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_453; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_453 ON public.station_minutes_453 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_454; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_454 ON public.station_minutes_454 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_455; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_455 ON public.station_minutes_455 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_459; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_459 ON public.station_minutes_459 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_460; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_460 ON public.station_minutes_460 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_461; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_461 ON public.station_minutes_461 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_462; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_462 ON public.station_minutes_462 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_463; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_463 ON public.station_minutes_463 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_464; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_464 ON public.station_minutes_464 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_465; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_465 ON public.station_minutes_465 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_466; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_466 ON public.station_minutes_466 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_467; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_467 ON public.station_minutes_467 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_469; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_469 ON public.station_minutes_469 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_470; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_470 ON public.station_minutes_470 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_473; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_473 ON public.station_minutes_473 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_474; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_474 ON public.station_minutes_474 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_500; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_500 ON public.station_minutes_500 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_501; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_501 ON public.station_minutes_501 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_502; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_502 ON public.station_minutes_502 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_503; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_503 ON public.station_minutes_503 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_504; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_504 ON public.station_minutes_504 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_505; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_505 ON public.station_minutes_505 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_514; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_514 ON public.station_minutes_514 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_530; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_530 ON public.station_minutes_530 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_533; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_533 ON public.station_minutes_533 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_537; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_537 ON public.station_minutes_537 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_539; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_539 ON public.station_minutes_539 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_553; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_553 ON public.station_minutes_553 USING btree (EXTRACT(epoch FROM at));


--
-- Name: station_minutes_epoch_556; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_556 ON public.station_minutes_556 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_561; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_561 ON public.station_minutes_561 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_565; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_565 ON public.station_minutes_565 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_575; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_575 ON public.station_minutes_575 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_577; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_577 ON public.station_minutes_577 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_578; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_578 ON public.station_minutes_578 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_594; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_594 ON public.station_minutes_594 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_595; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_595 ON public.station_minutes_595 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_597; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_597 ON public.station_minutes_597 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_601; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_601 ON public.station_minutes_601 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_602; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_602 ON public.station_minutes_602 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_603; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_603 ON public.station_minutes_603 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_604; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_604 ON public.station_minutes_604 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_605; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_605 ON public.station_minutes_605 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_606; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_606 ON public.station_minutes_606 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_607; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_607 ON public.station_minutes_607 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_608; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_608 ON public.station_minutes_608 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_609; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_609 ON public.station_minutes_609 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_610; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_610 ON public.station_minutes_610 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_611; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_611 ON public.station_minutes_611 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_615; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_615 ON public.station_minutes_615 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_616; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_616 ON public.station_minutes_616 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_617; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_617 ON public.station_minutes_617 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_618; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_618 ON public.station_minutes_618 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_619; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_619 ON public.station_minutes_619 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_620; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_620 ON public.station_minutes_620 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_622; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_622 ON public.station_minutes_622 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_624; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_624 ON public.station_minutes_624 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_625; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_625 ON public.station_minutes_625 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_628; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_628 ON public.station_minutes_628 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_epoch_631; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_631 ON public.station_minutes_631 USING btree (EXTRACT(epoch FROM at));


--
-- Name: station_minutes_epoch_632; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_632 ON public.station_minutes_632 USING btree (EXTRACT(epoch FROM at));


--
-- Name: station_minutes_epoch_633; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_633 ON public.station_minutes_633 USING btree (EXTRACT(epoch FROM at));


--
-- Name: station_minutes_epoch_636; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_636 ON public.station_minutes_636 USING btree (EXTRACT(epoch FROM at));


--
-- Name: station_minutes_epoch_99; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_epoch_99 ON public.station_minutes_99 USING btree (date_part('epoch'::text, at));


--
-- Name: station_minutes_sid_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_sid_at ON public.station_minutes USING btree (sid, at);


--
-- Name: submitted_at_index; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX submitted_at_index ON public.station_logs USING btree (submitted_at);


--
-- Name: uniq_hh; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh ON public.station_hours USING btree (public.uniq_hours(at), sid);


--
-- Name: uniq_hh_110; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_110 ON public.station_hours_110 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_167; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_167 ON public.station_hours_167 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_245; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_245 ON public.station_hours_245 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_247; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_247 ON public.station_hours_247 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_249; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_249 ON public.station_hours_249 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_259; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_259 ON public.station_hours_259 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_261; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_261 ON public.station_hours_261 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_284; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_284 ON public.station_hours_284 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_285; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_285 ON public.station_hours_285 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_296; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_296 ON public.station_hours_296 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_298; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_298 ON public.station_hours_298 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_307; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_307 ON public.station_hours_307 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_308; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_308 ON public.station_hours_308 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_309; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_309 ON public.station_hours_309 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_310; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_310 ON public.station_hours_310 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_314; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_314 ON public.station_hours_314 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_316; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_316 ON public.station_hours_316 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_317; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_317 ON public.station_hours_317 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_319; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_319 ON public.station_hours_319 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_320; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_320 ON public.station_hours_320 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_323; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_323 ON public.station_hours_323 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_326; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_326 ON public.station_hours_326 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_327; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_327 ON public.station_hours_327 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_329; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_329 ON public.station_hours_329 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_330; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_330 ON public.station_hours_330 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_331; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_331 ON public.station_hours_331 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_333; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_333 ON public.station_hours_333 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_334; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_334 ON public.station_hours_334 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_336; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_336 ON public.station_hours_336 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_337; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_337 ON public.station_hours_337 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_338; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_338 ON public.station_hours_338 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_339; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_339 ON public.station_hours_339 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_343; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_343 ON public.station_hours_343 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_346; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_346 ON public.station_hours_346 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_347; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_347 ON public.station_hours_347 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_348; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_348 ON public.station_hours_348 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_349; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_349 ON public.station_hours_349 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_350; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_350 ON public.station_hours_350 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_351; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_351 ON public.station_hours_351 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_352; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_352 ON public.station_hours_352 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_353; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_353 ON public.station_hours_353 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_354; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_354 ON public.station_hours_354 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_355; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_355 ON public.station_hours_355 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_356; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_356 ON public.station_hours_356 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_357; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_357 ON public.station_hours_357 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_358; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_358 ON public.station_hours_358 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_359; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_359 ON public.station_hours_359 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_360; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_360 ON public.station_hours_360 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_361; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_361 ON public.station_hours_361 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_362; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_362 ON public.station_hours_362 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_363; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_363 ON public.station_hours_363 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_364; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_364 ON public.station_hours_364 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_365; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_365 ON public.station_hours_365 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_370; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_370 ON public.station_hours_370 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_371; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_371 ON public.station_hours_371 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_372; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_372 ON public.station_hours_372 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_373; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_373 ON public.station_hours_373 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_374; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_374 ON public.station_hours_374 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_375; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_375 ON public.station_hours_375 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_376; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_376 ON public.station_hours_376 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_377; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_377 ON public.station_hours_377 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_378; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_378 ON public.station_hours_378 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_379; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_379 ON public.station_hours_379 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_380; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_380 ON public.station_hours_380 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_382; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_382 ON public.station_hours_382 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_383; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_383 ON public.station_hours_383 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_385; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_385 ON public.station_hours_385 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_387; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_387 ON public.station_hours_387 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_389; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_389 ON public.station_hours_389 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_390; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_390 ON public.station_hours_390 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_391; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_391 ON public.station_hours_391 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_392; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_392 ON public.station_hours_392 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_395; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_395 ON public.station_hours_395 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_396; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_396 ON public.station_hours_396 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_397; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_397 ON public.station_hours_397 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_398; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_398 ON public.station_hours_398 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_399; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_399 ON public.station_hours_399 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_400; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_400 ON public.station_hours_400 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_403; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_403 ON public.station_hours_403 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_404; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_404 ON public.station_hours_404 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_405; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_405 ON public.station_hours_405 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_406; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_406 ON public.station_hours_406 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_407; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_407 ON public.station_hours_407 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_409; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_409 ON public.station_hours_409 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_410; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_410 ON public.station_hours_410 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_411; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_411 ON public.station_hours_411 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_412; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_412 ON public.station_hours_412 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_413; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_413 ON public.station_hours_413 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_414; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_414 ON public.station_hours_414 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_415; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_415 ON public.station_hours_415 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_417; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_417 ON public.station_hours_417 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_418; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_418 ON public.station_hours_418 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_419; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_419 ON public.station_hours_419 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_420; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_420 ON public.station_hours_420 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_422; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_422 ON public.station_hours_422 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_423; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_423 ON public.station_hours_423 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_425; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_425 ON public.station_hours_425 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_428; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_428 ON public.station_hours_428 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_429; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_429 ON public.station_hours_429 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_430; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_430 ON public.station_hours_430 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_433; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_433 ON public.station_hours_433 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_434; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_434 ON public.station_hours_434 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_435; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_435 ON public.station_hours_435 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_436; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_436 ON public.station_hours_436 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_437; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_437 ON public.station_hours_437 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_443; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_443 ON public.station_hours_443 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_447; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_447 ON public.station_hours_447 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_451; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_451 ON public.station_hours_451 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_452; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_452 ON public.station_hours_452 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_453; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_453 ON public.station_hours_453 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_454; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_454 ON public.station_hours_454 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_455; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_455 ON public.station_hours_455 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_459; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_459 ON public.station_hours_459 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_460; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_460 ON public.station_hours_460 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_461; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_461 ON public.station_hours_461 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_462; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_462 ON public.station_hours_462 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_463; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_463 ON public.station_hours_463 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_464; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_464 ON public.station_hours_464 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_465; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_465 ON public.station_hours_465 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_466; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_466 ON public.station_hours_466 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_467; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_467 ON public.station_hours_467 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_469; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_469 ON public.station_hours_469 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_470; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_470 ON public.station_hours_470 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_473; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_473 ON public.station_hours_473 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_474; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_474 ON public.station_hours_474 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_500; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_500 ON public.station_hours_500 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_501; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_501 ON public.station_hours_501 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_502; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_502 ON public.station_hours_502 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_503; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_503 ON public.station_hours_503 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_504; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_504 ON public.station_hours_504 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_505; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_505 ON public.station_hours_505 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_514; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_514 ON public.station_hours_514 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_530; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_530 ON public.station_hours_530 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_533; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_533 ON public.station_hours_533 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_537; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_537 ON public.station_hours_537 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_539; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_539 ON public.station_hours_539 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_553; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_553 ON public.station_hours_553 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_556; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_556 ON public.station_hours_556 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_561; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_561 ON public.station_hours_561 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_565; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_565 ON public.station_hours_565 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_575; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_575 ON public.station_hours_575 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_577; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_577 ON public.station_hours_577 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_578; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_578 ON public.station_hours_578 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_594; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_594 ON public.station_hours_594 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_595; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_595 ON public.station_hours_595 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_597; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_597 ON public.station_hours_597 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_601; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_601 ON public.station_hours_601 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_602; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_602 ON public.station_hours_602 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_603; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_603 ON public.station_hours_603 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_604; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_604 ON public.station_hours_604 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_605; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_605 ON public.station_hours_605 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_606; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_606 ON public.station_hours_606 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_607; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_607 ON public.station_hours_607 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_608; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_608 ON public.station_hours_608 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_609; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_609 ON public.station_hours_609 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_610; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_610 ON public.station_hours_610 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_611; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_611 ON public.station_hours_611 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_615; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_615 ON public.station_hours_615 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_616; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_616 ON public.station_hours_616 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_617; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_617 ON public.station_hours_617 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_618; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_618 ON public.station_hours_618 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_619; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_619 ON public.station_hours_619 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_620; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_620 ON public.station_hours_620 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_622; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_622 ON public.station_hours_622 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_624; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_624 ON public.station_hours_624 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_625; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_625 ON public.station_hours_625 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_628; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_628 ON public.station_hours_628 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_631; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_631 ON public.station_hours_631 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_632; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_632 ON public.station_hours_632 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_633; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_633 ON public.station_hours_633 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_636; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_636 ON public.station_hours_636 USING btree (public.uniq_hours(at));


--
-- Name: uniq_hh_99; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh_99 ON public.station_hours_99 USING btree (public.uniq_hours(at));


--
-- Name: uniq_mm; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm ON public.station_minutes USING btree (public.uniq_minute(at), sid);


--
-- Name: uniq_mm_110; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_110 ON public.station_minutes_110 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_167; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_167 ON public.station_minutes_167 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_245; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_245 ON public.station_minutes_245 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_247; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_247 ON public.station_minutes_247 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_249; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_249 ON public.station_minutes_249 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_259; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_259 ON public.station_minutes_259 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_261; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_261 ON public.station_minutes_261 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_284; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_284 ON public.station_minutes_284 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_285; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_285 ON public.station_minutes_285 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_296; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_296 ON public.station_minutes_296 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_298; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_298 ON public.station_minutes_298 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_3001; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_3001 ON public.station_minutes_3001 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_307; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_307 ON public.station_minutes_307 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_308; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_308 ON public.station_minutes_308 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_309; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_309 ON public.station_minutes_309 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_310; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_310 ON public.station_minutes_310 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_314; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_314 ON public.station_minutes_314 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_316; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_316 ON public.station_minutes_316 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_317; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_317 ON public.station_minutes_317 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_319; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_319 ON public.station_minutes_319 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_320; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_320 ON public.station_minutes_320 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_323; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_323 ON public.station_minutes_323 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_326; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_326 ON public.station_minutes_326 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_327; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_327 ON public.station_minutes_327 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_329; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_329 ON public.station_minutes_329 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_330; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_330 ON public.station_minutes_330 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_331; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_331 ON public.station_minutes_331 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_333; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_333 ON public.station_minutes_333 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_334; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_334 ON public.station_minutes_334 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_336; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_336 ON public.station_minutes_336 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_337; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_337 ON public.station_minutes_337 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_338; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_338 ON public.station_minutes_338 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_339; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_339 ON public.station_minutes_339 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_343; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_343 ON public.station_minutes_343 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_346; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_346 ON public.station_minutes_346 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_347; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_347 ON public.station_minutes_347 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_348; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_348 ON public.station_minutes_348 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_349; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_349 ON public.station_minutes_349 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_350; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_350 ON public.station_minutes_350 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_351; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_351 ON public.station_minutes_351 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_352; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_352 ON public.station_minutes_352 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_353; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_353 ON public.station_minutes_353 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_354; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_354 ON public.station_minutes_354 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_355; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_355 ON public.station_minutes_355 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_356; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_356 ON public.station_minutes_356 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_357; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_357 ON public.station_minutes_357 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_358; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_358 ON public.station_minutes_358 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_359; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_359 ON public.station_minutes_359 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_360; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_360 ON public.station_minutes_360 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_361; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_361 ON public.station_minutes_361 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_362; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_362 ON public.station_minutes_362 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_363; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_363 ON public.station_minutes_363 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_364; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_364 ON public.station_minutes_364 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_365; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_365 ON public.station_minutes_365 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_370; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_370 ON public.station_minutes_370 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_371; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_371 ON public.station_minutes_371 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_372; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_372 ON public.station_minutes_372 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_373; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_373 ON public.station_minutes_373 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_374; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_374 ON public.station_minutes_374 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_375; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_375 ON public.station_minutes_375 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_376; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_376 ON public.station_minutes_376 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_377; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_377 ON public.station_minutes_377 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_378; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_378 ON public.station_minutes_378 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_379; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_379 ON public.station_minutes_379 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_380; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_380 ON public.station_minutes_380 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_382; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_382 ON public.station_minutes_382 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_383; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_383 ON public.station_minutes_383 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_385; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_385 ON public.station_minutes_385 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_387; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_387 ON public.station_minutes_387 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_389; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_389 ON public.station_minutes_389 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_390; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_390 ON public.station_minutes_390 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_391; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_391 ON public.station_minutes_391 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_392; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_392 ON public.station_minutes_392 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_395; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_395 ON public.station_minutes_395 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_396; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_396 ON public.station_minutes_396 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_397; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_397 ON public.station_minutes_397 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_398; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_398 ON public.station_minutes_398 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_399; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_399 ON public.station_minutes_399 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_400; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_400 ON public.station_minutes_400 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_403; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_403 ON public.station_minutes_403 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_404; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_404 ON public.station_minutes_404 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_405; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_405 ON public.station_minutes_405 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_406; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_406 ON public.station_minutes_406 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_407; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_407 ON public.station_minutes_407 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_409; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_409 ON public.station_minutes_409 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_410; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_410 ON public.station_minutes_410 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_411; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_411 ON public.station_minutes_411 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_412; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_412 ON public.station_minutes_412 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_413; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_413 ON public.station_minutes_413 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_414; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_414 ON public.station_minutes_414 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_415; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_415 ON public.station_minutes_415 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_417; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_417 ON public.station_minutes_417 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_418; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_418 ON public.station_minutes_418 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_419; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_419 ON public.station_minutes_419 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_420; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_420 ON public.station_minutes_420 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_422; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_422 ON public.station_minutes_422 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_423; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_423 ON public.station_minutes_423 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_425; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_425 ON public.station_minutes_425 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_428; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_428 ON public.station_minutes_428 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_429; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_429 ON public.station_minutes_429 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_430; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_430 ON public.station_minutes_430 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_433; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_433 ON public.station_minutes_433 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_434; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_434 ON public.station_minutes_434 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_435; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_435 ON public.station_minutes_435 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_436; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_436 ON public.station_minutes_436 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_437; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_437 ON public.station_minutes_437 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_443; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_443 ON public.station_minutes_443 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_447; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_447 ON public.station_minutes_447 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_451; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_451 ON public.station_minutes_451 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_452; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_452 ON public.station_minutes_452 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_453; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_453 ON public.station_minutes_453 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_454; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_454 ON public.station_minutes_454 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_455; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_455 ON public.station_minutes_455 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_459; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_459 ON public.station_minutes_459 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_460; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_460 ON public.station_minutes_460 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_461; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_461 ON public.station_minutes_461 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_462; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_462 ON public.station_minutes_462 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_463; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_463 ON public.station_minutes_463 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_464; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_464 ON public.station_minutes_464 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_465; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_465 ON public.station_minutes_465 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_466; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_466 ON public.station_minutes_466 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_467; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_467 ON public.station_minutes_467 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_469; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_469 ON public.station_minutes_469 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_470; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_470 ON public.station_minutes_470 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_473; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_473 ON public.station_minutes_473 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_474; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_474 ON public.station_minutes_474 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_500; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_500 ON public.station_minutes_500 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_501; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_501 ON public.station_minutes_501 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_502; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_502 ON public.station_minutes_502 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_503; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_503 ON public.station_minutes_503 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_504; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_504 ON public.station_minutes_504 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_505; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_505 ON public.station_minutes_505 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_514; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_514 ON public.station_minutes_514 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_530; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_530 ON public.station_minutes_530 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_533; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_533 ON public.station_minutes_533 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_537; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_537 ON public.station_minutes_537 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_539; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_539 ON public.station_minutes_539 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_553; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_553 ON public.station_minutes_553 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_556; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_556 ON public.station_minutes_556 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_561; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_561 ON public.station_minutes_561 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_565; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_565 ON public.station_minutes_565 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_575; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_575 ON public.station_minutes_575 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_577; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_577 ON public.station_minutes_577 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_578; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_578 ON public.station_minutes_578 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_594; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_594 ON public.station_minutes_594 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_595; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_595 ON public.station_minutes_595 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_597; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_597 ON public.station_minutes_597 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_601; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_601 ON public.station_minutes_601 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_602; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_602 ON public.station_minutes_602 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_603; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_603 ON public.station_minutes_603 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_604; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_604 ON public.station_minutes_604 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_605; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_605 ON public.station_minutes_605 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_606; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_606 ON public.station_minutes_606 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_607; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_607 ON public.station_minutes_607 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_608; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_608 ON public.station_minutes_608 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_609; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_609 ON public.station_minutes_609 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_610; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_610 ON public.station_minutes_610 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_611; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_611 ON public.station_minutes_611 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_615; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_615 ON public.station_minutes_615 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_616; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_616 ON public.station_minutes_616 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_617; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_617 ON public.station_minutes_617 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_618; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_618 ON public.station_minutes_618 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_619; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_619 ON public.station_minutes_619 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_620; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_620 ON public.station_minutes_620 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_622; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_622 ON public.station_minutes_622 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_624; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_624 ON public.station_minutes_624 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_625; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_625 ON public.station_minutes_625 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_628; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_628 ON public.station_minutes_628 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_631; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_631 ON public.station_minutes_631 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_632; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_632 ON public.station_minutes_632 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_633; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_633 ON public.station_minutes_633 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_636; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_636 ON public.station_minutes_636 USING btree (public.uniq_minute(at));


--
-- Name: uniq_mm_99; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm_99 ON public.station_minutes_99 USING btree (public.uniq_minute(at));


--
-- Name: unique_stations_imei; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX unique_stations_imei ON public.stations USING btree (imei);


--
-- Name: unique_users_email; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX unique_users_email ON public.users USING btree (email);


--
-- Name: station_hours trigger_ai_station_hours; Type: TRIGGER; Schema: public; Owner: geo
--

CREATE TRIGGER trigger_ai_station_hours AFTER INSERT ON public.station_hours FOR EACH ROW EXECUTE FUNCTION public.fn_ai_station_hours();


--
-- Name: station_logs trigger_ai_station_logs; Type: TRIGGER; Schema: public; Owner: geo
--

CREATE TRIGGER trigger_ai_station_logs AFTER INSERT ON public.station_logs FOR EACH ROW EXECUTE FUNCTION public.fn_ai_station_logs();


--
-- Name: station_minutes trigger_ai_station_minutes; Type: TRIGGER; Schema: public; Owner: geo
--

CREATE TRIGGER trigger_ai_station_minutes AFTER INSERT ON public.station_minutes FOR EACH ROW EXECUTE FUNCTION public.fn_ai_station_minutes();


--
-- Name: station_logs_110 station_logs_110_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_110
    ADD CONSTRAINT station_logs_110_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_167 station_logs_167_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_167
    ADD CONSTRAINT station_logs_167_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_245 station_logs_245_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_245
    ADD CONSTRAINT station_logs_245_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_247 station_logs_247_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_247
    ADD CONSTRAINT station_logs_247_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_249 station_logs_249_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_249
    ADD CONSTRAINT station_logs_249_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_259 station_logs_259_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_259
    ADD CONSTRAINT station_logs_259_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_261 station_logs_261_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_261
    ADD CONSTRAINT station_logs_261_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_284 station_logs_284_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_284
    ADD CONSTRAINT station_logs_284_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_285 station_logs_285_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_285
    ADD CONSTRAINT station_logs_285_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_296 station_logs_296_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_296
    ADD CONSTRAINT station_logs_296_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_298 station_logs_298_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_298
    ADD CONSTRAINT station_logs_298_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_307 station_logs_307_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_307
    ADD CONSTRAINT station_logs_307_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_308 station_logs_308_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_308
    ADD CONSTRAINT station_logs_308_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_309 station_logs_309_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_309
    ADD CONSTRAINT station_logs_309_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_310 station_logs_310_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_310
    ADD CONSTRAINT station_logs_310_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_314 station_logs_314_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_314
    ADD CONSTRAINT station_logs_314_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_316 station_logs_316_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_316
    ADD CONSTRAINT station_logs_316_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_317 station_logs_317_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_317
    ADD CONSTRAINT station_logs_317_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_319 station_logs_319_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_319
    ADD CONSTRAINT station_logs_319_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_320 station_logs_320_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_320
    ADD CONSTRAINT station_logs_320_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_323 station_logs_323_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_323
    ADD CONSTRAINT station_logs_323_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_326 station_logs_326_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_326
    ADD CONSTRAINT station_logs_326_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_327 station_logs_327_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_327
    ADD CONSTRAINT station_logs_327_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_329 station_logs_329_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_329
    ADD CONSTRAINT station_logs_329_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_330 station_logs_330_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_330
    ADD CONSTRAINT station_logs_330_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_331 station_logs_331_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_331
    ADD CONSTRAINT station_logs_331_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_333 station_logs_333_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_333
    ADD CONSTRAINT station_logs_333_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_334 station_logs_334_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_334
    ADD CONSTRAINT station_logs_334_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_336 station_logs_336_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_336
    ADD CONSTRAINT station_logs_336_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_337 station_logs_337_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_337
    ADD CONSTRAINT station_logs_337_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_338 station_logs_338_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_338
    ADD CONSTRAINT station_logs_338_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_339 station_logs_339_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_339
    ADD CONSTRAINT station_logs_339_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_343 station_logs_343_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_343
    ADD CONSTRAINT station_logs_343_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_346 station_logs_346_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_346
    ADD CONSTRAINT station_logs_346_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_347 station_logs_347_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_347
    ADD CONSTRAINT station_logs_347_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_348 station_logs_348_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_348
    ADD CONSTRAINT station_logs_348_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_349 station_logs_349_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_349
    ADD CONSTRAINT station_logs_349_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_350 station_logs_350_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_350
    ADD CONSTRAINT station_logs_350_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_351 station_logs_351_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_351
    ADD CONSTRAINT station_logs_351_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_352 station_logs_352_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_352
    ADD CONSTRAINT station_logs_352_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_353 station_logs_353_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_353
    ADD CONSTRAINT station_logs_353_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_354 station_logs_354_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_354
    ADD CONSTRAINT station_logs_354_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_355 station_logs_355_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_355
    ADD CONSTRAINT station_logs_355_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_356 station_logs_356_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_356
    ADD CONSTRAINT station_logs_356_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_357 station_logs_357_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_357
    ADD CONSTRAINT station_logs_357_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_358 station_logs_358_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_358
    ADD CONSTRAINT station_logs_358_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_359 station_logs_359_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_359
    ADD CONSTRAINT station_logs_359_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_360 station_logs_360_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_360
    ADD CONSTRAINT station_logs_360_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_361 station_logs_361_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_361
    ADD CONSTRAINT station_logs_361_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_362 station_logs_362_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_362
    ADD CONSTRAINT station_logs_362_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_363 station_logs_363_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_363
    ADD CONSTRAINT station_logs_363_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_364 station_logs_364_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_364
    ADD CONSTRAINT station_logs_364_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_365 station_logs_365_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_365
    ADD CONSTRAINT station_logs_365_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_370 station_logs_370_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_370
    ADD CONSTRAINT station_logs_370_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_371 station_logs_371_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_371
    ADD CONSTRAINT station_logs_371_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_372 station_logs_372_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_372
    ADD CONSTRAINT station_logs_372_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_373 station_logs_373_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_373
    ADD CONSTRAINT station_logs_373_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_374 station_logs_374_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_374
    ADD CONSTRAINT station_logs_374_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_375 station_logs_375_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_375
    ADD CONSTRAINT station_logs_375_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_376 station_logs_376_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_376
    ADD CONSTRAINT station_logs_376_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_377 station_logs_377_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_377
    ADD CONSTRAINT station_logs_377_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_378 station_logs_378_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_378
    ADD CONSTRAINT station_logs_378_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_379 station_logs_379_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_379
    ADD CONSTRAINT station_logs_379_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_380 station_logs_380_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_380
    ADD CONSTRAINT station_logs_380_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_382 station_logs_382_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_382
    ADD CONSTRAINT station_logs_382_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_383 station_logs_383_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_383
    ADD CONSTRAINT station_logs_383_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_385 station_logs_385_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_385
    ADD CONSTRAINT station_logs_385_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_387 station_logs_387_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_387
    ADD CONSTRAINT station_logs_387_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_389 station_logs_389_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_389
    ADD CONSTRAINT station_logs_389_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_390 station_logs_390_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_390
    ADD CONSTRAINT station_logs_390_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_391 station_logs_391_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_391
    ADD CONSTRAINT station_logs_391_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_392 station_logs_392_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_392
    ADD CONSTRAINT station_logs_392_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_395 station_logs_395_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_395
    ADD CONSTRAINT station_logs_395_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_396 station_logs_396_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_396
    ADD CONSTRAINT station_logs_396_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_397 station_logs_397_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_397
    ADD CONSTRAINT station_logs_397_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_398 station_logs_398_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_398
    ADD CONSTRAINT station_logs_398_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_399 station_logs_399_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_399
    ADD CONSTRAINT station_logs_399_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_400 station_logs_400_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_400
    ADD CONSTRAINT station_logs_400_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_403 station_logs_403_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_403
    ADD CONSTRAINT station_logs_403_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_404 station_logs_404_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_404
    ADD CONSTRAINT station_logs_404_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_405 station_logs_405_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_405
    ADD CONSTRAINT station_logs_405_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_406 station_logs_406_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_406
    ADD CONSTRAINT station_logs_406_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_407 station_logs_407_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_407
    ADD CONSTRAINT station_logs_407_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_409 station_logs_409_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_409
    ADD CONSTRAINT station_logs_409_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_410 station_logs_410_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_410
    ADD CONSTRAINT station_logs_410_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_411 station_logs_411_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_411
    ADD CONSTRAINT station_logs_411_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_412 station_logs_412_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_412
    ADD CONSTRAINT station_logs_412_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_413 station_logs_413_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_413
    ADD CONSTRAINT station_logs_413_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_414 station_logs_414_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_414
    ADD CONSTRAINT station_logs_414_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_415 station_logs_415_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_415
    ADD CONSTRAINT station_logs_415_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_417 station_logs_417_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_417
    ADD CONSTRAINT station_logs_417_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_418 station_logs_418_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_418
    ADD CONSTRAINT station_logs_418_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_419 station_logs_419_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_419
    ADD CONSTRAINT station_logs_419_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_420 station_logs_420_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_420
    ADD CONSTRAINT station_logs_420_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_422 station_logs_422_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_422
    ADD CONSTRAINT station_logs_422_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_423 station_logs_423_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_423
    ADD CONSTRAINT station_logs_423_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_425 station_logs_425_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_425
    ADD CONSTRAINT station_logs_425_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_428 station_logs_428_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_428
    ADD CONSTRAINT station_logs_428_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_429 station_logs_429_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_429
    ADD CONSTRAINT station_logs_429_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_430 station_logs_430_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_430
    ADD CONSTRAINT station_logs_430_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_433 station_logs_433_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_433
    ADD CONSTRAINT station_logs_433_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_434 station_logs_434_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_434
    ADD CONSTRAINT station_logs_434_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_435 station_logs_435_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_435
    ADD CONSTRAINT station_logs_435_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_436 station_logs_436_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_436
    ADD CONSTRAINT station_logs_436_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_437 station_logs_437_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_437
    ADD CONSTRAINT station_logs_437_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_443 station_logs_443_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_443
    ADD CONSTRAINT station_logs_443_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_447 station_logs_447_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_447
    ADD CONSTRAINT station_logs_447_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_451 station_logs_451_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_451
    ADD CONSTRAINT station_logs_451_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_452 station_logs_452_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_452
    ADD CONSTRAINT station_logs_452_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_453 station_logs_453_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_453
    ADD CONSTRAINT station_logs_453_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_454 station_logs_454_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_454
    ADD CONSTRAINT station_logs_454_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_455 station_logs_455_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_455
    ADD CONSTRAINT station_logs_455_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_459 station_logs_459_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_459
    ADD CONSTRAINT station_logs_459_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_460 station_logs_460_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_460
    ADD CONSTRAINT station_logs_460_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_462 station_logs_462_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_462
    ADD CONSTRAINT station_logs_462_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_463 station_logs_463_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_463
    ADD CONSTRAINT station_logs_463_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_464 station_logs_464_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_464
    ADD CONSTRAINT station_logs_464_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_465 station_logs_465_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_465
    ADD CONSTRAINT station_logs_465_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_466 station_logs_466_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_466
    ADD CONSTRAINT station_logs_466_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_467 station_logs_467_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_467
    ADD CONSTRAINT station_logs_467_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_469 station_logs_469_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_469
    ADD CONSTRAINT station_logs_469_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_470 station_logs_470_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_470
    ADD CONSTRAINT station_logs_470_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_473 station_logs_473_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_473
    ADD CONSTRAINT station_logs_473_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_474 station_logs_474_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_474
    ADD CONSTRAINT station_logs_474_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_500 station_logs_500_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_500
    ADD CONSTRAINT station_logs_500_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_501 station_logs_501_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_501
    ADD CONSTRAINT station_logs_501_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_502 station_logs_502_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_502
    ADD CONSTRAINT station_logs_502_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_503 station_logs_503_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_503
    ADD CONSTRAINT station_logs_503_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_504 station_logs_504_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_504
    ADD CONSTRAINT station_logs_504_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_505 station_logs_505_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_505
    ADD CONSTRAINT station_logs_505_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_514 station_logs_514_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_514
    ADD CONSTRAINT station_logs_514_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_530 station_logs_530_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_530
    ADD CONSTRAINT station_logs_530_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_533 station_logs_533_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_533
    ADD CONSTRAINT station_logs_533_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_537 station_logs_537_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_537
    ADD CONSTRAINT station_logs_537_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_539 station_logs_539_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_539
    ADD CONSTRAINT station_logs_539_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_553 station_logs_553_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_553
    ADD CONSTRAINT station_logs_553_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_556 station_logs_556_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_556
    ADD CONSTRAINT station_logs_556_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_561 station_logs_561_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_561
    ADD CONSTRAINT station_logs_561_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_565 station_logs_565_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_565
    ADD CONSTRAINT station_logs_565_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_575 station_logs_575_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_575
    ADD CONSTRAINT station_logs_575_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_577 station_logs_577_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_577
    ADD CONSTRAINT station_logs_577_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_578 station_logs_578_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_578
    ADD CONSTRAINT station_logs_578_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_594 station_logs_594_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_594
    ADD CONSTRAINT station_logs_594_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_595 station_logs_595_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_595
    ADD CONSTRAINT station_logs_595_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_597 station_logs_597_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_597
    ADD CONSTRAINT station_logs_597_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_601 station_logs_601_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_601
    ADD CONSTRAINT station_logs_601_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_602 station_logs_602_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_602
    ADD CONSTRAINT station_logs_602_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_603 station_logs_603_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_603
    ADD CONSTRAINT station_logs_603_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_604 station_logs_604_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_604
    ADD CONSTRAINT station_logs_604_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_605 station_logs_605_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_605
    ADD CONSTRAINT station_logs_605_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_606 station_logs_606_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_606
    ADD CONSTRAINT station_logs_606_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_607 station_logs_607_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_607
    ADD CONSTRAINT station_logs_607_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_608 station_logs_608_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_608
    ADD CONSTRAINT station_logs_608_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_609 station_logs_609_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_609
    ADD CONSTRAINT station_logs_609_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_610 station_logs_610_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_610
    ADD CONSTRAINT station_logs_610_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_611 station_logs_611_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_611
    ADD CONSTRAINT station_logs_611_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_615 station_logs_615_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_615
    ADD CONSTRAINT station_logs_615_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_616 station_logs_616_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_616
    ADD CONSTRAINT station_logs_616_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_617 station_logs_617_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_617
    ADD CONSTRAINT station_logs_617_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_618 station_logs_618_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_618
    ADD CONSTRAINT station_logs_618_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_619 station_logs_619_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_619
    ADD CONSTRAINT station_logs_619_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_620 station_logs_620_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_620
    ADD CONSTRAINT station_logs_620_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_622 station_logs_622_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_622
    ADD CONSTRAINT station_logs_622_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_624 station_logs_624_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_624
    ADD CONSTRAINT station_logs_624_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_631 station_logs_631_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_631
    ADD CONSTRAINT station_logs_631_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_632 station_logs_632_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_632
    ADD CONSTRAINT station_logs_632_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_633 station_logs_633_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_633
    ADD CONSTRAINT station_logs_633_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_636 station_logs_636_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_636
    ADD CONSTRAINT station_logs_636_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_645 station_logs_645_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_645
    ADD CONSTRAINT station_logs_645_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: station_logs_99 station_logs_99_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.station_logs_99
    ADD CONSTRAINT station_logs_99_station_fk FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: stations stations_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: user_auths user_auths_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.user_auths
    ADD CONSTRAINT user_auths_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- PostgreSQL database dump complete
--

