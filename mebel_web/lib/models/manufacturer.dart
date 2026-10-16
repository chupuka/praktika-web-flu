class Manufacturer {
  final int id;
  final String name;
  final String country;

  const Manufacturer({
    required this.id,
    required this.name,
    this.country = '',
  });
}
