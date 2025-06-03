import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final ThemeController controller = ThemeController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Tema'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: controller.getBackgroundGradient(),
        ),
        child: Obx(() => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: controller.getThemeColors().primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pilih Tema',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.getThemeColors().primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: AppThemeType.values.map((theme) {
                        final isSelected = controller.selectedTheme == theme;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildThemeOption(
                            theme: theme,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                controller.changeTheme(theme);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Preview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color: controller.getThemeColors().primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pratinjau Tema',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.getThemeColors().primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 120,
                      decoration: controller.getThemedDecoration(
                        withGradient: true,
                        borderRadius: 16,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.spa,
                              size: 32,
                              color: controller.getThemeColors().primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Salon Cantik',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: controller.getThemeColors().primary,
                              ),
                            ),
                            Text(
                              controller.selectedTheme.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: controller.getThemeColors().secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildThemeOption({
    required AppThemeType theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color themeColor;

    switch (theme) {
      case AppThemeType.pink:
        themeColor = Colors.pinkAccent;
        break;
      case AppThemeType.purple:
        themeColor = Colors.purple;
        break;
      case AppThemeType.teal:
        themeColor = Colors.teal;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                theme.icon,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                theme.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? themeColor : Colors.grey[700],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeColor,
                size: 24,
              ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}