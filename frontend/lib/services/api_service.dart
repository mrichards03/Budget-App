import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plaid_flutter/plaid_flutter.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Plaid endpoints
  Future<String> createLinkToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/plaid/create_link_token'),
    );

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

  Future<Map<String, dynamic>> syncTransactions(String accessToken) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/api/plaid/sync_transactions?access_token=$accessToken'),
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
}
