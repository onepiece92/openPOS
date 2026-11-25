/// Owner decisions and user-facing wording for the usage summary and the
/// feedback ask. Each is a single constant so it can be flipped or reworded
/// in one place.
library;

/// Whether the on-device usage counter is on until the shopkeeper turns it
/// off ("Stop counting"). Owner decision: on from first launch.
const bool kUsageCountingDefaultOn = true;

/// Whether the one-time disclosure line ([kUsageDisclosureText]) is shown.
const bool kUsageFirstRunDisclosure = true;

/// The one-time, non-modal disclosure (SnackBar). Shown to new installs and
/// to existing installs upgrading to this version alike: it is keyed on
/// "disclosure shown" being absent from the usage box.
const kUsageDisclosureText =
    'Open POS counts which features you use. The counts stay on this device '
    'unless you choose to send them. See them or turn counting off in Usage '
    'summary.';

/// Action label on the disclosure; opens the feedback & usage screen.
const kUsageDisclosureAction = 'Usage summary';

/// Title of the feedback & usage screen.
const kUsageScreenTitle = 'Feedback & usage summary';

/// Instruction at the top of the feedback & usage screen.
const kFeedbackInstruction =
    "Choose the feature you'd like us to improve and tell us what's missing. "
    'Send only the usage details related to it.';

/// Friendly offline-first line shown under the instruction (UI only; never
/// part of the sent text).
const kOfflineFirstLine =
    'Open POS works offline first. Text-based design and features that work '
    'without the internet are always our top priority.';

/// Shorter form of [kOfflineFirstLine] used on the timed ask.
const kOfflineFirstShortLine = 'Open POS works offline first.';

/// Question above the feature-area choices.
const kFeedbackAreaQuestion = 'Which part of Open POS should we improve?';

/// The single question of the timed ask (a SnackBar after a receipt is
/// closed, see `UsageAskController`).
const kFeedbackAskText = "What's the one thing you'd change about Open POS?";

/// Action on the timed ask; opens the feedback & usage screen.
const kFeedbackAskAction = 'Tell us';

/// Support screen row.
const kFeedbackSupportRowTitle = 'Send feedback & usage';
const kFeedbackSupportRowSubtitle =
    'Tell us what to improve, and see what is counted';

/// Longest message the shopkeeper can type.
const kFeedbackMessageMaxLength = 500;

/// Where a summary is sent — only ever by the shopkeeper, through WhatsApp
/// or their mail app (the app itself never sends anything).
const kUsageWhatsAppNumber = '9779802850777';
const kUsageEmailAddress = 'mail@brandbuilder.com.np';
const kUsageEmailSubject = 'Open POS usage summary';

/// wa.me links longer than this go to the share sheet as a .txt file
/// instead (some WhatsApp builds and browsers truncate long links).
const kWhatsAppMaxUrlLength = 2000;

/// File name of the .txt handed to the share sheet.
const kUsageSummaryFileName = 'open-pos-usage-summary.txt';
