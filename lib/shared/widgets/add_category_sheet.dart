import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../services/custom_category_service.dart';

/// Bottom sheet for creating a new custom category.
/// Returns the created [CustomCategory] or null if cancelled.
Future<CustomCategory?> showAddCategorySheet(BuildContext context) {
  return showModalBottomSheet<CustomCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AddCategorySheet(),
  );
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'tag';
  int _selectedColorIndex = 0;
  bool _isSaving = false;

  static const List<Color> _colorOptions = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF84CC16), // Lime
    Color(0xFF64748B), // Slate
    Color(0xFF0EA5E9), // Sky
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    final service = CustomCategoryService();
    final category = await service.addCategory(
      name: name,
      iconName: _selectedIcon,
      colorValue: _colorOptions[_selectedColorIndex].value,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (category != null) {
      HapticUtils.success();
      Navigator.pop(context, category);
    } else {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create category'),
          backgroundColor: AppTheme.rose500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconNames = AppCategories.availableIconNames;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXL),
          ),
        ),
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space16),

            // Title
            Text('New Category',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: DesignTokens.space20),

            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Pets, Hobbies, Rent',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space20),

            // Icon picker
            Text('Icon',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: DesignTokens.space8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: iconNames.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: DesignTokens.space8),
                itemBuilder: (context, index) {
                  final name = iconNames[index];
                  final isSelected = name == _selectedIcon;
                  final color = _colorOptions[_selectedColorIndex];
                  return GestureDetector(
                    onTap: () {
                      HapticUtils.light();
                      setState(() => _selectedIcon = name);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : context.colors.surface,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusSM),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : context.colors.onSurface.withOpacity(0.12),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        AppCategories.iconFromName(name),
                        size: 22,
                        color: isSelected
                            ? color
                            : context.colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: DesignTokens.space20),

            // Color picker
            Text('Color',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: DesignTokens.space8),
            Wrap(
              spacing: DesignTokens.space8,
              runSpacing: DesignTokens.space8,
              children: List.generate(_colorOptions.length, (index) {
                final isSelected = index == _selectedColorIndex;
                return GestureDetector(
                  onTap: () {
                    HapticUtils.light();
                    setState(() => _selectedColorIndex = index);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _colorOptions[index],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: context.colors.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: DesignTokens.space24),

            // Preview + Save
            Row(
              children: [
                // Preview
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: _colorOptions[_selectedColorIndex].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppCategories.iconFromName(_selectedIcon),
                        size: 18,
                        color: _colorOptions[_selectedColorIndex],
                      ),
                      const SizedBox(width: DesignTokens.space6),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Preview'
                            : _nameController.text,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: _colorOptions[_selectedColorIndex],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Save
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryIndigo,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMD),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
