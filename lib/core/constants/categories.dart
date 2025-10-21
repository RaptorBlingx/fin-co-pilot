import 'package:flutter/material.dart';

/// Category data model
class CategoryData {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryData({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Application-wide category definitions
class AppCategories {
  static const List<CategoryData> categories = [
    CategoryData(name: 'Groceries', icon: Icons.shopping_cart, color: Colors.green),
    CategoryData(name: 'Dining', icon: Icons.restaurant, color: Colors.orange),
    CategoryData(name: 'Transport', icon: Icons.directions_car, color: Colors.blue),
    CategoryData(name: 'Entertainment', icon: Icons.movie, color: Colors.purple),
    CategoryData(name: 'Shopping', icon: Icons.shopping_bag, color: Colors.pink),
    CategoryData(name: 'Health', icon: Icons.health_and_safety, color: Colors.red),
    CategoryData(name: 'Bills', icon: Icons.receipt, color: Colors.brown),
    CategoryData(name: 'Education', icon: Icons.school, color: Colors.indigo),
    CategoryData(name: 'Travel', icon: Icons.flight, color: Colors.teal),
    CategoryData(name: 'Other', icon: Icons.category, color: Colors.grey),
  ];

  /// Get category by name
  static CategoryData getCategoryByName(String? name) {
    if (name == null) return categories.first;
    return categories.firstWhere(
      (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      orElse: () => categories.last, // Return 'Other' as default
    );
  }

  /// Get all category names
  static List<String> get categoryNames => categories.map((c) => c.name).toList();
}
