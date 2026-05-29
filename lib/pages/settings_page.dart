import "package:arxiv/pages/how_to_use.dart";
import "package:arxiv/theme/app_theme.dart";
import "package:flutter/material.dart";
import "package:hive/hive.dart";
import "package:theme_provider/theme_provider.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var toolsOn = true;

  Future<void> saveToolsSetting(bool value) async {
    final toolsBox = await Hive.openBox("toolsBox");
    await toolsBox.put("toolsBox", value);
    await toolsBox.close();

    if (!mounted) return;
    setState(() {
      toolsOn = value;
    });
  }

  Future<void> loadToolsSetting() async {
    final toolsBox = await Hive.openBox("toolsBox");
    final savedToolsOn = await toolsBox.get("toolsBox") ?? true;
    await toolsBox.close();

    if (!mounted) return;
    setState(() {
      toolsOn = savedToolsOn;
    });
  }

  @override
  void initState() {
    super.initState();
    loadToolsSetting();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = ThemeProvider.controllerOf(context);
    final selectedThemeId = ThemeProvider.themeOf(context).id;
    final pairedThemeId = pairedBrightnessThemeId(selectedThemeId);
    final isDark = colorScheme.brightness == Brightness.dark;
    final themes = controller.allThemes;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          _SettingsSectionLabel(
            label: "Theme",
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8.0),
          _SettingsSwitchTile(
            icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            title: "Dark mode",
            subtitle: "Switches the current theme between light and dark.",
            value: isDark,
            onChanged: (_) {
              if (controller.hasTheme(pairedThemeId)) {
                controller.setTheme(pairedThemeId);
              }
            },
          ),
          const SizedBox(height: 4.0),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: themes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              final theme = themes[index];
              return _ThemeOptionTile(
                theme: theme,
                selected: theme.id == selectedThemeId,
                onSelected: () => controller.setTheme(theme.id),
              );
            },
          ),
          const SizedBox(height: 18.0),
          _SettingsSectionLabel(
            label: "AI Chat",
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8.0),
          _SettingsSwitchTile(
            icon: Icons.auto_fix_high_outlined,
            title: "Message tools",
            subtitle: "Enables Speak, Copy, and Share for AI replies.",
            value: toolsOn,
            onChanged: saveToolsSetting,
          ),
          const SizedBox(height: 18.0),
          _SettingsSectionLabel(
            label: "Help",
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8.0),
          _SettingsActionTile(
            icon: Icons.help_outline,
            title: "How to Use",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HowToUsePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.theme,
    required this.selected,
    required this.onSelected,
  });

  final AppTheme theme;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewScheme = theme.data.colorScheme;

    return _SettingsTileShell(
      selected: selected,
      onTap: onSelected,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ThemeSwatches(colorScheme: previewScheme),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          Text(
            theme.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwatches extends StatelessWidget {
  const _ThemeSwatches({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58.0,
      height: 34.0,
      child: Stack(
        children: [
          _Swatch(color: colorScheme.surface, left: 0.0, top: 0.0, size: 34.0),
          _Swatch(
            color: colorScheme.primaryContainer,
            left: 18.0,
            top: 0.0,
            size: 34.0,
          ),
          _Swatch(color: colorScheme.primary, left: 36.0, top: 0.0, size: 22.0),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.left,
    required this.top,
    required this.size,
  });

  final Color color;
  final double left;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsTileShell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsTileShell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsTileShell extends StatelessWidget {
  const _SettingsTileShell({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
    this.selected = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer
            : subtleSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(10.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
