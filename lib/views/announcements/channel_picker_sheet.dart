import 'package:flutter/material.dart';

import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_unread_service.dart';

/// Searchable channel picker shown as a bottom sheet.
///
/// Built by hand rather than with `dropdown_search` because that package's
/// modal sheet does not move above the keyboard: typing in its search box
/// hid the filtered results behind the keyboard, so filtering looked broken.
///
/// This sheet:
/// - lifts itself above the keyboard (`viewInsets`),
/// - shrinks to the space left when the keyboard is open,
/// - filters as you type, and
/// - dismisses the keyboard when the list is dragged.
///
/// Returns the chosen [AnnouncementChannel]; an empty `id` means
/// "All Channels".
class ChannelPickerSheet extends StatefulWidget {
  final List<AnnouncementChannel> channels;
  final String selectedId;
  final Language language;

  const ChannelPickerSheet({
    super.key,
    required this.channels,
    required this.selectedId,
    required this.language,
  });

  /// Opens the sheet and returns the picked channel, or null if dismissed.
  static Future<AnnouncementChannel?> show(
    BuildContext context, {
    required List<AnnouncementChannel> channels,
    required String selectedId,
    required Language language,
  }) {
    return showModalBottomSheet<AnnouncementChannel>(
      context: context,
      // Required so the sheet can grow and react to the keyboard.
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder:
          (_) => ChannelPickerSheet(
            channels: channels,
            selectedId: selectedId,
            language: language,
          ),
    );
  }

  @override
  State<ChannelPickerSheet> createState() => _ChannelPickerSheetState();
}

class _ChannelPickerSheetState extends State<ChannelPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Language get language => widget.language;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// "All Channels" is pinned first when not searching; while searching,
  /// only names containing the query are shown (case-insensitive).
  List<AnnouncementChannel> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.channels;
    return widget.channels
        .where((c) => c.displayName.toLowerCase().contains(q))
        .toList();
  }

  int get _channelCount => widget.channels.where((c) => c.id.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    // Fit between the top safe area and the keyboard, but never taller
    // than 85% of the screen.
    final available = media.size.height - keyboard - media.padding.top - 24;
    final maxHeight =
        available.clamp(220.0, media.size.height * 0.85).toDouble();

    return Padding(
      // Lift the whole sheet above the keyboard.
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildSearchField(),
                Flexible(child: _buildList(media.padding.bottom)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.78)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 18),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.selectChannel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_channelCount ${language.channels}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: language.searchChannel,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 22,
            color: primary,
          ),
          suffixIcon:
              _query.isEmpty
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 20),
                    color: Colors.grey[500],
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildList(double bottomSafeArea) {
    final items = _visible;

    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 32, 16, 32 + bottomSafeArea),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[350]),
            const SizedBox(height: 12),
            Text(
              language.noChannelFound,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Rebuild the unread badges if the counts change while open.
    return AnimatedBuilder(
      animation: AnnouncementUnreadService.instance,
      builder:
          (context, _) => ListView.builder(
            // shrinkWrap so a short list hugs its content; Flexible above
            // caps it, so a long list scrolls instead of overflowing.
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(0, 4, 0, 12 + bottomSafeArea),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildItem(items[index]),
          ),
    );
  }

  Widget _buildItem(AnnouncementChannel channel) {
    final unread = AnnouncementUnreadService.instance;
    final isAll = channel.id.isEmpty;
    final isSelected = channel.id == widget.selectedId;
    final count =
        isAll ? unread.totalUnread : unread.unreadForChannel(channel.id);
    final initial =
        channel.displayName.isEmpty
            ? '#'
            : channel.displayName.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(channel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected ? primary.withOpacity(0.4) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient:
                        isSelected || isAll
                            ? LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                            )
                            : null,
                    color: isSelected || isAll ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child:
                      isAll
                          ? const Icon(
                            Icons.all_inbox_rounded,
                            size: 19,
                            color: Colors.white,
                          )
                          : Text(
                            initial,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    channel.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primary : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
