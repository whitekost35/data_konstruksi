import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFE8F5E9);
  static const blue = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFEFF6FF);
  static const orange = Color(0xFFF59E0B);
  static const orangeSoft = Color(0xFFFFF7E8);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFF5F0FF);
  static const red = Color(0xFFEF4444);
  static const redSoft = Color(0xFFFFF1F2);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE7ECF1);
  static const page = Color(0xFFF8FAFC);
}

class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const AppPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.borderRadius = const BorderRadius.all(Radius.circular(20))});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.line),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: padding,
      child: child,
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const PageHeader({super.key, required this.title, required this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color softColor;

  const MetricCard({super.key, required this.title, required this.value, this.subtitle, required this.icon, required this.color, required this.softColor});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: softColor, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 23)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))],
        ])),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
    if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
  ]);
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const StatusPill({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
  );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const EmptyState({super.key, required this.title, required this.subtitle, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.inbox_outlined, color: AppColors.green)),
    const SizedBox(height: 14), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
  ])));
}
