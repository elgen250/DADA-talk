import 'package:flutter/material.dart';
import '../constants/languages.dart';
import '../theme/app_theme.dart';

class LanguageSelectorSheet extends StatefulWidget {
  final AppLanguage currentSelection;
  final String title;

  const LanguageSelectorSheet({
    super.key,
    required this.currentSelection,
    this.title = 'اختر اللغة',
  });

  static Future<AppLanguage?> show(
    BuildContext context, {
    required AppLanguage current,
    String title = 'اختر اللغة',
  }) {
    return showModalBottomSheet<AppLanguage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageSelectorSheet(
        currentSelection: current,
        title: title,
      ),
    );
  }

  @override
  State<LanguageSelectorSheet> createState() => _LanguageSelectorSheetState();
}

class _LanguageSelectorSheetState extends State<LanguageSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = kSupportedLanguages.where((l) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return l.name.toLowerCase().contains(q) ||
          l.nativeName.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن لغة أو دولة...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Languages list
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                indent: 64,
              ),
              itemBuilder: (context, index) {
                final lang = filtered[index];
                final isSelected = lang.code == widget.currentSelection.code;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Text(
                    lang.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Row(
                    children: [
                      Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${lang.name})',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop(lang);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
