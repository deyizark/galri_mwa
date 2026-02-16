class Photo {
  final int id;
  final String url;
  final int photographerId;

  Photo({
    required this.id,
    required this.url,
    required this.photographerId
  });
}

class Photographer {
  final int photographerId;
  final String photograger;

  Photographer({
    required this.photographerId,
    required this.photograger,
  });
}