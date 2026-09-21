import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/billing/billing_controller.dart';
import '../services/billing/remove_ads_billing.dart';

class BillingSettings extends StatelessWidget {
  const BillingSettings({super.key, required this.billing});
  final BillingController billing;
  Future<void> _delete(BuildContext context) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.billingDelete),
        content: SingleChildScrollView(child: Text(l.billingDeleteWarning)),
        actions: [
          TextButton(
            key: const Key('billing-delete-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.billingDeleteCancel),
          ),
          TextButton(
            key: const Key('billing-delete-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.billingDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await billing.deleteAccount();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          AccountDeletionResult.deleted => l.billingDeleted,
          AccountDeletionResult.failed => l.billingDeleteFailed,
          AccountDeletionResult.localCleanupFailed =>
            l.billingDeleteLocalFailed,
        }),
        duration: const Duration(seconds: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: billing,
    builder: (context, _) {
      final l = context.l10n;
      final status = !billing.configured
          ? l.billingUnavailable
          : billing.removeAds
          ? l.billingActive
          : switch (billing.state) {
              BillingState.pending ||
              BillingState.verifying => l.billingPending,
              BillingState.canceled => l.billingCanceled,
              BillingState.error ||
              BillingState.verificationFailed ||
              BillingState.persistenceFailed ||
              BillingState.completionFailed => l.billingError,
              BillingState.unavailable => l.billingUnavailable,
              _ => billing.signedIn ? l.billingReady : l.billingSignInRequired,
            };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.billingTitle, style: Theme.of(context).textTheme.titleMedium),
          Text(l.billingDetail),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(status, key: const Key('billing-status')),
          ),
          OutlinedButton(
            key: const Key('billing-login'),
            onPressed: billing.configured && !billing.busy
                ? billing.signIn
                : null,
            child: Text(billing.signedIn ? l.billingSwitch : l.billingLogin),
          ),
          if (billing.signedIn)
            TextButton(
              key: const Key('billing-logout'),
              onPressed: billing.busy ? null : billing.logout,
              child: Text(l.billingLogout),
            ),
          OutlinedButton(
            key: const Key('billing-buy'),
            onPressed:
                billing.signedIn &&
                    !billing.busy &&
                    !billing.removeAds &&
                    billing.localizedPrice != null
                ? () => billing.buy()
                : null,
            child: Text(
              billing.localizedPrice == null
                  ? l.billingTitle
                  : l.billingBuy(billing.localizedPrice!),
            ),
          ),
          OutlinedButton(
            key: const Key('billing-restore'),
            onPressed: billing.signedIn && !billing.busy
                ? billing.restore
                : null,
            child: Text(l.billingRestore),
          ),
          TextButton(
            key: const Key('billing-delete'),
            onPressed:
                !billing.busy &&
                    (billing.signedIn || billing.deletionCleanupPending)
                ? () => _delete(context)
                : null,
            child: Text(l.billingDelete),
          ),
          Text(
            l.billingFreshness,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    },
  );
}
