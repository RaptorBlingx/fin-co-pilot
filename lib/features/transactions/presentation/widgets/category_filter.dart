import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilter({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<Map<String, dynamic>> categories = [
    {'name': 'All', 'value': null, 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'name': 'Groceries', 'value': 'groceries', 'icon': Icons.shopping_cart, 'color': Colors.green},
    {'name': 'Dining', 'value': 'dining', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Transport', 'value': 'transport', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'Entertainment', 'value': 'entertainment', 'icon': Icons.movie, 'color': Colors.purple},
    {'name': 'Shopping', 'value': 'shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'Health', 'value': 'health', 'icon': Icons.health_and_safety, 'color': Colors.red},
    {'name': 'Bills', 'value': 'bills', 'icon': Icons.receipt, 'color': Colors.brown},
    {'name': 'Education', 'value': 'education', 'icon': Icons.school, 'color': Colors.indigo},
    {'name': 'Travel', 'value': 'travel', 'icon': Icons.flight, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onCategorySelected(category['value']),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  color: isSelected
                      ? category['color'].withOpacity(0.15)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? category['color']
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'],
                      color: isSelected
                          ? category['color']
                          : Colors.grey[600],
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? category['color']
                            : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}