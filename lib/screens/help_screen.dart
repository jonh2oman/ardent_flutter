import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../data/help_data.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HelpTopic> get _filteredTopics {
    if (_searchQuery.isEmpty) return HelpData.topics;
    final lowerQuery = _searchQuery.toLowerCase();
    return HelpData.topics.where((topic) {
      return topic.title.toLowerCase().contains(lowerQuery) ||
             topic.content.toLowerCase().contains(lowerQuery) ||
             topic.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help & Settings'),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildKnowledgeBase(theme),
          ),
          if (isDesktop)
            Container(width: 1, color: theme.dividerColor.withOpacity(0.1)),
          if (isDesktop)
            Expanded(
              flex: 1,
              child: _buildSidePanel(theme),
            ),
        ],
      ),
      // For mobile, we could put the side panel at the bottom of a ListView, but standard Row is fine for now
      // Or we can just build the side panel below the knowledge base if not desktop
    );
  }

  Widget _buildKnowledgeBase(ThemeData theme) {
    final topics = _filteredTopics;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help?',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search documentation...',
                  prefixIcon: const Icon(LucideIcons.search),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: topics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.fileQuestion, size: 48, color: theme.unselectedWidgetColor),
                      const SizedBox(height: 16),
                      Text('No articles found for "$_searchQuery"'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                      ),
                      child: ExpansionTile(
                        title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(topic.category, style: TextStyle(fontSize: 12, color: theme.primaryColor)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(topic.content, style: const TextStyle(height: 1.5)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (MediaQuery.of(context).size.width < 800)
          _buildSidePanel(theme),
      ],
    );
  }

  Widget _buildSidePanel(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSelector(theme),
          const SizedBox(height: 32),
          _buildAboutSection(theme),
          const SizedBox(height: 32),
          _buildChangelogSection(theme),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.palette, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text('Appearance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: AppThemeMode.values.map((mode) {
              final isSelected = themeProvider.themeMode == mode;
              final name = mode.toString().split('.').last.replaceAllMapped(
                    RegExp(r'[A-Z]'),
                    (match) => ' ${match.group(0)}',
                  );
              final capitalizedName = name[0].toUpperCase() + name.substring(1);

              return RadioListTile<AppThemeMode>(
                title: Text(capitalizedName),
                value: mode,
                groupValue: themeProvider.themeMode,
                activeColor: theme.primaryColor,
                onChanged: (AppThemeMode? value) {
                  if (value != null) {
                    themeProvider.setTheme(value);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final unitName = authProvider.corpsData?.unitDesignation ?? 'Command Center';
    final title = unitName.toLowerCase().contains('command center') 
        ? unitName 
        : '$unitName Command Center';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.info, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Version ${HelpData.version}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              Text('Author', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(HelpData.author, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangelogSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.listOrdered, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text('Changelog', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        ...HelpData.changelog.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry['version']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(entry['date']!, style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(entry['notes']!, style: const TextStyle(height: 1.5)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
