class HelpTopic {
  final String title;
  final String content;
  final String category;

  const HelpTopic({
    required this.title,
    required this.content,
    required this.category,
  });
}

class HelpData {
  static const String version = '1.0.0+1'; // Matches pubspec.yaml
  static const String author = 'Jonathan Waterman & Antigravity (Google DeepMind)';
  
  static const List<Map<String, String>> changelog = [
    {
      'version': '1.1.0',
      'date': 'May 2026',
      'notes': '• Added complete Fundraising Module (Campaigns, Assigned Products, Log Returns, PDF Leaderboard)\n• Added Ships Log Module for daily OOD tracking, checklists, and printable PDF exports\n• Added LSA Wish List feature under Supply to track requested items and auto-generate Sponsoring Committee Memos\n• Expanded Succession Planning to support formal Printable Position Letters\n• Enhanced PDF generation stability on macOS',
    },
    {
      'version': '1.0.0+1',
      'date': 'May 2026',
      'notes': '• Initial release of Command Center\n• Integrated Supply, Promotions, and Succession modules\n• Added thematic UI options including Night Vision\n• Added searchable help and documentation',
    },
    {
      'version': '0.9.5-beta',
      'date': 'May 2026',
      'notes': '• Fixed infinite loading PDF layout issues in Supply module\n• Improved cadet uniform data persistence',
    }
  ];

  static const List<HelpTopic> topics = [
    HelpTopic(
      title: 'Managing Personnel',
      category: 'Operations',
      content: 'The Personnel module allows you to view and manage all cadets and staff. You can view their service records, current ranks, and contact information. As an administrator, you can also update their permissions and assign them to specific roles.',
    ),
    HelpTopic(
      title: 'Issuing Uniforms & Kit',
      category: 'Supply',
      content: "Navigate to the Supply module to issue uniform parts. Select a cadet, verify their uniform sizes, and click 'Issue Item'. You can specify the size issued, quantity, and condition. To generate a printable Loan Card, click the PDF icon next to the cadet's name.",
    ),
    HelpTopic(
      title: 'Recording Attendance',
      category: 'Command',
      content: 'Use the Calendar module to track mandatory training periods. For each scheduled event, you can launch the Attendance Tracker. Mark cadets as Present, Absent, Excused, or AWOL. This data flows automatically into their service records and affects promotion eligibility.',
    ),
    HelpTopic(
      title: 'Processing Promotions',
      category: 'Operations',
      content: 'The Promotions module automatically evaluates cadets against the national standard for their next rank. It checks time in rank, phase completion, and attendance. Eligible cadets are highlighted in green. You can override and manually promote cadets if you have the correct administrative permissions.',
    ),
    HelpTopic(
      title: 'Succession Planning',
      category: 'Operations',
      content: 'Use the Succession module to designate primary and secondary backups for key unit positions (e.g., Coxswain, Training Officer). This ensures continuity of command and helps identify training gaps for junior leaders.',
    ),
    HelpTopic(
      title: 'Managing the Exchange (Canteen)',
      category: 'Financials',
      content: 'The Exchange module allows cadets to run a virtual bank account. They earn virtual currency for attendance and performance, which can be spent at the canteen. Use the "Bank Ledger" tab to credit or debit accounts, and the "POS" tab to process purchases.',
    ),
    HelpTopic(
      title: 'Changing App Themes',
      category: 'System',
      content: 'You can customize the appearance of Command Center by navigating to the Settings screen. Available themes include standard Light/Dark modes, as well as tactical themes: Sea, Army, Air, and Night Vision.',
    ),
    HelpTopic(
      title: 'Administrative Settings',
      category: 'System',
      content: 'The Admin module is restricted to high-level users. Here you can configure unit details, manage user access roles, configure the division structure, and export database backups.',
    ),
  ];
}
