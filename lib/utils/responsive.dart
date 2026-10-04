import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) {
    // Check if host is mobile subdomain
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.startsWith('mobile.')) return true;
    }
    
    // Fallback to screen width
    return MediaQuery.of(context).size.width < 850;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 850 && !Uri.base.host.startsWith('mobile.');

  @override
  Widget build(BuildContext context) {
    return isMobile(context) ? mobile : desktop;
  }
}
