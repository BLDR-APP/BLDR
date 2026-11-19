/// Banco de alimentos por país (N8). [collection] `null` = ainda não
/// populado ("Em breve").
enum FoodCountry {
  br('alimentos', '🇧🇷'),
  us('alimentos_us', '🇺🇸'),
  ca('alimentos_ca', '🇨🇦'),
  it(null, '🇮🇹');

  final String? collection;
  final String flag;
  const FoodCountry(this.collection, this.flag);

  bool get available => collection != null;

  /// País padrão pela região do dispositivo (nunca GPS). Itália ainda não
  /// tem base → Brasil.
  static FoodCountry fromRegion(String? countryCode) =>
      switch (countryCode?.toUpperCase()) {
        'US' => FoodCountry.us,
        'CA' => FoodCountry.ca,
        _ => FoodCountry.br,
      };

  static FoodCountry? byName(String? name) {
    for (final c in values) {
      if (c.name == name && c.available) return c;
    }
    return null;
  }
}
