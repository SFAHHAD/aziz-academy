/// Billing configuration for **Aziz Academy Plus** (the premium tier).
///
/// Web purchases go through Stripe Checkout. Mobile-app purchases will
/// later go through Apple / Google in-app purchase (their stores require
/// it for digital subscriptions) — that is a separate, owner-blocked step.
///
/// Stripe product: `prod_UXBF8MTSx3kmPL` (Q8Vision Stripe account).
abstract final class BillingConfig {
  static const stripeProductId = 'prod_UXBF8MTSx3kmPL';

  /// Hosted Stripe Checkout / payment-link URLs. Filled once the prices
  /// and payment links are created; until then [checkoutReady] is false
  /// and the upgrade screen shows an honest "opening soon" state rather
  /// than a button that goes nowhere.
  static const monthlyCheckoutUrl = '';
  static const yearlyCheckoutUrl = '';

  static bool get checkoutReady =>
      monthlyCheckoutUrl.isNotEmpty && yearlyCheckoutUrl.isNotEmpty;

  /// Display prices (KWD). The kid's market is Kuwait / GCC.
  static const monthlyPrice = '1 KWD';
  static const yearlyPrice = '10 KWD';

  /// Yearly framed against 12× monthly — used for the "best value" badge.
  static const yearlySavingsLabel = 'Save ~17%';
  static const yearlySavingsLabelAr = 'وفّر ١٧٪؜ تقريباً';
}
