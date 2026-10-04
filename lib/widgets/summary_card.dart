import 'dart:ui';
import 'package:flutter/material.dart';

class SummaryCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? extraValue;
  final IconData? icon; // Now optional
  final String? imagePath; // New parameter for asset icons
  final Color color;
  final bool isActive;
  final bool useGradientValue; // New
  final double? valueFontSize; // New
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.extraValue,
    this.icon,
    this.imagePath,
    required this.color,
    this.isActive = false,
    this.useGradientValue = false,
    this.valueFontSize,
    this.onTap,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: _isHovered ? Matrix4.translationValues(0.0, -4.0, 0.0) : Matrix4.identity(),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          gradient: widget.isActive 
            ? LinearGradient(
                colors: [widget.color, widget.color.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          color: widget.isActive ? null : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.isActive 
                ? widget.color.withValues(alpha: _isHovered ? 0.4 : 0.2)
                : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 25 : 15,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.isActive ? 0 : 10, sigmaY: widget.isActive ? 0 : 10),
            child: Stack(
              children: [
                // Large background trending arrow icon positioned relative to full card
                if (widget.isActive && widget.extraValue != null)
                  Positioned(
                    bottom: 12,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.trending_up, 
                          color: Colors.white.withValues(alpha: 0.1), 
                          size: 70, 
                        ),
                        Text(
                          widget.extraValue!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isActive ? 'Periode Aktif' : widget.title,
                        style: TextStyle(
                          color: widget.isActive ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.useGradientValue)
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF000000), Color(0xFF5856D6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.value,
                              style: TextStyle(
                                fontSize: widget.valueFontSize ?? 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.value,
                            style: TextStyle(
                              fontSize: widget.isActive ? 24 : 26,
                              fontWeight: FontWeight.w800,
                              color: widget.isActive ? Colors.white : Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: widget.isActive ? Colors.white.withValues(alpha: 0.7) : widget.color.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!widget.isActive)
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: widget.imagePath != null 
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              widget.imagePath!, 
                              color: widget.color,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(widget.icon, color: widget.color, size: 24),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
