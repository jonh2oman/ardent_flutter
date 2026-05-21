import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPriority = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final corpsId = auth.userData?.corpsId;

    if (corpsId == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTICE BOARD',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                    ),
                    Text(
                      'Unit announcements and communications',
                      style: TextStyle(color: Colors.white24, fontSize: 16),
                    ),
                  ],
                ),
                if (auth.userData?.isSupportAdmin ?? false)
                  ElevatedButton.icon(
                    onPressed: () => _showPostDialog(context, corpsId, auth.userData!.name),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('POST NOTICE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('corps')
                    .doc(corpsId)
                    .collection('notices')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final notices = snapshot.data!.docs;

                  if (notices.isEmpty) {
                    return const Center(child: Text('No notices posted yet.', style: TextStyle(color: Colors.white12)));
                  }

                  return ListView.builder(
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final notice = notices[index].data() as Map<String, dynamic>;
                      final id = notices[index].id;
                      return _buildNoticeCard(theme, id, notice, auth.userData?.isSupportAdmin ?? false, corpsId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(ThemeData theme, String id, Map<String, dynamic> notice, bool canDelete, String corpsId) {
    final bool isPriority = notice['priority'] ?? false;
    final DateTime? date = (notice['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPriority ? Colors.orangeAccent.withOpacity(0.05) : theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPriority ? Colors.orangeAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isPriority)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent, size: 16),
                    ),
                  Text(
                    notice['title'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPriority ? Colors.orangeAccent : Colors.white,
                    ),
                  ),
                ],
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.white24),
                  onPressed: () => _deleteNotice(corpsId, id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notice['content'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(LucideIcons.user, size: 12, color: Colors.white24),
              const SizedBox(width: 8),
              Text(
                notice['author'] ?? 'Unknown Author',
                style: const TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              const Icon(LucideIcons.calendar, size: 12, color: Colors.white24),
              const SizedBox(width: 8),
              Text(
                date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Unknown Date',
                style: const TextStyle(fontSize: 11, color: Colors.white24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostDialog(BuildContext context, String corpsId, String author) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('New Notice', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Content', hintText: 'What do you want to announce?'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isPriority,
                    onChanged: (val) => setDialogState(() => _isPriority = val ?? false),
                    activeColor: Colors.orangeAccent,
                  ),
                  const Text('Mark as Priority', style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () => _postNotice(context, corpsId, author),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text('POST'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postNotice(BuildContext context, String corpsId, String author) async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('notices').add({
      'title': _titleController.text,
      'content': _contentController.text,
      'priority': _isPriority,
      'author': author,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _contentController.clear();
    _isPriority = false;
    
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteNotice(String corpsId, String id) async {
    await FirebaseFirestore.instance.collection('corps').doc(corpsId).collection('notices').doc(id).delete();
  }
}
