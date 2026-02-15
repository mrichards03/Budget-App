import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/budget.dart';
import '../models/category.dart';
import 'main_layout_screen.dart';

class CreateBudgetScreen extends StatefulWidget {
  final VoidCallback? onBudgetCreated;

  const CreateBudgetScreen({super.key, this.onBudgetCreated});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  bool _setEndDate = false;

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final categoriesData = await apiService.getCategories();

      setState(() {
        _categories = categoriesData.map((c) => Category.fromJson(c)).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate
          : (_endDate ?? _startDate.add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is after start date if set
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Build subcategory budgets list with all subcategories at $0
      final subcategoryBudgets = <Map<String, dynamic>>[];
      for (var category in _categories) {
        if (category.subcategories != null) {
          for (var subcategory in category.subcategories!) {
            subcategoryBudgets.add({
              'subcategory_id': subcategory.id,
              'allocated_amount': 0.0,
            });
          }
        }
      }

      final budgetData = {
        'name': _nameController.text,
        'start_date': _startDate.toIso8601String(),
        if (_setEndDate && _endDate != null)
          'end_date': _endDate!.toIso8601String(),
        'subcategory_budgets': subcategoryBudgets,
      };

      await apiService.createBudget(budgetData);

      if (mounted) {
        if (widget.onBudgetCreated != null) {
          widget.onBudgetCreated!();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainLayoutScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create budget: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCategories) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New Budget',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Budget Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Set an end date'),
                subtitle: const Text('Leave unchecked for ongoing budget'),
                value: _setEndDate,
                onChanged: (value) {
                  setState(() {
                    _setEndDate = value ?? false;
                    if (_setEndDate && _endDate == null) {
                      _endDate = _startDate.add(const Duration(days: 30));
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_setEndDate) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endDate != null
                          ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                          : 'Not set',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : _createBudget,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Budget'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
