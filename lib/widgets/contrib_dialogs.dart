import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../contrib/contributions.dart';
import '../l10n/app_localizations.dart';

/// طلب الموافقة على تسجيل المسارات (مرة واحدة).
Future<bool> askTrackConsent(BuildContext context) async {
  final t = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.route),
      title: Text(t.consentTitle),
      content: Text(t.consentBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.consentNo),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.consentYes),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// «الخريطة هنا غير دقيقة»: يرجع الملاحظة أو null.
Future<String?> askMapIssue(BuildContext context) {
  final t = AppLocalizations.of(context);
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.mapIssueTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(hintText: t.mapIssueHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: Text(t.send),
        ),
      ],
    ),
  );
}

/// قسم «مساهماتي» في الإعدادات.
class ContributionsTile extends StatefulWidget {
  const ContributionsTile({super.key, required this.contributions});
  final Contributions contributions;

  @override
  State<ContributionsTile> createState() => _ContributionsTileState();
}

class _ContributionsTileState extends State<ContributionsTile> {
  bool? _consent;
  int _tracks = 0;
  int _issues = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final c = widget.contributions;
    final consent = await c.consent();
    final tracks = await c.trackCount();
    final issues = (await c.issues()).length;
    if (!mounted) return;
    setState(() {
      _consent = consent;
      _tracks = tracks;
      _issues = issues;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.contribTitle, style: Theme.of(context).textTheme.titleSmall),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.recordTracks),
          subtitle: Text(t.recordTracksHint),
          value: _consent ?? false,
          onChanged: (v) async {
            await widget.contributions.setConsent(v);
            await _refresh();
          },
        ),
        Text(t.contribCounts('$_tracks', '$_issues'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final json = await widget.contributions.exportGeoJson();
                await Clipboard.setData(ClipboardData(text: json));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(t.exported)));
              },
              icon: const Icon(Icons.ios_share),
              label: Text(t.exportData),
            ),
            TextButton.icon(
              onPressed: () async {
                await widget.contributions.clearAll();
                await _refresh();
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(t.deleteAll),
            ),
          ],
        ),
      ],
    );
  }
}
