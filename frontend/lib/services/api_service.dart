import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plaid_flutter/plaid_flutter.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Plaid endpoints
  Future<List<dynamic>> getInstitutions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/plaid/institutions'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get institutions');
    }
  }

  Future<String> createLinkToken({String? itemId}) async {
    final uri = itemId != null
        ? Uri.parse('$baseUrl/api/plaid/create_link_token')
            .replace(queryParameters: {'item_id': itemId})
        : Uri.parse('$baseUrl/api/plaid/create_link_token');

    final response = await http.post(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['link_token'];
    } else {
      throw Exception('Failed to create link token');
    }
  }

  Future<Map<String, dynamic>> exchangePublicToken(
      String publicToken, LinkInstitution? institution) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/plaid/exchange_public_token').replace(
        queryParameters: {
          'public_token': publicToken,
          'inst_id': institution?.id ?? '',
          'inst_name': institution?.name ?? '',
        },
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to exchange token');
    }
  }

  Future<Map<String, dynamic>> syncTransactions(String item_id) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/api/plaid/sync_transactions?item_id=$item_id'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync transactions');
    }
  }

  // Transaction endpoints
  Future<List<dynamic>> getTransactions({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/transactions/?skip=$skip&limit=$limit'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<void> categorizeTransaction(int transactionId, String category) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/api/transactions/$transactionId/categorize?category=$category'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to categorize transaction');
    }
  }

  // ML endpoints
  Future<Map<String, dynamic>> predictCategory({
    required String transactionText,
    required double amount,
    String? merchantName,
  }) async {
    final queryParams = {
      'transaction_text': transactionText,
      'amount': amount.toString(),
      if (merchantName != null) 'merchant_name': merchantName,
    };

    final uri = Uri.parse('$baseUrl/api/ml/predict')
        .replace(queryParameters: queryParams);

    final response = await http.post(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to predict category');
    }
  }

  Future<Map<String, dynamic>> trainModels() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ml/train'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to train models');
    }
  }

  // Budget endpoints
  Future<Map<String, dynamic>?> getCurrentBudget() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/budgets/current'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to get current budget');
    }
  }

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> budgetData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/budgets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(budgetData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create budget: ${response.body}');
    }
  }

  Future<List<dynamic>> getBudgetCategories(int budgetId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/budgets/$budgetId/categories'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get budget categories');
    }
  }

  Future<Map<String, dynamic>> updateSubcategoryBudget({
    required int budgetId,
    required int subcategoryBudgetId,
    required double allocatedAmount,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/budgets/$budgetId/subcategories/$subcategoryBudgetId')
          .replace(queryParameters: {
        'allocated_amount': allocatedAmount.toString(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update subcategory budget: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createBudgetWithAllCategories(String budgetName) async {
    // First get all categories
    final categories = await getCategories();
    
    // Build subcategory budgets with all subcategories set to $0
    final List<Map<String, dynamic>> subcategoryBudgets = [];
    for (var category in categories) {
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

  // Category endpoints
  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Account endpoints
  Future<List<dynamic>> getAccounts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/accounts'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load accounts');
    }
  }

  Future<List<dynamic>> getInstitutionsList() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/plaid/items'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get institutions list');
    }
  }

  Future<double> getTotalBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/accounts/total_balance'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['total_balance'].toDouble();
    } else {
      throw Exception('Failed to get total balance');
    }
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> getSpendingBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final uri = Uri.parse('$baseUrl/api/analytics/spending_breakdown')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get spending breakdown');
    }
  }

  Future<Map<String, dynamic>> getIncomeVsSpending({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final uri = Uri.parse('$baseUrl/api/analytics/income_vs_spending')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get income vs spending');
    }
  }
}
