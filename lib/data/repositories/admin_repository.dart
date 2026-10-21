import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/complaint_model.dart';
import '../models/announcement_model.dart';
import '../models/enums.dart';
import '../demo/demo_data.dart';

class AdminState {
  final List<ComplaintModel> complaints;
  final List<AnnouncementModel> announcements;

  const AdminState({
    required this.complaints,
    required this.announcements,
  });

  AdminState copyWith({
    List<ComplaintModel>? complaints,
    List<AnnouncementModel>? announcements,
  }) {
    return AdminState(
      complaints: complaints ?? this.complaints,
      announcements: announcements ?? this.announcements,
    );
  }
}

class AdminRepositoryNotifier extends Notifier<AdminState> {
  @override
  AdminState build() {
    return const AdminState(
      complaints: DemoData.demoComplaints,
      announcements: DemoData.demoAnnouncements,
    );
  }

  void updateComplaintStatus(String id, ComplaintStatus status, String? notes) {
    final updated = state.complaints.map((c) {
      if (c.id == id) {
        return c.copyWith(
          status: status,
          adminNotes: notes ?? c.adminNotes,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(complaints: updated);
  }

  void createAnnouncement(String title, String msgEn, String msgMr, String audience) {
    final newAnc = AnnouncementModel(
      id: 'anc_${DateTime.now().millisecondsSinceEpoch % 1000}',
      title: title,
      messageEn: msgEn,
      messageMr: msgMr,
      targetAudience: audience,
    );
    state = state.copyWith(announcements: [newAnc, ...state.announcements]);
  }
}

final adminRepositoryProvider = NotifierProvider<AdminRepositoryNotifier, AdminState>(AdminRepositoryNotifier.new);
