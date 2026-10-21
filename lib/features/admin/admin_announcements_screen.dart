import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../core/widgets/responsive_container.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/session/session_manager.dart';

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends ConsumerState<AdminAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _msgEnController = TextEditingController();
  final _msgMrController = TextEditingController();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                TextField(controller: _msgEnController, maxLines: 2, decoration: const InputDecoration(labelText: 'Message (English)')),
                const SizedBox(height: 10),
                TextField(controller: _msgMrController, maxLines: 2, decoration: const InputDecoration(labelText: 'Message (मराठी)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  ref.read(adminRepositoryProvider.notifier).createAnnouncement(
                    _titleController.text.trim(),
                    _msgEnController.text.trim(),
                    _msgMrController.text.trim(),
                    'ALL',
                  );
                  _titleController.clear();
                  _msgEnController.clear();
                  _msgMrController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Broadcast'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isMr = strings.isMr;
    final announcements = ref.watch(adminRepositoryProvider).announcements;

    return ResponsiveContainer(
      appBar: AppBar(title: Text(strings.announcements)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: announcements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final anc = announcements[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(anc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(anc.targetAudience, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(anc.getMessage(isMr), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(anc.createdAt, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          );
        },
      ),
    );
  }
}
