# from .models import Category, Product, EnumValue, Parameter, ParameterValue
#
#
# from django.test import TestCase
# from .utils.fill_test_data import fill_test_data
#
#
# class DatabaseFillTestCase(TestCase):
#     def setUp(self):
#         fill_test_data()
#
#     def test_database_filled_successfully(self):
#         self.assertEqual(Category.objects.count(), 11)
#         self.assertEqual(Product.objects.count(), 8)
#         self.assertEqual(EnumValue.objects.count(), 8)
#         self.assertEqual(Parameter.objects.count(), 4)
#         self.assertEqual(ParameterValue.objects.count(), 6)


from .models import Category, Product

# Проверяем наличие категории с id=1
root_category = Category.objects.get(id=1)
print(root_category)

# Проверяем, есть ли продукты с этой категорией
products = Product.objects.filter(category=root_category)
print(products)