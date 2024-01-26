class Source {
  final String name;
  final String color;
  final int iconCode;

  const Source({
    required this.name,
    required this.color,
    required this.iconCode,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'],
      color: json['color'],
      iconCode: json['icon_code'],
    );
  }
}
