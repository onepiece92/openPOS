import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/onboarding/data/country_repository.dart';
import 'package:pos_app/features/onboarding/domain/locale_country.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the region of a locale name', () {
    expect(regionFromLocaleName('en_GB'), 'GB');
    expect(regionFromLocaleName('en-GB'), 'GB');
    expect(regionFromLocaleName('en_GB.UTF-8'), 'GB');
    expect(regionFromLocaleName('zh_Hant_TW'), 'TW');
    expect(regionFromLocaleName('sr-Latn-RS@latin'), 'RS');
    expect(regionFromLocaleName('ne_np'), 'NP');
    for (final none in ['en', 'C', 'POSIX', 'es_419', '', null]) {
      expect(regionFromLocaleName(none), isNull, reason: '$none');
    }
  });

  test('a region maps through the bundled country data', () async {
    final countries = await CountryRepository.load();
    final gb = countryForRegion(countries, 'GB')!;
    expect((gb.code, gb.currency, gb.symbol), ('GB', 'GBP', '£'));
    expect(countryForRegion(countries, 'gb')!.code, 'GB');
    // No usable region: the US.
    for (final r in [null, '', '419']) {
      final c = countryForRegion(countries, r)!;
      expect((c.code, c.currency), ('US', 'USD'), reason: '$r');
    }
    expect(countryForRegion(const [], null), kFallbackCountry);
    // A region that isn't in the data: no match (the shopkeeper picks).
    expect(countryForRegion(countries, 'ZZ'), isNull);
    expect((
      kUnmatchedCountry.currency,
      kUnmatchedCountry.taxName,
      kUnmatchedCountry.timezone
    ), (
      'USD',
      'Tax',
      ''
    ));
  });
}
