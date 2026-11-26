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
    final gb = countryForRegion(countries, 'GB');
    expect((gb.code, gb.currency, gb.symbol), ('GB', 'GBP', '£'));
    expect(countryForRegion(countries, 'gb').code, 'GB');
    // Nothing usable, or not in the data: the US.
    for (final r in [null, '', 'ZZ', '419']) {
      final c = countryForRegion(countries, r);
      expect((c.code, c.currency), ('US', 'USD'), reason: '$r');
    }
    expect(countryForRegion(const [], 'GB'), kFallbackCountry);
  });
}
