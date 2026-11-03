import '../models/announcement_model.dart';

/// Hands the announcement data loaded with the Dashboard (notification
/// overview) to the Announcement tab, so opening the tab does not fetch the
/// same first page again.
///
/// The data is handed over once ([take] clears it) and only while it is
/// fresh, so a later visit always shows the server's current read state.
class AnnouncementFeedCache {
  AnnouncementFeedCache._();
  static final AnnouncementFeedCache instance = AnnouncementFeedCache._();

  static const Duration maxAge = Duration(minutes: 2);

  AnnouncementOverview? _overview;
  DateTime? _storedAt;

  void store(AnnouncementOverview overview) {
    if (overview.firstPage == null) return; // counts only: nothing to hand over
    _overview = overview;
    _storedAt = DateTime.now();
  }

  /// The stored overview if it is still fresh, then clears it.
  AnnouncementOverview? take() {
    final overview = _overview;
    final storedAt = _storedAt;
    clear();
    if (overview == null || storedAt == null) return null;
    if (DateTime.now().difference(storedAt) > maxAge) return null;
    return overview;
  }

  void clear() {
    _overview = null;
    _storedAt = null;
  }
}
