-- 1. Очистка таблиц.
TRUNCATE TABLE "Product", "Category", "Measure" RESTART IDENTITY CASCADE;

-- 2. Заполнение таблиц.
DO
$$
DECLARE
    root_id integer;
    anker_id integer;
    anker_metal_id integer;
    anker_clin_id integer;
    clinch_id integer;
    clinch_hammer_id integer;
    clinch_vent_id integer;
    length_id integer;
    length_of_head_id integer;
BEGIN
    RAISE NOTICE '=== ЗАПОЛНЕНИЕ ТАБЛИЦ ===';

    -- Заполнение таблицы единиц измерения.
    PERFORM create_measure('Штука', 'шт');  -- По умолчанию.
    PERFORM create_measure('Метр', 'м');
    PERFORM create_measure('Миллиметр', 'мм');
    PERFORM create_measure('Сантиметр', 'см');
    PERFORM create_measure('Килограмм', 'кг');
    PERFORM create_measure('Грамм', 'г');

    -- Заполнение иерархии категорий и изделий.
    SELECT create_category('Крепёжные изделия', NULL, 1) INTO root_id;


    SELECT create_category('Анкеры', root_id, 1) INTO anker_id;
    SELECT create_category('Анкеры металлические', anker_id, 1) INTO anker_metal_id;
    PERFORM create_product('Анкер металлический Sormat S-CSA I', anker_metal_id);
    PERFORM create_product('Анкер металлический Sormat S_csa HEX', anker_metal_id);
    SELECT create_category('Анкеры клиновые', anker_id, 1) INTO anker_clin_id;
    PERFORM create_product('Анкер клиновой с гайкой Sormat S-KAH', anker_clin_id);
    PERFORM create_product('Анкер клиновой с гайкой Sormat S-KAH HCR', anker_clin_id);

    SELECT create_category('Заклёпки', root_id, 1) INTO clinch_id;
    SELECT create_category('Заклёпки под молоток', clinch_id, 1) INTO clinch_hammer_id;
    PERFORM create_product('DIN 660 Заклёпка под молоток с полукруглой головкой', clinch_hammer_id);
    PERFORM create_product('DIN 661 Заклёпка под молоток с потайной головкой', clinch_hammer_id);
    SELECT create_category('Заклёпки вытяжные', clinch_id, 1) INTO clinch_vent_id;
    PERFORM create_product('DIN 7377 Заклёпка вытяжная стальная, нержавеющая', clinch_vent_id);
    PERFORM create_product('Заклёпка вытяжная (тяговая) алюминиевая с потайным буртиком AL/AL', clinch_vent_id);

    -- Заполнение иерархии параметров.
    SELECT create_parameter('Длина', '', NULL, 3) INTO length_id;
    SELECT create_parameter('Длина головки', '', length_id, 3) INTO length_of_head_id;

    -- Заполнение параметров изделий.
    PERFORM create_product_param(4, length_id, CAST(10000 AS character varying), 1);
    PERFORM create_product_param(4, length_of_head_id, CAST(1000 AS character varying), 2);
    PERFORM create_product_param(5, length_of_head_id, CAST(10000 AS character varying), 1);

    RAISE NOTICE '=== ЗАПОЛНЕНИЕ ТАБЛИЦ ЗАВЕРШЕНО ===';
END
$$;

-- 3. Функции удаления.
DO
$$
DECLARE
    deleted_name character varying;
BEGIN
    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ УДАЛЕНИЯ ===';

    -- Тест удаления параметра.
    PERFORM create_parameter('Тестовый параметр', 'Тестовое описание', NULL, 1);
    SELECT name INTO deleted_name FROM "Parameter" WHERE id = 3;
    PERFORM delete_parameter(3);
    IF NOT EXISTS (SELECT 1 FROM "Product" WHERE id = 3) THEN
        RAISE NOTICE 'PASS | Удаление параметра: %', deleted_name;
    ELSE
        RAISE NOTICE 'FAIL | Удаление параметра: %', deleted_name;
    END IF;

    -- Тест удаления параметра с подкатегориями (должно вызвать ошибку).
    BEGIN
        PERFORM delete_parameter(1);
        RAISE NOTICE 'FAIL | Удаление категории с подкатегориями';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PASS | Удаление категории с подкатегориями: %', SQLERRM;
    END;

    -- Тест удаления параметра изделия.
    PERFORM create_product_param(7, 2, '666');
    SELECT name INTO deleted_name FROM "Product" WHERE id = 7;
    PERFORM delete_product_param(7, 2);
    IF NOT EXISTS (SELECT 1 FROM "Product" WHERE id = 7) THEN
        RAISE NOTICE 'PASS | Удаление параметра у изделия: %', deleted_name;
    ELSE
        RAISE NOTICE 'FAIL | Удаление параметра у изделия: %', deleted_name;
    END IF;

    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ УДАЛЕНИЯ ЗАВЕРШЕНО ===';
END
$$;

-- 4. Функции обновления.
DO
$$
BEGIN
    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ ОБНОВЛЕНИЯ ===';

    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ ОБНОВЛЕНИЯ ЗАВЕРШЕНО ===';
END
$$;