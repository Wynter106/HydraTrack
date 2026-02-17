import 'package:flutter/material.dart';

/// HydraTrack Color System
/// Light Mode: Fresh & Clean
/// Dark Mode: Sleek & Premium

class AppColors {
  // ===== LIGHT MODE (Fresh & Clean) =====
  static const light = _LightColors();
  
  // ===== DARK MODE (Sleek & Premium) =====
  static const dark = _DarkColors();
}

class _LightColors {
  const _LightColors();

  // Core palette
  Color get primary => const Color(0xFF0EA5E9);        // Sky blue
  Color get primaryLight => const Color(0xFF7DD3FC);   // Light sky
  Color get primaryDark => const Color(0xFF0284C7);    // Deeper blue
  
  Color get secondary => const Color(0xFF14B8A6);      // Teal
  Color get secondaryLight => const Color(0xFF5EEAD4); // Light teal
  
  Color get accent => const Color(0xFF06B6D4);         // Cyan
  
  // Backgrounds
  Color get background => const Color(0xFFF8FAFC);     // Soft white
  Color get surface => const Color(0xFFFFFFFF);        // Pure white
  Color get surfaceVariant => const Color(0xFFF1F5F9); // Light gray
  
  // Text
  Color get textPrimary => const Color(0xFF0F172A);    // Near black
  Color get textSecondary => const Color(0xFF64748B);  // Slate gray
  Color get textTertiary => const Color(0xFF94A3B8);   // Light slate
  
  // Status colors
  Color get success => const Color(0xFF22C55E);        // Green
  Color get warning => const Color(0xFFF59E0B);        // Amber
  Color get error => const Color(0xFFEF4444);          // Red
  Color get info => const Color(0xFF3B82F6);           // Blue
  
  // Goal category colors (for badges/icons)
  Color get goalStreak => const Color(0xFFF97316);     // Orange
  Color get goalTime => const Color(0xFF8B5CF6);       // Purple
  Color get goalVariety => const Color(0xFF06B6D4);    // Cyan
  Color get goalLifetime => const Color(0xFF0EA5E9);   // Sky blue
  Color get goalChallenge => const Color(0xFFEC4899);  // Pink
  Color get goalSize => const Color(0xFF10B981);       // Emerald
  
  // Hydration gradient
  List<Color> get hydrationGradient => [
    const Color(0xFF7DD3FC),
    const Color(0xFF0EA5E9),
    const Color(0xFF0284C7),
  ];
  
  // Card shadows
  Color get shadow => const Color(0xFF0F172A).withOpacity(0.08);
}

class _DarkColors {
  const _DarkColors();

  // Core palette
  Color get primary => const Color(0xFF38BDF8);        // Bright sky blue
  Color get primaryLight => const Color(0xFF7DD3FC);   // Light sky
  Color get primaryDark => const Color(0xFF0EA5E9);    // Sky blue
  
  Color get secondary => const Color(0xFF2DD4BF);      // Bright teal
  Color get secondaryLight => const Color(0xFF5EEAD4); // Light teal
  
  Color get accent => const Color(0xFF22D3EE);         // Bright cyan (glow effect)
  
  // Backgrounds
  Color get background => const Color(0xFF0F172A);     // Deep navy
  Color get surface => const Color(0xFF1E293B);        // Slate
  Color get surfaceVariant => const Color(0xFF334155); // Lighter slate
  
  // Text
  Color get textPrimary => const Color(0xFFF8FAFC);    // Near white
  Color get textSecondary => const Color(0xFF94A3B8);  // Light slate
  Color get textTertiary => const Color(0xFF64748B);   // Slate gray
  
  // Status colors (slightly brighter for dark mode)
  Color get success => const Color(0xFF4ADE80);        // Bright green
  Color get warning => const Color(0xFFFBBF24);        // Bright amber
  Color get error => const Color(0xFFF87171);          // Bright red
  Color get info => const Color(0xFF60A5FA);           // Bright blue
  
  // Goal category colors (brighter/glowing for dark mode)
  Color get goalStreak => const Color(0xFFFB923C);     // Bright orange
  Color get goalTime => const Color(0xFFA78BFA);       // Bright purple
  Color get goalVariety => const Color(0xFF22D3EE);    // Bright cyan
  Color get goalLifetime => const Color(0xFF38BDF8);   // Bright sky blue
  Color get goalChallenge => const Color(0xFFF472B6);  // Bright pink
  Color get goalSize => const Color(0xFF34D399);       // Bright emerald
  
  // Hydration gradient (glowing effect)
  List<Color> get hydrationGradient => [
    const Color(0xFF22D3EE),
    const Color(0xFF38BDF8),
    const Color(0xFF0EA5E9),
  ];
  
  // Card shadows (subtle glow in dark mode)
  Color get shadow => const Color(0xFF38BDF8).withOpacity(0.1);
}