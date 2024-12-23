-- Create DB and tables

--
-- Database: etu-deans-db
--
CREATE DATABASE "etu-deans-db"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;



--
-- Table: public.group
--
CREATE TABLE IF NOT EXISTS public.student_group
(
    group_id smallint NOT NULL,
    group_enroll_year smallint NOT NULL,
    CONSTRAINT group_pkey PRIMARY KEY (group_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."group"
    OWNER to postgres;



--
-- Table: public.mark
--
CREATE TABLE IF NOT EXISTS public.mark
(
    mark_id integer NOT NULL DEFAULT nextval('mark_mark_id_seq'::regclass),
    subject_id smallint NOT NULL,
    student_id smallint NOT NULL,
    mark_date date NOT NULL,
    mark smallint,
    CONSTRAINT mark_pkey PRIMARY KEY (mark_id),
    CONSTRAINT mark__student_fkey FOREIGN KEY (student_id)
        REFERENCES public.student (student_id) MATCH FULL
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT mark__subject_fkey FOREIGN KEY (subject_id)
        REFERENCES public.subject (subject_id) MATCH FULL
        ON UPDATE CASCADE
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mark
    OWNER to postgres;



--
-- Table: public.report_type
--
CREATE TABLE IF NOT EXISTS public.report_type
(
    report_type_id smallint NOT NULL,
    report_type_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT report_type_pkey PRIMARY KEY (report_type_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.report_type
    OWNER to postgres;



--
-- Table: public.specialty
--
CREATE TABLE IF NOT EXISTS public.specialty
(
    specialty_id smallint NOT NULL DEFAULT nextval('specialty_specialty_id_seq'::regclass),
    specialty_code character varying(16) COLLATE pg_catalog."default" NOT NULL,
    specialty_name character varying(256) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT specialty_pkey PRIMARY KEY (specialty_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.specialty
    OWNER to postgres;



--
-- Table: public.student
--
CREATE TABLE IF NOT EXISTS public.student
(
    student_id integer NOT NULL DEFAULT nextval('student_student_id_seq'::regclass),
    first_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    last_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    family_name character varying(64) COLLATE pg_catalog."default",
    study_form_id smallint NOT NULL,
    group_id smallint NOT NULL,
    CONSTRAINT student_pkey PRIMARY KEY (student_id),
    CONSTRAINT student__group_fkey FOREIGN KEY (group_id)
        REFERENCES public.student_group (group_id) MATCH FULL
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT student__study_form_fkey FOREIGN KEY (study_form_id)
        REFERENCES public.study_form (form_id) MATCH FULL
        ON UPDATE CASCADE
        ON DELETE SET NULL
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.student
    OWNER to postgres;



--
-- Table: public.study_form
--
CREATE TABLE IF NOT EXISTS public.study_form
(
    form_id smallint NOT NULL,
    form_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT study_form_pkey PRIMARY KEY (form_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.study_form
    OWNER to postgres;



--
-- Table: public.subject
--
CREATE TABLE IF NOT EXISTS public.subject
(
    subject_id integer NOT NULL DEFAULT nextval('subject_subject_id_seq'::regclass),
    specialty_id smallint NOT NULL,
    subject_name character varying(256) COLLATE pg_catalog."default" NOT NULL,
    semester smallint NOT NULL,
    hours smallint,
    report_type_id smallint,
    CONSTRAINT subject_pkey PRIMARY KEY (subject_id),
    CONSTRAINT subject__report_type_fkey FOREIGN KEY (report_type_id)
        REFERENCES public.report_type (report_type_id) MATCH FULL
        ON UPDATE CASCADE
        ON DELETE SET NULL
        NOT VALID,
    CONSTRAINT subject__specialty_fkey FOREIGN KEY (specialty_id)
        REFERENCES public.specialty (specialty_id) MATCH FULL
        ON UPDATE CASCADE
        ON DELETE SET NULL
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.subject
    OWNER to postgres;
