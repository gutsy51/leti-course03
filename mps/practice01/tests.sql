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
    
    -- Тест удаления изделия.
    SELECT name INTO deleted_name FROM "Product" WHERE id=4;
    PERFORM delete_product(4);
    IF NOT EXISTS (SELECT 1 FROM "Product" WHERE id = 4) THEN
        RAISE NOTICE 'PASS | Удаление изделия: %', deleted_name;
    ELSE
        RAISE NOTICE 'FAIL | Удаление изделия: %', deleted_name;
    END IF;
    
    -- Тест удаления категории (должно вызвать ошибку, так как есть подкатегории).
    BEGIN
        PERFORM delete_category(2);
        RAISE NOTICE 'FAIL | Удаление категории с подкатегориями';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PASS | Удаление категории с подкатегориями: %', SQLERRM;
    END;

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


-- 5. Проверка целостности данных после всех операций.
DO
$$
BEGIN
    RAISE NOTICE '=== ПРОВЕРКА ЦЕЛОСТНОСТИ ДАННЫХ ===';

    -- Проверка ссылочной целостности.
    IF NOT EXISTS (
        SELECT 1 FROM "Category" c
        LEFT JOIN "Category" p ON c.parent_id = p.id
        WHERE c.parent_id IS NOT NULL AND p.id IS NULL
    ) THEN
        RAISE NOTICE 'Все ссылки на родительские категории корректны';
    END IF;

    -- Проверка изделий без категорий.
    IF NOT EXISTS (
        SELECT 1 FROM "Product" p
        LEFT JOIN "Category" c ON p.category_id = c.id
        WHERE c.id IS NULL
    ) THEN
        RAISE NOTICE 'Все изделия имеют корректные ссылки на категории';
    END IF;

    RAISE NOTICE '=== ПРОВЕРКА ЦЕЛОСТНОСТИ ДАННЫХ ЗАВЕРШЕНА ===';
END
$$;

-- 6. Тестирование функций поиска.
DO
$$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ ПОИСКА ===';

    RAISE NOTICE 'Все дочерние элементы "Крепёжные изделия":';
    FOR rec IN SELECT * FROM get_all_descendants(1) LOOP
        RAISE NOTICE 'Уровень % [is_cat=%]: % (ID:%, Parent:%)',
            rec.depth,
            rec.is_category,
            rec.name,
            rec.id,
            rec.parent_id;
    END LOOP;

    RAISE NOTICE '---';
    RAISE NOTICE 'Все родительские элементы "Анкеры клиновые:';
    FOR rec IN SELECT * FROM get_all_parents(6) LOOP
        RAISE NOTICE 'Уровень %: % (ID:%)',
            rec.depth_level,
            rec.parent_name,
            rec.parent_id;
    END LOOP;

    RAISE NOTICE '---';
    RAISE NOTICE 'Все терминальные дочерние элементы "Анкеры"';
    FOR rec IN SELECT * FROM get_terminal_categories(2) LOOP
        RAISE NOTICE 'Уровень %: % (ID:%)',
            rec.term_depth,
            rec.term_name,
            rec.term_id;
    END LOOP;

    RAISE NOTICE '---';
    RAISE NOTICE 'Все дочерние категории "Крепежные изделия"';
    FOR rec IN SELECT * FROM get_all_descendants(1) WHERE is_category = true LOOP
        RAISE NOTICE 'Уровень %: % (ID:%, Parent:%)',
            rec.depth,
            rec.name,
            rec.id,
            rec.parent_id;
    END LOOP;

    RAISE NOTICE '---';
    RAISE NOTICE 'Все дочерние изделия "Крепежные изделия"';
    FOR rec IN SELECT * FROM get_all_descendants(1) WHERE is_category = false LOOP
        RAISE NOTICE 'Уровень %: % (ID:%, Category:%)',
            rec.depth,
            rec.name,
            rec.id,
            rec.parent_id;
    END LOOP;

    RAISE NOTICE '---';
    RAISE NOTICE 'Все дочерние элементы "Заклёпки';
    FOR rec IN SELECT * FROM get_all_descendants(9) LOOP
        RAISE NOTICE 'Уровень % [is_cat=%]: % (ID:%, Parent:%)',
            rec.depth,
            rec.is_category,
            rec.name,
            rec.id,
            rec.parent_id;
    END LOOP;

    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ ПОИСКА ЗАВЕРШЕНО ===';
END
$$;