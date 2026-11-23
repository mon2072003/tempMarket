import 'package:flutter/material.dart';
import '../../../data/models/category_model.dart';
import '../../../core/localization/app_localizations.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel? category; // null represents "All"
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;

    final title = category != null
        ? category!.localizedName(loc.isArabic)
        : loc.translate('all_categories');

    final icon = category?.icon ?? Icons.grid_view_rounded;

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primary : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? primary
                    : theme.colorScheme.outlineVariant.withAlpha(80),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withAlpha(70),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
