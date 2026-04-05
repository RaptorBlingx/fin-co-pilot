import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/widgets.dart';

/// Central icon registry — every icon in the app references this class.
/// Uses Phosphor Icons: regular (outline) for unselected, fill for selected.
abstract final class AppIcons {
  // ─── Navigation ─────────────────────────────────────────────
  static IconData get dashboard => PhosphorIcons.house();
  static IconData get dashboardFilled => PhosphorIcons.house(PhosphorIconsStyle.fill);
  static IconData get transactions => PhosphorIcons.arrowsLeftRight();
  static IconData get transactionsFilled => PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.fill);
  static IconData get insights => PhosphorIcons.chartLineUp();
  static IconData get insightsFilled => PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill);
  static IconData get more => PhosphorIcons.dotsThreeOutline();
  static IconData get moreFilled => PhosphorIcons.dotsThreeOutline(PhosphorIconsStyle.fill);

  // ─── Actions ────────────────────────────────────────────────
  static IconData get add => PhosphorIcons.plus();
  static IconData get addBold => PhosphorIcons.plus(PhosphorIconsStyle.bold);
  static IconData get send => PhosphorIcons.paperPlaneTilt();
  static IconData get sendFilled => PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill);
  static IconData get camera => PhosphorIcons.camera();
  static IconData get cameraFilled => PhosphorIcons.camera(PhosphorIconsStyle.fill);
  static IconData get voice => PhosphorIcons.microphone();
  static IconData get voiceFilled => PhosphorIcons.microphone(PhosphorIconsStyle.fill);
  static IconData get edit => PhosphorIcons.pencilSimple();
  static IconData get delete => PhosphorIcons.trash();
  static IconData get share => PhosphorIcons.shareNetwork();
  static IconData get search => PhosphorIcons.magnifyingGlass();
  static IconData get filter => PhosphorIcons.funnel();
  static IconData get sort => PhosphorIcons.sortAscending();
  static IconData get close => PhosphorIcons.x();
  static IconData get back => PhosphorIcons.caretLeft();
  static IconData get forward => PhosphorIcons.caretRight();
  static IconData get down => PhosphorIcons.caretDown();
  static IconData get up => PhosphorIcons.caretUp();
  static IconData get check => PhosphorIcons.check();
  static IconData get checkCircle => PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
  static IconData get copy => PhosphorIcons.copy();

  // ─── Features ───────────────────────────────────────────────
  static IconData get settings => PhosphorIcons.gear();
  static IconData get settingsFilled => PhosphorIcons.gear(PhosphorIconsStyle.fill);
  static IconData get budget => PhosphorIcons.wallet();
  static IconData get budgetFilled => PhosphorIcons.wallet(PhosphorIconsStyle.fill);
  static IconData get coach => PhosphorIcons.lightbulb();
  static IconData get coachFilled => PhosphorIcons.lightbulb(PhosphorIconsStyle.fill);
  static IconData get chat => PhosphorIcons.chatCircle();
  static IconData get chatFilled => PhosphorIcons.chatCircle(PhosphorIconsStyle.fill);
  static IconData get receipt => PhosphorIcons.receipt();
  static IconData get receiptFilled => PhosphorIcons.receipt(PhosphorIconsStyle.fill);
  static IconData get reports => PhosphorIcons.chartBar();
  static IconData get reportsFilled => PhosphorIcons.chartBar(PhosphorIconsStyle.fill);
  static IconData get cashFlow => PhosphorIcons.currencyCircleDollar();
  static IconData get healthScore => PhosphorIcons.heartbeat();
  static IconData get subscriptions => PhosphorIcons.repeat();
  static IconData get shopping => PhosphorIcons.storefront();
  static IconData get notifications => PhosphorIcons.bell();
  static IconData get notificationsFilled => PhosphorIcons.bell(PhosphorIconsStyle.fill);

  // ─── AI / Copilot ──────────────────────────────────────────
  static IconData get ai => PhosphorIcons.sparkle();
  static IconData get aiFilled => PhosphorIcons.sparkle(PhosphorIconsStyle.fill);
  static IconData get robot => PhosphorIcons.robot();

  // ─── Insight types ─────────────────────────────────────────
  static IconData get celebration => PhosphorIcons.trophy();
  static IconData get warning => PhosphorIcons.warning();
  static IconData get tip => PhosphorIcons.lightbulb();
  static IconData get pattern => PhosphorIcons.trendUp();
  static IconData get trendDown => PhosphorIcons.trendDown();

  // ─── Auth / User ───────────────────────────────────────────
  static IconData get user => PhosphorIcons.user();
  static IconData get userFilled => PhosphorIcons.user(PhosphorIconsStyle.fill);
  static IconData get signOut => PhosphorIcons.signOut();
  static IconData get email => PhosphorIcons.envelope();
  static IconData get lock => PhosphorIcons.lock();
  static IconData get eye => PhosphorIcons.eye();
  static IconData get eyeOff => PhosphorIcons.eyeSlash();
  static IconData get fingerprint => PhosphorIcons.fingerprint();

  // ─── Theme ─────────────────────────────────────────────────
  static IconData get sun => PhosphorIcons.sunDim();
  static IconData get moon => PhosphorIcons.moon();
  static IconData get moonFilled => PhosphorIcons.moon(PhosphorIconsStyle.fill);

  // ─── Data / Export ─────────────────────────────────────────
  static IconData get filePdf => PhosphorIcons.filePdf();
  static IconData get fileCsv => PhosphorIcons.fileText();
  static IconData get download => PhosphorIcons.downloadSimple();
  static IconData get upload => PhosphorIcons.uploadSimple();

  // ─── Misc ──────────────────────────────────────────────────
  static IconData get info => PhosphorIcons.info();
  static IconData get help => PhosphorIcons.question();
  static IconData get bookmark => PhosphorIcons.bookmarkSimple();
  static IconData get bookmarkFilled => PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill);
  static IconData get calendar => PhosphorIcons.calendarBlank();
  static IconData get clock => PhosphorIcons.clock();
  static IconData get location => PhosphorIcons.mapPin();
  static IconData get currency => PhosphorIcons.currencyDollar();
  static IconData get tag => PhosphorIcons.tag();
  static IconData get note => PhosphorIcons.notepad();
  static IconData get refresh => PhosphorIcons.arrowClockwise();
  static IconData get empty => PhosphorIcons.tray();
}
