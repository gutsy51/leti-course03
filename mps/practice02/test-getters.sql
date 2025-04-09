-- 5. Тестирование функций поиска.
SELECT * FROM "Measure";
SELECT * FROM "Category";
SELECT * FROM "Product";
SELECT * FROM "Parameter";
SELECT * FROM "ProductParam";


SELECT * FROM get_child_parameters(1);

SELECT * FROM get_all_products_parameters();

SELECT * FROM get_product_parameters(4);
