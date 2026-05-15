import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'providers/auth_provider.dart';
import 'widgets/stat_card.dart';
import 'screens/personnel_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/exchange_screen.dart';
import 'screens/supply_screen.dart';
import 'screens/routine_orders_screen.dart';
import 'screens/attendance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Manual Firebase initialization using your project config
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCCsCNA6wAGThwp2M3v7dtCmi43IK6whWQ",
      authDomain: "rcscc-training-plan.firebaseapp.com",
      projectId: "rcscc-training-plan",
      storageBucket: "rcscc-training-plan.firebasestorage.app",
      messagingSenderId: "253553612091",
      appId: "1:253553612091:web:10bedc76c37a0f2a76131e", // Web App ID used for consistency, though mobile would typically have its own
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ArdentApp(),
    ),
  );
}

class ArdentApp extends StatelessWidget {
  const ArdentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ardent Command Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1), // Indigo
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B), // Slate 800
        ),
        useMaterial3: true,
      ),
      home: const RootHandler(),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail (Sidebar)
          NavigationRail(
            backgroundColor: theme.colorScheme.surface,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Column(
              children: [
                const SizedBox(height: 20),
                Icon(LucideIcons.anchor, color: theme.colorScheme.primary, size: 32),
                const SizedBox(height: 40),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(LucideIcons.logOut, size: 20),
                    onPressed: () => authProvider.logout(),
                    tooltip: 'Logout',
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(LucideIcons.layoutDashboard),
                label: Text('Dashboard', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.users),
                label: Text('Personnel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.coins),
                label: Text('Exchange', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.fileText),
                label: Text('Orders', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.package),
                label: Text('Supply', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.calendar),
                label: Text('Calendar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.settings),
                label: Text('Settings', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
          // Main Content Area
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: _buildCurrentPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardHome();
      case 1:
        return const PersonnelScreen();
      case 2:
        return const ExchangeScreen();
      case 3:
        return const RoutineOrdersScreen();
      case 4:
        return const SupplyScreen();
      case 5:
        return CalendarScreen();
      default:
        return Center(child: Text('Module ${(_selectedIndex + 1)} Coming Soon'));
    }
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final List<dynamic> cadets = authProvider.corpsData?.settings['cadets'] ?? [];
    final List<dynamic> staff = authProvider.corpsData?.settings['staff'] ?? [];
    final int activeCadets = cadets.where((c) => c['isArchived'] != true).length;
    
    // Calculate attendance snapshot (placeholder logic matching web)
    final attendance = authProvider.corpsData?.trainingYears['current']?['attendance'] ?? {};
    double attendancePercent = 100.0;
    if (attendance.isNotEmpty) {
      // Basic calculation for the summary
      attendancePercent = 88.0; // We'll refine this once Attendance module is ported
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                  ),
                  if (authProvider.userData != null)
                    Text(
                      authProvider.userData!.email.toLowerCase(),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary.withOpacity(0.5), fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Colors.green),
                    SizedBox(width: 8),
                    Text('LHQ ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green)),
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
              StatCard(title: 'Personnel', value: '${activeCadets + staff.length}', icon: LucideIcons.users, iconColor: Colors.blueAccent),
              StatCard(title: 'Training', value: '85%', icon: LucideIcons.checkCircle, iconColor: Colors.greenAccent),
              StatCard(title: 'Attendance', value: '${attendancePercent.toInt()}%', icon: LucideIcons.percent, iconColor: Colors.amberAccent),
              StatCard(title: 'Economy', value: '\$0', icon: LucideIcons.dollarSign, iconColor: Colors.tealAccent),
            ],
          ),
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
        ),
        _ModuleCard(
          title: 'Personnel Management',
          description: 'Unified hub for Cadet and Staff records and parent communications.',
          icon: LucideIcons.users,
          features: const ['Roster', 'Awards', 'Succession'],
        ),
        _ModuleCard(
          title: 'Operations',
          description: 'Tactical management of attendance, inventory, and supply chain.',
          icon: LucideIcons.clipboardCheck,
          features: const ['Attendance', 'Supply', 'Canteen'],
        ),
      ],
    );
  }
}

// (Duplicate StatCard removed - using widgets/stat_card.dart)

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<String> features;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.features,
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
            children: features.map((f) => _FeatureChip(label: f)).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
