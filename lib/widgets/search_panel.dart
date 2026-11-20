import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// لوحة البحث والاختصارات. تظهر كبطاقة سفلية على الجوال
/// وكلوحة جانبية على التابلت والآيباد.
class SearchPanel extends StatelessWidget {
  const SearchPanel({
    super.key,
    required this.onOpenSettings,
    required this.onOpenSearch,
    required this.onHome,
    required this.onWork,
    required this.onSaved,
    required this.onNearby,
    required this.onSaveCar,
    this.onCar,
    this.onVoice,
    this.onPrayer,
    this.prayerLabel,
    this.homeSet = false,
    this.workSet = false,
    this.scrollController,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSearch;
  final VoidCallback onHome;
  final VoidCallback onWork;
  final VoidCallback onSaved;
  final VoidCallback onNearby;
  final VoidCallback onSaveCar;

  /// يظهر زر «سيارتي» فقط إذا كان مكان السيارة محفوظاً.
  final VoidCallback? onCar;
  final VoidCallback? onVoice;
  final VoidCallback? onPrayer;

  /// مثل «العصر 2:44 م».
  final String? prayerLabel;
  final bool homeSet;
  final bool workSet;
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
                readOnly: true,
                onTap: onOpenSearch,
                decoration: InputDecoration(
                  hintText: t.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: t.voiceSearch,
                    icon: const Icon(Icons.mic_none),
                    onPressed: onVoice,
                  ),
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
            _Shortcut(
              icon: homeSet ? Icons.home : Icons.home_outlined,
              label: t.home,
              onTap: onHome,
            ),
            _Shortcut(
              icon: workSet ? Icons.work : Icons.work_outline,
              label: t.work,
              onTap: onWork,
            ),
            _Shortcut(icon: Icons.bookmark_border, label: t.saved, onTap: onSaved),
            _Shortcut(icon: Icons.near_me_outlined, label: t.nearby, onTap: onNearby),
            if (onPrayer != null)
              _Shortcut(
                  icon: Icons.mosque_outlined,
                  label: prayerLabel ?? t.prayerTimes,
                  onTap: onPrayer!),
            if (onCar != null)
              _Shortcut(icon: Icons.directions_car, label: t.myCar, onTap: onCar!),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onSaveCar,
            icon: const Icon(Icons.local_parking),
            label: Text(t.saveCar),
          ),
        ),
        const SizedBox(height: 8),
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
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
