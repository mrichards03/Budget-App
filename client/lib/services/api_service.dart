import 'api/simplefin_api_service.dart';
import 'api/transaction_api_service.dart';
import 'api/ml_api_service.dart';
import 'api/budget_api_service.dart';
import 'api/category_api_service.dart';
import 'api/account_api_service.dart';
import 'api/analytics_api_service.dart';

/// Lightweight facade that provides organized access to all API services.
///
/// Usage:
///   apiService.budgets.getCurrentBudget()
///   apiService.plaid.createLinkToken()
///   apiService.transactions.getTransactions()
class ApiService {
  final SimpleFinApiService simpleFin;
  final TransactionApiService transactions;
  final MlApiService ml;
  final BudgetApiService budgets;
  final CategoryApiService categories;
  final AccountApiService accounts;
  final AnalyticsApiService analytics;

  ApiService({required String baseUrl})
      : simpleFin = SimpleFinApiService(baseUrl: baseUrl),
        transactions = TransactionApiService(baseUrl: baseUrl),
        ml = MlApiService(baseUrl: baseUrl),
        budgets = BudgetApiService(baseUrl: baseUrl),
        categories = CategoryApiService(baseUrl: baseUrl),
        accounts = AccountApiService(baseUrl: baseUrl),
        analytics = AnalyticsApiService(baseUrl: baseUrl);
}
