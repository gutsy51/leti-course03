-- Функции поиска.
SELECT * FROM "Measure";
SELECT * FROM "Category";
SELECT * FROM "Product";
SELECT * FROM "EnumValue";
SELECT * FROM "Parameter";
SELECT * FROM "ParameterValue";

SELECT * FROM get_products_with_params_by_category(1);
SELECT * FROM get_product_params(4);