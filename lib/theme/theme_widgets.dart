import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

// Themed Background Widget
class ThemedBackground extends StatefulWidget {
  final Widget child;

  const ThemedBackground({
    super.key,
    required this.child,
  });

  @override
  State<ThemedBackground> createState() => _ThemedBackgroundState();
}

class _ThemedBackgroundState extends State<ThemedBackground> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      return Container(
        decoration: BoxDecoration(
          gradient: controller.getBackgroundGradient(),
        ),
        child: widget.child,
      );
    });
  }
}

// Themed Card Widget
class ThemedCard extends StatefulWidget {
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
  State<ThemedCard> createState() => _ThemedCardState();
}

class _ThemedCardState extends State<ThemedCard> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      Widget cardWidget = Container(
        margin: widget.margin,
        decoration: controller.getThemedDecoration(
          borderRadius: widget.borderRadius,
          withShadow: widget.withShadow,
          withGradient: widget.withGradient,
        ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: widget.child,
        ),
      );

      if (widget.onTap != null) {
        return GestureDetector(
          onTap: widget.onTap,
          child: cardWidget,
        );
      }

      return cardWidget;
    });
  }
}

// Themed Button Widget
class ThemedButton extends StatefulWidget {
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
  State<ThemedButton> createState() => _ThemedButtonState();
}

class _ThemedButtonState extends State<ThemedButton> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.isOutlined
            ? OutlinedButton.icon(
                onPressed: widget.onPressed,
                icon: widget.icon != null ? Icon(widget.icon) : const SizedBox.shrink(),
                label: Text(widget.text),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: widget.icon != null ? Icon(widget.icon) : const SizedBox.shrink(),
                label: Text(widget.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      );
    });
  }
}

// Themed App Bar
class ThemedAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<ThemedAppBar> createState() => _ThemedAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ThemedAppBarState extends State<ThemedAppBar> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      return AppBar(
        title: Text(widget.title),
        actions: widget.actions,
        leading: widget.leading,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
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
    });
  }
}

// Themed Icon Button
class ThemedIconButton extends StatefulWidget {
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
  State<ThemedIconButton> createState() => _ThemedIconButtonState();
}

class _ThemedIconButtonState extends State<ThemedIconButton> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      Widget iconWidget = Icon(
        widget.icon,
        size: widget.size,
        color: colors.primary,
      );

      if (widget.isCircular) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withOpacity(0.1),
          ),
          child: IconButton(
            onPressed: widget.onPressed,
            tooltip: widget.tooltip,
            icon: iconWidget,
          ),
        );
      }

      return IconButton(
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
        icon: iconWidget,
      );
    });
  }
}

// Themed Text Widget dengan warna otomatis
class ThemedText extends StatefulWidget {
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
  State<ThemedText> createState() => _ThemedTextState();
}

class _ThemedTextState extends State<ThemedText> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      Color? textColor;
      if (widget.isPrimary) {
        textColor = colors.primary;
      } else if (widget.isSecondary) {
        textColor = colors.secondary;
      }

      return Text(
        widget.text,
        style: (widget.style ?? const TextStyle()).copyWith(
          color: textColor ?? widget.style?.color,
        ),
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
      );
    });
  }
}

// Themed Container dengan animasi
class AnimatedThemedContainer extends StatefulWidget {
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
  State<AnimatedThemedContainer> createState() => _AnimatedThemedContainerState();
}

class _AnimatedThemedContainerState extends State<AnimatedThemedContainer> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      return AnimatedContainer(
        duration: widget.duration,
        margin: widget.margin,
        decoration: controller.getThemedDecoration(
          borderRadius: widget.borderRadius,
          withShadow: widget.withShadow,
          withGradient: widget.withGradient,
        ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: widget.child,
        ),
      );
    });
  }
}

// Themed Floating Action Button
class ThemedFloatingActionButton extends StatefulWidget {
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
  State<ThemedFloatingActionButton> createState() => _ThemedFloatingActionButtonState();
}

class _ThemedFloatingActionButtonState extends State<ThemedFloatingActionButton> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      return FloatingActionButton(
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
        mini: widget.mini,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        child: Icon(widget.icon),
      );
    });
  }
}

// Themed Bottom Navigation Bar
class ThemedBottomNavigationBar extends StatefulWidget {
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
  State<ThemedBottomNavigationBar> createState() => _ThemedBottomNavigationBarState();
}

class _ThemedBottomNavigationBarState extends State<ThemedBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      return BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        items: widget.items,
        selectedItemColor: colors.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      );
    });
  }
}

// Themed Scaffold
class ThemedScaffold extends StatefulWidget {
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
  State<ThemedScaffold> createState() => _ThemedScaffoldState();
}

class _ThemedScaffoldState extends State<ThemedScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      extendBody: widget.extendBody,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.bottomNavigationBar,
      drawer: widget.drawer,
      body: widget.withBackground ? ThemedBackground(child: widget.body) : widget.body,
    );
  }
}

// Themed ListTile
class ThemedListTile extends StatefulWidget {
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
  State<ThemedListTile> createState() => _ThemedListTileState();
}

class _ThemedListTileState extends State<ThemedListTile> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      return ListTile(
        leading: widget.leading,
        title: widget.title,
        subtitle: widget.subtitle,
        trailing: widget.trailing,
        onTap: widget.onTap,
        contentPadding: widget.contentPadding,
        selected: widget.selected,
        selectedTileColor: colors.primary.withOpacity(0.1),
        selectedColor: colors.primary,
      );
    });
  }
}

// Themed Divider
class ThemedDivider extends StatefulWidget {
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
  State<ThemedDivider> createState() => _ThemedDividerState();
}

class _ThemedDividerState extends State<ThemedDivider> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = ThemeController.to;
      final colors = controller.getThemeColors();

      return Divider(
        height: widget.height,
        thickness: widget.thickness,
        indent: widget.indent,
        endIndent: widget.endIndent,
        color: colors.primary.withOpacity(0.2),
      );
    });
  }
}