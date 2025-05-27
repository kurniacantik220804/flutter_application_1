import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

// Themed Background Widget
class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            gradient: controller.getBackgroundGradient(),
          ),
          child: child,
        );
      },
    );
  }
}

// Themed Card Widget
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool withShadow;
  final bool withGradient;
  final VoidCallback? onTap;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.withShadow = true,
    this.withGradient = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        Widget cardWidget = Container(
          margin: margin,
          decoration: controller.getThemedDecoration(
            borderRadius: borderRadius,
            withShadow: withShadow,
            withGradient: withGradient,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        );

        if (onTap != null) {
          return GestureDetector(
            onTap: onTap,
            child: cardWidget,
          );
        }

        return cardWidget;
      },
    );
  }
}

// Themed Button Widget
class ThemedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final double? width;
  final double height;

  const ThemedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        return SizedBox(
          width: width,
          height: height,
          child: isOutlined
              ? OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
                  label: Text(text),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: onPressed,
                  icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
                  label: Text(text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// Themed App Bar
class ThemedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const ThemedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        return AppBar(
          title: Text(title),
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Themed Icon Button
class ThemedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool isCircular;

  const ThemedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 24,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        Widget iconWidget = Icon(
          icon,
          size: size,
          color: colors.primary,
        );

        if (isCircular) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withOpacity(0.1),
            ),
            child: IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              icon: iconWidget,
            ),
          );
        }

        return IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: iconWidget,
        );
      },
    );
  }
}

// Themed Text Widget dengan warna otomatis
class ThemedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isPrimary;
  final bool isSecondary;
  final TextAlign? textAlign;
  final int? maxLines;

  const ThemedText({
    super.key,
    required this.text,
    this.style,
    this.isPrimary = false,
    this.isSecondary = false,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        Color? textColor;
        if (isPrimary) {
          textColor = colors.primary;
        } else if (isSecondary) {
          textColor = colors.secondary;
        }

        return Text(
          text,
          style: (style ?? const TextStyle()).copyWith(
            color: textColor ?? style?.color,
          ),
          textAlign: textAlign,
          maxLines: maxLines,
        );
      },
    );
  }
}

// Themed Container dengan animasi
class AnimatedThemedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool withShadow;
  final bool withGradient;
  final Duration duration;

  const AnimatedThemedContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.withShadow = true,
    this.withGradient = false,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        return AnimatedContainer(
          duration: duration,
          margin: margin,
          decoration: controller.getThemedDecoration(
            borderRadius: borderRadius,
            withShadow: withShadow,
            withGradient: withGradient,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        );
      },
    );
  }
}

// Themed Floating Action Button
class ThemedFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool mini;

  const ThemedFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        return FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          mini: mini,
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          child: Icon(icon),
        );
      },
    );
  }
}

// Themed Bottom Navigation Bar
class ThemedBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const ThemedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          selectedItemColor: colors.primary,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
        );
      },
    );
  }
}

// Themed Scaffold
class ThemedScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool withBackground;
  final bool extendBody;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const ThemedScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.withBackground = true,
    this.extendBody = false,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        return Scaffold(
          appBar: appBar,
          extendBody: extendBody,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
          drawer: drawer,
          body: withBackground ? ThemedBackground(child: body) : body,
        );
      },
    );
  }
}

// Themed ListTile
class ThemedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool selected;

  const ThemedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        return ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          onTap: onTap,
          contentPadding: contentPadding,
          selected: selected,
          selectedTileColor: colors.primary.withOpacity(0.1),
          selectedColor: colors.primary,
        );
      },
    );
  }
}

// Themed Divider
class ThemedDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final double indent;
  final double endIndent;

  const ThemedDivider({
    super.key,
    this.height = 16,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        final colors = controller.getThemeColors();

        return Divider(
          height: height,
          thickness: thickness,
          indent: indent,
          endIndent: endIndent,
          color: colors.primary.withOpacity(0.2),
        );
      },
    );
  }
}
