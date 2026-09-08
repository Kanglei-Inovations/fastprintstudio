import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/paper_presets.dart';
import '../../core/models/border_config.dart';
import '../../core/models/crop_rect_data.dart';
import '../../core/models/id_card_entry.dart';
import '../../core/models/id_card_preset.dart';
import '../../core/models/layout_item.dart';
import '../../core/models/l805_calibration.dart';
import '../../core/models/paper_preset.dart';
import '../../core/models/photo_finish.dart';
import '../../core/models/photo_group.dart';
import '../../core/models/photo_preset.dart';
import '../../core/models/print_layout.dart';

class LayoutEngine {
  static const _uuid = Uuid();

  /// Calculates multi-page/multi-sheet photo layouts (Sheet 1, Sheet 2...)
  /// when total requested copies exceed single sheet capacity.
  static List<PrintLayout> calculateMultiPhotoLayoutPages({
    required PaperPreset paperPreset,
    required List<PhotoGroup> groups,
    PaperOrientation orientation = PaperOrientation.landscape,
    double marginMm = 3.0,
    double spacingMm = 2.0,
    PhotoScalingMode scaling = PhotoScalingMode.fit,
    int dpi = 300,
  }) {
    final activeGroups = groups.where((g) => g.copiesCount > 0 && g.processedBytes != null).toList();
    if (activeGroups.isEmpty) {
      return [
        calculateMultiPhotoLayout(
          paperPreset: paperPreset,
          groups: groups,
          orientation: orientation,
          marginMm: marginMm,
          spacingMm: spacingMm,
          scaling: scaling,
          dpi: dpi,
        ),
      ];
    }

    // For single full 4R or A4 Photo Prints, each copy gets its own sheet
    if (activeGroups.length == 1 &&
        (activeGroups.first.preset.id == 'photo_4r' || activeGroups.first.preset.id == 'photo_a4')) {
      final base = calculateMultiPhotoLayout(
        paperPreset: paperPreset,
        groups: activeGroups,
        orientation: orientation,
        marginMm: marginMm,
        spacingMm: spacingMm,
        scaling: scaling,
        dpi: dpi,
      );
      final count = activeGroups.first.copiesCount.clamp(1, 100);
      return List.generate(count, (_) => base);
    }

    // Determine total requested copies
    final totalRequested = activeGroups.fold<int>(0, (sum, g) => sum + g.copiesCount);

    // First attempt a single sheet
    final firstSheet = calculateMultiPhotoLayout(
      paperPreset: paperPreset,
      groups: activeGroups,
      orientation: orientation,
      marginMm: marginMm,
      spacingMm: spacingMm,
      scaling: scaling,
      dpi: dpi,
    );

    // If all items fit on 1 sheet without overflow, return single sheet
    if (firstSheet.items.length >= totalRequested) {
      return [firstSheet];
    }

    // Otherwise, paginate across multiple sheets
    final remainingCopies = <String, int>{
      for (final g in activeGroups) g.id: g.copiesCount,
    };

    final pages = <PrintLayout>[];
    int safetyCounter = 0;

    while (remainingCopies.values.any((c) => c > 0) && safetyCounter < 50) {
      safetyCounter++;

      final currentSlice = activeGroups
          .where((g) => (remainingCopies[g.id] ?? 0) > 0)
          .map((g) => g.copyWith(copiesCount: remainingCopies[g.id]!))
          .toList();

      final sheet = calculateMultiPhotoLayout(
        paperPreset: paperPreset,
        groups: currentSlice,
        orientation: orientation,
        marginMm: marginMm,
        spacingMm: spacingMm,
        scaling: scaling,
        dpi: dpi,
      );

      if (sheet.items.isEmpty) break;

      final placedPerGroup = <String, int>{};
      for (final item in sheet.items) {
        if (item.groupId != null) {
          placedPerGroup[item.groupId!] = (placedPerGroup[item.groupId!] ?? 0) + 1;
        }
      }

      if (placedPerGroup.isEmpty) {
        pages.add(sheet);
        break;
      }

      for (final entry in placedPerGroup.entries) {
        remainingCopies[entry.key] = math.max(0, (remainingCopies[entry.key] ?? 0) - entry.value);
      }

      // Add clean sheet without overflow warning
      pages.add(sheet.copyWith(warningMessage: null));
    }

    return pages.isNotEmpty ? pages : [firstSheet];
  }

  /// Calculates Passport / Stamp Multi-Photo layout supporting mixed photo groups on a single sheet
  static PrintLayout calculateMultiPhotoLayout({
    required PaperPreset paperPreset,
    required List<PhotoGroup> groups,
    PaperOrientation orientation = PaperOrientation.landscape,
    double marginMm = 3.0,
    double spacingMm = 2.0,
    PhotoScalingMode scaling = PhotoScalingMode.fit,
    int dpi = 300,
  }) {
    final paperW = paperPreset.effectiveWidthMm(orientation);
    final paperH = paperPreset.effectiveHeightMm(orientation);

    // Filter valid groups with copies > 0
    final activeGroups = groups.where((g) => g.copiesCount > 0 && g.processedBytes != null).toList();

    if (activeGroups.isEmpty) {
      return PrintLayout(
        paperPreset: paperPreset,
        orientation: orientation,
        dpi: dpi,
        marginMm: marginMm,
        spacingMm: spacingMm,
        items: const [],
        serviceType: 'Photo Print',
        maxCapacity: 0,
      );
    }

    // Direct optimal placement for single 4R or A4 Photo Prints
    if (activeGroups.length == 1 &&
        (activeGroups.first.preset.id == 'photo_4r' || activeGroups.first.preset.id == 'photo_a4')) {
      final g = activeGroups.first;
      final targetW = math.max(10.0, paperW - (2 * marginMm));
      final targetH = math.max(10.0, paperH - (2 * marginMm));
      double itemW;
      double itemH;
      if (scaling == PhotoScalingMode.fill) {
        final scale = math.max(targetW / g.widthMm, targetH / g.heightMm);
        itemW = math.min(paperW, g.widthMm * scale);
        itemH = math.min(paperH, g.heightMm * scale);
      } else if (scaling == PhotoScalingMode.actualSize) {
        itemW = math.min(targetW, g.widthMm);
        itemH = math.min(targetH, g.heightMm);
      } else {
        // Fit
        final scale = math.min(targetW / g.widthMm, targetH / g.heightMm);
        itemW = g.widthMm * (scale > 1.0 ? 1.0 : scale);
        itemH = g.heightMm * (scale > 1.0 ? 1.0 : scale);
      }
      // Start photo on Top and Left with marginMm (never in middle)
      final posX = math.max(0.5, marginMm);
      final posY = math.max(0.5, marginMm);

      final items = <LayoutItem>[
        LayoutItem(
          id: _uuid.v4(),
          xMm: posX,
          yMm: posY,
          widthMm: itemW,
          heightMm: itemH,
          imageBytes: g.processedBytes!,
          groupId: g.id,
          label: g.name,
        ),
      ];

      return PrintLayout(
        paperPreset: paperPreset,
        orientation: orientation,
        dpi: dpi,
        marginMm: marginMm,
        spacingMm: spacingMm,
        items: items,
        serviceType: g.name,
        maxCapacity: 1,
      );
    }

    final totalRequested = activeGroups.fold<int>(0, (sum, g) => sum + g.copiesCount);

    // Try packing with different orientations, multi-shelf packing, and studio spacing tolerances
    _MultiPackingResult? bestPacking;

    for (final spacing in [spacingMm, 1.8, 1.2, 0.8]) {
      for (final margin in [marginMm, 2.0, 1.5, 1.0, 0.5]) {
        final currentAvailW = paperW - (2 * margin);
        final currentAvailH = paperH - (2 * margin);

        // Variant 1: Standard shelf packing
        final resultA = _packMultiGroups(
          availW: currentAvailW,
          availH: currentAvailH,
          groups: activeGroups,
          spacingMm: spacing,
          preferRotated: false,
        );

        // Variant 2: Rotated shelf packing
        final resultB = _packMultiGroups(
          availW: currentAvailW,
          availH: currentAvailH,
          groups: activeGroups,
          spacingMm: spacing,
          preferRotated: true,
        );

        // Variant 3: Corner / L-Shape Multi-Region Packing (e.g. 6 Passport in 3x2 grid + Stamp filling right column)
        final resultC = _packLShapedMixed(
          availW: currentAvailW,
          availH: currentAvailH,
          groups: activeGroups,
          spacingMm: spacing,
        );

        final candidates = [resultA, resultB, ?resultC];
        candidates.sort((a, b) => b.placedItems.length.compareTo(a.placedItems.length));
        final candidate = candidates.first;

        if (bestPacking == null || candidate.placedItems.length > bestPacking.placedItems.length) {
          bestPacking = candidate;
        }

        if (bestPacking.placedItems.length == totalRequested) {
          break;
        }
      }
      if (bestPacking != null && bestPacking.placedItems.length == totalRequested) {
        break;
      }
    }

    final packing = bestPacking!;

    // Start photos on Top and Left with marginMm (never in middle)
    // so remaining paper can be cleanly cut and reused for future prints
    final startX = math.max(0.5, marginMm);
    final startY = math.max(0.5, marginMm);

    final finalItems = <LayoutItem>[];
    for (final rawItem in packing.placedItems) {
      finalItems.add(
        rawItem.copyWith(
          xMm: startX + rawItem.xMm,
          yMm: startY + rawItem.yMm,
        ),
      );
    }

    String? warning;
    if (finalItems.length < totalRequested) {
      warning = 'Requested $totalRequested copies (${finalItems.length} placed) exceed ${paperPreset.name} sheet size. '
          'Please reduce copies or switch to Landscape/A4.';
    }

    return PrintLayout(
      paperPreset: paperPreset,
      orientation: orientation,
      dpi: dpi,
      marginMm: marginMm,
      spacingMm: spacingMm,
      items: finalItems,
      serviceType: activeGroups.length > 1 ? 'Passport + Stamp' : activeGroups.first.name,
      maxCapacity: finalItems.length,
      warningMessage: warning,
    );
  }

  /// Calculates maximum Stamp copies that can fill the remaining area of a 4R sheet
  static int calculateMaxStampCopies({
    required PaperPreset paperPreset,
    required PhotoGroup passportGroup,
    required PhotoGroup stampGroup,
    PaperOrientation orientation = PaperOrientation.landscape,
    double marginMm = 3.0,
    double spacingMm = 2.0,
  }) {
    int maxFit = 4;
    for (int count = 1; count <= 16; count++) {
      final testGroups = [
        passportGroup,
        stampGroup.copyWith(copiesCount: count),
      ];
      final layout = calculateMultiPhotoLayout(
        paperPreset: paperPreset,
        groups: testGroups,
        orientation: orientation,
        marginMm: marginMm,
        spacingMm: spacingMm,
      );
      if (layout.items.length >= passportGroup.copiesCount + count && layout.allItemsFit) {
        maxFit = count;
      }
    }
    return maxFit;
  }

  /// L-shaped / multi-region packing where primary group (Passport) occupies top-left,
  /// and secondary group (Stamp) fills the remaining right column and bottom row with auto-rotation.
  static _MultiPackingResult? _packLShapedMixed({
    required double availW,
    required double availH,
    required List<PhotoGroup> groups,
    required double spacingMm,
  }) {
    if (groups.length != 2) return null;

    final primary = groups[0];
    final secondary = groups[1];

    if (primary.processedBytes == null || secondary.processedBytes == null) return null;

    // Place primary group (e.g. 6 Passport in 3x2 grid)
    final primW = primary.totalItemWidthMm;
    final primH = primary.totalItemHeightMm;

    final primCols = math.max(1, ((availW + spacingMm) / (primW + spacingMm)).floor());
    final colsToUse = math.min(primCols, primary.copiesCount <= 6 ? 3 : 4);
    final primRows = ((primary.copiesCount - 1) ~/ colsToUse) + 1;

    final primTotalW = (colsToUse * primW) + ((colsToUse - 1) * spacingMm);
    final primTotalH = (primRows * primH) + ((primRows - 1) * spacingMm);

    if (primTotalW > availW + 0.5 || primTotalH > availH + 0.5) return null;

    final placedItems = <LayoutItem>[];

    // 1. Place Primary Photos
    int primPlaced = 0;
    for (int r = 0; r < primRows; r++) {
      for (int c = 0; c < colsToUse; c++) {
        if (primPlaced >= primary.copiesCount) break;
        final x = c * (primW + spacingMm);
        final y = r * (primH + spacingMm);

        placedItems.add(
          LayoutItem(
            id: _uuid.v4(),
            label: '${primary.name} ${primPlaced + 1}',
            groupId: primary.id,
            groupName: primary.name,
            imageBytes: primary.processedBytes!,
            xMm: x,
            yMm: y,
            widthMm: primW,
            heightMm: primH,
            borderConfig: primary.borderConfig,
          ),
        );
        primPlaced++;
      }
    }

    // 2. Place Secondary (Stamp) Photos in Right Column space
    final rightAvailW = availW - primTotalW - spacingMm;
    final secW = secondary.totalItemWidthMm;
    final secH = secondary.totalItemHeightMm;

    // Test upright vs rotated for right column
    bool rotateRight = false;
    double stampColW = secW;
    double stampColH = secH;

    if (rightAvailW >= secH - 1.0) {
      rotateRight = true;
      stampColW = secH;
      stampColH = secW;
    } else if (rightAvailW >= secW - 1.0) {
      stampColW = secW;
      stampColH = secH;
    }

    final stampBytesRight = secondary.processedBytes!;

    int secPlaced = 0;
    if (rightAvailW >= stampColW - 1.5) {
      final rightCols = math.max(1, ((rightAvailW + spacingMm) / (stampColW + spacingMm)).floor());
      final rightRows = math.max(1, ((availH + spacingMm + 1.0) / (stampColH + spacingMm)).floor());

      for (int c = 0; c < rightCols; c++) {
        for (int r = 0; r < rightRows; r++) {
          if (secPlaced >= secondary.copiesCount) break;
          final x = primTotalW + spacingMm + (c * (stampColW + spacingMm));
          final y = r * (stampColH + spacingMm);

          placedItems.add(
            LayoutItem(
              id: _uuid.v4(),
              label: '${secondary.name} ${secPlaced + 1}',
              groupId: secondary.id,
              groupName: secondary.name,
              imageBytes: stampBytesRight,
              xMm: x,
              yMm: y,
              widthMm: stampColW,
              heightMm: stampColH,
              rotationDegrees: rotateRight ? 90 : 0,
              borderConfig: secondary.borderConfig,
            ),
          );
          secPlaced++;
        }
      }
    }

    // 3. Place remaining Stamp Photos in Bottom Row space (under Primary)
    final bottomAvailH = availH - primTotalH - spacingMm;
    if (bottomAvailH >= secH - 1.0 && secPlaced < secondary.copiesCount) {
      final botCols = ((primTotalW + spacingMm) / (secW + spacingMm)).floor();
      final botRows = ((bottomAvailH + spacingMm) / (secH + spacingMm)).floor();

      for (int r = 0; r < botRows; r++) {
        for (int c = 0; c < botCols; c++) {
          if (secPlaced >= secondary.copiesCount) break;
          final x = c * (secW + spacingMm);
          final y = primTotalH + spacingMm + (r * (secH + spacingMm));

          placedItems.add(
            LayoutItem(
              id: _uuid.v4(),
              label: '${secondary.name} ${secPlaced + 1}',
              groupId: secondary.id,
              groupName: secondary.name,
              imageBytes: secondary.processedBytes!,
              xMm: x,
              yMm: y,
              widthMm: secW,
              heightMm: secH,
              borderConfig: secondary.borderConfig,
            ),
          );
          secPlaced++;
        }
      }
    }

    if (placedItems.isEmpty) return null;

    double maxW = 0.0;
    double maxH = 0.0;
    for (final it in placedItems) {
      maxW = math.max(maxW, it.rightMm);
      maxH = math.max(maxH, it.bottomMm);
    }

    return _MultiPackingResult(
      placedItems: placedItems,
      boundingWidth: maxW,
      boundingHeight: maxH,
      allFit: placedItems.length == (primary.copiesCount + secondary.copiesCount),
    );
  }

  static _MultiPackingResult _packMultiGroups({
    required double availW,
    required double availH,
    required List<PhotoGroup> groups,
    required double spacingMm,
    required bool preferRotated,
  }) {
    final placedItems = <LayoutItem>[];
    double currentY = 0.0;
    double maxRowWidth = 0.0;
    bool allFit = true;

    for (final group in groups) {
      final normalW = group.totalItemWidthMm;
      final normalH = group.totalItemHeightMm;

      final rotatedW = normalH;
      final rotatedH = normalW;

      final colsNormal = math.max(1, ((availW + spacingMm) / (normalW + spacingMm)).floor());
      final colsRotated = math.max(1, ((availW + spacingMm) / (rotatedW + spacingMm)).floor());

      final rowsNormal = ((group.copiesCount - 1) ~/ colsNormal) + 1;
      final hNormal = (rowsNormal * normalH) + ((rowsNormal - 1) * spacingMm);

      final rowsRotated = ((group.copiesCount - 1) ~/ colsRotated) + 1;
      final hRotated = (rowsRotated * rotatedH) + ((rowsRotated - 1) * spacingMm);

      bool useRotated = false;
      if (preferRotated) {
        if (colsRotated >= colsNormal || hRotated <= hNormal) {
          useRotated = true;
        }
      } else {
        if (currentY + hNormal > availH && currentY + hRotated <= availH) {
          useRotated = true;
        }
      }

      final itemW = useRotated ? rotatedW : normalW;
      final itemH = useRotated ? rotatedH : normalH;
      final cols = useRotated ? colsRotated : colsNormal;

      final itemBytes = group.processedBytes!;

      int remainingCopies = group.copiesCount;
      int copyIndex = 0;

      while (remainingCopies > 0) {
        final inThisRow = math.min(remainingCopies, cols);
        final rowW = (inThisRow * itemW) + ((inThisRow - 1) * spacingMm);

        if (rowW > maxRowWidth) maxRowWidth = rowW;

        if (currentY + itemH > availH + 0.5) {
          allFit = false;
          break; // Doesn't fit in available height
        }

        for (int c = 0; c < inThisRow; c++) {
          final x = c * (itemW + spacingMm);
          final y = currentY;

          placedItems.add(
            LayoutItem(
              id: _uuid.v4(),
              label: '${group.name} ${copyIndex + 1}',
              groupId: group.id,
              groupName: group.name,
              imageBytes: itemBytes,
              xMm: x,
              yMm: y,
              widthMm: itemW,
              heightMm: itemH,
              rotationDegrees: useRotated ? 90 : 0,
              borderConfig: group.borderConfig,
            ),
          );
          copyIndex++;
        }

        remainingCopies -= inThisRow;
        currentY += itemH + spacingMm;
      }
    }

    final totalHeight = currentY > 0 ? (currentY - spacingMm) : 0.0;

    return _MultiPackingResult(
      placedItems: placedItems,
      boundingWidth: maxRowWidth,
      boundingHeight: totalHeight,
      allFit: allFit && placedItems.length == groups.fold<int>(0, (s, g) => s + g.copiesCount),
    );
  }

  /// Calculates Passport / Stamp Photo layout on chosen paper sheet with auto-packing & studio spacing (single group)
  static PrintLayout calculatePhotoLayout({
    required PaperPreset paperPreset,
    required PhotoPreset photoPreset,
    required BorderConfig borderConfig,
    required Uint8List photoBytes,
    int? requestedCopies,
    PaperOrientation orientation = PaperOrientation.portrait,
    double marginMm = 3.0,
    double spacingMm = 2.0,
    int dpi = 300,
    bool allowAutoRotateItems = true,
  }) {
    final group = PhotoGroup(
      id: _uuid.v4(),
      name: photoPreset.name,
      preset: photoPreset,
      rawImageBytes: photoBytes,
      cropData: const CropRectData(),
      copiesCount: requestedCopies ?? 8,
      borderConfig: borderConfig,
      processedBytes: photoBytes,
    );

    return calculateMultiPhotoLayout(
      paperPreset: paperPreset,
      groups: [group],
      orientation: orientation,
      marginMm: marginMm,
      spacingMm: spacingMm,
      dpi: dpi,
    );
  }

  /// Calculates Aadhaar / ID Card Layout on chosen Paper (e.g. 4R, A4) with side-by-side or stacked orientation
  static PrintLayout calculateIdCardLayout({
    required PaperPreset paperPreset,
    required IDCardPreset idPreset,
    required Uint8List frontImageBytes,
    Uint8List? backImageBytes,
    PaperOrientation orientation = PaperOrientation.landscape,
    double marginMm = 3.0,
    double gapMm = 3.0,
    int dpi = 300,
    bool swapFrontBack = false,
    bool showDragonCutLines = true,
  }) {
    final paperW = paperPreset.effectiveWidthMm(orientation);
    final paperH = paperPreset.effectiveHeightMm(orientation);

    final cardW = idPreset.widthMm;
    final cardH = idPreset.heightMm;

    final hasBoth = backImageBytes != null && backImageBytes.isNotEmpty;

    final firstImage = swapFrontBack && hasBoth ? backImageBytes : frontImageBytes;
    final secondImage = swapFrontBack && hasBoth ? frontImageBytes : backImageBytes;

    final items = <LayoutItem>[];

    if (!hasBoth) {
      // Single Side centered on sheet
      final x = (paperW - cardW) / 2.0;
      final y = (paperH - cardH) / 2.0;

      items.add(
        LayoutItem(
          id: _uuid.v4(),
          label: swapFrontBack ? 'Back' : 'Front',
          imageBytes: firstImage,
          xMm: x,
          yMm: y,
          widthMm: cardW,
          heightMm: cardH,
          isFront: !swapFrontBack,
          isBack: swapFrontBack,
        ),
      );
    } else {
      // Both Sides on sheet
      final sideBySideW = (cardW * 2) + gapMm;
      final sideBySideH = cardH;

      final stackedW = cardW;
      final stackedH = (cardH * 2) + gapMm;

      if (sideBySideW <= (paperW - 2 * marginMm) && sideBySideH <= (paperH - 2 * marginMm)) {
        // Place Side by Side
        final startX = (paperW - sideBySideW) / 2.0;
        final startY = (paperH - sideBySideH) / 2.0;

        items.add(
          LayoutItem(
            id: _uuid.v4(),
            label: swapFrontBack ? 'Back' : 'Front',
            imageBytes: firstImage,
            xMm: startX,
            yMm: startY,
            widthMm: cardW,
            heightMm: cardH,
            isFront: !swapFrontBack,
            isBack: swapFrontBack,
          ),
        );

        items.add(
          LayoutItem(
            id: _uuid.v4(),
            label: swapFrontBack ? 'Front' : 'Back',
            imageBytes: secondImage!,
            xMm: startX + cardW + gapMm,
            yMm: startY,
            widthMm: cardW,
            heightMm: cardH,
            isFront: swapFrontBack,
            isBack: !swapFrontBack,
          ),
        );
      } else if (stackedW <= (paperW - 2 * marginMm) && stackedH <= (paperH - 2 * marginMm)) {
        // Place Stacked
        final startX = (paperW - stackedW) / 2.0;
        final startY = (paperH - stackedH) / 2.0;

        items.add(
          LayoutItem(
            id: _uuid.v4(),
            label: swapFrontBack ? 'Back' : 'Front',
            imageBytes: firstImage,
            xMm: startX,
            yMm: startY,
            widthMm: cardW,
            heightMm: cardH,
            isFront: !swapFrontBack,
            isBack: swapFrontBack,
          ),
        );

        items.add(
          LayoutItem(
            id: _uuid.v4(),
            label: swapFrontBack ? 'Front' : 'Back',
            imageBytes: secondImage!,
            xMm: startX,
            yMm: startY + cardH + gapMm,
            widthMm: cardW,
            heightMm: cardH,
            rotationDegrees: 180,
            isFront: swapFrontBack,
            isBack: !swapFrontBack,
          ),
        );
      } else {
        // Fallback Side by Side
        final startX = math.max(0.0, (paperW - sideBySideW) / 2.0);
        final startY = math.max(0.0, (paperH - sideBySideH) / 2.0);

        items.add(
          LayoutItem(
            id: _uuid.v4(),
            label: swapFrontBack ? 'Back' : 'Front',
            imageBytes: firstImage,
            xMm: startX,
            yMm: startY,
            widthMm: cardW,
            heightMm: cardH,
            isFront: !swapFrontBack,
            isBack: swapFrontBack,
          ),
        );

        items.add(
          LayoutItem(
            id: _uuid.v4(),
            label: swapFrontBack ? 'Front' : 'Back',
            imageBytes: secondImage!,
            xMm: startX + cardW + gapMm,
            yMm: startY,
            widthMm: cardW,
            heightMm: cardH,
            isFront: swapFrontBack,
            isBack: !swapFrontBack,
          ),
        );
      }
    }

    return PrintLayout(
      paperPreset: paperPreset,
      orientation: orientation,
      dpi: dpi,
      marginMm: marginMm,
      spacingMm: gapMm,
      items: items,
      serviceType: 'Aadhaar / ID Card',
      maxCapacity: 2,
      showDragonCutLines: showDragonCutLines,
    );
  }

  /// Calculates multi-page layout for Photo Paper / Lamination workflow
  /// Supports:
  /// - 4R paper: 1 card (front + back duplex or single) per sheet -> M sheets for M cards.
  /// - A4 paper: packs multiple card pairs starting from Top-Left, wrapping to next sheet if page is full.
  static List<PrintLayout> calculateMultiIdCardLayoutPages({
    required PaperPreset paperPreset,
    required IDCardPreset idPreset,
    required List<IdCardEntry> cards,
    PaperOrientation orientation = PaperOrientation.landscape,
    double marginMm = 3.0,
    double gapMm = 3.0,
    int dpi = 300,
    bool showDragonCutLines = true,
  }) {
    final validCards = cards.where((c) => c.frontBytes != null).toList();
    if (validCards.isEmpty) {
      return [];
    }

    final is4R = paperPreset.id == '4r' || paperPreset.id == 'four_r' || paperPreset.widthMm <= 105;
    if (is4R) {
      // 1 card per 4R sheet (1 file/person per page, then next page for next file/person)
      final layouts = <PrintLayout>[];
      for (int i = 0; i < validCards.length; i++) {
        final card = validCards[i];
        final layout = calculateIdCardLayout(
          paperPreset: paperPreset,
          idPreset: idPreset,
          frontImageBytes: card.frontBytes!,
          backImageBytes: card.hasBothSides ? card.backBytes : null,
          orientation: orientation,
          marginMm: marginMm,
          gapMm: gapMm,
          dpi: dpi,
          swapFrontBack: card.swapFrontBack,
          showDragonCutLines: showDragonCutLines,
        );
        layouts.add(layout.copyWith(
          serviceType: validCards.length > 1
              ? '${idPreset.name} (${card.name} - Sheet ${i + 1} of ${validCards.length})'
              : idPreset.name,
        ));
      }
      return layouts;
    }

    // For A4 or other larger paper:
    // Place cards starting from top-left.
    final paperW = paperPreset.effectiveWidthMm(orientation);
    final paperH = paperPreset.effectiveHeightMm(orientation);
    final cardW = idPreset.widthMm;
    final cardH = idPreset.heightMm;

    final layouts = <PrintLayout>[];
    var currentItems = <LayoutItem>[];
    int pageNum = 1;

    double curX = marginMm;
    double curY = marginMm;
    double rowMaxH = 0;

    for (int i = 0; i < validCards.length; i++) {
      final card = validCards[i];
      final hasBoth = card.hasBothSides && card.backBytes != null;
      final firstImg = card.swapFrontBack && hasBoth ? card.backBytes! : card.frontBytes!;
      final secondImg = card.swapFrontBack && hasBoth ? card.frontBytes! : card.backBytes;

      // Duplex side-by-side or single
      final entryW = hasBoth ? (cardW * 2 + gapMm) : cardW;
      final entryH = cardH;

      // Check if entry fits in current row
      if (curX + entryW > paperW - marginMm && curX > marginMm) {
        // Move to next row
        curX = marginMm;
        curY += rowMaxH + gapMm;
        rowMaxH = 0;
      }

      // Check if entry fits on current page
      if (curY + entryH > paperH - marginMm && currentItems.isNotEmpty) {
        // End current page and start a new one
        layouts.add(PrintLayout(
          paperPreset: paperPreset,
          orientation: orientation,
          dpi: dpi,
          marginMm: marginMm,
          spacingMm: gapMm,
          items: List.from(currentItems),
          serviceType: '${idPreset.name} (Sheet $pageNum)',
          maxCapacity: currentItems.length,
          showDragonCutLines: showDragonCutLines,
        ));
        pageNum++;
        currentItems = <LayoutItem>[];
        curX = marginMm;
        curY = marginMm;
        rowMaxH = 0;
      }

      // Place first side (Front or swapped Back)
      currentItems.add(LayoutItem(
        id: _uuid.v4(),
        label: '${card.name} ${card.swapFrontBack ? "Back" : "Front"}',
        imageBytes: firstImg,
        xMm: curX,
        yMm: curY,
        widthMm: cardW,
        heightMm: cardH,
        isFront: !card.swapFrontBack,
        isBack: card.swapFrontBack,
        groupId: card.id,
        groupName: card.name,
      ));

      // Place second side if duplex
      if (hasBoth && secondImg != null) {
        currentItems.add(LayoutItem(
          id: _uuid.v4(),
          label: '${card.name} ${card.swapFrontBack ? "Front" : "Back"}',
          imageBytes: secondImg,
          xMm: curX + cardW + gapMm,
          yMm: curY,
          widthMm: cardW,
          heightMm: cardH,
          isFront: card.swapFrontBack,
          isBack: !card.swapFrontBack,
          groupId: card.id,
          groupName: card.name,
        ));
      }

      curX += entryW + gapMm;
      rowMaxH = math.max(rowMaxH, entryH);
    }

    if (currentItems.isNotEmpty) {
      layouts.add(PrintLayout(
        paperPreset: paperPreset,
        orientation: orientation,
        dpi: dpi,
        marginMm: marginMm,
        spacingMm: gapMm,
        items: List.from(currentItems),
        serviceType: layouts.isNotEmpty
            ? '${idPreset.name} (Sheet $pageNum)'
            : idPreset.name,
        maxCapacity: currentItems.length,
        showDragonCutLines: showDragonCutLines,
      ));
    }

    return layouts;
  }

  /// Calculates multi-page layout for Xerox production method (Front + Back Paper Copy)
  /// - Always keeps only 1 person ID card (Front and Back) on 1 sheet.
  /// - Multiple files / persons generate multiple sheets (1 person per sheet).
  /// - Places Front and Back vertically one below another in normal 0° orientation.
  /// - Both cards have identical physical dimensions, width, height, aspect ratio, vertically aligned.
  /// - Horizontally centered and vertically centered on the paper sheet.
  /// - Preserves physical card dimensions (e.g. 85.6 x 54 mm for Aadhaar Card).
  /// - Configurable vertical gap between Front & Back (gapMm).
  /// - If "Include Back Side" is disabled (back is null or !hasBothSides), prints only Front.
  /// - No borders and no cut dot lines (plain paper output).
  static List<PrintLayout> calculateMultiXeroxLayoutPages({
    required PaperPreset paperPreset,
    required IDCardPreset idPreset,
    required List<IdCardEntry> cards,
    PaperOrientation orientation = PaperOrientation.portrait,
    double marginMm = 5.0,
    double gapMm = 6.0,
    int dpi = 300,
    bool showCutLines = false,
  }) {
    final validCards = cards.where((c) => c.frontBytes != null).toList();
    if (validCards.isEmpty) return [];

    final paperW = paperPreset.effectiveWidthMm(orientation);
    final paperH = paperPreset.effectiveHeightMm(orientation);
    final cardW = idPreset.widthMm;
    final cardH = idPreset.heightMm;

    final totalPages = validCards.length;
    final layouts = <PrintLayout>[];

    for (int p = 0; p < totalPages; p++) {
      final card = validCards[p];
      final items = <LayoutItem>[];

      final hasBoth = card.hasBothSides && card.backBytes != null;
      final firstImg = card.swapFrontBack && hasBoth ? card.backBytes! : card.frontBytes!;
      final secondImg = card.swapFrontBack && hasBoth ? card.frontBytes! : card.backBytes;

      final totalPersonH = (hasBoth && secondImg != null) ? ((cardH * 2) + gapMm) : cardH;
      final startY = math.max(marginMm, (paperH - totalPersonH) / 2.0);
      final centerX = math.max(marginMm, (paperW - cardW) / 2.0);

      // Front Card (0° normal orientation)
      items.add(
        LayoutItem(
          id: _uuid.v4(),
          label: '${card.name} ${card.swapFrontBack ? "Back" : "Front"}',
          imageBytes: firstImg,
          xMm: centerX,
          yMm: startY,
          widthMm: cardW,
          heightMm: cardH,
          rotationDegrees: 0, // Explicitly 0° (normal, upright)
          isFront: !card.swapFrontBack,
          isBack: card.swapFrontBack,
          groupId: card.id,
          groupName: card.name,
        ),
      );

      if (hasBoth && secondImg != null) {
        // Back Card placed vertically below Front, separated by gapMm (0° normal orientation, NOT 180°)
        items.add(
          LayoutItem(
            id: _uuid.v4(),
            label: '${card.name} ${card.swapFrontBack ? "Front" : "Back"}',
            imageBytes: secondImg,
            xMm: centerX,
            yMm: startY + cardH + gapMm,
            widthMm: cardW,
            heightMm: cardH,
            rotationDegrees: 0, // Explicitly 0° (normal, NOT 180°)
            isFront: card.swapFrontBack,
            isBack: !card.swapFrontBack,
            groupId: card.id,
            groupName: card.name,
          ),
        );
      }

      final pageTitle = totalPages > 1
          ? 'Xerox Copy (Sheet ${p + 1} of $totalPages)'
          : 'Xerox (Front + Back Paper Copy)';

      layouts.add(PrintLayout(
        paperPreset: paperPreset,
        orientation: orientation,
        dpi: dpi,
        marginMm: marginMm,
        spacingMm: gapMm,
        items: items,
        serviceType: pageTitle,
        maxCapacity: hasBoth ? 2 : 1,
        showDragonCutLines: false, // Xerox has NO cut lines or borders
      ));
    }

    return layouts;
  }

  /// Calculates single-sheet layout for Dragon Sheet (200 x 300 mm)
  /// - Duplex mode: places pairs (Front & Back)
  /// - Single mode: places all fronts
  static PrintLayout calculateDragonSheetLayout({
    required List<Uint8List> cardImages,
    bool isDuplex = true,
    double marginMm = 2.0,
    double spacingMm = 0.5,
    int dpi = 300,
    bool showDragonCutLines = true,
  }) {
    const sheetPreset = StandardPaperPresets.dragonSheet200x300;
    const cardW = 85.6;
    const cardH = 54.0;
    const cols = 2;
    const rows = 5;

    // Available sheet dimensions: 200 x 300 mm
    final totalCardsW = (cols * cardW) + ((cols - 1) * spacingMm);

    // Center grid horizontally, start from top with marginMm
    final startX = (sheetPreset.widthMm - totalCardsW) / 2.0;
    final startY = math.max(marginMm, 0.0);

    final items = <LayoutItem>[];
    const totalSlots = cols * rows; // 10 slots
    final count = math.min(cardImages.length, totalSlots);

    for (int i = 0; i < count; i++) {
      final r = i ~/ cols;
      final c = i % cols;
      final x = startX + (c * (cardW + spacingMm));
      final y = startY + (r * (cardH + spacingMm));

      String label;
      if (isDuplex) {
        final pairIndex = (i ~/ 2) + 1;
        final isFront = (i % 2 == 0);
        label = 'Card $pairIndex ${isFront ? 'Front' : 'Back'}';
      } else {
        label = 'Card ${i + 1}';
      }

      items.add(
        LayoutItem(
          id: _uuid.v4(),
          label: label,
          imageBytes: cardImages[i],
          xMm: x,
          yMm: y,
          widthMm: cardW,
          heightMm: cardH,
          isFront: isDuplex ? (i % 2 == 0) : true,
          isBack: isDuplex ? (i % 2 != 0) : false,
        ),
      );
    }

    return PrintLayout(
      paperPreset: sheetPreset,
      orientation: PaperOrientation.portrait,
      dpi: dpi,
      marginMm: marginMm,
      spacingMm: spacingMm,
      items: items,
      serviceType: 'Dragon Sheet PVC (200×300mm)',
      maxCapacity: totalSlots,
      showDragonCutLines: showDragonCutLines,
    );
  }

  /// Calculates multi-sheet layout for Dragon Sheet (200 x 300 mm)
  /// - Duplex mode: places up to 5 cards per sheet (Rows 0 to 4),
  ///   with Front on LEFT (Col 0) and Back on RIGHT (Col 1), starting from TOP.
  ///   Next cards follow row-by-row down. If > 5 cards, paginates to Sheet 2, Sheet 3, etc.
  /// - Single mode: places up to 10 cards per sheet across 2 columns x 5 rows.
  static List<PrintLayout> calculateMultiDragonSheetLayoutPages({
    required List<IdCardEntry> cards,
    bool isDuplex = true,
    double marginMm = 2.0,
    double spacingMm = 0.5,
    int dpi = 300,
    bool showDragonCutLines = true,
  }) {
    final validCards = cards.where((c) => c.frontBytes != null).toList();
    if (validCards.isEmpty) return [];

    const sheetPreset = StandardPaperPresets.dragonSheet200x300;
    const cardW = 85.6;
    const cardH = 54.0;
    const cols = 2;
    final totalCardsW = (cols * cardW) + ((cols - 1) * spacingMm);
    final startX = (sheetPreset.widthMm - totalCardsW) / 2.0;
    final startY = math.max(marginMm, 0.0);

    final layouts = <PrintLayout>[];

    if (isDuplex) {
      const cardsPerSheet = 5;
      final totalSheets = (validCards.length + cardsPerSheet - 1) ~/ cardsPerSheet;

      for (int s = 0; s < totalSheets; s++) {
        final sheetCards = validCards.skip(s * cardsPerSheet).take(cardsPerSheet).toList();
        final items = <LayoutItem>[];

        for (int r = 0; r < sheetCards.length; r++) {
          final card = sheetCards[r];
          final hasBoth = card.hasBothSides && card.backBytes != null;
          final frontImg = card.swapFrontBack && hasBoth ? card.backBytes! : card.frontBytes!;
          final backImg = card.swapFrontBack && hasBoth ? card.frontBytes! : (card.backBytes ?? frontImg);

          final y = startY + (r * (cardH + spacingMm));

          // Front on Left (Col 0)
          items.add(
            LayoutItem(
              id: _uuid.v4(),
              label: '${card.name} Front',
              imageBytes: frontImg,
              xMm: startX,
              yMm: y,
              widthMm: cardW,
              heightMm: cardH,
              isFront: true,
              isBack: false,
              groupId: card.id,
              groupName: card.name,
            ),
          );

          // Back on Right (Col 1)
          items.add(
            LayoutItem(
              id: _uuid.v4(),
              label: '${card.name} Back',
              imageBytes: backImg,
              xMm: startX + cardW + spacingMm,
              yMm: y,
              widthMm: cardW,
              heightMm: cardH,
              isFront: false,
              isBack: true,
              groupId: card.id,
              groupName: card.name,
            ),
          );
        }

        final title = totalSheets > 1
            ? 'Dragon Sheet PVC (Sheet ${s + 1} of $totalSheets)'
            : 'Dragon Sheet PVC (200×300mm)';

        layouts.add(PrintLayout(
          paperPreset: sheetPreset,
          orientation: PaperOrientation.portrait,
          dpi: dpi,
          marginMm: marginMm,
          spacingMm: spacingMm,
          items: items,
          serviceType: title,
          maxCapacity: 10,
          showDragonCutLines: showDragonCutLines,
        ));
      }
    } else {
      // Single side mode: 10 cards per sheet
      const cardsPerSheet = 10;
      final totalSheets = (validCards.length + cardsPerSheet - 1) ~/ cardsPerSheet;

      for (int s = 0; s < totalSheets; s++) {
        final sheetCards = validCards.skip(s * cardsPerSheet).take(cardsPerSheet).toList();
        final items = <LayoutItem>[];

        for (int i = 0; i < sheetCards.length; i++) {
          final card = sheetCards[i];
          final r = i ~/ cols;
          final c = i % cols;
          final x = startX + (c * (cardW + spacingMm));
          final y = startY + (r * (cardH + spacingMm));

          items.add(
            LayoutItem(
              id: _uuid.v4(),
              label: '${card.name} (${i + 1})',
              imageBytes: card.frontBytes!,
              xMm: x,
              yMm: y,
              widthMm: cardW,
              heightMm: cardH,
              isFront: true,
              isBack: false,
              groupId: card.id,
              groupName: card.name,
            ),
          );
        }

        final title = totalSheets > 1
            ? 'Dragon Sheet PVC Single (Sheet ${s + 1} of $totalSheets)'
            : 'Dragon Sheet PVC Single (200×300mm)';

        layouts.add(PrintLayout(
          paperPreset: sheetPreset,
          orientation: PaperOrientation.portrait,
          dpi: dpi,
          marginMm: marginMm,
          spacingMm: spacingMm,
          items: items,
          serviceType: title,
          maxCapacity: 10,
          showDragonCutLines: showDragonCutLines,
        ));
      }
    }

    return layouts;
  }

  /// Calculates multi-page layout for Epson L805 PVC Tray
  /// Batches cards into carrier tray pairs (Slot 1 and Slot 2):
  /// - For each batch of 2 cards (Card A, Card B):
  ///   - Page 2k + 1: Front of Card A (Slot 1) + Front of Card B (Slot 2)
  ///   - Page 2k + 2: Back of Card A (Slot 1) + Back of Card B (Slot 2)
  static List<PrintLayout> calculateMultiL805TrayLayoutPages({
    required List<IdCardEntry> cards,
    int cardsPerTray = 2, // 1 or 2
    L805Calibration calibration = L805Calibration.factoryDefault,
    int dpi = 300,
  }) {
    final validCards = cards.where((c) => c.frontBytes != null).toList();
    if (validCards.isEmpty) return [];

    final layouts = <PrintLayout>[];
    final step = cardsPerTray.clamp(1, 2);

    for (int i = 0; i < validCards.length; i += step) {
      final card1 = validCards[i];
      final card2 = (step == 2 && i + 1 < validCards.length) ? validCards[i + 1] : null;

      final front1 = card1.swapFrontBack ? (card1.backBytes ?? card1.frontBytes!) : card1.frontBytes!;
      final back1 = card1.swapFrontBack ? card1.frontBytes! : card1.backBytes;

      Uint8List? front2;
      Uint8List? back2;
      if (card2 != null) {
        front2 = card2.swapFrontBack ? (card2.backBytes ?? card2.frontBytes!) : card2.frontBytes!;
        back2 = card2.swapFrontBack ? card2.frontBytes! : card2.backBytes;
      }

      final batchNum = (i ~/ step) + 1;
      final totalBatches = (validCards.length + step - 1) ~/ step;

      // Page 1 of this batch: Front Side
      final frontLayout = calculateL805A4TrayLayout(
        slot1ImageBytes: front1,
        slot2ImageBytes: front2,
        isFrontPage: true,
        calibration: calibration,
        dpi: dpi,
        slot1GroupId: card1.id,
        slot2GroupId: card2?.id,
        slot1GroupName: card1.name,
        slot2GroupName: card2?.name,
      );

      final frontTitle = totalBatches > 1
          ? 'Epson L805 PVC (Batch $batchNum/$totalBatches - Front)'
          : 'Epson L805 PVC (Front Page)';

      layouts.add(frontLayout.copyWith(serviceType: frontTitle));

      // Page 2 of this batch: Back Side (if at least one card in this batch has both sides enabled, or has a back)
      final hasBack = card1.hasBothSides || (card2 != null && card2.hasBothSides) || back1 != null || back2 != null;
      if (hasBack) {
        final backLayout = calculateL805A4TrayLayout(
          slot1ImageBytes: (card1.hasBothSides && back1 != null)
              ? back1
              : (card1.hasBothSides ? (back1 ?? front1) : null),
          slot2ImageBytes: card2 != null
              ? ((card2.hasBothSides && back2 != null)
                  ? back2
                  : (card2.hasBothSides ? (back2 ?? front2) : null))
              : null,
          isFrontPage: false,
          calibration: calibration,
          dpi: dpi,
          slot1GroupId: card1.id,
          slot2GroupId: card2?.id,
          slot1GroupName: card1.name,
          slot2GroupName: card2?.name,
        );

        final backTitle = totalBatches > 1
            ? 'Epson L805 PVC (Batch $batchNum/$totalBatches - Back)'
            : 'Epson L805 PVC (Back Page)';

        layouts.add(backLayout.copyWith(serviceType: backTitle));
      }
    }

    return layouts;
  }

  /// Calculates Epson L805 A4 Carrier Tray layout for either Front page or Back page
  /// - Paper: A4 Portrait (210 x 297 mm)
  /// - slot1: Card #1 image (85.6 x 54.0 mm)
  /// - slot2: Card #2 image (optional, if 2 cards selected)
  /// - isFrontPage: true for Front page, false for Back page
  /// - calibration: L805Calibration
  static PrintLayout calculateL805A4TrayLayout({
    Uint8List? slot1ImageBytes,
    Uint8List? slot2ImageBytes,
    bool isFrontPage = true,
    L805Calibration calibration = L805Calibration.factoryDefault,
    int dpi = 300,
    String? slot1GroupId,
    String? slot2GroupId,
    String? slot1GroupName,
    String? slot2GroupName,
  }) {
    final items = <LayoutItem>[];

    if (slot1ImageBytes != null) {
      items.add(
        LayoutItem(
          id: _uuid.v4(),
          label: 'Slot 1: ${slot1GroupName ?? "Card #1"} (${isFrontPage ? "Front" : "Back"})',
          imageBytes: slot1ImageBytes,
          xMm: calibration.effectiveSlot1X,
          yMm: calibration.effectiveSlot1Y,
          widthMm: calibration.cardWidthMm,
          heightMm: calibration.cardHeightMm,
          isFront: isFrontPage,
          isBack: !isFrontPage,
          groupId: slot1GroupId,
          groupName: slot1GroupName ?? 'Card #1',
        ),
      );
    }

    if (slot2ImageBytes != null) {
      items.add(
        LayoutItem(
          id: _uuid.v4(),
          label: 'Slot 2: ${slot2GroupName ?? "Card #2"} (${isFrontPage ? "Front" : "Back"})',
          imageBytes: slot2ImageBytes,
          xMm: calibration.effectiveSlot2X,
          yMm: calibration.effectiveSlot2Y,
          widthMm: calibration.cardWidthMm,
          heightMm: calibration.cardHeightMm,
          isFront: isFrontPage,
          isBack: !isFrontPage,
          groupId: slot2GroupId,
          groupName: slot2GroupName ?? 'Card #2',
        ),
      );
    }

    return PrintLayout(
      paperPreset: StandardPaperPresets.a4,
      orientation: PaperOrientation.portrait,
      dpi: dpi,
      marginMm: 0.0,
      spacingMm: 0.0,
      items: items,
      serviceType: 'Epson L805 PVC Card (${isFrontPage ? 'Front' : 'Back'})',
      maxCapacity: 2,
    );
  }

  /// Calculates Epson L805 PVC Tray layout (legacy wrapper)
  static PrintLayout calculateL805TrayLayout({
    required Uint8List cardImageBytes,
    bool isFront = true,
    int dpi = 300,
  }) {
    return calculateL805A4TrayLayout(
      slot1ImageBytes: cardImageBytes,
      isFrontPage: isFront,
      dpi: dpi,
    );
  }
}

class _MultiPackingResult {
  final List<LayoutItem> placedItems;
  final double boundingWidth;
  final double boundingHeight;
  final bool allFit;

  _MultiPackingResult({
    required this.placedItems,
    required this.boundingWidth,
    required this.boundingHeight,
    required this.allFit,
  });
}
