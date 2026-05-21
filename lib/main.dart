import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'providers/auth_provider.dart';
import 'models/user_data.dart';
import 'widgets/stat_card.dart';
import 'screens/personnel_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/exchange_screen.dart';
import 'screens/supply_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/promotion_screen.dart';
import 'screens/training_dashboard_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/bulletin_board_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/marksmanship_screen.dart';
import 'providers/marksmanship_provider.dart';
import 'screens/financials_screen.dart';
import 'screens/awards_screen.dart';
import 'screens/succession_screen.dart';
import 'screens/ships_log_screen.dart';
import 'screens/fundraising_screen.dart';
import 'screens/lsa_wish_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'providers/theme_provider.dart';
import 'screens/help_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Manual Firebase initialization using your project config
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCCsCNA6wAGThwp2M3v7dtCmi43IK6whWQ",
      authDomain: "rcscc-training-plan.firebaseapp.com",
      projectId: "rcscc-training-plan",
      storageBucket: "rcscc-training-plan.firebasestorage.app",
      messagingSenderId: "253553612091",
      // Use platform-specific App ID
      appId: kIsWeb 
          ? "1:253553612091:web:10bedc76c37a0f2a76131e" 
          : (defaultTargetPlatform == TargetPlatform.macOS)
            ? "1:253553612091:ios:dc21d5f8562e4f2076131e"
            : "1:253553612091:web:10bedc76c37a0f2a76131e", // Default to web ID for other platforms for now
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MarksmanshipProvider>(
          create: (_) => MarksmanshipProvider(),
          update: (_, auth, marksmanship) {
            final corpsId = auth.userData?.corpsId;
            if (corpsId != null && corpsId != 'PENDING') {
              marksmanship!.init(corpsId);
            } else {
              marksmanship!.logout();
            }
            return marksmanship;
          },
        ),
      ],
      child: const ArdentApp(),
    ),
  );
}

class ArdentApp extends StatelessWidget {
  const ArdentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Command Center',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getThemeData(context),
          home: const RootHandler(),
        );
      },
    );
  }
}

class RootHandler extends StatelessWidget {
  const RootHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.user == null) {
      return const LoginScreen();
    }

    if (authProvider.userData?.corpsId == 'PENDING' || authProvider.userData?.isPendingAssignment == true) {
      return const WaitingRoomScreen();
    }

    return const DashboardScreen();
  }
}

// Placeholder Screens to be implemented next
// Login Screen with real Firebase logic
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoggingIn = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.anchor, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              const Text(
                'ARDENT COMMAND',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tactical Training Planner',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(LucideIcons.mail, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(LucideIcons.lock, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoggingIn 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('INITIALIZE SESSION', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Waiting for Unit Assignment...'),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _exchangeInitialTab = 0;

  List<String> _categoryOrder = [];
  Map<String, bool> _collapsedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadNavPreferences();
  }

  Future<void> _loadNavPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final orderStr = prefs.getString('nav_category_order');
      if (orderStr != null) {
        _categoryOrder = List<String>.from(json.decode(orderStr));
      }
      final collapsedStr = prefs.getString('nav_collapsed_categories');
      if (collapsedStr != null) {
        _collapsedCategories = Map<String, bool>.from(json.decode(collapsedStr));
      }
    });
  }

  Future<void> _saveNavPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nav_category_order', json.encode(_categoryOrder));
    await prefs.setString('nav_collapsed_categories', json.encode(_collapsedCategories));
  }

  List<_NavItem> _getNavItems(UserData? user) {
    final modules = user?.permissions['modules'] as Map<String, dynamic>? ?? {};
    final isSupportAdmin = user?.isSupportAdmin ?? false;
    final isAdmin = user?.isAdmin ?? false;
    final isAnyAdmin = isSupportAdmin || isAdmin;

    final items = [
      _NavItem(
        icon: LucideIcons.layoutDashboard,
        label: 'Dashboard',
        page: DashboardHome(
          onFeatureTap: (feature) {
            String targetLabel = '';
            int? initialTab;
            
            switch (feature) {
              case 'ATP Planner':
                targetLabel = 'Calendar';
                break;
              case 'Op Orders':
                targetLabel = 'Orders';
                break;
              case 'Financials':
                targetLabel = 'Financials';
                break;
              case 'Roster':
                targetLabel = 'Personnel';
                break;
              case 'Awards':
                targetLabel = 'Promotions';
                break;
              case 'Succession':
                targetLabel = 'Succession';
                break;
              case 'Attendance':
                targetLabel = 'Calendar';
                break;
              case 'Supply':
                targetLabel = 'Supply';
                break;
              case 'Canteen':
                targetLabel = 'Exchange';
                initialTab = 1;
                break;
            }

            if (targetLabel.isNotEmpty) {
              if (targetLabel.toLowerCase() == 'exchange') {
                setState(() {
                  _exchangeInitialTab = initialTab ?? 0;
                });
              }
              final navItems = _getNavItems(user);
              final idx = navItems.indexWhere((it) => it.label.toLowerCase() == targetLabel.toLowerCase());
              if (idx != -1) {
                setState(() {
                  _selectedIndex = idx;
                });
              }
            }
          },
        ),
        category: 'COMMAND',
      ),
      _NavItem(
        icon: LucideIcons.megaphone,
        label: 'Notices',
        page: const BulletinBoardScreen(),
        category: 'COMMAND',
      ),
      _NavItem(
        icon: LucideIcons.calendar,
        label: 'Calendar',
        page: const CalendarScreen(),
        category: 'TRAINING',
      ),
      if (isAnyAdmin)
        _NavItem(
          icon: LucideIcons.settings,
          label: 'Admin',
          page: const AdminSettingsScreen(),
          category: 'ADMIN',
        ),
      if (isAnyAdmin || modules['admin'] == true)
        _NavItem(
          icon: LucideIcons.bookOpen,
          label: 'Ship\'s Log',
          page: const ShipsLogScreen(),
          category: 'ADMIN',
        ),
      if (isAnyAdmin || (modules['personnel'] ?? false))
        _NavItem(
          icon: LucideIcons.users,
          label: 'Personnel',
          page: const PersonnelScreen(),
          category: 'OPERATIONS',
        ),
      if (isAnyAdmin || (modules['personnel'] ?? false))
        _NavItem(
          icon: LucideIcons.gitMerge,
          label: 'Succession',
          page: const SuccessionScreen(),
          category: 'OPERATIONS',
        ),
      if (isAnyAdmin || (modules['personnel'] ?? false))
        _NavItem(
          icon: LucideIcons.award,
          label: 'Promotions',
          page: const PromotionScreen(),
          category: 'OPERATIONS',
        ),
      if (isAnyAdmin || (modules['personnel'] ?? false))
        _NavItem(
          icon: LucideIcons.medal,
          label: 'Awards',
          page: const AwardsScreen(),
          category: 'OPERATIONS',
        ),
      if (isAnyAdmin || (modules['training'] ?? false))
        _NavItem(
          icon: LucideIcons.barChart2,
          label: 'Analytics',
          page: const TrainingDashboardScreen(),
          category: 'TRAINING',
        ),
      if (isAnyAdmin || (modules['marksmanship'] ?? false))
        _NavItem(
          icon: LucideIcons.target,
          label: 'Range',
          page: const MarksmanshipScreen(),
          category: 'TRAINING',
        ),
      if (isAnyAdmin || (modules['finance'] ?? false))
        _NavItem(
          icon: LucideIcons.coins,
          label: 'Exchange',
          page: ExchangeScreen(initialTab: _exchangeInitialTab),
          category: 'LOGISTICS',
        ),
      if (isAnyAdmin || (modules['finance'] ?? false))
        _NavItem(
          icon: LucideIcons.wallet,
          label: 'Financials',
          page: const FinancialsScreen(),
          category: 'LOGISTICS',
        ),
      if (isAnyAdmin || (modules['finance'] ?? false))
        _NavItem(
          icon: LucideIcons.banknote,
          label: 'Fundraising',
          page: const FundraisingScreen(),
          category: 'LOGISTICS',
        ),
      if (isAnyAdmin || (modules['orders'] ?? false))
        _NavItem(
          icon: LucideIcons.fileText,
          label: 'Orders',
          page: const OrdersScreen(),
          category: 'LOGISTICS',
        ),
      if (isAnyAdmin || (modules['supply'] ?? false))
        _NavItem(
          icon: LucideIcons.package,
          label: 'Supply',
          page: const SupplyScreen(),
          category: 'LOGISTICS',
        ),
      if (isAnyAdmin || (modules['supply'] ?? false))
        _NavItem(
          icon: LucideIcons.listPlus,
          label: 'LSA Wish List',
          page: const LSAWishListScreen(),
          category: 'LOGISTICS',
        ),
      _NavItem(
        icon: LucideIcons.helpCircle,
        label: 'Help & Settings',
        page: const HelpScreen(),
        category: 'SYSTEM',
      ),
    ];

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final navItems = _getNavItems(authProvider.userData);

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    final Map<String, List<int>> groupedIndices = {};
    for (int i = 0; i < navItems.length; i++) {
      final cat = navItems[i].category;
      groupedIndices.putIfAbsent(cat, () => []).add(i);
    }

    for (var cat in groupedIndices.keys) {
      if (!_categoryOrder.contains(cat)) {
        _categoryOrder.add(cat);
      }
    }
    _categoryOrder.removeWhere((cat) => !groupedIndices.containsKey(cat));

    return Scaffold(
      body: Row(
        children: [
          // Custom Sidebar
          Container(
            width: 260,
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 40),
                if (authProvider.corpsData?.logoUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Image.network(
                            authProvider.corpsData!.logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              LucideIcons.anchor, 
                              color: theme.colorScheme.primary, 
                              size: 40
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authProvider.corpsData?.unitDesignation.toUpperCase() ?? 'ARDENT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 14, 
                            letterSpacing: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.anchor, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          authProvider.corpsData?.unitDesignation.toUpperCase() ?? 'COMMAND CENTER',
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 18, 
                            letterSpacing: 2,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                Expanded(
                  child: ReorderableListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _categoryOrder.removeAt(oldIndex);
                        _categoryOrder.insert(newIndex, item);
                        _saveNavPreferences();
                      });
                    },
                    children: _categoryOrder.map((category) {
                      final indices = groupedIndices[category] ?? [];
                      if (indices.isEmpty) return SizedBox.shrink(key: ValueKey('empty_$category'));
                      final isCollapsed = _collapsedCategories[category] ?? false;

                      return Column(
                        key: ValueKey(category),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _collapsedCategories[category] = !isCollapsed;
                                _saveNavPreferences();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12, top: 24, bottom: 8, right: 12),
                              child: Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: _categoryOrder.indexOf(category),
                                    child: Icon(LucideIcons.gripVertical, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  Icon(
                                    isCollapsed ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                                    size: 14,
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isCollapsed)
                            ...indices.map((index) {
                              final item = navItems[index];
                              final isSelected = _selectedIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  selected: isSelected,
                                  selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
                                  leading: Icon(
                                    item.icon,
                                    size: 18,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  title: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  onTap: () {
                                     if (item.label.toLowerCase() == 'exchange') {
                                       setState(() {
                                         _exchangeInitialTab = 0;
                                       });
                                     }
                                     setState(() => _selectedIndex = index);
                                   },
                                ),
                              );
                            }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(LucideIcons.logOut, size: 18, color: Colors.redAccent),
                    title: const Text('Logout', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                    onTap: () => authProvider.logout(),
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(thickness: 1, width: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          // Main Content Area
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: navItems[_selectedIndex].page,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget page;
  final String category;

  _NavItem({
    required this.icon,
    required this.label,
    required this.page,
    required this.category,
  });
}

class DashboardHome extends StatelessWidget {
  final Function(String) onFeatureTap;
  const DashboardHome({super.key, required this.onFeatureTap});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final List<dynamic> cadets = authProvider.corpsData?.settings?['cadets'] ?? [];
    final int staffCount = authProvider.staffCount;
    final int activeCadets = cadets.where((c) => c['isArchived'] != true).length;
    
    // Calculate attendance snapshot
    final currentYear = authProvider.corpsData?.trainingYears?['current'] as Map<String, dynamic>?;
    final attendance = currentYear?['attendance'] ?? {};
    double attendancePercent = 100.0;
    if (attendance.isNotEmpty) {
      // Basic calculation for the summary
      attendancePercent = 88.0; // We'll refine this once Attendance module is ported
    }

    // Calculate current unit status
    final calendar = currentYear?['calendar'] as Map<String, dynamic>? ?? {};
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayEvent = calendar[todayKey];
    
    final bool isActive = todayEvent != null;
    final String statusText = todayEvent?['type'] == 'lhq' 
        ? 'LHQ ACTIVE' 
        : (todayEvent?['type'] == 'weekend' ? 'WEEKEND TRG' : 'STAND DOWN');
    
    final Color statusColor = todayEvent?['type'] == 'lhq' 
        ? Colors.green 
        : (todayEvent?['type'] == 'weekend' ? Colors.amber : Colors.white38);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DASHBOARD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (authProvider.userData == null)
                        ? 'SYNCING PROFILE...'
                        : 'Welcome Aboard, ${authProvider.userData?.rank ?? ""} ${authProvider.userData?.lastName ?? "Officer"}'.toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: statusColor),
                    const SizedBox(width: 8),
                    Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              StatCard(title: 'Personnel', value: '${activeCadets + staffCount}', icon: LucideIcons.users, iconColor: Colors.blueAccent),
              StatCard(title: 'Training', value: '85%', icon: LucideIcons.checkCircle, iconColor: Colors.greenAccent),
              StatCard(title: 'Attendance', value: '${attendancePercent.toInt()}%', icon: LucideIcons.percent, iconColor: Colors.amberAccent),
              StatCard(title: 'Economy', value: '\$0', icon: LucideIcons.dollarSign, iconColor: Colors.tealAccent),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'RECENT NOTICES',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white54),
          ),
          const SizedBox(height: 24),
          _buildRecentNotices(authProvider.userData?.corpsId),
          const SizedBox(height: 40),
          const Text(
            'SYSTEM MODULES',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          // Module Cards
          _buildModuleGrid(context),
        ],
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 1,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.2,
      children: [
        _ModuleCard(
          title: 'Strategic Planning',
          description: 'Master the training cycle with strategic tools for every level of leadership.',
          icon: LucideIcons.folderKanban,
          features: const ['ATP Planner', 'Op Orders', 'Financials'],
          onFeatureTap: onFeatureTap,
        ),
        _ModuleCard(
          title: 'Personnel Management',
          description: 'Unified hub for Cadet and Staff records and parent communications.',
          icon: LucideIcons.users,
          features: const ['Roster', 'Awards', 'Succession'],
          onFeatureTap: onFeatureTap,
        ),
        _ModuleCard(
          title: 'Operations',
          description: 'Tactical management of attendance, inventory, and supply chain.',
          icon: LucideIcons.clipboardCheck,
          features: const ['Attendance', 'Supply', 'Canteen'],
          onFeatureTap: onFeatureTap,
        ),
      ],
    );
  }

  Widget _buildRecentNotices(String? corpsId) {
    if (corpsId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('corps')
          .doc(corpsId)
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final notices = snapshot.data!.docs;

        return Column(
          children: notices.map((n) {
            final data = n.data() as Map<String, dynamic>;
            final bool isPriority = data['priority'] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPriority ? Colors.orangeAccent.withOpacity(0.05) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isPriority ? Colors.orangeAccent.withOpacity(0.2) : Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(
                    isPriority ? LucideIcons.alertTriangle : LucideIcons.megaphone, 
                    size: 16, 
                    color: isPriority ? Colors.orangeAccent : Colors.white24
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          data['content'] ?? '', 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 14, color: Colors.white10),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// (Duplicate StatCard removed - using widgets/stat_card.dart)

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<String> features;
  final Function(String) onFeatureTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.features,
    required this.onFeatureTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), height: 1.5),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.map((f) => _FeatureChip(
              label: f,
              onTap: () => onFeatureTap(f),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FeatureChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
