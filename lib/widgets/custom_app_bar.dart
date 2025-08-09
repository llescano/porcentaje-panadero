import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'animated_theme_toggle.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isForm;
  final bool isLoading;
  final VoidCallback? onSave;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.isForm = false,
    this.isLoading = false,
    this.onSave,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
              : null,
      actions: [
        if (isForm) ..._buildFormActions(context),
        ...?actions,
        AnimatedThemeToggle(
          isDark: isDark,
          onToggle: () => themeProvider.toggleTheme(!isDark),
        ),
      ],
    );
  }

  List<Widget> _buildFormActions(BuildContext context) {
    return [
      if (isLoading)
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        )
      else if (onSave != null)
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
          tooltip: 'Guardar',
        ),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
