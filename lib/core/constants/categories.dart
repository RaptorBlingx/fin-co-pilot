import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../../services/custom_category_service.dart';

/// Category data model
class CategoryData {
  final String name;
  final IconData icon;
  final IconData iconFilled;
  final Color color;

  const CategoryData({
    required this.name,
    required this.icon,
    required this.iconFilled,
    required this.color,
  });
}

/// Application-wide category definitions
class AppCategories {
  static final List<CategoryData> categories = [
    CategoryData(name: 'Groceries', icon: PhosphorIcons.shoppingCart(), iconFilled: PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[0]),
    CategoryData(name: 'Dining', icon: PhosphorIcons.forkKnife(), iconFilled: PhosphorIcons.forkKnife(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[1]),
    CategoryData(name: 'Transport', icon: PhosphorIcons.car(), iconFilled: PhosphorIcons.car(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[2]),
    CategoryData(name: 'Entertainment', icon: PhosphorIcons.filmSlate(), iconFilled: PhosphorIcons.filmSlate(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[3]),
    CategoryData(name: 'Shopping', icon: PhosphorIcons.bag(), iconFilled: PhosphorIcons.bag(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[4]),
    CategoryData(name: 'Health', icon: PhosphorIcons.heartbeat(), iconFilled: PhosphorIcons.heartbeat(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[5]),
    CategoryData(name: 'Bills', icon: PhosphorIcons.receipt(), iconFilled: PhosphorIcons.receipt(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[6]),
    CategoryData(name: 'Education', icon: PhosphorIcons.graduationCap(), iconFilled: PhosphorIcons.graduationCap(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[7]),
    CategoryData(name: 'Travel', icon: PhosphorIcons.airplane(), iconFilled: PhosphorIcons.airplane(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[8]),
    CategoryData(name: 'Other', icon: PhosphorIcons.dotsThreeCircle(), iconFilled: PhosphorIcons.dotsThreeCircle(PhosphorIconsStyle.fill), color: AppTheme.categoryColors[9]),
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

  /// Merge predefined categories with user's custom categories.
  static List<CategoryData> mergedWith(List<CustomCategory> custom) {
    final merged = List<CategoryData>.from(categories);
    for (final c in custom) {
      // Skip if a built-in category with the same name already exists
      final exists = merged.any(
        (cat) => cat.name.toLowerCase() == c.name.toLowerCase(),
      );
      if (exists) continue;

      final icon = iconFromName(c.iconName);
      final iconFilled = iconFilledFromName(c.iconName);
      merged.insert(merged.length - 1, CategoryData(
        name: c.name,
        icon: icon,
        iconFilled: iconFilled,
        color: Color(c.colorValue),
      ));
    }
    return merged;
  }

  /// Map of icon names to Phosphor icons for custom categories.
  static final Map<String, IconData Function()> _iconMap = {
    'tag': () => PhosphorIcons.tag(),
    'house': () => PhosphorIcons.house(),
    'gift': () => PhosphorIcons.gift(),
    'baby': () => PhosphorIcons.baby(),
    'paw': () => PhosphorIcons.pawPrint(),
    'wrench': () => PhosphorIcons.wrench(),
    'coffee': () => PhosphorIcons.coffee(),
    'barbell': () => PhosphorIcons.barbell(),
    'book': () => PhosphorIcons.book(),
    'music': () => PhosphorIcons.musicNotes(),
    'game': () => PhosphorIcons.gameController(),
    'leaf': () => PhosphorIcons.leaf(),
    'piggyBank': () => PhosphorIcons.piggyBank(),
    'wallet': () => PhosphorIcons.wallet(),
    'creditCard': () => PhosphorIcons.creditCard(),
    'bank': () => PhosphorIcons.bank(),
    'handCoins': () => PhosphorIcons.handCoins(),
    'scissors': () => PhosphorIcons.scissors(),
    'tShirt': () => PhosphorIcons.tShirt(),
    'phone': () => PhosphorIcons.phone(),
    'wifi': () => PhosphorIcons.wifiHigh(),
    'drop': () => PhosphorIcons.drop(),
    'fire': () => PhosphorIcons.fire(),
    'star': () => PhosphorIcons.star(),
    'heart': () => PhosphorIcons.heart(),
    'smiley': () => PhosphorIcons.smiley(),
    'pizza': () => PhosphorIcons.pizza(),
    'beer': () => PhosphorIcons.beerStein(),
    'flower': () => PhosphorIcons.flower(),
    'sun': () => PhosphorIcons.sun(),
  };

  static final Map<String, IconData Function()> _iconFilledMap = {
    'tag': () => PhosphorIcons.tag(PhosphorIconsStyle.fill),
    'house': () => PhosphorIcons.house(PhosphorIconsStyle.fill),
    'gift': () => PhosphorIcons.gift(PhosphorIconsStyle.fill),
    'baby': () => PhosphorIcons.baby(PhosphorIconsStyle.fill),
    'paw': () => PhosphorIcons.pawPrint(PhosphorIconsStyle.fill),
    'wrench': () => PhosphorIcons.wrench(PhosphorIconsStyle.fill),
    'coffee': () => PhosphorIcons.coffee(PhosphorIconsStyle.fill),
    'barbell': () => PhosphorIcons.barbell(PhosphorIconsStyle.fill),
    'book': () => PhosphorIcons.book(PhosphorIconsStyle.fill),
    'music': () => PhosphorIcons.musicNotes(PhosphorIconsStyle.fill),
    'game': () => PhosphorIcons.gameController(PhosphorIconsStyle.fill),
    'leaf': () => PhosphorIcons.leaf(PhosphorIconsStyle.fill),
    'piggyBank': () => PhosphorIcons.piggyBank(PhosphorIconsStyle.fill),
    'wallet': () => PhosphorIcons.wallet(PhosphorIconsStyle.fill),
    'creditCard': () => PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
    'bank': () => PhosphorIcons.bank(PhosphorIconsStyle.fill),
    'handCoins': () => PhosphorIcons.handCoins(PhosphorIconsStyle.fill),
    'scissors': () => PhosphorIcons.scissors(PhosphorIconsStyle.fill),
    'tShirt': () => PhosphorIcons.tShirt(PhosphorIconsStyle.fill),
    'phone': () => PhosphorIcons.phone(PhosphorIconsStyle.fill),
    'wifi': () => PhosphorIcons.wifiHigh(PhosphorIconsStyle.fill),
    'drop': () => PhosphorIcons.drop(PhosphorIconsStyle.fill),
    'fire': () => PhosphorIcons.fire(PhosphorIconsStyle.fill),
    'star': () => PhosphorIcons.star(PhosphorIconsStyle.fill),
    'heart': () => PhosphorIcons.heart(PhosphorIconsStyle.fill),
    'smiley': () => PhosphorIcons.smiley(PhosphorIconsStyle.fill),
    'pizza': () => PhosphorIcons.pizza(PhosphorIconsStyle.fill),
    'beer': () => PhosphorIcons.beerStein(PhosphorIconsStyle.fill),
    'flower': () => PhosphorIcons.flower(PhosphorIconsStyle.fill),
    'sun': () => PhosphorIcons.sun(PhosphorIconsStyle.fill),
  };

  /// Get icon names available for custom categories.
  static List<String> get availableIconNames => _iconMap.keys.toList();

  static IconData iconFromName(String name) {
    return (_iconMap[name] ?? _iconMap['tag']!)();
  }

  static IconData iconFilledFromName(String name) {
    return (_iconFilledMap[name] ?? _iconFilledMap['tag']!)();
  }
}
