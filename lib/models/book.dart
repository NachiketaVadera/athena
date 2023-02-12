class BookInfo {
  final String title;
  final String imgUrl;
  final String format;
  final String size;
  final String publisher;
  final String isbn;
  final String year;
  final String? downloadUrl;

  const BookInfo({
    required this.title,
    required this.imgUrl,
    required this.format,
    required this.size,
    required this.publisher,
    required this.isbn,
    required this.year,
    this.downloadUrl,
  });
}
