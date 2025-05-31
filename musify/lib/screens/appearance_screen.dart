import 'package:flutter/material.dart';
import 'package:musify/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text('Theme Mode', style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          const Divider(height: 32.0),
          Text('Accent Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                themeProvider.availableAccentColors.entries.map((entry) {
                  final Color colorValue = entry.value;
                  bool isSelected = themeProvider.accentColor == colorValue;

                  return InkWell(
                    onTap: () => themeProvider.setAccentColor(colorValue),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border:
                            isSelected
                                ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  width: 2.5,
                                )
                                : Border.all(
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color:
                                    ThemeData.estimateBrightnessForColor(
                                              colorValue,
                                            ) ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                size: 20,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Selected: ${themeProvider.getAccentColorName(themeProvider.accentColor)}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
