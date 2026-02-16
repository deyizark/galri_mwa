class Photographer {
  final int photographerId;
  final String photographer;
  final String photographerUrl;
  int totalPhotos;

  Photographer({
    required this.photographerId,
    required this.photographer,
    required this.photographerUrl,
    this.totalPhotos = 0,
  });

  factory Photographer.fromJson(Map<String, dynamic> json) => Photographer(
        photographerId: json['photographer_id'],
        photographer: json['photographer'],
        photographerUrl: json['photographer_url'],
      );
}

class Photo {
  final int id;
  final int photographerId;
  final String photographer;
  final String photographerUrl;
  final String url;
  final String src;

  Photo({
    required this.id,
    required this.photographerId,
    required this.photographer,
    required this.photographerUrl,
    required this.url,
    required this.src,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'],
        photographerId: json['photographer_id'],
        photographer: json['photographer'],
        photographerUrl: json['photographer_url'],
        url: json['url'],
        src: json['src']['medium'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'photographer_id': photographerId,
        'photographer': photographer,
        'photographer_url': photographerUrl,
        'url': url,
        'src': {'medium': src},
      };
}
