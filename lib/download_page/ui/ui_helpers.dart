// download_page/ui/ui_helpers.dart
// ── BRUTALIST EDITORIAL DESIGN ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/logger.dart';

const _hCream   = Color(0xFFF5F0E8);
const _hInk     = Color(0xFF1A1A1A);
const _hInkSoft = Color(0xFF3A3530);
const _hInkMute = Color(0xFF888070);
const _hAccent  = Color(0xFFE8441A);
const _hPaper   = Color(0xFFEDE8DF);
const _hBorderW = 2.0;

class UIHelpers {

  static Color getLogColor(String level) {
    switch (level) {
      case 'ERROR': return _hAccent;
      case 'WARN':  return const Color(0xFFD4A017);
      case 'INFO':  return _hInk;
      case 'DEBUG': return _hInkMute;
      default:      return _hInkSoft;
    }
  }

  // ── Logs dialog ─────────────────────────────────────────────────────────────
  static void showLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _hCream,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          decoration: const BoxDecoration(
            color: _hCream,
            border: Border.fromBorderSide(BorderSide(color: _hInk, width: _hBorderW)),
            boxShadow: [BoxShadow(color: _hInk, offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar
              Container(
                width: double.infinity,
                color: _hInk,
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DEBUG LOGS', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      color: _hCream, letterSpacing: 1.5, fontFamily: 'monospace',
                    )),
                    Row(
                      children: [
                        _headerBtn(
                          icon: Icons.copy_rounded,
                          label: 'COPY',
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: Logger.getAllLogsAsString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Logs copied', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                                backgroundColor: _hInk,
                                behavior: SnackBarBehavior.floating,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _headerBtn(
                          icon: Icons.delete_outline_rounded,
                          label: 'CLEAR',
                          isAccent: true,
                          onTap: () {
                            Logger.clear();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Log list
              SizedBox(
                width: double.maxFinite,
                height: 320,
                child: Logger.logs.isEmpty
                    ? const Center(
                        child: Text('No logs.', style: TextStyle(color: _hInkMute, fontFamily: 'monospace', fontSize: 12)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: Logger.logs.length,
                        itemBuilder: (context, i) {
                          final log = Logger.logs[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log.toString(),
                              style: TextStyle(
                                fontFamily: 'monospace', fontSize: 11,
                                color: getLogColor(log.level), height: 1.4,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Footer
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _hInk, width: 1.5)),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: _hPaper,
                    child: const Center(
                      child: Text('CLOSE', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        color: _hInk, letterSpacing: 1.5, fontFamily: 'monospace',
                      )),
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

  // ── Error dialog ─────────────────────────────────────────────────────────────
  static void showErrorDialog(BuildContext context, List<String> errorMessages) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _hCream,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          decoration: const BoxDecoration(
            color: _hCream,
            border: Border.fromBorderSide(BorderSide(color: _hAccent, width: _hBorderW)),
            boxShadow: [BoxShadow(color: _hInk, offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar
              Container(
                width: double.infinity,
                color: _hAccent,
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ERROR DETAILS', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      color: _hCream, letterSpacing: 1.5, fontFamily: 'monospace',
                    )),
                    _headerBtn(
                      icon: Icons.copy_rounded,
                      label: 'COPY',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: errorMessages.join('\n')));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Errors copied', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                            backgroundColor: _hInk,
                            behavior: SnackBarBehavior.floating,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Error list
              SizedBox(
                width: double.maxFinite,
                height: 240,
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: errorMessages.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6, height: 6,
                            margin: const EdgeInsets.only(top: 5, right: 8),
                            color: _hAccent,
                          ),
                          Expanded(
                            child: Text(
                              errorMessages[i],
                              style: const TextStyle(
                                color: _hInkSoft, fontSize: 12,
                                fontFamily: 'monospace', height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Footer
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _hAccent, width: 1.5)),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: _hPaper,
                    child: const Center(
                      child: Text('CLOSE', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        color: _hInk, letterSpacing: 1.5, fontFamily: 'monospace',
                      )),
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

  static Widget _headerBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAccent ? _hAccent : _hCream.withAlpha(30),
          border: Border.all(color: _hCream.withAlpha(100), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _hCream, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w900,
              color: _hCream, letterSpacing: 1.2, fontFamily: 'monospace',
            )),
          ],
        ),
      ),
    );
  }
}
