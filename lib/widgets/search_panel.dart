import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// لوحة البحث والاختصارات. تظهر كبطاقة سفلية على الجوال
/// وكلوحة جانبية على التابلت والآيباد.
class SearchPanel extends StatelessWidget {
  const SearchPanel({
    super.key,
    required this.onOpenSettings,
    this.scrollController,
  });

  final VoidCallback onOpenSettings;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true, // البحث الفعلي في الخطوة 1.2
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.mic_none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: t.settings,
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Shortcut(icon: Icons.home_outlined, label: t.home),
            _Shortcut(icon: Icons.work_outline, label: t.work),
            _Shortcut(icon: Icons.bookmark_border, label: t.saved),
            _Shortcut(icon: Icons.near_me_outlined, label: t.nearby),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          t.attribution,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {}, // تُفعّل مع المحفوظات في الخطوة 1.5
    );
  }
}
