import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mobile_navigation_provider.dart';
import 'mobile_dashboard_screen.dart';
import 'mobile_attendance_screen.dart';
import 'mobile_salary_summary_screen.dart';
import 'mobile_kasbon_ledger_screen.dart';
import '../bumimas_modern_detail_screen.dart';
import '../worker_screen.dart';
import 'package:data_konstruksi/services/auth_provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';

class MobileMainShell extends StatefulWidget {
  const MobileMainShell({super.key});

  @override
  State<MobileMainShell> createState() => _MobileMainShellState();
}

class _MobileMainShellState extends State<MobileMainShell> {
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

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<MobileNavigationProvider>();
    final auth = context.read<AuthProvider>();
    final provider = context.watch<ProjectProvider>();
    final profile = provider.userProfile;
    
    final screens = [
      const MobileDashboardScreen(),
      const MobileAttendanceScreen(),
      const MobileSalarySummaryScreen(),
      const MobileKasbonLedgerScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Konstruksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DrawerHeader(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF005BBF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.building_2_fill, color: Colors.white, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              auth.isAdmin ? 'Manager' : 'Proyek Anda',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16)
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // User Profile Section
                    if (profile != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFFE3E3E3),
                                  backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                                  child: profile.photoUrl == null 
                                    ? const Icon(CupertinoIcons.person_fill, color: Colors.black54, size: 30) 
                                    : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                                      Text(profile.status, style: const TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _profileDetail(CupertinoIcons.location_solid, profile.address),
                            const SizedBox(height: 8),
                            _profileDetail(CupertinoIcons.phone_fill, profile.contact),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(CupertinoIcons.person_2_fill, color: Color(0xFF007AFF)),
                      title: const Text('Manajemen Pekerja', style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerScreen()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(CupertinoIcons.cart_fill, color: Color(0xFF5856D6)),
                      title: const Text('Bumimas Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BumimasModernDetailScreen(category: 'Bumimas_Belanja')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF34C759)),
                      title: const Text('Bumimas Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BumimasModernDetailScreen(category: 'Bumimas_Lunas')));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(CupertinoIcons.power, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
              onTap: () {
                provider.clearProfile();
                auth.logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: screens[navProvider.currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: navProvider.currentIndex,
        onDestinationSelected: (i) => navProvider.setIndex(i),
        destinations: const [
          NavigationDestination(icon: Icon(CupertinoIcons.house_fill), label: 'Dashboard'),
          NavigationDestination(icon: Icon(CupertinoIcons.calendar_badge_minus), label: 'Absensi'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Gajian'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Kasbon'),
        ],
      ),
    );
  }

  Widget _profileDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text, 
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
