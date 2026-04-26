SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE IF NOT EXISTS speedtest_users (
    id integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT now() NOT NULL,
    ip text NOT NULL,
    ispinfo text,
    extra text,
    ua text NOT NULL,
    lang text NOT NULL,
    dl text,
    ul text,
    ping text,
    jitter text,
    log text
);

ALTER TABLE speedtest_users OWNER TO {{ pg_speedtest_user }};

CREATE SEQUENCE IF NOT EXISTS speedtest_users_id_seq
    START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER TABLE speedtest_users_id_seq OWNER TO {{ pg_speedtest_user }};
ALTER SEQUENCE speedtest_users_id_seq OWNED BY speedtest_users.id;
ALTER TABLE ONLY speedtest_users ALTER COLUMN id SET DEFAULT nextval('speedtest_users_id_seq'::regclass);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'speedtest_users_pkey') THEN
        ALTER TABLE ONLY speedtest_users ADD CONSTRAINT speedtest_users_pkey PRIMARY KEY (id);
    END IF;
END
$$;

SELECT pg_catalog.setval('speedtest_users_id_seq', 1, true);
