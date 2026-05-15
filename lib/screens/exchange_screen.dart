import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class ExchangeScreen extends StatelessWidget {
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final userData = auth.userData;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARDENT EXCHANGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unit Bank & Rewards',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                ),
              ],
            ),
          ),
          
          // Merit Balance Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURRENT BALANCE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.coins, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        '${userData?.merits ?? 0}',
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      const Text('MERITS', style: TextStyle(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'RECENT TRANSACTIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1.0),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _buildTransactionHistory(auth, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(AuthProvider auth, ThemeData theme) {
    // In a real app, we'd fetch this from the subcollection.
    // For now, I'll show a "Feature Coming Soon" or a placeholder list.
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowUpRight, color: Colors.greenAccent, size: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unit Activity Participation', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Awarded by Training Officer', style: TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              const Text('+25', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        );
      },
    );
  }
}
