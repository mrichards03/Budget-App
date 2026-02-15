import 'base_api_service.dart';
import 'category_api_service.dart';

class BudgetApiService extends BaseApiService {
  final CategoryApiService _categoryService;

  BudgetApiService({required super.baseUrl})
      : _categoryService = CategoryApiService(baseUrl: baseUrl);

  Future<Map<String, dynamic>?> getCurrentBudget() async {
    return await get('/api/budgets/current');
  }

  Future<Map<String, dynamic>> createBudget(
      Map<String, dynamic> budgetData) async {
    return await post('/api/budgets', body: budgetData);
  }

  Future<List<dynamic>> getBudgetCategories(int budgetId) async {
    return await get('/api/budgets/$budgetId/categories');
  }

  Future<Map<String, dynamic>> updateSubcategoryBudget({
    required int budgetId,
    required int subcategoryBudgetId,
    required double allocatedAmount,
  }) async {
    return await put(
      '/api/budgets/$budgetId/subcategories/$subcategoryBudgetId?allocated_amount=$allocatedAmount',
    );
  }

  Future<Map<String, dynamic>> createBudgetWithAllCategories(
      String budgetName) async {
    // First get all categories
    final categoriesList = await _categoryService.getCategories();

    // Build subcategory budgets with all subcategories set to $0
    final List<Map<String, dynamic>> subcategoryBudgets = [];
    for (var category in categoriesList) {
      if (category['subcategories'] != null) {
        for (var subcategory in category['subcategories']) {
          subcategoryBudgets.add({
            'subcategory_id': subcategory['id'],
            'allocated_amount': 0.0,
          });
        }
      }
    }

    // Create budget with all subcategories
    final budgetData = {
      'name': budgetName,
      'start_date': DateTime.now().toIso8601String(),
      'subcategory_budgets': subcategoryBudgets,
    };

    return await createBudget(budgetData);
  }
}
