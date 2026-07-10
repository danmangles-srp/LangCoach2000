// Rivendell — minimal, dependency-free localizations (NFR-2.5.x).
//
// Flutter's gen_l10n would pull flutter_localizations, which forces an intl
// bump that clashes with the project's pinned matrix (intl ^0.19). Until that
// pin moves, we hand-roll a Localizations<AppStrings>: externalized, locale-
// aware strings with Uzbek (uz) as a first-class locale — Rivendell is for
// learners of Uzbek — and English (en) as the fallback/seed. Migrating to
// gen_l10n later is a mechanical ARB port; the call sites (AppStrings.of) stay.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// The locales Rivendell ships translations for, in priority order. Drives
  /// `MaterialApp.supportedLocales`. Keep the seed locale last so the device
  /// locale resolves to a translation when one exists.
  static const List<Locale> supportedLocales = [Locale('uz'), Locale('en')];

  static const _en = _Bundle(
    recordingsTitle: 'Recordings',
    recordingsDetailTitle: 'Recording',
    recordingsNotFound: 'This recording is no longer available.',
    emptyTitle: 'No recordings yet',
    emptyBody:
        'Point Rivendell at your Samsung Voice Recorder folder and your '
        'recordings will appear here.',
    emptyHint: 'Tap refresh after picking a folder to index it.',
    loading: 'Loading recordings…',
    errorTitle: "Couldn't load recordings",
    retry: 'Try again',
    scanTooltip: 'Refresh library',
    scanFailed: "Couldn't scan that folder.",
    scannedCountN: 'Indexed {n} recordings.',
    folderOnboardingTitle: 'Point Rivendell at your recordings',
    folderOnboardingBodyN:
        'Choose your Samsung Voice Recorder folder so Rivendell can '
        "index your .m4a, .mp3, and .wav files. It's usually called "
        '"{name}".',
    folderOnboardingPick: 'Choose folder',
    folderOnboardingNone: 'No folder selected.',
    folderOnboardingNonSvrWarning:
        "That isn't the usual Voice Recorder folder — indexing it anyway.",
    folderOnboardingSaveFailed: "Couldn't save that folder. Try again.",
    unknownDuration: '—:—',
    unknownFormat: 'audio',
    metaDate: 'Recorded',
    metaDuration: 'Duration',
    metaSize: 'Size',
    metaFormat: 'Format',
    playTooltip: 'Play',
    pauseTooltip: 'Pause',
    replayTooltip: 'Replay',
    queueNavToday: 'Today',
    queueNavLibrary: 'Library',
    queueTitle: "Today's Review Queue",
    queueEmptyTitle: 'Nothing due today',
    queueEmptyBody:
        'You’re all caught up. Recordings due for review will appear '
        'here on their schedule.',
    queueStaleBadge: 'Stale',
    queueDueToday: 'Due today',
    queueDueTomorrow: 'Due tomorrow',
    queueSectionTomorrow: 'Tomorrow',
    queueOverdueN: '{n} day overdue',
    queueNowPlaying: 'Now playing',
    reviewHistoryTitle: 'Review history',
    reviewLastReviewed: 'Last reviewed',
    reviewNever: 'Never',
    reviewMilestoneReached: 'Milestone reached',
    reviewNoneYet: 'None yet',
    reviewCountN: '{n} reviews',
    reviewMarkReviewed: 'Mark reviewed',
    reviewUndo: 'Undo',
    reviewDueLabel: 'Due',
    reviewSaveFailed:
        "Couldn't save this review. Mark it reviewed on the recording.",
    recordTooltip: 'Record',
    recordSheetTitle: 'Record',
    recordStart: 'Record',
    recordStop: 'Stop',
    recordSaving: 'Saving…',
    recordNameLabel: 'Name',
    recordNameHint: 'Leave blank for a timestamped name',
    recordPermissionDenied:
        'Microphone permission denied. Grant it in system settings to record.',
    recordNoFolder: 'Pick a Samsung Voice Recorder folder before recording.',
    recordFailed: "Couldn't save the recording. Try again.",
    recordSavedN: 'Saved “{name}”.',
    recordingMenuRename: 'Rename',
    recordingMenuDelete: 'Delete',
    renameDialogTitle: 'Rename recording',
    renameFailed: "Couldn't rename. Try again.",
    deleteDialogTitle: 'Delete recording?',
    deleteDialogBodyN:
        'Delete “{name}”? This removes the audio file and all its vocab '
        'and review data.',
    deleteFailed: "Couldn't delete. Try again.",
    wordLogTitle: 'Word log',
    wordLogTabText: 'Text',
    wordLogTabImages: 'Images',
    wordLogAddText: 'Add text log',
    wordLogEditText: 'Edit text log',
    wordLogAddImage: 'Add photo',
    wordLogTextEmpty: 'No text log yet. Paste an English↔Uzbek word list.',
    wordLogImagesEmpty: 'No photos attached yet.',
    wordLogTextDialogHint: 'One pair per line: uzbek: english',
    wordLogSave: 'Save',
    wordLogCancel: 'Cancel',
    wordLogAttachFailed: 'Could not attach. Try again.',
    ankiSend: 'Send to Anki',
    ankiSending: 'Sending…',
    ankiRetry: 'Retry',
    ankiNotInstalledTitle: 'AnkiDroid not installed',
    ankiNotInstalledBody:
        'Install AnkiDroid (com.ichi2.anki) from Google Play, then reopen '
        'this recording and send again.',
    ankiSendFailed: 'Send failed. Try again.',
    ankiAddedN: 'Added: {n}',
    ankiSkippedN: 'Skipped: {n}',
    ankiFailedN: 'Failed: {n}',
    ankiPendingN: 'Queued images: {n}',
    ankiPendingHint:
        'Queued images generate on reconnect and attach on your next send.',
    ankiGotIt: 'Got it',
    ankiGrantTitle: 'Allow AnkiDroid access',
    ankiGrantBody:
        'Rivendell needs AnkiDroid API access to add cards. Tap Continue to '
        'grant.',
    ankiGrantContinue: 'Continue',
    ankiEnableApiHint:
        'Open AnkiDroid → Settings → enable the AnkiDroid API, then retry.',
    tasksTitle: 'Tasks',
    tasksEmptyTitle: 'No tasks yet',
    tasksEmptyBody:
        'Add an exercise or goal — e.g. “Memorize Yor-Yor” — with an optional '
        'due date.',
    tasksAdd: 'Add task',
    taskFieldTitle: 'Title',
    taskFieldDescription: 'Notes (optional)',
    taskFieldDueDate: 'Due date',
    taskNoDate: 'No date',
    taskClearDate: 'Clear date',
    taskSave: 'Save',
    taskDelete: 'Delete',
    taskOverdue: 'Overdue',
    taskDueOnN: 'Due {date}',
    taskDetailTitle: 'Task',
    taskEditAction: 'Edit',
    taskCreatedOnN: 'Created {date}',
    taskNotFound: 'This task is no longer available.',
    coachTitle: 'Coach Bank',
    coachEmptyTitle: 'No notes yet',
    coachEmptyBody:
        'Save conversation topics, questions, and scripts, then pin the '
        'recordings and vocab you’ll cover.',
    coachAdd: 'Add note',
    coachFieldBody: 'Script',
    coachRecordings: 'Recordings',
    coachVocab: 'Vocab',
    coachAttach: 'Attach',
    coachNone: 'None',
    coachPickRecordings: 'Pick recordings',
    coachPickVocab: 'Pick vocab logs',
    coachNRecordingsN: '{n} recordings',
    coachNVocabN: '{n} vocab',
    statsTitle: 'Stats',
    statsGranularityDaily: 'Daily',
    statsGranularityWeekly: 'Weekly',
    statsGranularityMonthly: 'Monthly',
    statsMetricLessonDuration: 'Lesson time',
    statsMetricJournalingOutput: 'Vocab logs',
    statsMetricCompletedQueueItems: 'Reviews done',
    statsMetricFlashcardsReviewed: 'Flashcards',
    statsEmptyTitle: 'No data yet',
    statsEmptyBody:
        'Listen to a due recording or add a vocab log and your stats '
        'will appear here.',
    settingsTitle: 'Settings',
    settingsTooltip: 'Settings',
    settingsAutoAdvanceTitle: 'Auto-advance to next recording',
    settingsAutoAdvanceSubtitle:
        'When a recording finishes in the review queue, jump to the next one.',
    settingsThemeTitle: 'Theme',
    settingsThemeSystem: 'System',
    settingsThemeLight: 'Light',
    settingsThemeDark: 'Dark',
    settingsReportTitle: 'Weekly email report',
    settingsReportDayLabel: 'Send day',
    settingsReportTimeLabel: 'Send time',
    settingsReportRecipientLabel: 'Recipient email',
    settingsReportRecipientHint: 'you@example.com',
    settingsReportRecipientHelp:
        'Defaults to your Gmail address when left blank.',
    settingsReportSmtpUserLabel: 'Gmail address',
    settingsReportSmtpPasswordLabel: 'App password',
    settingsReportSmtpPasswordHelp:
        'A 16-character Google app password (2FA required).',
    settingsReportSaveCredentials: 'Save credentials',
    settingsReportCredentialsSaved: 'Credentials saved',
    settingsReportLastSentLabel: 'Last sent',
    settingsReportNextSendLabel: 'Next send',
    settingsReportNeverSent: 'Never',
    settingsReportNotConfigured:
        'Add your Gmail address + app password to enable weekly reports.',
    settingsAiImageQueueTitle: 'AI image queue',
    settingsAiImageQueueSubtitle: 'Review pending image generations',
    aiQueuePendingHeader: 'Pending',
    aiQueuePendingEmpty: 'No pending images.',
    aiQueuePendingLinkN: '{n} images queued →',
    aiQueueGeneratedHeader: 'Generated',
    aiQueueGeneratedEmpty: 'No images generated yet.',
    aiQueueAttemptsN: 'Attempts: {n}',
    aiQueueLastErrorLabel: 'Last error',
    aiQueueEnqueuedLabel: 'Enqueued',
  );

  static const _uz = _Bundle(
    recordingsTitle: 'Yozuvlar',
    recordingsDetailTitle: 'Yozuv',
    recordingsNotFound: 'Bu yozuv endi mavjud emas.',
    emptyTitle: "Hozircha yozuvlar yo'q",
    emptyBody:
        "Rivendell'ni Samsung Voice Recorder jildiga yo'naltiring — "
        'yozuvlaringiz shu yerda paydo bo‘ladi.',
    emptyHint: 'Jildni tanlagach, yangilash tugmasini bosing.',
    loading: 'Yozuvlar yuklanmoqda…',
    errorTitle: "Yozuvlarni yuklab bo'lmadi",
    retry: 'Qayta urinib ko‘ring',
    scanTooltip: 'Kutubxonani yangilash',
    scanFailed: 'Bu jildni skanerlab bo‘lmadi.',
    scannedCountN: '{n} ta yozuv indekslandi.',
    folderOnboardingTitle: "Rivendell'ni yozuvlaringizga yo'naltiring",
    folderOnboardingBodyN:
        'Samsung Voice Recorder jildini tanlang — Rivendell .m4a, .mp3 va '
        '.wav fayllaringizni indekslay oladi. Odatda u "{name}" deb ataladi.',
    folderOnboardingPick: 'Jildni tanlang',
    folderOnboardingNone: 'Jild tanlanmadi.',
    folderOnboardingNonSvrWarning:
        'Bu odatdagidek Voice Recorder jildi emas — baribir indekslanmoqda.',
    folderOnboardingSaveFailed: "Jildni saqlab bo'lmadi. Qayta urinib ko'ring.",
    unknownDuration: '—:—',
    unknownFormat: 'audio',
    metaDate: 'Yozilgan',
    metaDuration: 'Davomiyligi',
    metaSize: 'Hajmi',
    metaFormat: 'Format',
    playTooltip: 'Ijro etish',
    pauseTooltip: 'To‘xtatish',
    replayTooltip: 'Qayta ijro',
    queueNavToday: 'Bugun',
    queueNavLibrary: 'Kutubxona',
    queueTitle: 'Bugungi takrorlash navbati',
    queueEmptyTitle: 'Bugun takrorlash yo‘q',
    queueEmptyBody:
        'Hammasi bajarildi. Takrorlashga zarur yozuvlar jadvali bo‘yicha '
        'shu yerda paydo bo‘ladi.',
    queueStaleBadge: 'Muddati o‘tgan',
    queueDueToday: 'Bugun',
    queueDueTomorrow: 'Ertaga',
    queueSectionTomorrow: 'Ertaga',
    queueOverdueN: '{n} kun muddati o‘tgan',
    queueNowPlaying: 'Ijro etilmoqda',
    reviewHistoryTitle: 'Takrorlash tarixi',
    reviewLastReviewed: 'So‘nggi takrorlash',
    reviewNever: 'Hech qachon',
    reviewMilestoneReached: 'Erishilgan bosqich',
    reviewNoneYet: 'Hali yo‘q',
    reviewCountN: '{n} ta takrorlash',
    reviewMarkReviewed: 'Belgilash',
    reviewUndo: 'Bekor qilish',
    reviewDueLabel: 'Muddati',
    reviewSaveFailed:
        'Bu takrorlashni saqlab bo‘lmadi. Yozuvdan qo‘lda belgilang.',
    recordTooltip: 'Yozib olish',
    recordSheetTitle: 'Yozib olish',
    recordStart: 'Yozib olish',
    recordStop: 'To‘xtatish',
    recordSaving: 'Saqlanmoqda…',
    recordNameLabel: 'Nomi',
    recordNameHint: 'Bo‘sh qoldirsangiz vaqt belgili nom',
    recordPermissionDenied:
        'Mikrofon ruxsati rad etildi. Yozib olish uchun sozlamalarda '
        'ruxsat bering.',
    recordNoFolder:
        'Yozib olishdan oldin Samsung Voice Recorder jildini tanlang.',
    recordFailed: 'Yozuvni saqlab bo‘lmadi. Qayta urinib ko‘ring.',
    recordSavedN: '“{name}” saqlandi.',
    recordingMenuRename: 'Nomini o‘zgartirish',
    recordingMenuDelete: 'O‘chirish',
    renameDialogTitle: 'Yozuv nomini o‘zgartirish',
    renameFailed: 'Nomini o‘zgartirib bo‘lmadi. Qayta urinib ko‘ring.',
    deleteDialogTitle: 'Yozuvni o‘chiraymi?',
    deleteDialogBodyN:
        '“{name}” o‘chirilsinmi? Audio fayl va barcha so‘z/takrorlash '
        'ma’lumotlari olib tashlanadi.',
    deleteFailed: 'O‘chirib bo‘lmadi. Qayta urinib ko‘ring.',
    wordLogTitle: 'So‘zlar daftari',
    wordLogTabText: 'Matn',
    wordLogTabImages: 'Rasmlar',
    wordLogAddText: 'Matn qo‘shish',
    wordLogEditText: 'Matnni tahrirlash',
    wordLogAddImage: 'Rasm qo‘shish',
    wordLogTextEmpty:
        'Hozircha matn yo‘q. Inglizcha↔o‘zbekcha so‘zlar ro‘yxatini qo‘ying.',
    wordLogImagesEmpty: 'Hozircha birorta rasm biriktirilmagan.',
    wordLogTextDialogHint: 'Har qatorda bittadan: uzbek: english',
    wordLogSave: 'Saqlash',
    wordLogCancel: 'Bekor qilish',
    wordLogAttachFailed: 'Biriktirib bo‘lmadi. Qayta urinib ko‘ring.',
    ankiSend: "Anki'ga yuborish",
    ankiSending: 'Yuborilmoqda…',
    ankiRetry: 'Qayta urinish',
    ankiNotInstalledTitle: 'AnkiDroid o‘rnatilmagan',
    ankiNotInstalledBody:
        "Google Play'dan AnkiDroid (com.ichi2.anki) o‘rnating, so‘ng yozuvni "
        'qaytaring va yuboring.',
    ankiSendFailed: 'Yuborib bo‘lmadi. Qayta urinib ko‘ring.',
    ankiAddedN: 'Qo‘shildi: {n}',
    ankiSkippedN: 'O‘tkazib yuborildi: {n}',
    ankiFailedN: 'Muvaffaqiyatsiz: {n}',
    ankiPendingN: 'Navbatdagi rasmlar: {n}',
    ankiPendingHint:
        'Navbatdagi rasmlar aloqada tiklanganda yaratiladi va keyingi '
        'yuborishda biriktiriladi.',
    ankiGotIt: 'Tushunarli',
    ankiGrantTitle: 'AnkiDroid ruxsatini bering',
    ankiGrantBody:
        "Rivendell'ga kartalarni qo‘shish uchun AnkiDroid API ruxsati kerak. "
        'Ruxsat berish uchun Davom etishni bosing.',
    ankiGrantContinue: 'Davom etish',
    ankiEnableApiHint:
        "AnkiDroid'ni oching → Sozlamalar → AnkiDroid API ni yoqing, so‘ng "
        'qayta urining.',
    tasksTitle: 'Vazifalar',
    tasksEmptyTitle: 'Hozircha vazifalar yo‘q',
    tasksEmptyBody:
        'Mashq yoki maqsad qo‘shing — masalan, “Yor-Yor ni yod oling” — '
        'ixtiyoriy muddat bilan.',
    tasksAdd: 'Vazifa qo‘shish',
    taskFieldTitle: 'Sarlavha',
    taskFieldDescription: 'Izoh (ixtiyoriy)',
    taskFieldDueDate: 'Muddati',
    taskNoDate: 'Sanasiz',
    taskClearDate: 'Sanani olib tashlash',
    taskSave: 'Saqlash',
    taskDelete: 'O‘chirish',
    taskOverdue: 'Muddati o‘tgan',
    taskDueOnN: 'Muddati: {date}',
    taskDetailTitle: 'Vazifa',
    taskEditAction: 'Tahrirlash',
    taskCreatedOnN: 'Yaratilgan: {date}',
    taskNotFound: 'Bu vazifa endi mavjud emas.',
    coachTitle: 'Murabbiy banki',
    coachEmptyTitle: 'Hali yozuvlar yo‘q',
    coachEmptyBody:
        'Suhbat mavzulari, savollar va ssenariylarni saqlang — so‘ng ko‘rib '
        'chiqadigan yozuv va lug‘atni biriktiring.',
    coachAdd: 'Yozuv qo‘shish',
    coachFieldBody: 'Ssenariy',
    coachRecordings: 'Yozuvlar',
    coachVocab: 'Lug‘at',
    coachAttach: 'Biriktirish',
    coachNone: 'Yo‘q',
    coachPickRecordings: 'Yozuvlarni tanlash',
    coachPickVocab: 'Lug‘atni tanlash',
    coachNRecordingsN: '{n} yozuv',
    coachNVocabN: '{n} lug‘at',
    statsTitle: 'Statistika',
    statsGranularityDaily: 'Kunlik',
    statsGranularityWeekly: 'Haftalik',
    statsGranularityMonthly: 'Oylik',
    statsMetricLessonDuration: 'Dars vaqti',
    statsMetricJournalingOutput: 'Lug‘atlar',
    statsMetricCompletedQueueItems: 'Tugatilgan takrorlar',
    statsMetricFlashcardsReviewed: 'Flashkartalar',
    statsEmptyTitle: 'Hozircha maʼlumot yo‘q',
    statsEmptyBody:
        'Muddatli yozuvni tinglang yoki lug‘at qo‘shing — statistika '
        'shu yerda paydo bo‘ladi.',
    settingsTitle: 'Sozlamalar',
    settingsTooltip: 'Sozlamalar',
    settingsAutoAdvanceTitle: 'Keyingi yozuvga avtomatik o‘tish',
    settingsAutoAdvanceSubtitle:
        'Navbatdagi yozuv tugagach, keyingisiga o‘tiladi.',
    settingsThemeTitle: 'Mavzu',
    settingsThemeSystem: 'Tizim',
    settingsThemeLight: 'Yorug‘',
    settingsThemeDark: 'Qorong‘i',
    settingsReportTitle: 'Haftalik hisobot xati',
    settingsReportDayLabel: 'Yuborish kuni',
    settingsReportTimeLabel: 'Yuborish vaqti',
    settingsReportRecipientLabel: 'Qabul qiluvchi pochta',
    settingsReportRecipientHint: 'you@example.com',
    settingsReportRecipientHelp:
        'Bo‘sh qoldirilsa, Gmail manzilingizdan foydalaniladi.',
    settingsReportSmtpUserLabel: 'Gmail manzili',
    settingsReportSmtpPasswordLabel: 'Ilova paroli',
    settingsReportSmtpPasswordHelp:
        '16 belgidan iborat Google ilova paroli (2FA kerak).',
    settingsReportSaveCredentials: 'Maxfiy maʼlumotni saqlash',
    settingsReportCredentialsSaved: 'Maxfiy maʼlumot saqlandi',
    settingsReportLastSentLabel: 'Oxirgi yuborilgan',
    settingsReportNextSendLabel: 'Keyingi yuborish',
    settingsReportNeverSent: 'Hech qachon',
    settingsReportNotConfigured:
        'Haftalik hisobotni yoqish uchun Gmail manzil + ilova '
        'parolini kiriting.',
    settingsAiImageQueueTitle: 'Tasvir navbati',
    settingsAiImageQueueSubtitle: 'Kutilayotgan tasvir generatsiyasini ko‘rish',
    aiQueuePendingHeader: 'Kutilmoqda',
    aiQueuePendingEmpty: 'Kutilayotgan tasvir yo‘q.',
    aiQueuePendingLinkN: '{n} ta tasvir navbatda →',
    aiQueueGeneratedHeader: 'Yaratilgan',
    aiQueueGeneratedEmpty: 'Hali tasvir yaratilmagan.',
    aiQueueAttemptsN: 'Urinishlar: {n}',
    aiQueueLastErrorLabel: 'So‘nggi xato',
    aiQueueEnqueuedLabel: 'Navbatga olindi',
  );

  // Resolve the bundle for the active locale, falling back to English.
  _Bundle get _bundle => locale.languageCode == 'uz' ? _uz : _en;

  String get recordingsTitle => _bundle.recordingsTitle;
  String get recordingsDetailTitle => _bundle.recordingsDetailTitle;
  String get recordingsNotFound => _bundle.recordingsNotFound;
  String get emptyTitle => _bundle.emptyTitle;
  String get emptyBody => _bundle.emptyBody;
  String get emptyHint => _bundle.emptyHint;
  String get loading => _bundle.loading;
  String get errorTitle => _bundle.errorTitle;
  String get retry => _bundle.retry;
  String get scanTooltip => _bundle.scanTooltip;
  String get scanFailed => _bundle.scanFailed;
  String scannedCount(int n) => _bundle.scannedCountN.replaceAll('{n}', '$n');
  String get folderOnboardingTitle => _bundle.folderOnboardingTitle;
  String folderOnboardingBody(String name) =>
      _bundle.folderOnboardingBodyN.replaceAll('{name}', name);
  String get folderOnboardingPick => _bundle.folderOnboardingPick;
  String get folderOnboardingNone => _bundle.folderOnboardingNone;
  String get folderOnboardingNonSvrWarning =>
      _bundle.folderOnboardingNonSvrWarning;
  String get folderOnboardingSaveFailed => _bundle.folderOnboardingSaveFailed;
  String get unknownDuration => _bundle.unknownDuration;
  String get unknownFormat => _bundle.unknownFormat;
  String get metaDate => _bundle.metaDate;
  String get metaDuration => _bundle.metaDuration;
  String get metaSize => _bundle.metaSize;
  String get metaFormat => _bundle.metaFormat;
  String get playTooltip => _bundle.playTooltip;
  String get pauseTooltip => _bundle.pauseTooltip;
  String get replayTooltip => _bundle.replayTooltip;
  String get queueNavToday => _bundle.queueNavToday;
  String get queueNavLibrary => _bundle.queueNavLibrary;
  String get queueTitle => _bundle.queueTitle;
  String get queueEmptyTitle => _bundle.queueEmptyTitle;
  String get queueEmptyBody => _bundle.queueEmptyBody;
  String get queueStaleBadge => _bundle.queueStaleBadge;
  String get queueDueToday => _bundle.queueDueToday;
  String get queueDueTomorrow => _bundle.queueDueTomorrow;
  String get queueSectionTomorrow => _bundle.queueSectionTomorrow;
  String queueOverdue(int n) => _bundle.queueOverdueN.replaceAll('{n}', '$n');
  String get queueNowPlaying => _bundle.queueNowPlaying;
  String get reviewHistoryTitle => _bundle.reviewHistoryTitle;
  String get reviewLastReviewed => _bundle.reviewLastReviewed;
  String get reviewNever => _bundle.reviewNever;
  String get reviewMilestoneReached => _bundle.reviewMilestoneReached;
  String get reviewNoneYet => _bundle.reviewNoneYet;
  String reviewCount(int n) => _bundle.reviewCountN.replaceAll('{n}', '$n');
  String get reviewMarkReviewed => _bundle.reviewMarkReviewed;
  String get reviewUndo => _bundle.reviewUndo;
  String get reviewDueLabel => _bundle.reviewDueLabel;
  String get reviewSaveFailed => _bundle.reviewSaveFailed;
  String get recordTooltip => _bundle.recordTooltip;
  String get recordSheetTitle => _bundle.recordSheetTitle;
  String get recordStart => _bundle.recordStart;
  String get recordStop => _bundle.recordStop;
  String get recordSaving => _bundle.recordSaving;
  String get recordNameLabel => _bundle.recordNameLabel;
  String get recordNameHint => _bundle.recordNameHint;
  String get recordPermissionDenied => _bundle.recordPermissionDenied;
  String get recordNoFolder => _bundle.recordNoFolder;
  String get recordFailed => _bundle.recordFailed;
  String recordSaved(String name) =>
      _bundle.recordSavedN.replaceAll('{name}', name);
  String get recordingMenuRename => _bundle.recordingMenuRename;
  String get recordingMenuDelete => _bundle.recordingMenuDelete;
  String get renameDialogTitle => _bundle.renameDialogTitle;
  String get renameFailed => _bundle.renameFailed;
  String get deleteDialogTitle => _bundle.deleteDialogTitle;
  String deleteDialogBody(String name) =>
      _bundle.deleteDialogBodyN.replaceAll('{name}', name);
  String get deleteFailed => _bundle.deleteFailed;
  String get wordLogTitle => _bundle.wordLogTitle;
  String get wordLogTabText => _bundle.wordLogTabText;
  String get wordLogTabImages => _bundle.wordLogTabImages;
  String get wordLogAddText => _bundle.wordLogAddText;
  String get wordLogEditText => _bundle.wordLogEditText;
  String get wordLogAddImage => _bundle.wordLogAddImage;
  String get wordLogTextEmpty => _bundle.wordLogTextEmpty;
  String get wordLogImagesEmpty => _bundle.wordLogImagesEmpty;
  String get wordLogTextDialogHint => _bundle.wordLogTextDialogHint;
  String get wordLogSave => _bundle.wordLogSave;
  String get wordLogCancel => _bundle.wordLogCancel;
  String get wordLogAttachFailed => _bundle.wordLogAttachFailed;
  String get ankiSend => _bundle.ankiSend;
  String get ankiSending => _bundle.ankiSending;
  String get ankiRetry => _bundle.ankiRetry;
  String get ankiNotInstalledTitle => _bundle.ankiNotInstalledTitle;
  String get ankiNotInstalledBody => _bundle.ankiNotInstalledBody;
  String get ankiSendFailed => _bundle.ankiSendFailed;
  String ankiAdded(int n) => _bundle.ankiAddedN.replaceAll('{n}', '$n');
  String ankiSkipped(int n) => _bundle.ankiSkippedN.replaceAll('{n}', '$n');
  String ankiFailed(int n) => _bundle.ankiFailedN.replaceAll('{n}', '$n');
  String ankiPending(int n) => _bundle.ankiPendingN.replaceAll('{n}', '$n');
  String get ankiPendingHint => _bundle.ankiPendingHint;
  String get ankiGotIt => _bundle.ankiGotIt;
  String get ankiGrantTitle => _bundle.ankiGrantTitle;
  String get ankiGrantBody => _bundle.ankiGrantBody;
  String get ankiGrantContinue => _bundle.ankiGrantContinue;
  String get ankiEnableApiHint => _bundle.ankiEnableApiHint;
  String get tasksTitle => _bundle.tasksTitle;
  String get tasksEmptyTitle => _bundle.tasksEmptyTitle;
  String get tasksEmptyBody => _bundle.tasksEmptyBody;
  String get tasksAdd => _bundle.tasksAdd;
  String get taskFieldTitle => _bundle.taskFieldTitle;
  String get taskFieldDescription => _bundle.taskFieldDescription;
  String get taskFieldDueDate => _bundle.taskFieldDueDate;
  String get taskNoDate => _bundle.taskNoDate;
  String get taskClearDate => _bundle.taskClearDate;
  String get taskSave => _bundle.taskSave;
  String get taskDelete => _bundle.taskDelete;
  String get taskOverdue => _bundle.taskOverdue;
  String taskDueOn(String date) =>
      _bundle.taskDueOnN.replaceAll('{date}', date);
  String get taskDetailTitle => _bundle.taskDetailTitle;
  String get taskEditAction => _bundle.taskEditAction;
  String taskCreatedOn(String date) =>
      _bundle.taskCreatedOnN.replaceAll('{date}', date);
  String get taskNotFound => _bundle.taskNotFound;

  String get coachTitle => _bundle.coachTitle;
  String get coachEmptyTitle => _bundle.coachEmptyTitle;
  String get coachEmptyBody => _bundle.coachEmptyBody;
  String get coachAdd => _bundle.coachAdd;
  String get coachFieldBody => _bundle.coachFieldBody;
  String get coachRecordings => _bundle.coachRecordings;
  String get coachVocab => _bundle.coachVocab;
  String get coachAttach => _bundle.coachAttach;
  String get coachNone => _bundle.coachNone;
  String get coachPickRecordings => _bundle.coachPickRecordings;
  String get coachPickVocab => _bundle.coachPickVocab;
  String coachNRecordings(int n) =>
      _bundle.coachNRecordingsN.replaceAll('{n}', '$n');
  String coachNVocab(int n) => _bundle.coachNVocabN.replaceAll('{n}', '$n');

  String get statsTitle => _bundle.statsTitle;
  String get statsGranularityDaily => _bundle.statsGranularityDaily;
  String get statsGranularityWeekly => _bundle.statsGranularityWeekly;
  String get statsGranularityMonthly => _bundle.statsGranularityMonthly;
  String get statsMetricLessonDuration => _bundle.statsMetricLessonDuration;
  String get statsMetricJournalingOutput => _bundle.statsMetricJournalingOutput;
  String get statsMetricCompletedQueueItems =>
      _bundle.statsMetricCompletedQueueItems;
  String get statsMetricFlashcardsReviewed =>
      _bundle.statsMetricFlashcardsReviewed;
  String get statsEmptyTitle => _bundle.statsEmptyTitle;
  String get statsEmptyBody => _bundle.statsEmptyBody;

  String get settingsTitle => _bundle.settingsTitle;
  String get settingsTooltip => _bundle.settingsTooltip;
  String get settingsAutoAdvanceTitle => _bundle.settingsAutoAdvanceTitle;
  String get settingsAutoAdvanceSubtitle => _bundle.settingsAutoAdvanceSubtitle;
  String get settingsThemeTitle => _bundle.settingsThemeTitle;
  String get settingsThemeSystem => _bundle.settingsThemeSystem;
  String get settingsThemeLight => _bundle.settingsThemeLight;
  String get settingsThemeDark => _bundle.settingsThemeDark;
  String get settingsReportTitle => _bundle.settingsReportTitle;
  String get settingsReportDayLabel => _bundle.settingsReportDayLabel;
  String get settingsReportTimeLabel => _bundle.settingsReportTimeLabel;
  String get settingsReportRecipientLabel =>
      _bundle.settingsReportRecipientLabel;
  String get settingsReportRecipientHint => _bundle.settingsReportRecipientHint;
  String get settingsReportRecipientHelp => _bundle.settingsReportRecipientHelp;
  String get settingsReportSmtpUserLabel => _bundle.settingsReportSmtpUserLabel;
  String get settingsReportSmtpPasswordLabel =>
      _bundle.settingsReportSmtpPasswordLabel;
  String get settingsReportSmtpPasswordHelp =>
      _bundle.settingsReportSmtpPasswordHelp;
  String get settingsReportSaveCredentials =>
      _bundle.settingsReportSaveCredentials;
  String get settingsReportCredentialsSaved =>
      _bundle.settingsReportCredentialsSaved;
  String get settingsReportLastSentLabel => _bundle.settingsReportLastSentLabel;
  String get settingsReportNextSendLabel => _bundle.settingsReportNextSendLabel;
  String get settingsReportNeverSent => _bundle.settingsReportNeverSent;
  String get settingsReportNotConfigured => _bundle.settingsReportNotConfigured;
  String get settingsAiImageQueueTitle => _bundle.settingsAiImageQueueTitle;
  String get settingsAiImageQueueSubtitle =>
      _bundle.settingsAiImageQueueSubtitle;
  String get aiQueuePendingHeader => _bundle.aiQueuePendingHeader;
  String get aiQueuePendingEmpty => _bundle.aiQueuePendingEmpty;
  String aiQueuePendingLink(int n) =>
      _bundle.aiQueuePendingLinkN.replaceAll('{n}', '$n');
  String get aiQueueGeneratedHeader => _bundle.aiQueueGeneratedHeader;
  String get aiQueueGeneratedEmpty => _bundle.aiQueueGeneratedEmpty;
  String aiQueueAttempts(int n) =>
      _bundle.aiQueueAttemptsN.replaceAll('{n}', '$n');
  String get aiQueueLastErrorLabel => _bundle.aiQueueLastErrorLabel;
  String get aiQueueEnqueuedLabel => _bundle.aiQueueEnqueuedLabel;

  // The standard Flutter Localizations accessor convention (`AppStrings.of`);
  // VGA's "static method → constructor" lint doesn't fit the lookup pattern.
  // ignore: prefer_constructors_over_static_methods
  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    return strings ?? const AppStrings(Locale('en'));
  }
}

@immutable
class _Bundle {
  const _Bundle({
    required this.recordingsTitle,
    required this.recordingsDetailTitle,
    required this.recordingsNotFound,
    required this.emptyTitle,
    required this.emptyBody,
    required this.emptyHint,
    required this.loading,
    required this.errorTitle,
    required this.retry,
    required this.scanTooltip,
    required this.scanFailed,
    required this.scannedCountN,
    required this.folderOnboardingTitle,
    required this.folderOnboardingBodyN,
    required this.folderOnboardingPick,
    required this.folderOnboardingNone,
    required this.folderOnboardingNonSvrWarning,
    required this.folderOnboardingSaveFailed,
    required this.unknownDuration,
    required this.unknownFormat,
    required this.metaDate,
    required this.metaDuration,
    required this.metaSize,
    required this.metaFormat,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.replayTooltip,
    required this.queueNavToday,
    required this.queueNavLibrary,
    required this.queueTitle,
    required this.queueEmptyTitle,
    required this.queueEmptyBody,
    required this.queueStaleBadge,
    required this.queueDueToday,
    required this.queueDueTomorrow,
    required this.queueSectionTomorrow,
    required this.queueOverdueN,
    required this.queueNowPlaying,
    required this.reviewHistoryTitle,
    required this.reviewLastReviewed,
    required this.reviewNever,
    required this.reviewMilestoneReached,
    required this.reviewNoneYet,
    required this.reviewCountN,
    required this.reviewMarkReviewed,
    required this.reviewUndo,
    required this.reviewDueLabel,
    required this.reviewSaveFailed,
    required this.recordTooltip,
    required this.recordSheetTitle,
    required this.recordStart,
    required this.recordStop,
    required this.recordSaving,
    required this.recordNameLabel,
    required this.recordNameHint,
    required this.recordPermissionDenied,
    required this.recordNoFolder,
    required this.recordFailed,
    required this.recordSavedN,
    required this.recordingMenuRename,
    required this.recordingMenuDelete,
    required this.renameDialogTitle,
    required this.renameFailed,
    required this.deleteDialogTitle,
    required this.deleteDialogBodyN,
    required this.deleteFailed,
    required this.wordLogTitle,
    required this.wordLogTabText,
    required this.wordLogTabImages,
    required this.wordLogAddText,
    required this.wordLogEditText,
    required this.wordLogAddImage,
    required this.wordLogTextEmpty,
    required this.wordLogImagesEmpty,
    required this.wordLogTextDialogHint,
    required this.wordLogSave,
    required this.wordLogCancel,
    required this.wordLogAttachFailed,
    required this.ankiSend,
    required this.ankiSending,
    required this.ankiRetry,
    required this.ankiNotInstalledTitle,
    required this.ankiNotInstalledBody,
    required this.ankiSendFailed,
    required this.ankiAddedN,
    required this.ankiSkippedN,
    required this.ankiFailedN,
    required this.ankiPendingN,
    required this.ankiPendingHint,
    required this.ankiGotIt,
    required this.ankiGrantTitle,
    required this.ankiGrantBody,
    required this.ankiGrantContinue,
    required this.ankiEnableApiHint,
    required this.tasksTitle,
    required this.tasksEmptyTitle,
    required this.tasksEmptyBody,
    required this.tasksAdd,
    required this.taskFieldTitle,
    required this.taskFieldDescription,
    required this.taskFieldDueDate,
    required this.taskNoDate,
    required this.taskClearDate,
    required this.taskSave,
    required this.taskDelete,
    required this.taskOverdue,
    required this.taskDueOnN,
    required this.taskDetailTitle,
    required this.taskEditAction,
    required this.taskCreatedOnN,
    required this.taskNotFound,
    required this.coachTitle,
    required this.coachEmptyTitle,
    required this.coachEmptyBody,
    required this.coachAdd,
    required this.coachFieldBody,
    required this.coachRecordings,
    required this.coachVocab,
    required this.coachAttach,
    required this.coachNone,
    required this.coachPickRecordings,
    required this.coachPickVocab,
    required this.coachNRecordingsN,
    required this.coachNVocabN,
    required this.statsTitle,
    required this.statsGranularityDaily,
    required this.statsGranularityWeekly,
    required this.statsGranularityMonthly,
    required this.statsMetricLessonDuration,
    required this.statsMetricJournalingOutput,
    required this.statsMetricCompletedQueueItems,
    required this.statsMetricFlashcardsReviewed,
    required this.statsEmptyTitle,
    required this.statsEmptyBody,
    required this.settingsTitle,
    required this.settingsTooltip,
    required this.settingsAutoAdvanceTitle,
    required this.settingsAutoAdvanceSubtitle,
    required this.settingsThemeTitle,
    required this.settingsThemeSystem,
    required this.settingsThemeLight,
    required this.settingsThemeDark,
    required this.settingsReportTitle,
    required this.settingsReportDayLabel,
    required this.settingsReportTimeLabel,
    required this.settingsReportRecipientLabel,
    required this.settingsReportRecipientHint,
    required this.settingsReportRecipientHelp,
    required this.settingsReportSmtpUserLabel,
    required this.settingsReportSmtpPasswordLabel,
    required this.settingsReportSmtpPasswordHelp,
    required this.settingsReportSaveCredentials,
    required this.settingsReportCredentialsSaved,
    required this.settingsReportLastSentLabel,
    required this.settingsReportNextSendLabel,
    required this.settingsReportNeverSent,
    required this.settingsReportNotConfigured,
    required this.settingsAiImageQueueTitle,
    required this.settingsAiImageQueueSubtitle,
    required this.aiQueuePendingHeader,
    required this.aiQueuePendingLinkN,
    required this.aiQueuePendingEmpty,
    required this.aiQueueGeneratedHeader,
    required this.aiQueueGeneratedEmpty,
    required this.aiQueueAttemptsN,
    required this.aiQueueLastErrorLabel,
    required this.aiQueueEnqueuedLabel,
  });

  final String recordingsTitle;
  final String recordingsDetailTitle;
  final String recordingsNotFound;
  final String emptyTitle;
  final String emptyBody;
  final String emptyHint;
  final String loading;
  final String errorTitle;
  final String retry;
  final String scanTooltip;
  final String scanFailed;
  final String scannedCountN;
  final String folderOnboardingTitle;
  final String folderOnboardingBodyN;
  final String folderOnboardingPick;
  final String folderOnboardingNone;
  final String folderOnboardingNonSvrWarning;
  final String folderOnboardingSaveFailed;
  final String unknownDuration;
  final String unknownFormat;
  final String metaDate;
  final String metaDuration;
  final String metaSize;
  final String metaFormat;
  final String playTooltip;
  final String pauseTooltip;
  final String replayTooltip;
  final String queueNavToday;
  final String queueNavLibrary;
  final String queueTitle;
  final String queueEmptyTitle;
  final String queueEmptyBody;
  final String queueStaleBadge;
  final String queueDueToday;
  final String queueDueTomorrow;
  final String queueSectionTomorrow;
  final String queueOverdueN;
  final String queueNowPlaying;
  final String reviewHistoryTitle;
  final String reviewLastReviewed;
  final String reviewNever;
  final String reviewMilestoneReached;
  final String reviewNoneYet;
  final String reviewCountN;
  final String reviewMarkReviewed;
  final String reviewUndo;
  final String reviewDueLabel;
  final String reviewSaveFailed;
  final String recordTooltip;
  final String recordSheetTitle;
  final String recordStart;
  final String recordStop;
  final String recordSaving;
  final String recordNameLabel;
  final String recordNameHint;
  final String recordPermissionDenied;
  final String recordNoFolder;
  final String recordFailed;
  final String recordSavedN;
  final String recordingMenuRename;
  final String recordingMenuDelete;
  final String renameDialogTitle;
  final String renameFailed;
  final String deleteDialogTitle;
  final String deleteDialogBodyN;
  final String deleteFailed;
  final String wordLogTitle;
  final String wordLogTabText;
  final String wordLogTabImages;
  final String wordLogAddText;
  final String wordLogEditText;
  final String wordLogAddImage;
  final String wordLogTextEmpty;
  final String wordLogImagesEmpty;
  final String wordLogTextDialogHint;
  final String wordLogSave;
  final String wordLogCancel;
  final String wordLogAttachFailed;
  final String ankiSend;
  final String ankiSending;
  final String ankiRetry;
  final String ankiNotInstalledTitle;
  final String ankiNotInstalledBody;
  final String ankiSendFailed;
  final String ankiAddedN;
  final String ankiSkippedN;
  final String ankiFailedN;
  final String ankiPendingN;
  final String ankiPendingHint;
  final String ankiGotIt;
  final String ankiGrantTitle;
  final String ankiGrantBody;
  final String ankiGrantContinue;
  final String ankiEnableApiHint;
  final String tasksTitle;
  final String tasksEmptyTitle;
  final String tasksEmptyBody;
  final String tasksAdd;
  final String taskFieldTitle;
  final String taskFieldDescription;
  final String taskFieldDueDate;
  final String taskNoDate;
  final String taskClearDate;
  final String taskSave;
  final String taskDelete;
  final String taskOverdue;
  final String taskDueOnN;
  final String taskDetailTitle;
  final String taskEditAction;
  final String taskCreatedOnN;
  final String taskNotFound;
  final String coachTitle;
  final String coachEmptyTitle;
  final String coachEmptyBody;
  final String coachAdd;
  final String coachFieldBody;
  final String coachRecordings;
  final String coachVocab;
  final String coachAttach;
  final String coachNone;
  final String coachPickRecordings;
  final String coachPickVocab;
  final String coachNRecordingsN;
  final String coachNVocabN;
  final String statsTitle;
  final String statsGranularityDaily;
  final String statsGranularityWeekly;
  final String statsGranularityMonthly;
  final String statsMetricLessonDuration;
  final String statsMetricJournalingOutput;
  final String statsMetricCompletedQueueItems;
  final String statsMetricFlashcardsReviewed;
  final String statsEmptyTitle;
  final String statsEmptyBody;
  final String settingsTitle;
  final String settingsTooltip;
  final String settingsAutoAdvanceTitle;
  final String settingsAutoAdvanceSubtitle;
  final String settingsThemeTitle;
  final String settingsThemeSystem;
  final String settingsThemeLight;
  final String settingsThemeDark;
  final String settingsReportTitle;
  final String settingsReportDayLabel;
  final String settingsReportTimeLabel;
  final String settingsReportRecipientLabel;
  final String settingsReportRecipientHint;
  final String settingsReportRecipientHelp;
  final String settingsReportSmtpUserLabel;
  final String settingsReportSmtpPasswordLabel;
  final String settingsReportSmtpPasswordHelp;
  final String settingsReportSaveCredentials;
  final String settingsReportCredentialsSaved;
  final String settingsReportLastSentLabel;
  final String settingsReportNextSendLabel;
  final String settingsReportNeverSent;
  final String settingsReportNotConfigured;
  final String settingsAiImageQueueTitle;
  final String settingsAiImageQueueSubtitle;
  final String aiQueuePendingHeader;
  final String aiQueuePendingLinkN;
  final String aiQueuePendingEmpty;
  final String aiQueueGeneratedHeader;
  final String aiQueueGeneratedEmpty;
  final String aiQueueAttemptsN;
  final String aiQueueLastErrorLabel;
  final String aiQueueEnqueuedLabel;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    final code = locale.languageCode;
    return code == 'en' || code == 'uz';
  }

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture<AppStrings>(AppStrings(locale));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
