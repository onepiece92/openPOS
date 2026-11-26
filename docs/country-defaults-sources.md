# Country defaults: sources

Backs `assets/locales/country_defaults.json` (read only by onboarding).

**Re-verify every year**, and whenever a country announces a VAT change. A rate of 0 means: not confirmed from a fetched, readable official source, contested, tiered by region or sub-national, recently changed or announced to change. The user then types their own rate. EU rates come from the EU "Your Europe" VAT table (the site's own last-checked date is 2026-07-13).

"Checked" holds 2026-11-26 only where a fetch of the source actually succeeded. "not confirmed: set to 0" means no readable official source was fetched. "not re-verified" is an original entry not checked in this pass.

Symbols: the CLDR symbol if every code point is in the bundled JetBrains Mono cmap (enforced by `test/data/country_defaults_test.dart`); otherwise the ISO code or a common Latin abbreviation. Arabic-script and Hebrew symbols are never used. The symbols of BD, GH, IN, KR, NG, PH and TH (original entries) are not in the bundled font; they are allowlisted in the test and left unchanged.

## Changes to original entries

| Code | Country | Rate | Why |
|---|---|---|---|
| BR | Brazil | 17.0 -> 0 | ICMS is a state tax; no national rate |
| CA | Canada | 13.0 -> 0 | HST is provincial (Ontario 13); national GST is 5; sub-national like US |
| GH | Ghana | 15.0 -> 0 | VAT 15 + NHIL 2.5 + GETFund 2.5 = 20 effective from 2026-01-01 (https://gra.gov.gh/?p=14078) |
| MY | Malaysia | 6.0 -> 0 | service tax 8% (6% only F&B etc.), sales tax 5/10% |
| PK | Pakistan | 17.0 -> 0 | statute says 18 (https://download1.fbr.gov.pk/Docs/202586148252375SalesTaxActupdatedupto2025-26.pdf) but not readable here and FBR HTML still says 16, so 18 not confirmed |

Notes kept at their original value: TH 7 is a temporary reduction from the statutory 10; VN 10 is statutory, with a temporary 8% on many items until 2026-12-31.

## All entries

| Code | Country | Currency | Symbol | Symbol basis | Tax name | Rate % | Checked | Source / note |
|---|---|---|---|---|---|---|---|---|
| AE | United Arab Emirates | AED | AED | ISO code (CLDR symbol missing from font, or right-to-left, or none) | VAT | 5.0 | 2026-11-26 | https://tax.gov.ae/en/taxes/vat.aspx |
| AR | Argentina | ARS | AR$ | common local abbreviation | IVA | 0.0 | not confirmed: set to 0 | https://biblioteca.arca.gob.ar/dcp/TOR_C_020631_1997_03_26 - 0: current Art. 28 text not readable on fetched pages (21% believed) |
| AT | Austria | EUR | € | CLDR | MwSt | 20.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| AU | Australia | AUD | A$ | CLDR (existing entry) | GST | 10.0 | not re-verified | not re-verified in this pass - existing entry |
| BD | Bangladesh | BDT | ৳ | CLDR (existing entry; glyph NOT in bundled font) | VAT | 15.0 | not re-verified | not re-verified in this pass - existing entry |
| BE | Belgium | EUR | € | CLDR | VAT | 21.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| BG | Bulgaria | EUR | € | CLDR | DDS | 20.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates - EUR since 2026-01-01 |
| BH | Bahrain | BHD | BHD | ISO code (CLDR symbol missing from font, or right-to-left, or none) | VAT | 0.0 | not confirmed: set to 0 | https://www.nbr.gov.bh/vat_faqs/17 - 0: NBR page returned 403 when fetched |
| BR | Brazil | BRL | R$ | CLDR (existing entry) | ICMS | 0.0 | not confirmed: set to 0 | not re-verified in this pass - CHANGED 17 -> 0: ICMS is a state tax; no national rate |
| BW | Botswana | BWP | P | common local abbreviation | VAT | 0.0 | 2026-11-26 | https://www.burs.org.bw/index.php/tax/tax-laws-2026?download=958%3Avalue-added-tax-act-2026 - 0: new VAT Act 2026, BURS pages still say 12% |
| CA | Canada | CAD | CA$ | CLDR (existing entry) | HST | 0.0 | not confirmed: set to 0 | https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses/charge-collect-which-rate/calculator.html - CHANGED 13 -> 0: HST is provincial (Ontario 13); national GST is 5; sub-national like US |
| CH | Switzerland | CHF | CHF | ISO code (CLDR symbol missing from font, or right-to-left, or none) | MWST | 8.1 | 2026-11-26 | https://www.estv.admin.ch/estv/en/home/value-added-tax/vat-rates-switzerland.html - page updated 2026-11-05 |
| CI | Côte d'Ivoire | XOF | CFA | common local abbreviation | TVA | 0.0 | not confirmed: set to 0 | (none readable) - 0: only PDFs found (18% believed); no readable official HTML page |
| CL | Chile | CLP | CL$ | common local abbreviation | IVA | 19.0 | 2026-11-26 | https://www.sii.cl/preguntas_frecuentes/impuestos_mensuales/001_130_0572.htm |
| CM | Cameroon | XAF | FCFA | common local abbreviation | TVA | 19.25 | 2026-11-26 | https://minfi.gov.cm/la-taxe-sur-la-valeur-ajoutee-tva-en-bref/ - 17.5% + 10% council surtax; official HTML, undated |
| CN | China | CNY | ¥ | CLDR (existing entry) | VAT | 13.0 | not re-verified | not re-verified in this pass - existing entry |
| CO | Colombia | COP | CO$ | common local abbreviation | IVA | 19.0 | 2026-11-26 | https://normograma.dian.gov.co/dian/compilacion/docs/oficio_dian_8857_2025.htm |
| CR | Costa Rica | CRC | CRC | ISO code (CLDR symbol missing from font, or right-to-left, or none) | IVA | 0.0 | not confirmed: set to 0 | (none fetched) - 0: official site not fetchable |
| CY | Cyprus | EUR | € | CLDR | VAT | 19.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| CZ | Czechia | CZK | Kč | CLDR | DPH | 21.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| DE | Germany | EUR | € | CLDR (existing entry) | VAT | 19.0 | not re-verified | not re-verified in this pass - existing entry |
| DK | Denmark | DKK | kr | CLDR | Moms | 25.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| DO | Dominican Republic | DOP | RD$ | common local abbreviation | ITBIS | 18.0 | 2026-11-26 | https://dgii.gov.do/cicloContribuyente/obligacionesTributarias/principalesImpuestos/Paginas/Itbis.aspx |
| DZ | Algeria | DZD | DZD | ISO code (CLDR symbol missing from font, or right-to-left, or none) | TVA | 0.0 | not confirmed: set to 0 | https://www.mfdgi.gov.dz/fr/professionnels/services-pro/regime-reel/la-taxe-sur-la-valeur-ajoutee - 0: official page not fetchable |
| EC | Ecuador | USD | $ | CLDR | IVA | 0.0 | 2026-11-26 | https://www.sri.gob.ec/en/impuesto-al-valor-agregado-iva - 0: conflicting official sources, rate set by decree |
| EE | Estonia | EUR | € | CLDR | KM | 24.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates - raised 22->24 in July 2025 |
| EG | Egypt | EGP | E£ | CLDR (existing entry) | VAT | 14.0 | not re-verified | not re-verified in this pass - existing entry |
| ES | Spain | EUR | € | CLDR | IVA | 21.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates - mainland rate; Canary Islands/Ceuta/Melilla differ |
| ET | Ethiopia | ETB | Br | CLDR (existing entry) | VAT | 15.0 | not re-verified | not re-verified in this pass - existing entry |
| FI | Finland | EUR | € | CLDR | ALV | 25.5 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| FR | France | EUR | € | CLDR (existing entry) | TVA | 20.0 | not re-verified | not re-verified in this pass - existing entry |
| GB | United Kingdom | GBP | £ | CLDR (existing entry) | VAT | 20.0 | 2026-11-26 | https://www.gov.uk/vat-rates - existing entry |
| GH | Ghana | GHS | ₵ | CLDR (existing entry; glyph NOT in bundled font) | VAT | 0.0 | not confirmed: set to 0 | https://gra.gov.gh/?p=14078 - CHANGED 15 -> 0: VAT 15 + NHIL 2.5 + GETFund 2.5 = 20 effective from 2026-01-01 (https://gra.gov.gh/?p=14078) |
| GR | Greece | EUR | € | CLDR | FPA | 24.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| GT | Guatemala | GTQ | Q | common local abbreviation | IVA | 0.0 | not confirmed: set to 0 | (none fetched) - 0: SAT site returned 403 |
| HK | Hong Kong | HKD | HK$ | common local abbreviation | Tax | 0.0 | 2026-11-26 | https://www.hkengage.gov.hk/en/essentials/basics/tax - 0: no sales tax, VAT or GST |
| HR | Croatia | EUR | € | CLDR | PDV | 25.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| HU | Hungary | HUF | Ft | CLDR | AFA | 27.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| ID | Indonesia | IDR | Rp | CLDR (existing entry) | PPN | 11.0 | 2026-11-26 | https://www.pajak.go.id/id/siaran-pers/pemerintah-terbitkan-aturan-dpp-nilai-lain-dan-besaran-tertentu-ppn - statutory 12% on 11/12 of the base = 11 effective; kept |
| IE | Ireland | EUR | € | CLDR | VAT | 23.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| IL | Israel | ILS | ILS | ISO code (CLDR symbol missing from font, or right-to-left, or none) | VAT | 0.0 | not confirmed: set to 0 | (none fetched) - 0: official gov.il source not fetchable (403) |
| IN | India | INR | ₹ | CLDR (existing entry; glyph NOT in bundled font) | GST | 18.0 | not re-verified | not re-verified in this pass - existing entry |
| IS | Iceland | ISK | kr | CLDR | VSK | 24.0 | 2026-11-26 | https://www.skatturinn.is/english/companies/value-added-tax/ |
| IT | Italy | EUR | € | CLDR | IVA | 22.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| JM | Jamaica | JMD | J$ | common local abbreviation | GCT | 15.0 | 2026-11-26 | https://jis.gov.jm/govt-projects-29-4b-from-new-revenue-measures-in-fiscal-year-2026-27/ - TAJ page inconsistent (16.5 text vs 15.0 table); JIS Feb 2026 says 15 |
| JO | Jordan | JOD | JOD | ISO code (CLDR symbol missing from font, or right-to-left, or none) | GST | 0.0 | not confirmed: set to 0 | https://www.istd.gov.jo/indexEn.aspx - 0: rate not confirmed from an official page |
| JP | Japan | JPY | ¥ | CLDR (existing entry) | Consumption Tax | 10.0 | not re-verified | not re-verified in this pass - existing entry |
| KE | Kenya | KES | KSh | CLDR (existing entry) | VAT | 16.0 | 2026-11-26 | https://www.kra.go.ke/individual/filing-paying/types-of-taxes/value-added-tax - existing entry |
| KH | Cambodia | KHR | KHR | ISO code (CLDR symbol missing from font, or right-to-left, or none) | VAT | 10.0 | 2026-11-26 | https://www.tax.gov.kh/en/faq |
| KR | South Korea | KRW | ₩ | CLDR (existing entry; glyph NOT in bundled font) | VAT | 10.0 | not re-verified | not re-verified in this pass - existing entry |
| KW | Kuwait | KWD | KWD | ISO code (CLDR symbol missing from font, or right-to-left, or none) | Tax | 0.0 | not confirmed: set to 0 | (none fetched) - 0: no VAT; no official page confirming |
| LK | Sri Lanka | LKR | Rs | common local abbreviation | VAT | 18.0 | 2026-11-26 | https://www.ird.gov.lk/en/type%20of%20taxes/sitepages/value%20added%20tax%20(vat).aspx - page updated 2025-11-19; Act No. 14 of 2026 not seen to change the general rate |
| LT | Lithuania | EUR | € | CLDR | PVM | 21.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| LU | Luxembourg | EUR | € | CLDR | TVA | 17.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| LV | Latvia | EUR | € | CLDR | PVN | 21.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| MA | Morocco | MAD | MAD | ISO code (CLDR symbol missing from font, or right-to-left, or none) | TVA | 20.0 | 2026-11-26 | https://tax.gov.ma/wps/portal/DGI/Vos-impots-procedures/Taxe-sur-la-valeur-ajoutee/!ut/p/z0/theme.html - official HTML; also CGI 2026 art. 99 |
| MM | Myanmar | MMK | MMK | ISO code (CLDR symbol missing from font, or right-to-left, or none) | Commercial Tax | 0.0 | 2026-11-26 | https://www.ird.gov.mm/tax-knowledge/faqs/commercial-tax - 0: contested; 5% general rate on page but not relied on |
| MT | Malta | EUR | € | CLDR | VAT | 18.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| MW | Malawi | MWK | MK | common local abbreviation | VAT | 0.0 | 2026-11-26 | https://www.mra.mw/admin/storage/download_files/1767182853_NEW%20TAX%20MEASURES.pdf - 0: rose to 17.5% on 2025-12-30 |
| MX | Mexico | MXN | MX$ | CLDR (existing entry) | IVA | 16.0 | not re-verified | not re-verified in this pass - existing entry |
| MY | Malaysia | MYR | RM | CLDR (existing entry) | SST | 0.0 | not confirmed: set to 0 | https://mysst.customs.gov.my/faq-services-tax/ - CHANGED 6 -> 0: service tax 8% (6% only F&B etc.), sales tax 5/10% |
| MZ | Mozambique | MZN | MT | common local abbreviation | IVA | 0.0 | not confirmed: set to 0 | (none fetched) - 0: no official page; VAT Code amended Dec 2025 |
| NA | Namibia | NAD | N$ | common local abbreviation | VAT | 15.0 | 2026-11-26 | https://www.itas.namra.org.na/taxes - official HTML, undated |
| NG | Nigeria | NGN | ₦ | CLDR (existing entry; glyph NOT in bundled font) | VAT | 7.5 | not re-verified | not re-verified in this pass - existing entry |
| NL | Netherlands | EUR | € | CLDR | BTW | 21.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| NO | Norway | NOK | kr | CLDR | MVA | 25.0 | 2026-11-26 | https://www.skatteetaten.no/en/rates/value-added-tax/ |
| NP | Nepal | NPR | Rs | CLDR (existing entry) | VAT | 13.0 | not re-verified | not re-verified in this pass - existing entry |
| NZ | New Zealand | NZD | NZ$ | CLDR (existing entry) | GST | 15.0 | 2026-11-26 | https://www.ird.govt.nz/gst - existing entry |
| OM | Oman | OMR | OMR | ISO code (CLDR symbol missing from font, or right-to-left, or none) | VAT | 5.0 | 2026-11-26 | https://tms.taxoman.gov.om/portal/tax-rate |
| PA | Panama | USD | $ | CLDR | ITBMS | 7.0 | 2026-11-26 | https://dgi.mef.gob.pa/itbms/Generalidades - USD is the circulating currency |
| PE | Peru | PEN | S/ | common local abbreviation | IGV | 18.0 | 2026-11-26 | https://orientacion.sunat.gob.pe/3053-concepto-tasa-y-operaciones-gravadas-igv-empresas - 18% combined IGV+IPM; split is changing |
| PH | Philippines | PHP | ₱ | CLDR (existing entry; glyph NOT in bundled font) | VAT | 12.0 | not re-verified | not re-verified in this pass - existing entry |
| PK | Pakistan | PKR | Rs | CLDR (existing entry) | GST | 0.0 | not confirmed: set to 0 | https://www.fbr.gov.pk/sales-tax/142263/131269 - CHANGED 17 -> 0: statute says 18 (https://download1.fbr.gov.pk/Docs/202586148252375SalesTaxActupdatedupto2025-26.pdf) but not readable here and FBR HTML still says 16, so 18 not confirmed |
| PL | Poland | PLN | zł | CLDR | VAT | 23.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| PT | Portugal | EUR | € | CLDR | IVA | 23.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates - mainland rate; Azores/Madeira differ |
| QA | Qatar | QAR | QAR | ISO code (CLDR symbol missing from font, or right-to-left, or none) | Tax | 0.0 | 2026-11-26 | https://www.gta.gov.qa/en/investors-guide - 0: no VAT applied nationally |
| RO | Romania | RON | lei | CLDR | TVA | 21.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates - raised 19->21 in Aug 2025 |
| RW | Rwanda | RWF | FRw | CLDR (existing entry) | VAT | 18.0 | not re-verified | not re-verified in this pass - existing entry |
| SA | Saudi Arabia | SAR | SR | CLDR (existing entry) | VAT | 15.0 | not re-verified | not re-verified in this pass - existing entry |
| SE | Sweden | SEK | kr | CLDR | Moms | 25.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| SG | Singapore | SGD | S$ | CLDR (existing entry) | GST | 9.0 | not re-verified | not re-verified in this pass - existing entry |
| SI | Slovenia | EUR | € | CLDR | DDV | 22.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates |
| SK | Slovakia | EUR | € | CLDR | DPH | 23.0 | 2026-11-26 | https://www.europa.eu/youreurope/business/taxation/vat/vat-rules-rates - raised 20->23 in Jan 2025 |
| SN | Senegal | XOF | CFA | common local abbreviation | TVA | 18.0 | 2026-11-26 | https://www.dgid.sn/entreprises |
| TH | Thailand | THB | ฿ | CLDR (existing entry; glyph NOT in bundled font) | VAT | 7.0 | 2026-11-26 | https://www.rd.go.th/english/6043.html - 7% is a temporary reduction from the statutory 10%; source page dated 2020, expiry not confirmed from an official source |
| TN | Tunisia | TND | TND | ISO code (CLDR symbol missing from font, or right-to-left, or none) | TVA | 0.0 | 2026-11-26 | https://www.finances.gov.tn/fr/apercu-general-sur-la-fiscalite - 0: official page says 18%, contradicting 19% elsewhere |
| TR | Türkiye | TRY | TRY | ISO code (CLDR symbol missing from font, or right-to-left, or none) | KDV | 0.0 | not confirmed: set to 0 | (none fetched) - 0: general rate believed 20% but official GIB page could not be read when fetched |
| TT | Trinidad and Tobago | TTD | TT$ | common local abbreviation | VAT | 0.0 | 2026-11-26 | https://www.ird.gov.tt/VAT - 0: VAT changes proposed in Oct 2026 budget |
| TW | Taiwan | TWD | NT$ | common local abbreviation | Business Tax | 0.0 | 2026-11-26 | https://law-out.mof.gov.tw/EngLawContent.aspx?id=20649 - 0: statute sets a 5-10% range; collected rate not stated on fetched page |
| TZ | Tanzania | TZS | TSh | CLDR (existing entry) | VAT | 18.0 | not re-verified | not re-verified in this pass - existing entry |
| UA | Ukraine | UAH | ₴ | CLDR | PDV | 0.0 | not confirmed: set to 0 | https://www.kmu.gov.ua/en/news/stiikist-zarady-rozvytku-uriad-skhvalyv-proiekt-derzhbiudzhetu-2027 - 0: 2027 draft budget proposes 20->21% |
| UG | Uganda | UGX | USh | CLDR (existing entry) | VAT | 18.0 | not re-verified | not re-verified in this pass - existing entry |
| US | United States | USD | $ | CLDR (existing entry) | Sales Tax | 0.0 | not re-verified | not re-verified in this pass - no national sales tax; state taxes vary |
| UY | Uruguay | UYU | $U | common local abbreviation | IVA | 22.0 | 2026-11-26 | https://www.gub.uy/direccion-general-impositiva/comunicacion/publicaciones/son-bienes-servicios-gravados-tasa-basica-del-22 |
| VN | Vietnam | VND | ₫ | CLDR (existing entry) | VAT | 10.0 | not re-verified | not re-verified in this pass - 10% statutory; temporary 8% on many goods/services until 2026-12-31 (Resolution 204/2025/QH15), not verified on an official page |
| ZA | South Africa | ZAR | R | CLDR (existing entry) | VAT | 15.0 | 2026-11-26 | https://www.sars.gov.za/types-of-tax/value-added-tax/ - existing entry |
| ZM | Zambia | ZMW | ZK | CLDR (existing entry) | VAT | 16.0 | not re-verified | not re-verified in this pass - existing entry |
| ZW | Zimbabwe | ZWG | ZWG | ISO code (CLDR symbol missing from font, or right-to-left, or none) | VAT | 0.0 | 2026-11-26 | https://www.zimra.co.zw/domestic-taxes/vat/mechanics-of-vat - 0: changed 15->15.5% on 2026-01-01; ZIMRA pages disagree |
