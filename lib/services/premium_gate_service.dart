import '../models/user_context.dart';

/// Feature identifiers for premium gating.
enum Feature {
  longTermMemory,
  advancedCoaching,
  conversationMemory,
  unlimitedGoals,
  behavioralNudges,
  proModelTier,
  fullContextBuilder,
  fullInsightsHistory,
  chatHistory,
}

/// Service that gates premium features based on the user's subscription tier.
///
/// Free tier gets basic functionality; Pro ($4.99/mo) unlocks the full
/// AI-powered experience: memory, advanced coaching, conversation recall, etc.
class PremiumGateService {
  PremiumGateService._();

  /// Check whether the given [feature] is available for this [ctx].
  static bool canUse(Feature feature, UserContext ctx) {
    if (ctx.subscriptionTier == 'pro') return true;

    // Free tier gates:
    switch (feature) {
      case Feature.longTermMemory:
        return false; // Pro only
      case Feature.advancedCoaching:
        return false; // Pro only — free gets static library tips
      case Feature.conversationMemory:
        return false; // Pro only
      case Feature.unlimitedGoals:
        return false; // Free gets 1 goal (checked elsewhere by count)
      case Feature.behavioralNudges:
        return false; // Pro only
      case Feature.proModelTier:
        return false; // Free uses Flash; Pro uses Flash + Pro
      case Feature.fullContextBuilder:
        return false; // Free gets basic (currency + budget only)
      case Feature.fullInsightsHistory:
        return false; // Free: last 7 days; Pro: full history
      case Feature.chatHistory:
        return true; // Available for both tiers, but with session limits
    }
  }

  /// Maximum number of financial goals for the given tier.
  static int maxGoals(UserContext ctx) {
    return ctx.subscriptionTier == 'pro' ? 999 : 1;
  }

  /// Maximum coaching tips per day for the given tier.
  static int maxCoachingTipsPerDay(UserContext ctx) {
    return ctx.subscriptionTier == 'pro' ? 999 : 1;
  }

  /// Insights history window in days for the given tier.
  static int insightsHistoryDays(UserContext ctx) {
    return ctx.subscriptionTier == 'pro' ? 365 : 7;
  }

  /// Maximum number of stored chat sessions for the given tier.
  static int maxChatSessions(UserContext ctx) {
    return ctx.subscriptionTier == 'pro' ? 999 : 7;
  }

  /// The model name to use based on tier.
  /// Free: gemini-3.1-flash-lite-preview  |  Pro: gemini-3-flash-preview (+ Pro for deep analysis)
  static String modelForTier(UserContext ctx) {
    return ctx.subscriptionTier == 'pro'
        ? 'gemini-3-flash-preview'
        : 'gemini-3.1-flash-lite-preview';
  }

  /// The upgraded model for deep analysis tasks (Pro only).
  static String? deepAnalysisModel(UserContext ctx) {
    return ctx.subscriptionTier == 'pro' ? 'gemini-3.1-pro-preview' : null;
  }
}
