import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'fundraising_tabs/campaigns_tab.dart';
import 'fundraising_tabs/assignment_tab.dart';
import 'fundraising_tabs/returns_tab.dart';
import 'fundraising_tabs/report_tab.dart';

class FundraisingScreen extends StatefulWidget {
  const FundraisingScreen({Key? key}) : super(key: key);

  @override
  _FundraisingScreenState createState() => _FundraisingScreenState();
}

class _FundraisingScreenState extends State<FundraisingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildTabBar(),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final corpsId = auth.userData?.corpsId ?? '';
                if (corpsId.isEmpty) return const SizedBox.shrink();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    CampaignsTab(corpsId: corpsId),
                    AssignmentTab(corpsId: corpsId),
                    ReturnsTab(corpsId: corpsId),
                    ReportTab(corpsId: corpsId),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Fundraising',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 90),
            child: Text(
              'Manage fundraising campaigns, track product distribution, and log returns.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        tabs: const [
          Tab(text: 'Campaigns & Products'),
          Tab(text: 'Product Assignment'),
          Tab(text: 'Log Returns'),
          Tab(text: 'Report'),
        ],
      ),
    );
  }

}
