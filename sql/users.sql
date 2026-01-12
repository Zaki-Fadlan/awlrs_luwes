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

SET search_path = public, pg_catalog;


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: geo
--

COPY groups (id, created_at, updated_at, deleted_at, name, note, updated_by, deleted_by, restored_by, created_by) FROM stdin;
2	2013-08-26 14:05:49	2013-08-26 14:05:49	\N	Guest	\N	\N	\N	\N	\N
1	2013-08-26 14:05:49	2014-08-08 22:46:34	\N	Administrator	Luhut12	1	\N	\N	\N
\.


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geo
--

SELECT pg_catalog.setval('groups_id_seq', 7, true);

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: geo
--

COPY users (id, created_at, updated_at, deleted_at, email, password, reset_id, verified, note, group_id, phone, full_name, updated_by, deleted_by, restored_by, created_by) FROM stdin;
12	2013-09-18 00:13:00	2013-09-18 00:13:00	\N	x@gmail.com	
\.

--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geo
--

SELECT pg_catalog.setval('users_id_seq', 85, true);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--



--
-- PostgreSQL database dump complete
--

