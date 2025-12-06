import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';

enum AppBarType {
  normal,
  transparent,
  colored,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final AppBarType type;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? flexibleSpace;
  final Widget? titleWidget;
  final double elevation;
  final double height;
  final bool automaticallyImplyLeading;
  final VoidCallback? onLeadingPressed;
  
  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.type = AppBarType.normal,
    this.backgroundColor,
    this.textColor,
    this.flexibleSpace,
    this.titleWidget,
    this.elevation = 4.0,
    this.height = kToolbarHeight,
    this.automaticallyImplyLeading = true,
    this.onLeadingPressed,
  }) : super(key: key);
  
  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    // Determinar color de fondo según el tipo
    final Color bgColor = _getBackgroundColor();
    
    // Determinar color de texto según el tipo y el color de fondo
    final Color txtColor = textColor ?? _getTextColor(bgColor);
    
    return AppBar(
      title: titleWidget ?? Text(
        title,
        style: TextStyle(
          color: txtColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      leading: _buildLeadingWidget(context, txtColor),
      centerTitle: centerTitle,
      backgroundColor: bgColor,
      elevation: type == AppBarType.transparent ? 0 : elevation,
      flexibleSpace: flexibleSpace,
      automaticallyImplyLeading: automaticallyImplyLeading,
      iconTheme: IconThemeData(color: txtColor),
    );
  }
  
  // Construir widget para el botón de navegación hacia atrás
  Widget? _buildLeadingWidget(BuildContext context, Color iconColor) {
    if (leading != null) {
      return leading;
    }
    
    if (automaticallyImplyLeading && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: iconColor,
        onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
      );
    }
    
    return null;
  }
  
  // Determinar color de fondo según el tipo
  Color _getBackgroundColor() {
    switch (type) {
      case AppBarType.transparent:
        return Colors.transparent;
      case AppBarType.colored:
        return backgroundColor ?? AppTheme.primaryColor;
      case AppBarType.normal:
      default:
        return backgroundColor ?? AppTheme.primaryColor;
    }
  }
  
  // Determinar color de texto apropiado basado en el color de fondo
  Color _getTextColor(Color backgroundColor) {
    if (backgroundColor == Colors.transparent) {
      return AppTheme.textPrimaryColor;
    }
    
    // Calcular luminancia para determinar si usar texto claro u oscuro
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// App Bar con logo de la empresa
class LogoAppBar extends CustomAppBar {
  final double logoHeight;
  final String? logoPath;
  final VoidCallback? onLogoTap;
  
  LogoAppBar({
    Key? key,
    String title = '',
    List<Widget>? actions,
    Widget? leading,
    AppBarType type = AppBarType.normal,
    Color? backgroundColor,
    Color? textColor,
    double elevation = 4.0,
    bool automaticallyImplyLeading = true,
    VoidCallback? onLeadingPressed,
    this.logoHeight = 40,
    this.logoPath,
    this.onLogoTap,
  }) : super(
    key: key,
    title: title,
    actions: actions,
    leading: leading,
    type: type,
    backgroundColor: backgroundColor,
    textColor: textColor,
    centerTitle: true,
    elevation: elevation,
    automaticallyImplyLeading: automaticallyImplyLeading,
    onLeadingPressed: onLeadingPressed,
    titleWidget: GestureDetector(
      onTap: onLogoTap,
      child: Image.asset(
        logoPath ?? 'assets/images/logo.png',
        height: logoHeight,
      ),
    ),
  );
}