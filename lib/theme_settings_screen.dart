import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Tema'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeController.to.getBackgroundGradient(),
        ),
        child: GetBuilder<ThemeController>(
          builder: (controller) {
            return ListView(
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
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: AppThemeType.values.length,
                          itemBuilder: (context, index) {
                            final theme = AppThemeType.values[index];
                            final isSelected =
                                controller.selectedTheme == theme;

                            return _buildThemeOption(
                              theme: theme,
                              isSelected: isSelected,
                              onTap: () => controller.changeTheme(theme),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Dark Mode Toggle
                Card(
                  child: ListTile(
                    leading: Icon(
                      controller.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: controller.getThemeColors().primary,
                    ),
                    title: const Text('Mode Gelap'),
                    subtitle: Text(
                      controller.isDarkMode ? 'Aktif' : 'Nonaktif',
                    ),
                    trailing: Obx(() => Switch(
                          value: controller.isDarkMode,
                          onChanged: (value) => controller.toggleDarkMode(),
                          activeColor: controller.getThemeColors().primary,
                        )),
                  ),
                ),

                const SizedBox(height: 16),

                // Custom Color Picker (jika tema custom dipilih)
                if (controller.selectedTheme == AppThemeType.custom) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.color_lens,
                                color: controller.getThemeColors().primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Warna Kustom',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: controller.getThemeColors().primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildColorPicker(
                                  title: 'Warna Utama',
                                  color: controller.customPrimaryColor,
                                  onColorChanged: (color) {
                                    controller.setCustomColors(
                                      color,
                                      controller.customSecondaryColor,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildColorPicker(
                                  title: 'Warna Sekunder',
                                  color: controller.customSecondaryColor,
                                  onColorChanged: (color) {
                                    controller.setCustomColors(
                                      controller.customPrimaryColor,
                                      color,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                              'Preview Tema',
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
                                    color:
                                        controller.getThemeColors().secondary,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required AppThemeType theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final controller = ThemeController.to;
    Color themeColor;

    switch (theme) {
      case AppThemeType.pink:
        themeColor = Colors.pinkAccent;
        break;
      case AppThemeType.blue:
        themeColor = Colors.blue;
        break;
      case AppThemeType.purple:
        themeColor = Colors.purple;
        break;
      case AppThemeType.green:
        themeColor = Colors.green;
        break;
      case AppThemeType.orange:
        themeColor = Colors.orange;
        break;
      case AppThemeType.teal:
        themeColor = Colors.teal;
        break;
      case AppThemeType.custom:
        themeColor = controller.customPrimaryColor;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                theme.icon,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                theme.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? themeColor : Colors.grey[700],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeColor,
                size: 20,
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker({
    required String title,
    required Color color,
    required Function(Color) onColorChanged,
  }) {
    final predefinedColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: predefinedColors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final pickerColor = predefinedColors[index];
              return GestureDetector(
                onTap: () => onColorChanged(pickerColor),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: pickerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == pickerColor
                          ? Colors.black
                          : Colors.grey[300]!,
                      width: color == pickerColor ? 2 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
