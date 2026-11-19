import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/models/user_backup.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

/// Manual, on-device export/restore. This does not upload a profile or imply
/// automatic cloud sync. A separate review and confirmation precede replacement.
class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  final _input = TextEditingController();
  UserBackupData? _reviewed;
  String? _reviewedSource;
  String _lastInput = '';
  String? _notice;
  bool _error = false;
  bool _confirming = false;

  static const _labels = {
    'streak': 'Current streak',
    'longest_streak': 'Longest streak',
    'theme_mode': 'Theme',
    'favorites': 'Library favorites',
    'favorite_sounds': 'Favorite sounds',
    'presets': 'Saved mixes',
    'renamed_presets': 'Renamed mixes',
    'sessions': 'Session history',
    'reminder_enabled': 'Reminder preference',
    'reminder_hour': 'Reminder hour',
    'reminder_minute': 'Reminder minute',
  };

  @override
  void initState() {
    super.initState();
    _input.addListener(_edited);
  }

  @override
  void dispose() {
    _input.removeListener(_edited);
    _input.dispose();
    super.dispose();
  }

  void _edited() {
    if (_input.text == _lastInput) return;
    _lastInput = _input.text;
    setState(() {
      _reviewed = null;
      _reviewedSource = null;
      _notice = null;
    });
  }

  String _summary(dynamic value) {
    if (value is List || value is Map) {
      final count = value is List ? value.length : (value as Map).length;
      return '$count ${count == 1 ? 'entry' : 'entries'}';
    }
    return '$value';
  }

  Future<void> _copyBackup() async {
    try {
      final source = context.read<AppState>().exportUserDataToJson();
      await Clipboard.setData(ClipboardData(text: source));
      if (!mounted) return;
      setState(() {
        _error = false;
        _notice =
            'Backup copied. Save it somewhere private before replacing data.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _notice = 'Clipboard access failed. Your profile was not changed.';
      });
    }
  }

  void _review() {
    try {
      final backup = context.read<AppState>().validateUserBackupFromJson(
        _input.text,
      );
      setState(() {
        _reviewed = backup;
        _reviewedSource = _input.text;
        _notice = null;
        _error = false;
      });
    } on FormatException catch (error) {
      setState(() {
        _reviewed = null;
        _reviewedSource = null;
        _error = true;
        // Do not display FormatException.toString(): JSON errors can include
        // personal excerpts of the pasted source.
        _notice = '${error.message} Your existing data has not changed.';
      });
    }
  }

  Future<void> _restore() async {
    final source = _reviewedSource;
    if (source == null || _confirming || source != _input.text) return;
    setState(() => _confirming = true);
    try {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Replace saved data?'),
          content: const Text(
            'Only the reviewed categories will be replaced. This cannot be undone '
            'automatically. Copy a fresh backup first. Purchases and notification '
            'permissions do not transfer.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              key: const ValueKey('confirm-data-restore'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Replace reviewed data'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true || source != _input.text) return;
      final restored = context.read<AppState>().importUserDataFromJson(source);
      setState(() {
        _reviewed = null;
        _reviewedSource = null;
        _error = !restored;
        _notice = restored
            ? 'Profile restored on this device. Check reminder permissions separately.'
            : 'Restore could not be applied. Review the backup again; no invalid fields were imported.';
      });
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<AppState>().isUserDataReady;
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF061722),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Backup & restore'),
        backgroundColor: Color(0xF0061722),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Keep a private copy',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This manual backup includes saved mixes, favorites, streaks, '
                'reminder preferences and up to the latest 500 sessions. It can '
                'contain personal session titles and mood ratings. Keep it private: '
                'other apps may be able to read your clipboard.',
                style: TextStyle(color: Color(0xFFBCD0DC), height: 1.5),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                key: const ValueKey('copy-profile-backup'),
                onPressed: ready && !_confirming ? _copyBackup : null,
                child: const Text('Copy backup to clipboard'),
              ),
              const SizedBox(height: 30),
              const Text(
                'Restore a backup',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Paste your JSON, review the categories, then confirm replacement. '
                'Nothing is uploaded or played. Maximum import size: 2 MiB.',
                style: TextStyle(color: Color(0xFFBCD0DC), height: 1.5),
              ),
              const SizedBox(height: 14),
              CupertinoTextField(
                key: const ValueKey('backup-json-input'),
                controller: _input,
                enabled: ready && !_confirming,
                placeholder: 'Paste backup JSON here',
                minLines: 5,
                maxLines: 8,
                maxLength: UserBackupData.maxBytes,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A3B),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                key: const ValueKey('review-profile-backup'),
                onPressed: ready && !_confirming ? _review : null,
                child: const Text('Review backup'),
              ),
              if (_reviewed != null) ...[
                const Text(
                  'These categories will be replaced:',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                for (final entry in _reviewed!.values.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '${_labels[entry.key]}: ${_summary(entry.value)}',
                      style: const TextStyle(color: Color(0xFFBCD0DC)),
                    ),
                  ),
                const SizedBox(height: 10),
                CupertinoButton.filled(
                  key: const ValueKey('apply-profile-backup'),
                  onPressed: ready && !_confirming ? _restore : null,
                  child: const Text('Restore reviewed backup'),
                ),
              ],
              if (!ready)
                const Text(
                  'Preparing device storage…',
                  style: TextStyle(color: Color(0xFFBCD0DC)),
                ),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _notice!,
                      key: const ValueKey('backup-result'),
                      style: TextStyle(
                        height: 1.5,
                        color: _error
                            ? const Color(0xFFFFCA9B)
                            : const Color(0xFF78EED0),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'This is not automatic cloud sync or an encrypted vault. '
                'Purchases, trial access, API keys, audio downloads and device '
                'notification permissions are not restored. Keep an independent '
                'backup: browser/device storage can be cleared.',
                style: TextStyle(
                  color: Color(0xFF9BB4C4),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
