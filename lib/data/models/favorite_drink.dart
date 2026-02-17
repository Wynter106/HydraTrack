/// FavoriteDrink Model
/// 
/// Represents a user's favorite beverage with customization options.
/// Used to manage favorite drinks and Quick Add shortcuts.
class FavoriteDrink {
  final String id;
  final String userId;
  final String beverageName;
  final String? displayName;
  final String? customIcon;
  final double? customVolumeOz;
  final int displayOrder;
  final bool isQuickAdd;
  final DateTime createdAt;
  final DateTime updatedAt;

  FavoriteDrink({
    required this.id,
    required this.userId,
    required this.beverageName,
    this.displayName,
    this.customIcon,
    this.customVolumeOz,
    required this.displayOrder,
    required this.isQuickAdd,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get effective display name (displayName or beverageName)
  String get effectiveName => displayName ?? beverageName; 

  factory FavoriteDrink.fromMap(Map<String, dynamic> map) {
    return FavoriteDrink(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      beverageName: map['beverage_name'] as String,
      displayName: map['display_name'] as String?,
      customIcon: map['custom_icon'] as String?,
      customVolumeOz: (map['custom_volume_oz'] as num?)?.toDouble(),
      displayOrder: map['display_order'] as int? ?? 0,
      isQuickAdd: map['is_quick_add'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'beverage_name': beverageName,
      'display_name': displayName, 
      'custom_icon': customIcon,
      'custom_volume_oz': customVolumeOz,
      'display_order': displayOrder,
      'is_quick_add': isQuickAdd,
    };
  }

  FavoriteDrink copyWith({
    String? id,
    String? userId,
    String? beverageName,
    String? displayName,         
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
      displayName: displayName ?? this.displayName,  
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
    return 'FavoriteDrink(id: $id, beverageName: $beverageName, displayName: $displayName, isQuickAdd: $isQuickAdd)';
  }
}