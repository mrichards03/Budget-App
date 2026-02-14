import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import '../services/api_service.dart';

class PlaidLinkScreen extends StatefulWidget {
  final Function() onSuccess;

  const PlaidLinkScreen({super.key, required this.onSuccess});

  @override
  State<PlaidLinkScreen> createState() => _PlaidLinkScreenState();
}

class _PlaidLinkScreenState extends State<PlaidLinkScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlaidLink();
  }

  Future<void> _initializePlaidLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Step 1: Get link token from backend
      final linkToken = await apiService.createLinkToken();

      // Step 2: Configure Plaid Link
      final configuration = LinkTokenConfiguration(token: linkToken);

      PlaidLink.onSuccess.listen((success) {
        _handlePlaidSuccess(success.publicToken, success.metadata.institution);
      });

      PlaidLink.onEvent.listen((event) {
        print('Plaid Event: ${event.name}');
      });

      PlaidLink.onExit.listen((exit) {
        print('Plaid Exit: ${exit.error}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });

      PlaidLink.create(configuration: configuration);
      // Open Plaid Link
      PlaidLink.open();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handlePlaidSuccess(
      String publicToken, LinkInstitution? institution) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // Exchange public token for access token
      await apiService.exchangePublicToken(publicToken, institution);

      // Call the success callback
      widget.onSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account connected successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Bank Account'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 50, color: Colors.red),
                      const SizedBox(height: 20),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _initializePlaidLink,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance,
                          size: 100, color: Colors.blue),
                      SizedBox(height: 20),
                      Text(
                        'Setting up Plaid Link...',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
      ),
    );
  }
}
