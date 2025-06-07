import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_application_1/screen/admin_dashboard_screen.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dashboard_screen.dart';
import 'package:flutter_application_1/screen/promo/admin_promo_management_screen.dart';
import 'riwayat_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/theme/theme_widgets.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> with TickerProviderStateMixin {
  final autoSizeGroup = AutoSizeGroup();
  var _bottomNavIndex = 0;

  late AnimationController _fabAnimationController;
  late AnimationController _borderRadiusAnimationController;
  late Animation<double> fabAnimation;
  late Animation<double> borderRadiusAnimation;
  late CurvedAnimation fabCurve;
  late CurvedAnimation borderRadiusCurve;
  late AnimationController _hideBottomBarAnimationController;

  // Icon dan title khusus untuk admin
  static const iconList = <IconData>[
    Icons.dashboard_rounded,
    Icons.admin_panel_settings_rounded, // Ubah dari discount ke admin panel
    Icons.settings_rounded,
    Icons.history_rounded,
  ];

  static const titleList = ["Dashboard", "Kelola Promo", "Pengaturan", "Riwayat"];

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    // Pages khusus untuk admin
    pages = [
      const AdminDashboardScreen(),
      const AdminPromoManagementScreen(), // Screen baru untuk admin promo
      const SettingsScreen(),
      const RiwayatScreen(),
    ];

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _borderRadiusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    fabCurve = CurvedAnimation(
      parent: _fabAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );

    borderRadiusCurve = CurvedAnimation(
      parent: _borderRadiusAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );

    fabAnimation = Tween<double>(begin: 0, end: 1).animate(fabCurve);
    borderRadiusAnimation =
        Tween<double>(begin: 0, end: 1).animate(borderRadiusCurve);

    _hideBottomBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _fabAnimationController.forward();
          _borderRadiusAnimationController.forward();
        }
      },
    );
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.metrics.axis == Axis.vertical) {
      switch (notification.direction) {
        case ScrollDirection.forward:
          _hideBottomBarAnimationController.reverse();
          _fabAnimationController.forward(from: 0);
          break;
        case ScrollDirection.reverse:
          _hideBottomBarAnimationController.forward();
          _fabAnimationController.reverse(from: 1);
          break;
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _borderRadiusAnimationController.dispose();
    _hideBottomBarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final colors = themeController.getThemeColors();

        return ThemedScaffold(
          extendBody: true,
          withBackground: false,
          body: NotificationListener<ScrollNotification>(
            onNotification: onScrollNotification,
            child: IndexedStack(index: _bottomNavIndex, children: pages),
          ),
          floatingActionButton: ThemedFloatingActionButton(
            icon: Icons.add_business_rounded, // Icon khusus admin
            onPressed: () {
              // Quick add promo atau quick action lainnya
              _showQuickActions();
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AnimatedBottomNavigationBar.builder(
            itemCount: iconList.length,
            tabBuilder: (int index, bool isActive) {
              final color = isActive ? colors.primary : Colors.grey;
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconList[index], size: 24, color: color),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AutoSizeText(
                      titleList[index],
                      maxLines: 1,
                      style: TextStyle(color: color, fontSize: 12),
                      group: autoSizeGroup,
                    ),
                  ),
                ],
              );
            },
            backgroundColor: Colors.white,
            activeIndex: _bottomNavIndex,
            splashColor: colors.primary,
            notchAndCornersAnimation: borderRadiusAnimation,
            splashSpeedInMilliseconds: 300,
            notchSmoothness: NotchSmoothness.defaultEdge,
            gapLocation: GapLocation.center,
            leftCornerRadius: 32,
            rightCornerRadius: 32,
            onTap: (index) => setState(() => _bottomNavIndex = index),
            hideAnimationController: _hideBottomBarAnimationController,
            shadow: BoxShadow(
              offset: const Offset(0, 1),
              blurRadius: 12,
              spreadRadius: 0.5,
              color: colors.primary.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Tambah Promo Baru'),
              subtitle: const Text('Buat promo baru untuk pelanggan'),
              onTap: () {
                Navigator.pop(context);
                // Navigate ke form tambah promo
                setState(() => _bottomNavIndex = 1); // Pindah ke tab Kelola Promo
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Lihat Statistik'),
              subtitle: const Text('Analisis performa promo'),
              onTap: () {
                Navigator.pop(context);
                // Show statistik
              },
            ),
            ListTile(
              leading: const Icon(Icons.notification_add, color: Colors.orange),
              title: const Text('Kirim Notifikasi'),
              subtitle: const Text('Notifikasi promo ke semua user'),
              onTap: () {
                Navigator.pop(context);
                // Show form notifikasi
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}