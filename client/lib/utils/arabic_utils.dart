// lib/utils/arabic_utils.dart

import 'package:flutter/material.dart';

/// Utility functions for Arabic text handling and RTL support

class ArabicUtils {
  /// Check if text contains Arabic script characters
  static bool isArabic(String text) {
    for (final char in text.runes) {
      if (_isArabicChar(char)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a character is in Arabic Unicode ranges
  static bool _isArabicChar(int char) {
    // Arabic (0600–06FF)
    if (char >= 0x0600 && char <= 0x06FF) return true;
    // Arabic Supplement (0750–077F)
    if (char >= 0x0750 && char <= 0x077F) return true;
    // Arabic Extended-A (08A0–08FF)
    if (char >= 0x08A0 && char <= 0x08FF) return true;
    // Arabic Presentation Forms-A (FB50–FDFF)
    if (char >= 0xFB50 && char <= 0xFDFF) return true;
    // Arabic Presentation Forms-B (FE70–FEFF)
    if (char >= 0xFE70 && char <= 0xFEFF) return true;
    // Arabic Mathematical Alphabetic Symbols (1EE00–1EEFF)
    if (char >= 0x1EE00 && char <= 0x1EEFF) return true;
    return false;
  }

  /// Get text direction based on content
  static TextDirection getTextDirection(String text) {
    return isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Get appropriate text alignment for text
  static TextAlign getTextAlign(String text) {
    return isArabic(text) ? TextAlign.right : TextAlign.left;
  }

  /// Wrap text with appropriate directionality
  static Widget wrapWithDirectionality({
    required Widget child,
    required String text,
  }) {
    return Directionality(textDirection: getTextDirection(text), child: child);
  }

  /// Get appropriate locale for Arabic/English
  static Locale getLocale(String text) {
    return isArabic(text) ? const Locale('ar', 'EG') : const Locale('en', 'US');
  }

  /// Format text with proper punctuation for the language
  static String formatForLanguage(String text, String language) {
    if (language == 'ar') {
      // Ensure Arabic punctuation
      return text
          .replaceAll('.', '۔')
          .replaceAll(',', '،')
          .replaceAll('?', '؟')
          .replaceAll('!', '!')
          .replaceAll(':', '؛')
          .replaceAll(';', '؛');
    }
    return text;
  }

  /// Detect language from text content
  static String detectLanguage(String text) {
    if (isArabic(text)) return 'ar';
    return 'en';
  }

  /// Get appropriate font family for language
  static String getFontFamily(String language) {
    if (language == 'ar') {
      return 'NotoNaskhArabic'; // or NotoSansArabic
    }
    return 'NotoSans';
  }

  /// Get appropriate text style for language
  static TextStyle getTextStyle({
    required String text,
    required BuildContext context,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    final isAr = isArabic(text);
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: isAr ? 'NotoNaskhArabic' : 'NotoSans',
      height: isAr ? 1.5 : 1.2, // Arabic needs more line height
    );
  }
}

/// Extension for easy RTL support on Text widgets
extension ArabicText on String {
  /// Get text direction
  TextDirection get textDirection => ArabicUtils.getTextDirection(this);

  /// Get text alignment
  TextAlign get textAlign => ArabicUtils.getTextAlign(this);

  /// Check if Arabic
  bool get isArabic => ArabicUtils.isArabic(this);

  /// Wrap with Directionality widget
  Widget wrapWithDirectionality({required Widget child}) {
    return ArabicUtils.wrapWithDirectionality(text: this, child: child);
  }

  /// Get locale
  Locale get locale => ArabicUtils.getLocale(this);
}
