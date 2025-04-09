-- Создание таблицы "Параметры" (Классификатор Перечислений).
CREATE TABLE public."Parameter"
(
    id serial NOT NULL,
    name character varying(128) NOT NULL,
    description text,
    parent_id integer,
    measure_id integer,
    CONSTRAINT parameter_id PRIMARY KEY (id)
);

ALTER TABLE IF EXISTS public."Parameter"
    OWNER to postgres;

ALTER TABLE IF EXISTS public."Parameter"
    ADD CONSTRAINT parameter_parent_id FOREIGN KEY (parent_id)
    REFERENCES public."Parameter" (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;
ALTER TABLE IF EXISTS public."Parameter"
    ADD CONSTRAINT parameter_measure_id FOREIGN KEY (measure_id)
    REFERENCES public."Measure" (id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

-- Создание таблицы "Изделие-Параметр" (Пары изделий и перечислений).
CREATE TABLE public."ProductParam"
(
    product_id integer NOT NULL,
    parameter_id integer NOT NULL,
    value character varying(255) NOT NULL,
    priority smallint DEFAULT -1,
    CONSTRAINT product_parameter_id PRIMARY KEY (product_id, parameter_id),
    CONSTRAINT productparam_product_id FOREIGN KEY (product_id)
        REFERENCES public."Product" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT productparam_parameter_id FOREIGN KEY (parameter_id)
        REFERENCES public."Parameter" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

ALTER TABLE IF EXISTS public."ProductParam"
    OWNER to postgres;
