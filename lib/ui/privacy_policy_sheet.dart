import 'package:flutter/material.dart';

import '../app/release_capabilities.dart';
import '../design/tokens.dart';
import '../l10n/l10n.dart';
import '../services/privacy/privacy_link_actions.dart';
import 'primitives.dart';

Future<void> showPrivacyPolicySheet({
  required BuildContext context,
  required ReleaseCapabilities capabilities,
  required PrivacyLinkActions linkActions,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: TokenfrontColors.deepField.withValues(alpha: .78),
  builder: (context) =>
      _PrivacyPolicySheet(capabilities: capabilities, linkActions: linkActions),
);

class _PrivacyPolicySheet extends StatelessWidget {
  const _PrivacyPolicySheet({
    required this.capabilities,
    required this.linkActions,
  });

  final ReleaseCapabilities capabilities;
  final PrivacyLinkActions linkActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = <(String, String)>[
      (l10n.privacyDataStoredTitle, l10n.privacyDataStoredBody),
      (l10n.privacyAnalyticsTitle, l10n.privacyAnalyticsBody),
      (l10n.privacyAdvertisingTitle, l10n.privacyAdvertisingBody),
      (l10n.privacyAccountsTitle, l10n.privacyAccountsBody),
      (l10n.privacyHostingTitle, l10n.privacyHostingBody),
      (l10n.privacyChildrenTitle, l10n.privacyChildrenBody),
      (l10n.privacyChangesTitle, l10n.privacyChangesBody),
    ];
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: TokenfrontColors.battlefieldOxide,
            shape: const BeveledRectangleBorder(
              side: BorderSide(color: Color(0x99F2E9D1)),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                  child: Text(
                    l10n.privacyPolicyTitle,
                    style: TokenfrontType.display.copyWith(fontSize: 24),
                  ),
                ),
                Expanded(
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      key: const Key('privacy-policy-content'),
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.privacyPolicyEffectiveDate,
                            style: TokenfrontType.instrument.copyWith(
                              color: TokenfrontColors.quietText,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.privacyPolicyIntro,
                            style: TokenfrontType.body,
                          ),
                          for (final section in sections) ...[
                            const SizedBox(height: 20),
                            _PolicySection(title: section.$1, body: section.$2),
                          ],
                          const SizedBox(height: 20),
                          _PolicySection(
                            title: l10n.privacyContactTitle,
                            body: 'Toris\n${capabilities.privacyContactEmail}',
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.privacyPublicUrlLabel,
                            style: TokenfrontType.instrument.copyWith(
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            capabilities.privacyPolicyUrl,
                            style: TokenfrontType.body.copyWith(
                              color: TokenfrontColors.cobalt,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                key: const Key('copy-privacy-url'),
                                onPressed: () async {
                                  await linkActions.copy(
                                    capabilities.privacyPolicyUrl,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.privacyUrlCopied),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy_outlined),
                                label: Text(l10n.privacyCopyUrl),
                              ),
                              OutlinedButton.icon(
                                key: const Key('open-privacy-url'),
                                onPressed: () async {
                                  final opened = await linkActions.openExternal(
                                    capabilities.privacyPolicyUri,
                                  );
                                  if (!opened && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.privacyOpenFailed),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: Text(l10n.privacyOpenPublicPage),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TacticalButton(
                            key: const Key('close-privacy-policy'),
                            label: l10n.closePanel,
                            expanded: true,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TokenfrontType.instrument.copyWith(fontSize: 10)),
      const SizedBox(height: 6),
      Text(
        body,
        style: TokenfrontType.body.copyWith(
          color: TokenfrontColors.quietText,
          fontSize: 12,
        ),
      ),
    ],
  );
}
