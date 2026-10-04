import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ModernDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? footer;
  final List<Widget>? actions;
  final double width;

  const ModernDialog({
    super.key,
    required this.title,
    required this.content,
    this.footer,
    this.actions,
    this.width = 480,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 24 : 32)),
      child: Container(
        width: width,
        padding: EdgeInsets.all(isCompact ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 22, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: -0.5
                    ),
                  ),
                ),
                if (actions != null) ...[
                  ...actions!,
                  SizedBox(width: isCompact ? 8 : 12),
                ],
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(CupertinoIcons.multiply, size: isCompact ? 20 : 22, color: Colors.black26),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 20 : 32),
            Flexible(child: content),
            if (footer != null) ...[
              SizedBox(height: isCompact ? 20 : 32),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class ModernField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool hasBottomPadding;

  const ModernField({
    super.key,
    required this.label,
    required this.child,
    this.hasBottomPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: hasBottomPadding ? 24 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w600),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ModernInputContainer extends StatelessWidget {
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  const ModernInputContainer({
    super.key,
    required this.child,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? Colors.black26),
            const SizedBox(width: 12),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 18),
      color: isPrimary ? const Color(0xFFE8F5F2) : const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(16),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isPrimary ? const Color(0xFF006D63) : const Color(0xFFFF4545),
        ),
      ),
    );
  }
}
