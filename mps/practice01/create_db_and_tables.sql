-- Создание базы данных.
CREATE DATABASE "2372_mps_classifier"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = 'libc'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


-- Создание последовательности для ID Категорий и Изделий.
-- Используем отдельную последовательность, ведь по примеру ID должен быть обще-инкрементным.
CREATE SEQUENCE public."Category_Product_id_seq";

ALTER SEQUENCE public."Category_Product_id_seq"
    OWNER TO postgres;


-- Создание таблицы "Единицы измерения".
CREATE TABLE public."Measure"
(
    id integer NOT NULL DEFAULT nextval('"Category_Product_id_seq"'::regclass),
    name character varying(64) NOT NULL,
    name_short character varying(16) NOT NULL,
    CONSTRAINT measure_id PRIMARY KEY (id),
    CONSTRAINT uq_measure_name UNIQUE (name),
    CONSTRAINT uq_measure_name_short UNIQUE (name_short)
);

ALTER TABLE IF EXISTS public."Measure"
    OWNER to postgres;


-- Создание таблицы "Категории".
CREATE TABLE public."Category"
(
    id serial NOT NULL,
    name character varying(128) NOT NULL,
    parent_id integer,
    measure_id integer DEFAULT 1,
    CONSTRAINT category_id PRIMARY KEY (id),
    CONSTRAINT uq_category_name UNIQUE (name),
    CONSTRAINT category_measure_id FOREIGN KEY (measure_id)
        REFERENCES public."Measure" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE SET DEFAULT
);

ALTER TABLE IF EXISTS public."Category"
    OWNER to postgres;

ALTER TABLE IF EXISTS public."Category"
    ADD CONSTRAINT category_parent_id FOREIGN KEY (parent_id)
    REFERENCES public."Category" (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;


-- Создание таблицы "Изделия".
CREATE TABLE public."Product"
(
    id integer NOT NULL DEFAULT nextval('"Category_Product_id_seq"'),
    category_id integer NOT NULL,
    name character varying(128) NOT NULL,
    CONSTRAINT product_id PRIMARY KEY (id),
    CONSTRAINT product_category_id FOREIGN KEY (category_id)
        REFERENCES public."Category" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

ALTER TABLE IF EXISTS public."Product"
    OWNER to postgres;
