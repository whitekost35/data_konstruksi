import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import 'kasbon_ledger_screen.dart';
import 'salary_summary_screen.dart';
import 'bumimas_modern_detail_screen.dart';
import 'package:data_konstruksi/services/auth_provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<ProjectProvider>().refreshData(profileId: auth.role);
      }
    });
  }

  final screens = [
    const DashboardScreen(),
    const BumimasModernDetailScreen(category: 'Bumimas_Belanja'),
    const BumimasModernDetailScreen(category: 'Bumimas_Lunas'),
    const AttendanceScreen(),
    const SalarySummaryScreen(),
    const KasbonLedgerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFE8ECEF), Color(0xFFF8F9FA), Color(0xFFE3E6E8)],
        ))),
        Positioned(top: -120, right: -120, child: Container(
          width: 520, height: 520,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF007AFF).withValues(alpha: .035)),
        )),
        Row(children: [
          _sidebar(context),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey(index), child: screens[index]),
          )),
        ]),
      ]),
    );
  }

  Widget _sidebar(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .35),
        border: Border(right: BorderSide(color: Colors.black.withValues(alpha: .06))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 20, 48),
              child: Row(children: [
                const Icon(CupertinoIcons.building_2_fill, color: Colors.black, size: 40),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(auth.isAdmin ? 'Admin' : 'Owner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
                  const Text('Data Konstruksi', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ]),
            ),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              _item(0, CupertinoIcons.house_fill, 'Dashboard', Colors.black),
              const SizedBox(height: 12),
              _item(1, CupertinoIcons.cart_fill, 'Bumimas Belanja', Colors.black),
              const SizedBox(height: 12),
              _item(2, CupertinoIcons.check_mark, 'Bumimas Lunas', Colors.black),
              const SizedBox(height: 12),
              _item(3, CupertinoIcons.calendar_badge_minus, 'Absensi', Colors.black),
              const SizedBox(height: 12),
              _item(4, Icons.payments, 'Gajian', Colors.black),
              const SizedBox(height: 12),
              _item(5, Icons.account_balance_wallet, 'Kasbon', Colors.black),
            ])),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label, Color iconColor) {
    final selected = i == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? Colors.black.withValues(alpha: .05) : Colors.transparent, 
          borderRadius: BorderRadius.circular(12)
        ),
        child: ListTile(
          onTap: () {
            if (i == -1) {
              context.read<ProjectProvider>().clearProfile();
              context.read<AuthProvider>().logout();
            } else {
              setState(() => index = i);
            }
          },
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, size: 24, color: iconColor),
          title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: iconColor == Colors.redAccent ? Colors.redAccent : Colors.black)),
        ),
      ),
    );
  }
}
