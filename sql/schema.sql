--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: geo; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE geo WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_CA.UTF-8' LC_CTYPE = 'en_CA.UTF-8';


ALTER DATABASE geo OWNER TO postgres;

\connect geo

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;

--
-- Name: uniq_hours(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION uniq_hours(some_time timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
select to_char($1, 'YYYYDDDHH24');
$_$;


ALTER FUNCTION public.uniq_hours(some_time timestamp without time zone) OWNER TO geo;

--
-- Name: uniq_minute(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: geo
--

CREATE FUNCTION uniq_minute(some_time timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
select to_char($1, 'YYYYDDDHH24MI');
$_$;


ALTER FUNCTION public.uniq_minute(some_time timestamp without time zone) OWNER TO geo;

SET default_tablespace = '';

SET default_with_oids = false;

SET search_path = public, pg_catalog;

--
-- Name: groups; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE groups (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    name character varying(50),
    note text,
    updated_by bigint,
    deleted_by bigint,
    restored_by bigint,
    created_by bigint
);


ALTER TABLE groups OWNER TO geo;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE groups_id_seq OWNER TO geo;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: station_hours; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE station_hours (
    at timestamp without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE station_hours OWNER TO geo;

--
-- Name: station_logs; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE station_logs (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    submitted_at timestamp without time zone,
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
    data jsonb
);


ALTER TABLE station_logs OWNER TO geo;

--
-- Name: station_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE station_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_logs_id_seq OWNER TO geo;

--
-- Name: station_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE station_logs_id_seq OWNED BY station_logs.id;


--
-- Name: station_minutes; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE station_minutes (
    at timestamp without time zone,
    slid integer NOT NULL,
    sid integer NOT NULL
);


ALTER TABLE station_minutes OWNER TO geo;

--
-- Name: stations; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE stations (
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
    min_filter integer DEFAULT '-2'::integer,
    max_filter integer DEFAULT 2,
    updated_by bigint,
    deleted_by bigint,
    restored_by bigint,
    created_by bigint
);


ALTER TABLE stations OWNER TO geo;

--
-- Name: stations_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE stations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stations_id_seq OWNER TO geo;

--
-- Name: stations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE stations_id_seq OWNED BY stations.id;


--
-- Name: user_auths; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE user_auths (
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


ALTER TABLE user_auths OWNER TO geo;

--
-- Name: user_auths_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE user_auths_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_auths_id_seq OWNER TO geo;

--
-- Name: user_auths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE user_auths_id_seq OWNED BY user_auths.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: geo
--

CREATE TABLE users (
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
    created_by bigint
);


ALTER TABLE users OWNER TO geo;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: geo
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO geo;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geo
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: station_logs id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY station_logs ALTER COLUMN id SET DEFAULT nextval('station_logs_id_seq'::regclass);


--
-- Name: stations id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY stations ALTER COLUMN id SET DEFAULT nextval('stations_id_seq'::regclass);


--
-- Name: user_auths id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY user_auths ALTER COLUMN id SET DEFAULT nextval('user_auths_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: geo
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: station_hours station_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY station_hours
    ADD CONSTRAINT station_hours_pkey PRIMARY KEY (slid, sid);


--
-- Name: station_logs station_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY station_logs
    ADD CONSTRAINT station_logs_pkey PRIMARY KEY (id);


--
-- Name: station_minutes station_minutes_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY station_minutes
    ADD CONSTRAINT station_minutes_pkey PRIMARY KEY (slid, sid);


--
-- Name: stations stations_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY stations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (id);


--
-- Name: station_logs uniq_sid_sat; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY station_logs
    ADD CONSTRAINT uniq_sid_sat UNIQUE (station_id, submitted_at);


--
-- Name: user_auths user_auths_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY user_auths
    ADD CONSTRAINT user_auths_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


SET search_path = public, pg_catalog;

--
-- Name: email_unique; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX email_unique ON users USING btree (email);


--
-- Name: index_station_hours_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_hours_at ON station_hours USING btree (at);


--
-- Name: index_station_hours_sid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_hours_sid ON station_hours USING btree (sid);


--
-- Name: index_station_hours_slid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_hours_slid ON station_hours USING btree (slid);


--
-- Name: index_station_logs_station; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_logs_station ON station_logs USING btree (station_id);


--
-- Name: index_station_minutes_at; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_minutes_at ON station_minutes USING btree (at);


--
-- Name: index_station_minutes_sid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_minutes_sid ON station_minutes USING btree (sid);


--
-- Name: index_station_minutes_slid; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_station_minutes_slid ON station_minutes USING btree (slid);


--
-- Name: index_stations_group; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_stations_group ON stations USING btree (group_id);


--
-- Name: index_user_auths_user; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_user_auths_user ON user_auths USING btree (user_id);


--
-- Name: index_users_group; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX index_users_group ON users USING btree (group_id);


--
-- Name: order_sid_sat; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX order_sid_sat ON station_logs USING btree (station_id, submitted_at);


--
-- Name: station_hours_at_idx; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_hours_at_idx ON station_hours USING btree (at);


--
-- Name: station_minutes_at_idx; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX station_minutes_at_idx ON station_minutes USING btree (at);


--
-- Name: submitted_at_index; Type: INDEX; Schema: public; Owner: geo
--

CREATE INDEX submitted_at_index ON station_logs USING btree (submitted_at);


--
-- Name: uniq_hh; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_hh ON station_hours USING btree (uniq_hours(at), sid);


--
-- Name: uniq_mm; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX uniq_mm ON station_minutes USING btree (uniq_minute(at), sid);


--
-- Name: unique_groups_name; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX unique_groups_name ON groups USING btree (name);


--
-- Name: unique_stations_imei; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX unique_stations_imei ON stations USING btree (imei);


--
-- Name: unique_users_email; Type: INDEX; Schema: public; Owner: geo
--

CREATE UNIQUE INDEX unique_users_email ON users USING btree (email);


--
-- Name: station_logs station_logs_station_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY station_logs
    ADD CONSTRAINT station_logs_station_fk FOREIGN KEY (station_id) REFERENCES stations(id);


--
-- Name: stations stations_group_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY stations
    ADD CONSTRAINT stations_group_fk FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: user_auths user_auths_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY user_auths
    ADD CONSTRAINT user_auths_user_fk FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: users users_group_fk; Type: FK CONSTRAINT; Schema: public; Owner: geo
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_group_fk FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- PostgreSQL database dump complete
--


-- additional table since 2017-08-28 Prayogo

CREATE TABLE predictions (
    id BIGSERIAL PRIMARY KEY,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    predict_epoch FLOAT, -- the submit date
    station_id integer NOT NULL,
    level float NOT NULL,
    CONSTRAINT sta_id__predict_epoch UNIQUE (station_id, predict_epoch)
);