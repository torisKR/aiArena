import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/l10n.dart';
import '../settings/game_preferences.dart';
import 'primitives.dart';

Future<void> showSignalSettings({
  required BuildContext context,
  required GamePreferences preferences,
  required bool analyticsSharingAllowed,
  required bool adRequestsAllowed,
  required ValueChanged<bool> onAnalyticsChanged,
  required ValueChanged<bool> onAdRequestsChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: TokenfrontColors.deepField.withValues(alpha: .78),
  builder: (context) => _SignalSettingsSheet(
    preferences: preferences,
    analyticsSharingAllowed: analyticsSharingAllowed,
    adRequestsAllowed: adRequestsAllowed,
    onAnalyticsChanged: onAnalyticsChanged,
    onAdRequestsChanged: onAdRequestsChanged,
  ),
);

class _SignalSettingsSheet extends StatefulWidget {
  const _SignalSettingsSheet({
    required this.preferences,
    required this.analyticsSharingAllowed,
    required this.adRequestsAllowed,
    required this.onAnalyticsChanged,
    required this.onAdRequestsChanged,
  });

  final GamePreferences preferences;
  final bool analyticsSharingAllowed;
  final bool adRequestsAllowed;
  final ValueChanged<bool> onAnalyticsChanged;
  final ValueChanged<bool> onAdRequestsChanged;

  @override
  State<_SignalSettingsSheet> createState() => _SignalSettingsSheetState();
}

class _SignalSettingsSheetState extends State<_SignalSettingsSheet> {
  late bool analyticsSharingAllowed = widget.analyticsSharingAllowed;
  late bool adRequestsAllowed = widget.adRequestsAllowed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
          child: Material(
            color: TokenfrontColors.battlefieldOxide,
            shape: const BeveledRectangleBorder(
              side: BorderSide(color: Color(0x99F2E9D1)),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: widget.preferences,
              builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.settingsTitle,
                                style: TokenfrontType.display.copyWith(
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                context.l10n.settingsSubtitle,
                                style: TokenfrontType.body.copyWith(
                                  color: TokenfrontColors.quietText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.closeSettings,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(context.l10n.languageSection),
                    _LanguageSelector(preferences: widget.preferences),
                    const SizedBox(height: 22),
                    _SectionLabel(context.l10n.battlefieldSection),
                    _SignalToggle(
                      label: context.l10n.lowSpecFilter,
                      detail: context.l10n.lowSpecFilterDetail,
                      value: widget.preferences.lowSpecMode,
                      onChanged: widget.preferences.setLowSpecMode,
                    ),
                    _SignalToggle(
                      label: context.l10n.reduceMotion,
                      detail: context.l10n.reduceMotionDetail,
                      value: widget.preferences.forceReducedMotion,
                      onChanged: widget.preferences.setForceReducedMotion,
                    ),
                    _SignalToggle(
                      label: context.l10n.mouseCamera,
                      detail: context.l10n.mouseCameraDetail,
                      value: widget.preferences.mouseCameraEnabled,
                      onChanged: widget.preferences.setMouseCameraEnabled,
                    ),
                    _SignalToggle(
                      label: context.l10n.audioCues,
                      detail: context.l10n.audioCuesDetail,
                      value: widget.preferences.audioEnabled,
                      onChanged: widget.preferences.setAudioEnabled,
                    ),
                    _SignalToggle(
                      label: context.l10n.hapticCues,
                      detail: context.l10n.hapticCuesDetail,
                      value: widget.preferences.hapticsEnabled,
                      onChanged: widget.preferences.setHapticsEnabled,
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(context.l10n.privacySection),
                    _SignalToggle(
                      label: context.l10n.shareAnalytics,
                      detail: context.l10n.shareAnalyticsDetail,
                      value: analyticsSharingAllowed,
                      onChanged: (value) {
                        setState(() => analyticsSharingAllowed = value);
                        widget.onAnalyticsChanged(value);
                      },
                    ),
                    _SignalToggle(
                      label: context.l10n.adRequests,
                      detail: context.l10n.adRequestsDetail,
                      value: adRequestsAllowed,
                      onChanged: (value) {
                        setState(() => adRequestsAllowed = value);
                        widget.onAdRequestsChanged(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.privacyDefaultNote,
                      style: TokenfrontType.body.copyWith(
                        color: TokenfrontColors.quietText,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TacticalButton(
                      label: context.l10n.closePanel,
                      expanded: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.preferences});

  final GamePreferences preferences;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = <String, String>{
      TokenfrontLocales.system: l10n.languageSystem,
      TokenfrontLocales.english: l10n.languageEnglish,
      TokenfrontLocales.korean: l10n.languageKorean,
      TokenfrontLocales.japanese: l10n.languageJapanese,
      TokenfrontLocales.simplifiedChinese: l10n.languageSimplifiedChinese,
    };
    final selector = SizedBox(
      width: 184,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('language-selector'),
          value: preferences.languageCode,
          isExpanded: true,
          dropdownColor: TokenfrontColors.battlefieldOxide,
          items: [
            for (final entry in labels.entries)
              DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  overflow: TextOverflow.ellipsis,
                  style: TokenfrontType.body.copyWith(fontSize: 12),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) preferences.setLanguageCode(value);
          },
        ),
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.displayLanguage,
          style: TokenfrontType.instrument.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.displayLanguageDetail,
          style: TokenfrontType.body.copyWith(
            color: TokenfrontColors.quietText,
            fontSize: 11,
          ),
        ),
      ],
    );
    return Semantics(
      label: l10n.displayLanguage,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x22F2E9D1))),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 520
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    copy,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: selector),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 14),
                    selector,
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: TokenfrontType.instrument.copyWith(
        color: TokenfrontColors.quietText,
        fontSize: 10,
      ),
    ),
  );
}

class _SignalToggle extends StatelessWidget {
  const _SignalToggle({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: value ? context.l10n.semanticsOn : context.l10n.semanticsOff,
    toggled: value,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22F2E9D1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TokenfrontType.instrument.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: TokenfrontType.body.copyWith(
                    color: TokenfrontColors.quietText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 92,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(context.l10n.stateOff)),
                ButtonSegment(value: true, label: Text(context.l10n.stateOn)),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  TokenfrontType.instrument.copyWith(fontSize: 9),
                ),
                foregroundColor: const WidgetStatePropertyAll(
                  TokenfrontColors.relayIvory,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
