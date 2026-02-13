/// FavoriteDrink Model
/// 
/// Represents a user's favorite beverage with customization options.
/// Used to manage favorite drinks and Quick Add shortcuts.
class FavoriteDrink {
  final String id;
  final String userId;
  final String beverageName;
  final String? customIcon;           // nullable (optional)
  final double? customVolumeOz;       // nullable (optional)
  final int displayOrder;
  final bool isQuickAdd;              // whether this is shown in Quick Add
  final DateTime createdAt;
  final DateTime updatedAt;

  FavoriteDrink({
    required this.id,
    required this.userId,
    required this.beverageName,
    this.customIcon,
    this.customVolumeOz,
    required this.displayOrder,
    required this.isQuickAdd,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Supabase JSON to Dart object
  /// 
  /// Usage:
  /// ```dart
  /// final data = await supabase.from('favorite_drinks').select();
  /// final favorite = FavoriteDrink.fromMap(data[0]);
  /// ```
  factory FavoriteDrink.fromMap(Map<String, dynamic> map) {
    return FavoriteDrink(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      beverageName: map['beverage_name'] as String,
      customIcon: map['custom_icon'] as String?,
      customVolumeOz: (map['custom_volume_oz'] as num?)?.toDouble(),
      displayOrder: map['display_order'] as int? ?? 0,
      isQuickAdd: map['is_quick_add'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Dart object to Supabase JSON
  /// 
  /// Usage:
  /// ```dart
  /// await supabase.from('favorite_drinks').insert(favorite.toMap());
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'beverage_name': beverageName,
      'custom_icon': customIcon,
      'custom_volume_oz': customVolumeOz,
      'display_order': displayOrder,
      'is_quick_add': isQuickAdd,
    };
  }

  /// Create a copy with some fields updated
  /// 
  /// Usage:
  /// ```dart
  /// final updated = favorite.copyWith(isQuickAdd: true);
  /// ```
  FavoriteDrink copyWith({
    String? id,
    String? userId,
    String? beverageName,
    String? customIcon,
    double? customVolumeOz,
    int? displayOrder,
    bool? isQuickAdd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteDrink(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      beverageName: beverageName ?? this.beverageName,
      customIcon: customIcon ?? this.customIcon,
      customVolumeOz: customVolumeOz ?? this.customVolumeOz,
      displayOrder: displayOrder ?? this.displayOrder,
      isQuickAdd: isQuickAdd ?? this.isQuickAdd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FavoriteDrink(id: $id, beverageName: $beverageName, isQuickAdd: $isQuickAdd)';
  }
}