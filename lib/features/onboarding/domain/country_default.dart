class CountryDefault {
  final String code;
  final String name;
  final String currency;
  final String symbol;
  final String timezone;
  final String taxName;
  final double taxRate;

  const CountryDefault({
    required this.code,
    required this.name,
    required this.currency,
    required this.symbol,
    required this.timezone,
    required this.taxName,
    required this.taxRate,
  });

  factory CountryDefault.fromJson(Map<String, dynamic> j) => CountryDefault(
        code: j['code'] as String,
        name: j['name'] as String,
        currency: j['currency'] as String,
        symbol: j['symbol'] as String,
        timezone: j['timezone'] as String,
        taxName: j['taxName'] as String,
        taxRate: (j['taxRate'] as num).toDouble(),
      );
}
