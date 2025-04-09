/* ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ */

-- Проверка наличия цикла в иерархии обновляемого параметра.
/* Проверяет наличие цикла в иерархии обновляемого параметра.
    Вход:
        p_child_id (integer): ID вставляемого параметра,
        p_parent_id (integer): ID родительского параметра.
    Выход:
        void: Отсутствует.
    Эффекты:
        Вызывает ошибку при обнаружении цикла.
    Требования:
        Параметры (вставляемый и родительский) должны быть различны.
*/
CREATE OR REPLACE FUNCTION check_parameter_cycle(
    p_child_id integer,
    p_parent_id integer
) RETURNS void AS
$$
DECLARE
    is_cycle boolean;
BEGIN
    IF p_child_id = p_parent_id THEN
        RAISE EXCEPTION 'Параметр не может быть родителем самого себя.';
    END IF;

    WITH RECURSIVE parameter_hierarchy AS (
        SELECT id, parent_id FROM "Parameter" WHERE id = p_parent_id
        UNION ALL
        SELECT c.id, c.parent_id
        FROM "Parameter" c
        JOIN parameter_hierarchy ch ON c.id = ch.parent_id
    )
    SELECT EXISTS (SELECT 1 FROM parameter_hierarchy WHERE id = p_child_id) INTO is_cycle;

    IF is_cycle THEN
        RAISE EXCEPTION 'Обнаружен цикл в иерархии параметра.';
    END IF;
END;
$$ LANGUAGE plpgsql;



/* ФУНКЦИИ СОЗДАНИЯ ЗАПИСЕЙ */

-- Создать новую запись в таблице Параметры.
/* Создаёт новую запись в таблице Параметры, возвращает ID новой записи.
    Вход:
        p_name (character varying(128)): Название параметра,
        p_description (text): Описание параметра (необязательный),
        p_parent_id (integer): ID родительского параметра (необязательный),
        p_measure_id (integer): ID единицы измерения.
    Выход:
        integer: ID новой записи.
    Эффекты:
        Добавление нового Параметра в таблицу Параметры,
        Вызов ошибки, если единицы измерения не существует,
        Вызов ошибки, если параметр уже существует,
        Вызов ошибки, если родительский параметр не существует,
        Возврат ID новой записи.
    Требования:
        Параметр не должен существовать,
        Единица измерения должна существовать,
        Родительский параметр должен существовать,
*/
CREATE OR REPLACE FUNCTION public.create_parameter(
    p_name character varying(128),
    p_description text DEFAULT NULL,
    p_parent_id integer DEFAULT NULL,
    p_measure_id integer DEFAULT NULL
) RETURNS integer AS
$$
DECLARE
    new_id integer;
BEGIN
    -- Проверка единицы измерения.
    IF p_measure_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public."Measure" WHERE id = p_measure_id) THEN
        RAISE EXCEPTION 'Единица измерения с ID % не существует', p_measure_id;
    END IF;

    -- Создание параметра.
    INSERT INTO public."Parameter" (name, description, parent_id, measure_id)
    VALUES (p_name, p_description, p_parent_id, p_measure_id)
    RETURNING id INTO new_id;

    RETURN new_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Параметр с таким именем уже существует в данной родительской группе';
END;
$$ LANGUAGE plpgsql;

-- Добавление новой записи в таблицу Изделие-Параметр.
/* Создаёт новую запись в таблице Изделие-Параметр, возвращает ID новой записи.
    Вход:
        p_product_id (integer): ID изделия,
        p_parameter_id (integer): ID параметра,
        p_value (character varying(128)): Значение параметра,
        p_priority (integer): Приоритет (необязательный).
    Выход:
        void: Отсутствует.
    Эффекты:
        Добавление новой пары Изделие-Параметр в таблицу,
        Вызов ошибки, если пара существует,
        Вызов ошибки, если параметра не существует,
        Вызов ошибки, если изделия не существует,
        Возврат ID новой записи.
    Требования:
        Пара должна быть уникальной,
        Параметр должен существовать,
        Изделие должно существовать.
*/
CREATE OR REPLACE FUNCTION create_product_param(
    p_product_id integer,
    p_parameter_id integer,
    p_value character varying(255),
    p_priority integer DEFAULT -1
) RETURNS void AS
$$
BEGIN
    -- Проверка существования изделия.
    IF NOT EXISTS (SELECT 1 FROM public."Product" WHERE id = p_product_id) THEN
        RAISE EXCEPTION 'Изделие с ID % не найдено', p_product_id;
    END IF;

    -- Проверка существования параметра.
    IF NOT EXISTS (SELECT 1 FROM public."Parameter" WHERE id = p_parameter_id) THEN
        RAISE EXCEPTION 'Параметр с ID % не найден', p_parameter_id;
    END IF;

    -- Вставка значения параметра
    INSERT INTO public."ProductParam" (product_id, parameter_id, value, priority)
    VALUES (p_product_id, p_parameter_id, p_value, p_priority);
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Этот параметр уже задан для данного изделия';
END;
$$ LANGUAGE plpgsql;



/* ФУНКЦИИ УДАЛЕНИЯ ЗАПИСЕЙ */

-- Удаление записи из таблицы Изделие-Параметр.
/* Удаляет запись из таблицы Параметры.
    Вход:
        p_id (integer): ID удаляемой записи.
    Выход:
        void: Отсутствует.
    Эффекты:
        Удаление записи из таблицы Параметры,
        Вызов ошибки, если Параметр не существует,
        Вызов ошибки, если есть дочерние Параметры,
        Вызов ошибки, если есть записи в таблице Изделие-Параметр.
    Требования:,
        Параметр должен существовать,
        Не должно быть дочерних элементов.
*/
CREATE OR REPLACE FUNCTION delete_parameter(
    p_id integer
) RETURNS void AS
$$
DECLARE
    has_children bool;
    has_product_params bool;
    param_name character varying;
BEGIN
    -- Проверка существования параметра.
    SELECT name INTO param_name FROM public."Parameter" WHERE id = p_id;
    IF param_name IS NULL THEN
        RAISE EXCEPTION 'Параметр с ID % не найден', p_id;
    END IF;

    -- Проверка на наличие дочерних параметров.
    SELECT EXISTS (
        SELECT 1 FROM public."Parameter" WHERE parent_id = p_id
    ) INTO has_children;
    IF has_children THEN
        RAISE EXCEPTION 'Нельзя удалить параметр "%" (ID %): существуют дочерние параметры', param_name, p_id;
    END IF;

    -- Проверка на использование в изделиях.
    SELECT EXISTS (
        SELECT 1 FROM public."ProductParam" WHERE parameter_id = p_id
    ) INTO has_product_params;
    IF has_product_params THEN
        RAISE EXCEPTION 'Нельзя удалить параметр "%" (ID %): он используется в изделиях', param_name, p_id;
    END IF;

    -- Удаление параметра.
    DELETE FROM public."Parameter" WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Удаление записи из таблицы Изделие-Параметр.
/* Удаляет запись из таблицы Изделие-Параметр.
    Вход:
        p_id (integer): ID удаляемой записи.
    Выход:
        void: Отсутствует.
    Эффекты:
        Удаление записи из таблицы Изделие-Параметр,
        Вызов ошибки, если записи не существует.
    Требования:,
        Пара должна существовать.
*/
CREATE OR REPLACE FUNCTION delete_product_param(
    p_product_id integer,
    p_parameter_id integer
) RETURNS void AS
$$
DECLARE
    product_name character varying;
    param_name character varying;
BEGIN
    -- Получаем названия для информационного сообщения.
    SELECT p.name, pr.name
    INTO product_name, param_name
    FROM public."Product" p, public."Parameter" pr
    WHERE p.id = p_product_id AND pr.id = p_parameter_id;

    -- Проверка существования изделия.
    IF product_name IS NULL THEN
        RAISE EXCEPTION 'Изделие с ID % не найдено', p_product_id;
    END IF;

    -- Проверка существования параметра.
    IF param_name IS NULL THEN
        RAISE EXCEPTION 'Параметр с ID % не найден', p_parameter_id;
    END IF;

    -- Удаление связи.
    DELETE FROM public."ProductParam"
    WHERE product_id = p_product_id
    AND parameter_id = p_parameter_id;

    -- Проверка, что связь удалена (существовала).
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Связь между изделием "%" (ID %) и параметром "%" (ID %) не найдена',
            product_name, p_product_id, param_name, p_parameter_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


/* ФУНКЦИИ ОБНОВЛЕНИЯ ЗАПИСЕЙ */

-- Обновление записи в таблице Параметры.
/* Обновляет запись в таблице Параметры.
    Вход:
        p_id (integer): ID обновляемой записи,
        p_name (character varying(128)): Название параметра (необязательный),
        p_description (text): Описание параметра (необязательный),
        p_parent_id (integer): ID родительского параметра (необязательный),
        p_measure_id (integer): ID единицы измерения (необязательный).
    Выход:
        void: Отсутствует.
    Эффекты:
        Обновление записи,
        Вызов ошибки, если единицы измерения не существует,
        Вызов ошибки, если параметр не существует,
        Вызов ошибки, если родительский параметр не существует,
    Требования:
        Параметр должен существовать,
        Единица измерения должна существовать,
        Родительский параметр должен существовать,
*/
CREATE OR REPLACE FUNCTION update_parameter(
    p_id integer,
    p_name character varying(128) DEFAULT NULL,
    p_description text DEFAULT NULL,
    p_parent_id integer DEFAULT NULL,
    p_measure_id integer DEFAULT NULL
)
RETURNS void AS
$$
DECLARE
    current_record record;
BEGIN
    -- Получаем текущие данные параметра.
    SELECT * INTO current_record FROM public."Parameter" WHERE id = p_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Параметр с ID % не найден', p_id;
    END IF;

    -- Проверка существования родительского параметра.
    IF p_parent_id IS NOT NULL THEN
        PERFORM check_parameter_cycle(p_id, p_parent_id);
    END IF;

    -- Проверка существования единицы измерения.
    IF p_measure_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public."Measure" WHERE id = p_measure_id) THEN
        RAISE EXCEPTION 'Единица измерения с ID % не существует', p_measure_id;
    END IF;

    -- Обновление данных.
    UPDATE public."Parameter" SET
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        parent_id = COALESCE(p_parent_id, parent_id),
        measure_id = COALESCE(p_measure_id, measure_id)
    WHERE id = p_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Параметр с таким именем уже существует в данной родительской группе';
END;
$$ LANGUAGE plpgsql;

-- Обновление записи в таблице Изделие-Параметр.
/* Обновляет запись в таблице Изделие-Параметр.
    Вход:
        p_product_id (integer): ID изделия,
        p_parameter_id (integer): ID параметра,
        p_value (character varying(255)): Значение параметра (необязательный),
        p_priority (integer): Приоритет (необязательный).
    Выход:
        void: Отсутствует.
    Эффекты:
        Обновление записи,
        Вызов ошибки, если пара не существует.
    Требования:
        Пара должна существовать,
*/
CREATE OR REPLACE FUNCTION public.update_product_param(
    p_product_id integer,
    p_parameter_id integer,
    p_value character varying(255) DEFAULT NULL,
    p_priority integer DEFAULT NULL
)
RETURNS void AS
$$
BEGIN
    -- Проверка существования связи.
    IF NOT EXISTS (
        SELECT 1 FROM public."ProductParam"
        WHERE product_id = p_product_id AND parameter_id = p_parameter_id
    ) THEN
        RAISE EXCEPTION 'Связь между изделием % и параметром % не найдена',
            p_product_id, p_parameter_id;
    END IF;

    -- Обновление данных.
    UPDATE public."ProductParam" SET
        value = COALESCE(p_value, value),
        priority = COALESCE(p_priority, priority)
    WHERE product_id = p_product_id AND parameter_id = p_parameter_id;
END;
$$ LANGUAGE plpgsql;



/* ФУНКЦИИ ПОИСКА ЗАПИСЕЙ */

-- Поиск записей в таблице Параметры.
/* Возвращает все дочерние параметры по идентификатору родительского
    Вход:
        p_parent_id (integer): ID родительского параметра,
    Выход:
        TABLE: Таблица дочерних параметров.
*/
CREATE OR REPLACE FUNCTION get_child_parameters(
    p_parent_id integer
) RETURNS TABLE(
    id integer,
    name character varying(128),
    description text,
    measure_id integer,
    measure_name character varying(64),
    measure_short character varying(16)
) AS
$$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, p.description, p.measure_id, m.name AS measure_name, m.name_short AS measure_short
    FROM public."Parameter" p
    LEFT JOIN public."Measure" m ON p.measure_id = m.id
    WHERE p.parent_id = p_parent_id
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Поиск записей в таблице Изделие-Параметр.
/* Возвращает все значения параметров */
CREATE OR REPLACE FUNCTION get_all_products_parameters()
RETURNS TABLE(
    product_id integer,
    product_name character varying(128),
    parameter_id integer,
    parameter_name character varying(128),
    value character varying(255),
    priority smallint,
    measure_id integer,
    measure_name character varying(64),
    measure_short character varying(16)
) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        pp.product_id,
        pr.name AS product_name,
        pp.parameter_id,
        p.name AS parameter_name,
        pp.value,
        pp.priority,
        p.measure_id,
        m.name AS measure_name,
        m.name_short AS measure_short
    FROM public."ProductParam" pp
    JOIN public."Product" pr ON pp.product_id = pr.id
    JOIN public."Parameter" p ON pp.parameter_id = p.id
    LEFT JOIN public."Measure" m ON p.measure_id = m.id
    ORDER BY pr.name, pp.priority, p.name;
END;
$$ LANGUAGE plpgsql;

-- Поиск записей в таблице Изделие-Параметр.
/* Возвращает все значения параметров заданного изделия
    Вход:
        p_product_id (integer): ID изделия,
    Выход:
        TABLE: Таблица значений параметров.
*/
CREATE OR REPLACE FUNCTION get_product_parameters(
    p_product_id integer
) RETURNS TABLE(
    parameter_id integer,
    parameter_name character varying(128),
    value character varying(255),
    priority smallint,
    measure_id integer,
    measure_name character varying(64),
    measure_short character varying(16),
    description text
) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        pp.parameter_id,
        p.name AS parameter_name,
        pp.value,
        pp.priority,
        p.measure_id,
        m.name AS measure_name,
        m.name_short AS measure_short,
        p.description
    FROM public."ProductParam" pp
    JOIN public."Parameter" p ON pp.parameter_id = p.id
    LEFT JOIN public."Measure" m ON p.measure_id = m.id
    WHERE pp.product_id = p_product_id
    ORDER BY pp.priority, p.name;
END;
$$ LANGUAGE plpgsql;