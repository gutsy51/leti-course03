-- 1. Очистка таблиц.
TRUNCATE TABLE "Product", "Category", "Measure" RESTART IDENTITY CASCADE;

-- 2. Заполнение таблицы единиц измерения.
INSERT INTO "Measure" (name, name_short)
VALUES ('Штуки', 'шт'),
       ('Миллиметры', 'мм'),
       ('Граммы', 'г'),
       ('Сантиметры', 'см');

-- 4. Заполнение иерархии категорий и изделий
DO
$$
DECLARE
    root_id integer;
    cat1_id integer;
    cat2_id integer;
    cat3_id integer;
    cat4_id integer;
    cat5_id integer;
BEGIN
    -- Вставка в соответствие с примером из "Анализа предметной области".
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES ('Крепёжные изделия', NULL, 1)
    RETURNING id INTO root_id;
    
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES ('Анкеры', root_id, 1)
    RETURNING id INTO cat1_id;
    
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES ('Анкеры металлические', cat1_id, 1)
    RETURNING id INTO cat2_id;

    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'Анкер металлический Sormat S-CSA I',
        cat2_id,
        '{"diameter": 10, "length": 60, "material": "сталь", "coating": "цинковое"}'
    );
    
    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'Анкер металлический Sormat S-CSA HEX', 
        cat2_id,
        '{"diameter": 12, "length": 80, "material": "сталь", "coating": "цинковое"}'
    );
    
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES ('Анкеры клиновые', cat1_id, 1)
    RETURNING id INTO cat3_id;
    
    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'Анкер клиновой с гайкой Sormat S-KAH', 
        cat3_id,
        '{"diameter": 8, "length": 50, "material": "сталь", "coating": "оцинкованное"}'
    );
    
    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'Анкер клиновой с гайкой Sormat S-KAH HCR', 
        cat3_id,
        '{"diameter": 10, "length": 60, "material": "нержавеющая сталь"}'
    );
    
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES ('Заклёпки', root_id, 1)
    RETURNING id INTO cat4_id;
    
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES ('Заклёпка под молоток', cat4_id, 1)
    RETURNING id INTO cat5_id;
    
    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'DIN 660 Заклёпка под молоток с полукруглой головкой', 
        cat5_id,
        '{"standard": "DIN 660", "diameter": 3, "length": 10, "material": "сталь"}'
    );
    
    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'DIN 661 Заклёпка под молоток с потайной головкой', 
        cat5_id,
        '{"standard": "DIN 661", "diameter": 4, "length": 12, "material": "сталь"}'
    );
    
    INSERT INTO "Category" (name, parent_id, measure_id)
    VALUES ('Заклёпка вытяжная', cat4_id, 1)
    RETURNING id INTO cat5_id;
    
    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'DIN 7337 Заклёпка вытяжная стальная, нержавеющая', 
        cat5_id,
        '{"standard": "DIN 7337", "diameter": 3.2, "length": 8, "material": "нержавеющая сталь"}'
    );
    
    INSERT INTO "Product" (name, category_id, properties)
    VALUES (
        'Заклёпка вытяжная (тяговая) алюминиевая с потайным буртиком AL/AL', 
        cat5_id,
        '{"diameter": 4, "length": 10, "material": "алюминий"}'
    );
END
$$;

-- 4. Функции удаления.
DO
$$
DECLARE
    deleted_name character varying;
BEGIN
    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ УДАЛЕНИЯ ===';
    
    -- Тест удаления изделия.
    SELECT name INTO deleted_name FROM "Product" WHERE id = 4;
    PERFORM delete_product(4);
    RAISE NOTICE 'Удалено изделие: %', deleted_name;
    IF NOT EXISTS (SELECT 1 FROM "Product" WHERE id = 4) THEN
        RAISE NOTICE 'Тест удаления изделия пройден успешно';
    END IF;
    
    -- Тест удаления категории (должно вызвать ошибку, так как есть подкатегории).
    BEGIN
        PERFORM delete_category(2);
        RAISE NOTICE 'ОШИБКА: удаление категории с подкатегориями не вызвало исключения';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Тест защиты от удаления категории с подкатегориями пройден: %', SQLERRM;
    END;
END
$$;

-- 5. Функции вставки.
DO
$$
DECLARE
    new_id integer;
BEGIN
    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ ВСТАВКИ ===';
    
    -- Тест создания категории.
    SELECT create_category('Тестовая категория', 1) INTO new_id;
    RAISE NOTICE 'Создана категория с ID: %', new_id;
    
    -- Тест создания изделия.
    SELECT create_product('Тестовое изделие', new_id, '{"test": true}'::jsonb) INTO new_id;
    RAISE NOTICE 'Создано изделие с ID: %', new_id;
    
    -- Тест создания единицы измерения.
    SELECT create_measure('Тестовая единица', 'тест') INTO new_id;
    RAISE NOTICE 'Создана единица измерения с ID: %', new_id;
    
    -- Тест защиты от дублирования имен категорий.
    BEGIN
        PERFORM create_category('Анкеры', 1);
        RAISE NOTICE 'ОШИБКА: создание дубликата категории не вызвало исключения';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Тест защиты от дубликатов категорий пройден: %', SQLERRM;
    END;
END
$$;

-- 6. Тестирование функций поиска.
DO
$$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ФУНКЦИЙ ПОИСКА ===';

    -- Поиск всех потомков категории "Крепёжные изделия" (ID=1).
    RAISE NOTICE 'Потомки категории "Крепёжные изделия":';
    FOR rec IN SELECT * FROM get_all_children(1) LOOP
        RAISE NOTICE 'Уровень %: % (ID:%)', rec.depth_level, rec.child_name, rec.child_id;
    END LOOP;

    -- Поиск всех родителей для CategoryID=6.
    RAISE NOTICE 'Родители категории "Анкеры клиновые" (ID=6):';
    FOR rec IN SELECT * FROM get_all_parents(6) LOOP
        RAISE NOTICE 'Уровень %: % (ID:%)', rec.depth_level, rec.parent_name, rec.parent_id;
    END LOOP;

    -- Поиск терминальных категорий для "Крепёжные изделия".
    RAISE NOTICE 'Терминальные категории в поддереве "Крепёжные изделия":';
    FOR rec IN SELECT * FROM get_terminal_categories(1) LOOP
        RAISE NOTICE 'Уровень %: % (ID:%)', rec.term_depth, rec.term_name, rec.term_id;
    END LOOP;
END $$;

-- 7. Проверка целостности данных после всех операций.
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

    RAISE NOTICE '=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===';
END
$$;
