import 'package:flutter/material.dart';
import '../theme/id_card_palette.dart';

class PdfPasswordDialog extends StatefulWidget {
  final IdCardPalette palette;
  final String fileName;
  final String? errorMessage;
  final bool isProcessing;
  final ValueChanged<String> onUnlock;
  final VoidCallback onCancel;

  const PdfPasswordDialog({
    super.key,
    required this.palette,
    required this.fileName,
    this.errorMessage,
    this.isProcessing = false,
    required this.onUnlock,
    required this.onCancel,
  });

  static Future<void> show({
    required BuildContext context,
    required IdCardPalette palette,
    required String fileName,
    String? errorMessage,
    bool isProcessing = false,
    required ValueChanged<String> onUnlock,
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PdfPasswordDialog(
        palette: palette,
        fileName: fileName,
        errorMessage: errorMessage,
        isProcessing: isProcessing,
        onUnlock: onUnlock,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<PdfPasswordDialog> createState() => _PdfPasswordDialogState();
}

class _PdfPasswordDialogState extends State<PdfPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text.trim();
    if (password.isNotEmpty) {
      widget.onUnlock(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Dialog(
      backgroundColor: palette.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.cardBorder),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Lock Icon
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: palette.isDark ? palette.blue.withValues(alpha: 0.18) : palette.blueLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: palette.isDark ? palette.blue.withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Icon(Icons.lock_rounded, size: 20, color: palette.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Password Required',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.fileName,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'This document is password protected (e.g. e-Aadhaar password). Enter the password below to decrypt and prepare for printing.',
              style: TextStyle(
                fontSize: 12,
                color: palette.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Password Input Field
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Enter PDF Password',
                hintStyle: TextStyle(fontSize: 12, color: palette.textMuted),
                filled: true,
                fillColor: palette.pillBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.pillBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.pillBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.blue, width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),

            // Error message banner
            if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.isDark ? palette.red.withValues(alpha: 0.15) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: palette.isDark ? palette.red.withValues(alpha: 0.35) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 14, color: palette.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.isProcessing ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    side: BorderSide(color: palette.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: widget.isProcessing ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: widget.isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Unlock PDF',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
