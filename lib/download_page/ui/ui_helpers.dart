// download_page/ui/ui_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/logger.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0A0A14);
  static const surface   = Color(0xFF12121E);
  static const surface2  = Color(0xFF1A1A2E);
  static const border    = Color(0xFF2D2D3F);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF06B6D4);
  static const red       = Color(0xFFEF4444);
  static const amber     = Color(0xFFF59E0B);
  static const green     = Color(0xFF10B981);
  static const textHi    = Color(0xFFF1F5F9);
  static const textMid   = Color(0xFF94A3B8);
  static const textLo    = Color(0xFF475569);
}
// ─────────────────────────────────────────────────────────────────────────────

class UIHelpers {
  /// Color-codes log levels for better visual distinction
  static Color getLogColor(String level) {
    switch (level) {
      case 'ERROR':
        return _C.red;
      case 'WARN':
        return _C.amber;
      case 'INFO':
        return _C.cyan;
      case 'DEBUG':
        return _C.textLo;
      default:
        return _C.textMid;
    }
  }

  /// Dark-themed debug dialog with copy/clear functionality
  static void showLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Logs',
                    style: TextStyle(
                      color: _C.textHi,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      _iconBtn(
                        Icons.copy_rounded,
                        _C.textMid,
                        () {
                          Clipboard.setData(ClipboardData(text: Logger.getAllLogsAsString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Logs copied'),
                              backgroundColor: _C.surface2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _iconBtn(
                        Icons.delete_outline_rounded,
                        _C.red.withOpacity(0.8),
                        () {
                          Logger.clear();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _C.border),
              const SizedBox(height: 8),
              // Log list
              SizedBox(
                width: double.maxFinite,
                height: 340,
                child: ListView.builder(
                  itemCount: Logger.logs.length,
                  itemBuilder: (context, index) {
                    final log = Logger.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: getLogColor(log.level),
                          height: 1.4,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: _C.border),
              const SizedBox(height: 12),
              // Close button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _C.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Center(
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: _C.textMid,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dark-themed error dialog with copy functionality
  static void showErrorDialog(BuildContext context, List<String> errorMessages) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.red.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _C.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.error_outline_rounded, color: _C.red, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Error Details',
                        style: TextStyle(
                          color: _C.textHi,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  _iconBtn(
                    Icons.copy_rounded,
                    _C.textMid,
                    () {
                      Clipboard.setData(ClipboardData(text: errorMessages.join('\n')));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Errors copied'),
                          backgroundColor: _C.surface2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _C.border),
              const SizedBox(height: 8),
              // Error list
              SizedBox(
                width: double.maxFinite,
                height: 260,
                child: ListView.builder(
                  itemCount: errorMessages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 5, color: _C.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessages[index],
                              style: const TextStyle(
                                color: _C.red,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: _C.border),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _C.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Center(
                    child: Text(
                      'Close',
                      style: TextStyle(color: _C.textMid, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
