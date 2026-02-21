import 'package:flutter/material.dart';

class IconHelper {
  static IconData getIconForSubcategory(String subcategoryName) {
    final name = subcategoryName.toLowerCase();

    if (name.contains('rent') || name.contains('mortgage')) return Icons.home;
    if (name.contains('phone')) return Icons.phone;
    if (name.contains('internet')) return Icons.wifi;
    if (name.contains('utilit')) return Icons.bolt;
    if (name.contains('grocer')) return Icons.shopping_cart;
    if (name.contains('transport')) return Icons.directions_car;
    if (name.contains('medical')) return Icons.medical_services;
    if (name.contains('emergency')) return Icons.emergency;
    if (name.contains('dining')) return Icons.restaurant;
    if (name.contains('entertainment')) return Icons.movie;
    if (name.contains('vacation')) return Icons.flight;
    if (name.contains('subscription')) return Icons.sync;

    return Icons.category;
  }
}
