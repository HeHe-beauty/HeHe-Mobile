class PlaceItem {
  final int? hospitalId;
  final String id;
  final String name;
  final List<String> tags;
  final String description;
  final String address;
  final bool isBookmarked;
  final int? bookmarkCount;
  final double latitude;
  final double longitude;

  const PlaceItem({
    this.hospitalId,
    required this.id,
    required this.name,
    required this.tags,
    required this.description,
    required this.address,
    required this.isBookmarked,
    this.bookmarkCount = 0,
    required this.latitude,
    required this.longitude,
  });

  PlaceItem copyWith({
    int? hospitalId,
    String? id,
    String? name,
    List<String>? tags,
    String? description,
    String? address,
    bool? isBookmarked,
    int? bookmarkCount,
    double? latitude,
    double? longitude,
  }) {
    return PlaceItem(
      hospitalId: hospitalId ?? this.hospitalId,
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      address: address ?? this.address,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount ?? 0,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
