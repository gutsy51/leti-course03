/* ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ */

-- Проверка наличия цикла в иерархии категории.
/* Проверяет наличие цикла в иерархии вставляемой категории.
    Вход:
        p_child_id (integer): ID вставляемой категории,
        p_parent_id (integer): ID родительской категории.
    Выход:
        void: Отсутствует.
    Эффекты:
        Вызывает ошибку при обнаружении цикла.
    Требования:
        Категории вставляемой и родительской категории должны быть различны.
*/
CREATE OR REPLACE FUNCTION check_category_cycle(
    p_child_id integer,
    p_parent_id integer
) RETURNS void AS
$$
DECLARE
    is_cycle boolean;
BEGIN
    IF p_child_id = p_parent_id THEN
        RAISE EXCEPTION 'Категория не может быть родителем самой себя';
    END IF;

    WITH RECURSIVE category_hierarchy AS (
        SELECT id, parent_id FROM "Category" WHERE id = p_parent_id
        UNION ALL
        SELECT c.id, c.parent_id
        FROM "Category" c
        JOIN category_hierarchy ch ON c.id = ch.parent_id
    )
    SELECT EXISTS (SELECT 1 FROM category_hierarchy WHERE id = p_child_id) INTO is_cycle;

    IF is_cycle THEN
        RAISE EXCEPTION 'Обнаружен цикл в иерархии категории';
    END IF;
END;
$$ LANGUAGE plpgsql;



/* ФУНКЦИИ СОЗДАНИЯ ЗАПИСЕЙ */

-- Создать новую запись в таблице Единицы измерения.
/* Добавляет новую запись в таблицу Единицы измерения, возвращает ID новой записи.
    Вход:
        p_name (character varying(64)): Название единицы измерения,
        p_name_short (character varying(16)): Сокращение единицы измерения.
    Выход:
        integer: ID новой записи.
    Эффекты:
        Добавление новой ЕИ в таблицу Единицы измерения,
        Вызов ошибки, если ЕИ с таким названием или сокращением уже существует,
        Возврат ID новой записи.
    Требования:
        ЕИ не должна ранее существовать.
*/
CREATE OR REPLACE FUNCTION create_measure(
    p_name character varying(64),
    p_name_short character varying(16)
) RETURNS integer AS
$$
DECLARE
    new_id integer;
BEGIN
    INSERT INTO "Measure" (name, name_short)
    VALUES (p_name, p_name_short)
    RETURNING id INTO new_id;

    RETURN new_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Единица измерения с таким названием или сокращением уже существует';
END;
$$ LANGUAGE plpgsql;


-- Создать новую запись в таблице Категории.
/* Добавляет новую запись в таблицу Категории, возвращает ID новой записи.
    Вход:
        p_name (character varying(128)): Название категории,
        p_parent_id (integer): ID родительской категории (необязательный),
        p_measure_id (integer): ID единицы измерения (по умолчанию 1 (штук)).
    Выход:
        integer: ID новой записи.
    Эффекты:
        Добавление новой Категории в таблицу Единицы измерения,
        Вызов ошибки, если родительской категории не существует,
        Вызов ошибки, если единицы измерения не существует,
        Вызов ошибки, если категория уже существует,
        Возврат ID новой записи.
    Требования:
        Родительская категория не должна ранее существовать,
        Единица измерения не должна ранее существовать,
        Категория не должна ранее существовать.
*/
CREATE OR REPLACE FUNCTION create_category(
    p_name character varying(128),
    p_parent_id integer DEFAULT NULL,
    p_measure_id integer DEFAULT 1
) RETURNS integer AS
$$
DECLARE
    new_id integer;
BEGIN
    -- Проверка существования родительской категории.
    IF p_parent_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "Category" WHERE id = p_parent_id
    ) THEN
        RAISE EXCEPTION 'Родительская категория с ID % не существует', p_parent_id;
    END IF;

    -- Проверка существования единицы измерения.
    IF NOT EXISTS (SELECT 1 FROM "Measure" WHERE id = p_measure_id) THEN
        RAISE EXCEPTION 'Единица измерения с ID % не существует', p_measure_id;
    END IF;

    -- Вставка.
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES (p_name, p_parent_id, p_measure_id)
    RETURNING id INTO new_id;

    RETURN new_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Категория с таким именем уже существует в данном родительском разделе';
END;
$$ LANGUAGE plpgsql;


-- Создать новую запись в таблице Изделия.
/* Добавляет новую запись в таблицу Изделия, возвращает ID новой записи.
    Вход:
        p_name (character varying(128)): Название изделия,
        p_category_id (integer): ID категории, в которую добавляется изделие.
    Выход:
        integer: ID новой записи.
    Эффекты:
        Добавление нового Изделия в таблицу Изделия,
        Вызов ошибки, если родительской категории не существует,
        Возврат ID новой записи.
    Требования:
        Родительская категория не должна ранее существовать,
*/
CREATE OR REPLACE FUNCTION create_product(
    p_name character varying(128),
    p_category_id integer
) RETURNS integer AS
$$
DECLARE
    new_id integer;
BEGIN
    -- Проверка существования категории.
    IF NOT EXISTS (SELECT 1 FROM "Category" WHERE id = p_category_id) THEN
        RAISE EXCEPTION 'Категория с ID % не существует', p_category_id;
    END IF;

    -- Вставка.
    INSERT INTO "Product" (name, category_id)
    VALUES (p_name, p_category_id)
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$ language plpgsql;



/* ФУНКЦИИ УДАЛЕНИЯ ЗАПИСЕЙ */

-- Удаление записи из таблицы Единицы измерения.
/* Удаляет существующую запись из таблицы Единицы измерения.
    Вход:
        p_id (integer): ID удаляемой записи.
    Выход:
        void: Отсутствует.
    Эффекты:
        Удаление записи из таблицы Единицы измерения,
        Вызов ошибки, если ЕИ не существует,
        Вызов ошибки, если ЕИ по умолчанию (id=1) не существует,
        Установка значения по умолчанию Категориям, использовавшим данную ЕИ.
    Требования:
        ЕИ должна существовать,
        ЕИ по умолчанию должна существовать,
*/
CREATE OR REPLACE FUNCTION delete_measure(
    p_id integer
) RETURNS void AS
$$
DECLARE
    is_used boolean;
BEGIN
    -- Проверка существования.
    IF NOT EXISTS (SELECT 1 FROM "Measure" WHERE id = p_id) THEN
        RAISE EXCEPTION 'Единица измерения с ID % не существует', p_id;
    END IF;

    -- Проверка существования ЕИ по умолчанию.
    IF NOT EXISTS (SELECT 1 FROM "Measure" WHERE id = 1) THEN
        RAISE EXCEPTION 'Единица измерения по умолчанию не существует';
    END IF;

    -- Используется ли ЕИ в категориях.
    SELECT EXISTS (
        SELECT 1 FROM "Category" WHERE measure_id = p_id
    ) INTO is_used;
    IF is_used THEN
        UPDATE "Category"
        SET measure_id = 1
        WHERE measure_id = p_id;
    END IF;

    -- Удаление
    DELETE FROM "Measure" WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Удаление записи из таблицы Категории.
/* Удаляет существующую запись из таблицы Категории.
    Вход:
        p_id (integer): ID удаляемой записи.
    Выход:
        void: Отсутствует.
    Эффекты:
        Удаление записи из таблицы Категории,
        Вызов ошибки, если Категория не существует,
        Вызов ошибки, если существуют дочерние Категории,
        Вызов ошибки, если существуют Изделия, принадлежащие данной Категории.
    Требования:
        Категория должна существовать,
        Категория не должна содержать дочерних,
        Категория не должна содержать изделий.
*/
CREATE OR REPLACE FUNCTION delete_category(
    p_id integer
) RETURNS void AS
$$
DECLARE
    has_children boolean;
    has_products boolean;
BEGIN
    -- Проверка существования.
    IF NOT EXISTS (SELECT 1 FROM "Category" WHERE id = p_id) THEN
        RAISE EXCEPTION 'Категория с ID % не найдена', p_id;
    END IF;

    -- Проверка на наличие дочерних категорий.
    SELECT EXISTS (
        SELECT 1 FROM "Category"
        WHERE parent_id = p_id
    ) INTO has_children;
    IF has_children THEN
        RAISE EXCEPTION 'Нельзя удалить категорию с ID %, так как она содержит подкатегории', p_id;
    END IF;

    -- Проверка на наличие изделий в категории.
    SELECT EXISTS (
        SELECT 1 FROM "Product"
        WHERE category_id = p_id
    ) INTO has_products;
    IF has_products THEN
        RAISE EXCEPTION 'Нельзя удалить категорию с ID %, так как она содержит изделия', p_id;
    END IF;

    -- Удаление.
    DELETE FROM "Category" WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Удаление записи из таблицы Изделия.
/* Удаляет существующую запись из таблицы Изделия.
    Вход:
        p_id (integer): ID удаляемой записи.
    Выход:
        void: Отсутствует.
    Эффекты:
        Удаление записи из таблицы Изделия,
        Вызов ошибки, если Изделия не существует,
    Требования:
        Изделие должно существовать,
*/
CREATE OR REPLACE FUNCTION delete_product(
    p_id integer
) RETURNS void AS
$$
BEGIN
    -- Проверка существования.
    IF NOT EXISTS (SELECT 1 FROM "Product" WHERE id = p_id) THEN
        RAISE EXCEPTION 'Продукт с ID % не найден', p_id;
    END IF;

    -- Удаление
    DELETE FROM "Product" WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;



/* ФУНКЦИИ ОБНОВЛЕНИЯ ЗАПИСЕЙ */

-- Обновление записи в таблице Единицы измерения.
/* Обновляет существующую запись в таблице Единицы измерения.
    Вход:
        p_id (integer): ID изменяемой записи,
        p_name (character varying(64)): Новое название,
        p_name_short (character varying(16)): Новое сокращение.
    Выход:
        void: Отсутствует.
    Эффекты:
        Обновление записи,
        Вызов ошибки, если запись не существует,
        Вызов ошибки, если запись с таким названием уже существует,
        Вызов ошибки, если запись с таким сокращением уже существует,
    Требования:
        Запись должна существовать,
        Обновленная запись не должна конфликтовать с существующими.
*/
CREATE OR REPLACE FUNCTION update_measure(
    p_id integer,
    p_name character varying(64) DEFAULT NULL,
    p_name_short character varying(16) DEFAULT NULL
) RETURNS void AS
$$
BEGIN
    -- Проверка существования единицы измерения.
    IF NOT EXISTS (SELECT 1 FROM "Measure" WHERE id = p_id) THEN
        RAISE EXCEPTION 'Единица измерения с ID % не найдена', p_id;
    END IF;

    -- Проверка уникальности нового имени.
    IF p_name IS NOT NULL AND EXISTS (
        SELECT 1 FROM "Measure"
        WHERE name = p_name AND id != p_id
    ) THEN
        RAISE EXCEPTION 'Единица измерения с названием "%" уже существует', p_name;
    END IF;

    -- Проверка уникальности нового сокращения.
    IF p_name_short IS NOT NULL AND EXISTS (
        SELECT 1 FROM "Measure"
        WHERE name_short = p_name_short AND id != p_id
    ) THEN
        RAISE EXCEPTION 'Единица измерения с сокращением "%" уже существует', p_name_short;
    END IF;

    -- Обновление данных.
    UPDATE "Measure" SET
        name = COALESCE(p_name, name),
        name_short = COALESCE(p_name_short, name_short)
    WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Обновление записи в таблице Категории.
/* Обновляет существующую запись в таблице Категории.
    Вход:
        p_id (integer): ID изменяемой записи,
        p_name (character varying(128)): Новое название,
        p_parent_id (integer): ID новой родительской категории,
        p_measure_id (integer): ID новой единицы измерения.
    Выход:
        void: Отсутствует.
    Эффекты:
        Обновление записи,
        Вызов ошибки, если запись не существует,
        Вызов ошибки, если новой ЕИ не существует,
        Вызов ошибки, если новая родительская категория создает цикл,
        Вызов ошибки, если новая родительская и изменяемая категория одинаковы,
        Вызов ошибки, если новой родительской категории не существует,
    Требования:
        Запись должна существовать,
        Изменяемая ЕИ должна существовать,
        Изменяемая родительская категория должна существовать,
        Изменяемая родительская категория не должна быть родителем самой себе,
        Изменяемая родительская категория не должна создавать циклов.
*/
CREATE OR REPLACE FUNCTION update_category(
    p_id integer,
    p_name character varying(128) DEFAULT NULL,
    p_parent_id integer DEFAULT NULL,
    p_measure_id integer DEFAULT NULL
) RETURNS void AS
$$
BEGIN
    -- Проверка существования категории.
    IF NOT EXISTS (SELECT 1 FROM "Category" WHERE id = p_id) THEN
        RAISE EXCEPTION 'Категория с ID % не найдена', p_id;
    END IF;

    -- Проверка существования новой единицы измерения
    IF p_measure_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM "Measure" WHERE id = p_measure_id) THEN
        RAISE EXCEPTION 'Единица измерения с ID % не существует', p_measure_id;
    END IF;

    -- Если меняется parent_id - проверка на циклы.
    IF p_parent_id IS NOT NULL THEN
        -- Категория не может быть родителем самой себя.
        IF p_id = p_parent_id THEN
            RAISE EXCEPTION 'Категория не может быть родителем самой себя';
        END IF;

        -- Проверка существования родительской категории.
        IF NOT EXISTS (SELECT 1 FROM "Category" WHERE id = p_parent_id) THEN
            RAISE EXCEPTION 'Родительская категория с ID % не существует', p_parent_id;
        END IF;

        -- Проверка циклов.
        PERFORM check_category_cycle(p_id, p_parent_id);
    END IF;

    -- Обновление данных.
    UPDATE "Category" SET
        name = COALESCE(p_name, name),
        parent_id = COALESCE(p_parent_id, parent_id),
        measure_id = COALESCE(p_measure_id, measure_id)
    WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Обновление записи в таблице Изделия.
/* Обновляет существующую запись в таблице Изделия.
    Вход:
        p_id (integer): ID изменяемой записи,
        p_name (character varying(128)): Новое название,
        p_category_id (integer): ID новой родительской категории,
    Выход:
        void: Отсутствует.
    Эффекты:
        Обновление записи,
        Вызов ошибки, если запись не существует,
        Вызов ошибки, если новой родительской категории не существует,
    Требования:
        Запись должна существовать,
        Родительская категория должна существовать
*/
CREATE OR REPLACE FUNCTION update_product(
    p_id integer,
    p_name character varying(128) DEFAULT NULL,
    p_category_id integer DEFAULT NULL
) RETURNS void AS
$$
BEGIN
    -- Проверка существования изделия.
    IF NOT EXISTS (SELECT 1 FROM "Product" WHERE id = p_id) THEN
        RAISE EXCEPTION 'Изделие с ID % не найдено', p_id;
    END IF;

    -- Проверка существования категории.
    IF p_category_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM "Category" WHERE id = p_category_id) THEN
        RAISE EXCEPTION 'Категория с ID % не существует', p_category_id;
    END IF;

    -- Обновление данных.
    UPDATE "Product" SET
        name = COALESCE(p_name, name),
        category_id = COALESCE(p_category_id, category_id)
    WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;



/* ФУНКЦИИ ПОИСКА ЗАПИСЕЙ */

-- Получение всех дочерних категорий.
/* Возвращает таблицу всех дочерних элементов (и категорий, и изделий) по идентификатору родительской.
    Вход:
        p_category_id (integer): ID родительской категории,
    Выход:
        TABLE: Таблица дочерних элементов.
*/
CREATE OR REPLACE FUNCTION get_all_descendants(
    p_category_id integer
) RETURNS TABLE(
    id integer,
    name character varying(128),
    is_category bool,
    parent_id integer,
    measure_id integer,
    depth integer
) AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE category_tree AS (
        -- Базовый случай: начальная категория.
        SELECT
            c.id,
            c.name,
            true AS is_category,
            c.parent_id,
            c.measure_id,
            0 AS depth
        FROM "Category" c
        WHERE c.id = p_category_id

        UNION ALL

        -- Рекурсивный случай: все дочерние категории.
        SELECT
            child.id,
            child.name,
            true AS is_category,
            child.parent_id,
            child.measure_id,
            parent.depth + 1
        FROM "Category" child
        JOIN category_tree parent ON child.parent_id = parent.id
    )
    -- Выбираем все дочерние категории (исключая исходную).
    SELECT
        ct.id,
        ct.name,
        ct.is_category,
        ct.parent_id,
        ct.measure_id,
        ct.depth
    FROM category_tree ct
    WHERE ct.depth > 0

    UNION ALL

    -- Добавляем все изделия для найденных категорий.
    SELECT
        p.id,
        p.name,
        false as is_category,
        p.category_id AS parent_id,
        NULL AS measure_id,
        ct.depth + 1 AS depth
    FROM "Product" p
    JOIN category_tree ct ON p.category_id = ct.id
    ORDER BY depth, is_category, name;
END;
$$ LANGUAGE plpgsql;

-- Получение всех родительских категорий.
/* Возвращает таблицу всех родительских категорий по идентификатору дочерней.
    Вход:
        p_category_id (integer): ID дочерней категории,
    Выход:
        TABLE: Таблица родительских категорий.
*/
CREATE OR REPLACE FUNCTION get_all_parents(
    p_category_id integer
)
RETURNS TABLE(
    parent_id integer,
    parent_name character varying(128),
    parent_parent_id integer,
    parent_measure_id integer,
    depth_level integer
) AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE category_path AS (
        -- Базовый случай: начальная категория.
        SELECT
            c.id,
            c.name,
            c.parent_id,
            c.measure_id,
            0 AS depth
        FROM "Category" c
        WHERE c.id = p_category_id

        UNION ALL

        -- Рекурсивный случай: все родительские категории.
        SELECT
            parent.id,
            parent.name,
            parent.parent_id,
            parent.measure_id,
            child.depth + 1
        FROM "Category" parent
        JOIN category_path child ON parent.id = child.parent_id
    )
    SELECT
        cp.id,
        cp.name,
        cp.parent_id,
        cp.measure_id,
        cp.depth
    FROM category_path cp
    WHERE cp.depth > 0
    ORDER BY cp.depth;
END;
$$ LANGUAGE plpgsql;

-- Поиск всех терминальных классов заданной категории.
/* Возвращает таблицу всех терминальных категорий по идентификатору родительской.
    Вход:
        p_category_id (integer): ID родительской категории,
    Выход:
        TABLE: Таблица терминальных категорий.
*/
CREATE OR REPLACE FUNCTION get_terminal_categories(
    p_category_id integer
)
RETURNS TABLE(
    term_id integer,
    term_name character varying(128),
    term_parent_id integer,
    term_measure_id integer,
    term_depth integer
) AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE category_tree AS (
        -- Базовый случай: начальная категория.
        SELECT
            c.id,
            c.name,
            c.parent_id,
            c.measure_id,
            0 AS depth
        FROM "Category" c
        WHERE c.id = p_category_id

        UNION ALL

        -- Рекурсивный случай: все дочерние категории.
        SELECT
            child.id,
            child.name,
            child.parent_id,
            child.measure_id,
            parent.depth + 1
        FROM "Category" child
        JOIN category_tree parent ON child.parent_id = parent.id
    )
    SELECT
        ct.id,
        ct.name,
        ct.parent_id,
        ct.measure_id,
        ct.depth
    FROM category_tree ct
    WHERE NOT EXISTS (
        SELECT 1 FROM "Category" c
        WHERE c.parent_id = ct.id
    ) AND ct.id != p_category_id
    ORDER BY ct.depth, ct.name;
END;
$$ LANGUAGE plpgsql;
