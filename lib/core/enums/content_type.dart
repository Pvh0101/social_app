enum ContentType {
  post('post'),
  comment('comment'),
  story('story');

  final String value;
  const ContentType(this.value);

  factory ContentType.fromString(String value) {
    return ContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw Exception('Invalid content type: $value'),
    );
  }
}

extension ContentTypeExtension on ContentType {
  String get name => value;
}
