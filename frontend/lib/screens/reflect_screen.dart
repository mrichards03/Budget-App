import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/analytics.dart';
import 'reflect/spending_breakdown_tab.dart';
import 'reflect/spending_trends_tab.dart';
import 'reflect/net_worth_tab.dart';

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen>
    with SingleTickerProviderStateMixin {
  AnalyticsResponse? _analyticsData;
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final data = await apiService.analytics.getAnalyticsData(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _analyticsData = AnalyticsResponse.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now(),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  void _resetToThisMonth() {
    setState(() {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tabs
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Spending Breakdown'),
                Tab(text: 'Spending Trends'),
                Tab(text: 'Net Worth'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      SpendingBreakdownTab(
                        analyticsData: _analyticsData,
                        startDate: _startDate,
                        endDate: _endDate,
                        onRefresh: _resetToThisMonth,
                        onSelectDateRange: _selectDateRange,
                      ),
                      SpendingTrendsTab(
                        analyticsData: _analyticsData,
                        onRefresh: _loadData,
                      ),
                      NetWorthTab(
                        analyticsData: _analyticsData,
                        onRefresh: _loadData,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
