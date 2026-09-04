class AppSettings {
  // Existing fields
  final String? defaultPrinterName;
  final int defaultDpi;
  final String defaultPaperPresetId;
  final String defaultPhotoPresetId;
  final String defaultIdCardPresetId;
  final int defaultPassportCopies;
  final bool defaultPassportFillAuto;
  final double defaultOuterBorderMm;
  final double defaultInnerBorderMm;
  final double defaultIdGapMm;
  final double defaultIdMarginMm;
  final bool enableAutoCleanup;
  final bool enableAutoDetect;
  final bool isDarkMode;

  // General & Interface
  final String language;
  final bool startOnStartup;
  final bool confirmBeforePrinting;
  final bool rememberLastService;
  final bool autoSaveProjects;
  final String themeMode; // 'Light', 'Dark', 'System'
  final String uiDensity; // 'Comfortable', 'Compact'
  final bool showTooltips;
  final bool showShortcuts;
  final String accentColor;
  final bool compactSidebar;
  final bool enableAnimations;

  // Project Behavior & Notifications
  final bool openLastProjectOnStartup;
  final bool showRecentProjects;
  final bool autoCheckUpdates;
  final bool showSuccessNotifications;
  final bool showErrorNotifications;
  final bool playNotificationSound;

  // Printer Behavior
  final bool rememberSelectedPrinter;
  final bool autoSelectSystemDefault;
  final bool showPrinterStatus;
  final bool warnWhenOffline;

  // Print Defaults
  final String defaultOrientation; // 'Portrait', 'Landscape'
  final String defaultColorMode; // 'Color', 'Black & White'
  final String defaultPrintSides; // 'Single-sided', 'Duplex Long Edge', 'Duplex Short Edge'
  final String defaultScaling; // 'Actual Size', 'Fit to Page', 'Fill Page'
  final int defaultDocCopies;

  // Paper & Layout
  final double paperMarginTopMm;
  final double paperMarginBottomMm;
  final double paperMarginLeftMm;
  final double paperMarginRightMm;
  final double cutGapMm;
  final String measurementUnit; // 'mm', 'inch'

  // Image Processing
  final double defaultBrightness; // -100 to 100 (0 default)
  final double defaultContrast; // -100 to 100 (0 default)
  final double defaultSharpness; // 0 to 100 (0 default)
  final bool imageAutoEnhance;
  final bool imageAutoRotate;
  final bool preserveAspectRatio;
  final bool preventAccidentalCropping;

  // Document Processing
  final String pdfRenderQuality; // 'Standard (300 DPI)', 'Draft (150 DPI)', 'High (600 DPI)'
  final bool preservePdfPageSize;
  final bool pdfAutoRotate;
  final bool docFitContentToPage;

  // Shop Information
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String shopEmail;
  final String shopGst;
  final String receiptFooter;

  // Storage & Backup
  final String storageLocation;
  final bool autoBackupEnabled;
  final String backupFrequency; // 'Daily', 'Weekly', 'Monthly'

  // Print History Settings
  final bool enablePrintHistory;
  final String historyRetention; // '7 days', '30 days', '90 days', 'Forever'
  final bool storeThumbnails;
  final bool storeDocumentNames;

  const AppSettings({
    this.defaultPrinterName,
    this.defaultDpi = 300,
    this.defaultPaperPresetId = 'a4',
    this.defaultPhotoPresetId = 'passport_35_45',
    this.defaultIdCardPresetId = 'aadhaar_standard',
    this.defaultPassportCopies = 8,
    this.defaultPassportFillAuto = true,
    this.defaultOuterBorderMm = 0.8,
    this.defaultInnerBorderMm = 0.25,
    this.defaultIdGapMm = 5.0,
    this.defaultIdMarginMm = 4.0,
    this.enableAutoCleanup = true,
    this.enableAutoDetect = true,
    this.isDarkMode = false,
    this.language = 'English',
    this.startOnStartup = false,
    this.confirmBeforePrinting = true,
    this.rememberLastService = true,
    this.autoSaveProjects = true,
    this.themeMode = 'Light',
    this.uiDensity = 'Comfortable',
    this.showTooltips = true,
    this.showShortcuts = true,
    this.accentColor = '#2563EB',
    this.compactSidebar = false,
    this.enableAnimations = true,
    this.openLastProjectOnStartup = false,
    this.showRecentProjects = true,
    this.autoCheckUpdates = true,
    this.showSuccessNotifications = true,
    this.showErrorNotifications = true,
    this.playNotificationSound = false,
    this.rememberSelectedPrinter = true,
    this.autoSelectSystemDefault = true,
    this.showPrinterStatus = true,
    this.warnWhenOffline = true,
    this.defaultOrientation = 'Portrait',
    this.defaultColorMode = 'Color',
    this.defaultPrintSides = 'Single-sided',
    this.defaultScaling = 'Fit to Page',
    this.defaultDocCopies = 1,
    this.paperMarginTopMm = 5.0,
    this.paperMarginBottomMm = 5.0,
    this.paperMarginLeftMm = 5.0,
    this.paperMarginRightMm = 5.0,
    this.cutGapMm = 2.0,
    this.measurementUnit = 'mm',
    this.defaultBrightness = 0.0,
    this.defaultContrast = 0.0,
    this.defaultSharpness = 0.0,
    this.imageAutoEnhance = false,
    this.imageAutoRotate = true,
    this.preserveAspectRatio = true,
    this.preventAccidentalCropping = true,
    this.pdfRenderQuality = 'Standard (300 DPI)',
    this.preservePdfPageSize = true,
    this.pdfAutoRotate = true,
    this.docFitContentToPage = true,
    this.shopName = 'FastPrint Studio',
    this.shopAddress = 'Main Market Road, City Center',
    this.shopPhone = '+91 98765 43210',
    this.shopEmail = 'support@fastprintstudio.com',
    this.shopGst = '',
    this.receiptFooter = 'Thank you for choosing FastPrint Studio! Visit again.',
    this.storageLocation = 'C:\\FastPrintStudio\\Data',
    this.autoBackupEnabled = true,
    this.backupFrequency = 'Weekly',
    this.enablePrintHistory = true,
    this.historyRetention = 'Forever',
    this.storeThumbnails = true,
    this.storeDocumentNames = true,
  });

  AppSettings copyWith({
    String? defaultPrinterName,
    int? defaultDpi,
    String? defaultPaperPresetId,
    String? defaultPhotoPresetId,
    String? defaultIdCardPresetId,
    int? defaultPassportCopies,
    bool? defaultPassportFillAuto,
    double? defaultOuterBorderMm,
    double? defaultInnerBorderMm,
    double? defaultIdGapMm,
    double? defaultIdMarginMm,
    bool? enableAutoCleanup,
    bool? enableAutoDetect,
    bool? isDarkMode,
    String? language,
    bool? startOnStartup,
    bool? confirmBeforePrinting,
    bool? rememberLastService,
    bool? autoSaveProjects,
    String? themeMode,
    String? uiDensity,
    bool? showTooltips,
    bool? showShortcuts,
    String? accentColor,
    bool? compactSidebar,
    bool? enableAnimations,
    bool? openLastProjectOnStartup,
    bool? showRecentProjects,
    bool? autoCheckUpdates,
    bool? showSuccessNotifications,
    bool? showErrorNotifications,
    bool? playNotificationSound,
    bool? rememberSelectedPrinter,
    bool? autoSelectSystemDefault,
    bool? showPrinterStatus,
    bool? warnWhenOffline,
    String? defaultOrientation,
    String? defaultColorMode,
    String? defaultPrintSides,
    String? defaultScaling,
    int? defaultDocCopies,
    double? paperMarginTopMm,
    double? paperMarginBottomMm,
    double? paperMarginLeftMm,
    double? paperMarginRightMm,
    double? cutGapMm,
    String? measurementUnit,
    double? defaultBrightness,
    double? defaultContrast,
    double? defaultSharpness,
    bool? imageAutoEnhance,
    bool? imageAutoRotate,
    bool? preserveAspectRatio,
    bool? preventAccidentalCropping,
    String? pdfRenderQuality,
    bool? preservePdfPageSize,
    bool? pdfAutoRotate,
    bool? docFitContentToPage,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? shopEmail,
    String? shopGst,
    String? receiptFooter,
    String? storageLocation,
    bool? autoBackupEnabled,
    String? backupFrequency,
    bool? enablePrintHistory,
    String? historyRetention,
    bool? storeThumbnails,
    bool? storeDocumentNames,
  }) {
    return AppSettings(
      defaultPrinterName: defaultPrinterName ?? this.defaultPrinterName,
      defaultDpi: defaultDpi ?? this.defaultDpi,
      defaultPaperPresetId: defaultPaperPresetId ?? this.defaultPaperPresetId,
      defaultPhotoPresetId: defaultPhotoPresetId ?? this.defaultPhotoPresetId,
      defaultIdCardPresetId: defaultIdCardPresetId ?? this.defaultIdCardPresetId,
      defaultPassportCopies: defaultPassportCopies ?? this.defaultPassportCopies,
      defaultPassportFillAuto: defaultPassportFillAuto ?? this.defaultPassportFillAuto,
      defaultOuterBorderMm: defaultOuterBorderMm ?? this.defaultOuterBorderMm,
      defaultInnerBorderMm: defaultInnerBorderMm ?? this.defaultInnerBorderMm,
      defaultIdGapMm: defaultIdGapMm ?? this.defaultIdGapMm,
      defaultIdMarginMm: defaultIdMarginMm ?? this.defaultIdMarginMm,
      enableAutoCleanup: enableAutoCleanup ?? this.enableAutoCleanup,
      enableAutoDetect: enableAutoDetect ?? this.enableAutoDetect,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      startOnStartup: startOnStartup ?? this.startOnStartup,
      confirmBeforePrinting: confirmBeforePrinting ?? this.confirmBeforePrinting,
      rememberLastService: rememberLastService ?? this.rememberLastService,
      autoSaveProjects: autoSaveProjects ?? this.autoSaveProjects,
      themeMode: themeMode ?? this.themeMode,
      uiDensity: uiDensity ?? this.uiDensity,
      showTooltips: showTooltips ?? this.showTooltips,
      showShortcuts: showShortcuts ?? this.showShortcuts,
      accentColor: accentColor ?? this.accentColor,
      compactSidebar: compactSidebar ?? this.compactSidebar,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      openLastProjectOnStartup: openLastProjectOnStartup ?? this.openLastProjectOnStartup,
      showRecentProjects: showRecentProjects ?? this.showRecentProjects,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      showSuccessNotifications: showSuccessNotifications ?? this.showSuccessNotifications,
      showErrorNotifications: showErrorNotifications ?? this.showErrorNotifications,
      playNotificationSound: playNotificationSound ?? this.playNotificationSound,
      rememberSelectedPrinter: rememberSelectedPrinter ?? this.rememberSelectedPrinter,
      autoSelectSystemDefault: autoSelectSystemDefault ?? this.autoSelectSystemDefault,
      showPrinterStatus: showPrinterStatus ?? this.showPrinterStatus,
      warnWhenOffline: warnWhenOffline ?? this.warnWhenOffline,
      defaultOrientation: defaultOrientation ?? this.defaultOrientation,
      defaultColorMode: defaultColorMode ?? this.defaultColorMode,
      defaultPrintSides: defaultPrintSides ?? this.defaultPrintSides,
      defaultScaling: defaultScaling ?? this.defaultScaling,
      defaultDocCopies: defaultDocCopies ?? this.defaultDocCopies,
      paperMarginTopMm: paperMarginTopMm ?? this.paperMarginTopMm,
      paperMarginBottomMm: paperMarginBottomMm ?? this.paperMarginBottomMm,
      paperMarginLeftMm: paperMarginLeftMm ?? this.paperMarginLeftMm,
      paperMarginRightMm: paperMarginRightMm ?? this.paperMarginRightMm,
      cutGapMm: cutGapMm ?? this.cutGapMm,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      defaultBrightness: defaultBrightness ?? this.defaultBrightness,
      defaultContrast: defaultContrast ?? this.defaultContrast,
      defaultSharpness: defaultSharpness ?? this.defaultSharpness,
      imageAutoEnhance: imageAutoEnhance ?? this.imageAutoEnhance,
      imageAutoRotate: imageAutoRotate ?? this.imageAutoRotate,
      preserveAspectRatio: preserveAspectRatio ?? this.preserveAspectRatio,
      preventAccidentalCropping: preventAccidentalCropping ?? this.preventAccidentalCropping,
      pdfRenderQuality: pdfRenderQuality ?? this.pdfRenderQuality,
      preservePdfPageSize: preservePdfPageSize ?? this.preservePdfPageSize,
      pdfAutoRotate: pdfAutoRotate ?? this.pdfAutoRotate,
      docFitContentToPage: docFitContentToPage ?? this.docFitContentToPage,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      shopEmail: shopEmail ?? this.shopEmail,
      shopGst: shopGst ?? this.shopGst,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      storageLocation: storageLocation ?? this.storageLocation,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      enablePrintHistory: enablePrintHistory ?? this.enablePrintHistory,
      historyRetention: historyRetention ?? this.historyRetention,
      storeThumbnails: storeThumbnails ?? this.storeThumbnails,
      storeDocumentNames: storeDocumentNames ?? this.storeDocumentNames,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultPrinterName': defaultPrinterName,
        'defaultDpi': defaultDpi,
        'defaultPaperPresetId': defaultPaperPresetId,
        'defaultPhotoPresetId': defaultPhotoPresetId,
        'defaultIdCardPresetId': defaultIdCardPresetId,
        'defaultPassportCopies': defaultPassportCopies,
        'defaultPassportFillAuto': defaultPassportFillAuto,
        'defaultOuterBorderMm': defaultOuterBorderMm,
        'defaultInnerBorderMm': defaultInnerBorderMm,
        'defaultIdGapMm': defaultIdGapMm,
        'defaultIdMarginMm': defaultIdMarginMm,
        'enableAutoCleanup': enableAutoCleanup,
        'enableAutoDetect': enableAutoDetect,
        'isDarkMode': isDarkMode,
        'language': language,
        'startOnStartup': startOnStartup,
        'confirmBeforePrinting': confirmBeforePrinting,
        'rememberLastService': rememberLastService,
        'autoSaveProjects': autoSaveProjects,
        'themeMode': themeMode,
        'uiDensity': uiDensity,
        'showTooltips': showTooltips,
        'showShortcuts': showShortcuts,
        'accentColor': accentColor,
        'compactSidebar': compactSidebar,
        'enableAnimations': enableAnimations,
        'openLastProjectOnStartup': openLastProjectOnStartup,
        'showRecentProjects': showRecentProjects,
        'autoCheckUpdates': autoCheckUpdates,
        'showSuccessNotifications': showSuccessNotifications,
        'showErrorNotifications': showErrorNotifications,
        'playNotificationSound': playNotificationSound,
        'rememberSelectedPrinter': rememberSelectedPrinter,
        'autoSelectSystemDefault': autoSelectSystemDefault,
        'showPrinterStatus': showPrinterStatus,
        'warnWhenOffline': warnWhenOffline,
        'defaultOrientation': defaultOrientation,
        'defaultColorMode': defaultColorMode,
        'defaultPrintSides': defaultPrintSides,
        'defaultScaling': defaultScaling,
        'defaultDocCopies': defaultDocCopies,
        'paperMarginTopMm': paperMarginTopMm,
        'paperMarginBottomMm': paperMarginBottomMm,
        'paperMarginLeftMm': paperMarginLeftMm,
        'paperMarginRightMm': paperMarginRightMm,
        'cutGapMm': cutGapMm,
        'measurementUnit': measurementUnit,
        'defaultBrightness': defaultBrightness,
        'defaultContrast': defaultContrast,
        'defaultSharpness': defaultSharpness,
        'imageAutoEnhance': imageAutoEnhance,
        'imageAutoRotate': imageAutoRotate,
        'preserveAspectRatio': preserveAspectRatio,
        'preventAccidentalCropping': preventAccidentalCropping,
        'pdfRenderQuality': pdfRenderQuality,
        'preservePdfPageSize': preservePdfPageSize,
        'pdfAutoRotate': pdfAutoRotate,
        'docFitContentToPage': docFitContentToPage,
        'shopName': shopName,
        'shopAddress': shopAddress,
        'shopPhone': shopPhone,
        'shopEmail': shopEmail,
        'shopGst': shopGst,
        'receiptFooter': receiptFooter,
        'storageLocation': storageLocation,
        'autoBackupEnabled': autoBackupEnabled,
        'backupFrequency': backupFrequency,
        'enablePrintHistory': enablePrintHistory,
        'historyRetention': historyRetention,
        'storeThumbnails': storeThumbnails,
        'storeDocumentNames': storeDocumentNames,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        defaultPrinterName: json['defaultPrinterName'] as String?,
        defaultDpi: json['defaultDpi'] as int? ?? 300,
        defaultPaperPresetId: json['defaultPaperPresetId'] as String? ?? 'a4',
        defaultPhotoPresetId: json['defaultPhotoPresetId'] as String? ?? 'passport_35_45',
        defaultIdCardPresetId: json['defaultIdCardPresetId'] as String? ?? 'aadhaar_standard',
        defaultPassportCopies: json['defaultPassportCopies'] as int? ?? 8,
        defaultPassportFillAuto: json['defaultPassportFillAuto'] as bool? ?? true,
        defaultOuterBorderMm: (json['defaultOuterBorderMm'] as num?)?.toDouble() ?? 0.8,
        defaultInnerBorderMm: (json['defaultInnerBorderMm'] as num?)?.toDouble() ?? 0.25,
        defaultIdGapMm: (json['defaultIdGapMm'] as num?)?.toDouble() ?? 5.0,
        defaultIdMarginMm: (json['defaultIdMarginMm'] as num?)?.toDouble() ?? 4.0,
        enableAutoCleanup: json['enableAutoCleanup'] as bool? ?? true,
        enableAutoDetect: json['enableAutoDetect'] as bool? ?? true,
        isDarkMode: json['isDarkMode'] as bool? ?? false,
        language: json['language'] as String? ?? 'English',
        startOnStartup: json['startOnStartup'] as bool? ?? false,
        confirmBeforePrinting: json['confirmBeforePrinting'] as bool? ?? true,
        rememberLastService: json['rememberLastService'] as bool? ?? true,
        autoSaveProjects: json['autoSaveProjects'] as bool? ?? true,
        themeMode: json['themeMode'] as String? ?? 'Light',
        uiDensity: json['uiDensity'] as String? ?? 'Comfortable',
        showTooltips: json['showTooltips'] as bool? ?? true,
        showShortcuts: json['showShortcuts'] as bool? ?? true,
        accentColor: json['accentColor'] as String? ?? '#2563EB',
        compactSidebar: json['compactSidebar'] as bool? ?? false,
        enableAnimations: json['enableAnimations'] as bool? ?? true,
        openLastProjectOnStartup: json['openLastProjectOnStartup'] as bool? ?? false,
        showRecentProjects: json['showRecentProjects'] as bool? ?? true,
        autoCheckUpdates: json['autoCheckUpdates'] as bool? ?? true,
        showSuccessNotifications: json['showSuccessNotifications'] as bool? ?? true,
        showErrorNotifications: json['showErrorNotifications'] as bool? ?? true,
        playNotificationSound: json['playNotificationSound'] as bool? ?? false,
        rememberSelectedPrinter: json['rememberSelectedPrinter'] as bool? ?? true,
        autoSelectSystemDefault: json['autoSelectSystemDefault'] as bool? ?? true,
        showPrinterStatus: json['showPrinterStatus'] as bool? ?? true,
        warnWhenOffline: json['warnWhenOffline'] as bool? ?? true,
        defaultOrientation: json['defaultOrientation'] as String? ?? 'Portrait',
        defaultColorMode: json['defaultColorMode'] as String? ?? 'Color',
        defaultPrintSides: json['defaultPrintSides'] as String? ?? 'Single-sided',
        defaultScaling: json['defaultScaling'] as String? ?? 'Fit to Page',
        defaultDocCopies: json['defaultDocCopies'] as int? ?? 1,
        paperMarginTopMm: (json['paperMarginTopMm'] as num?)?.toDouble() ?? 5.0,
        paperMarginBottomMm: (json['paperMarginBottomMm'] as num?)?.toDouble() ?? 5.0,
        paperMarginLeftMm: (json['paperMarginLeftMm'] as num?)?.toDouble() ?? 5.0,
        paperMarginRightMm: (json['paperMarginRightMm'] as num?)?.toDouble() ?? 5.0,
        cutGapMm: (json['cutGapMm'] as num?)?.toDouble() ?? 2.0,
        measurementUnit: json['measurementUnit'] as String? ?? 'mm',
        defaultBrightness: (json['defaultBrightness'] as num?)?.toDouble() ?? 0.0,
        defaultContrast: (json['defaultContrast'] as num?)?.toDouble() ?? 0.0,
        defaultSharpness: (json['defaultSharpness'] as num?)?.toDouble() ?? 0.0,
        imageAutoEnhance: json['imageAutoEnhance'] as bool? ?? false,
        imageAutoRotate: json['imageAutoRotate'] as bool? ?? true,
        preserveAspectRatio: json['preserveAspectRatio'] as bool? ?? true,
        preventAccidentalCropping: json['preventAccidentalCropping'] as bool? ?? true,
        pdfRenderQuality: json['pdfRenderQuality'] as String? ?? 'Standard (300 DPI)',
        preservePdfPageSize: json['preservePdfPageSize'] as bool? ?? true,
        pdfAutoRotate: json['pdfAutoRotate'] as bool? ?? true,
        docFitContentToPage: json['docFitContentToPage'] as bool? ?? true,
        shopName: json['shopName'] as String? ?? 'FastPrint Studio',
        shopAddress: json['shopAddress'] as String? ?? 'Main Market Road, City Center',
        shopPhone: json['shopPhone'] as String? ?? '+91 98765 43210',
        shopEmail: json['shopEmail'] as String? ?? 'support@fastprintstudio.com',
        shopGst: json['shopGst'] as String? ?? '',
        receiptFooter: json['receiptFooter'] as String? ?? 'Thank you for choosing FastPrint Studio! Visit again.',
        storageLocation: json['storageLocation'] as String? ?? 'C:\\FastPrintStudio\\Data',
        autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? true,
        backupFrequency: json['backupFrequency'] as String? ?? 'Weekly',
        enablePrintHistory: json['enablePrintHistory'] as bool? ?? true,
        historyRetention: json['historyRetention'] as String? ?? 'Forever',
        storeThumbnails: json['storeThumbnails'] as bool? ?? true,
        storeDocumentNames: json['storeDocumentNames'] as bool? ?? true,
      );
}
