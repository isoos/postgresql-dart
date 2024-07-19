// ignore_for_file: non_constant_identifier_names, prefer_single_quotes, prefer_final_locals

class TimeZoneSettings {
  String value = 'UTC';
  /// [value] location name
  TimeZoneSettings(this.value);
}

final _databaseMap = {
  'Africa/Abidjan': Location('Africa/Abidjan', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Accra': Location('Africa/Accra', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Addis_Ababa': Location('Africa/Addis_Ababa', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Africa/Algiers': Location('Africa/Algiers', [
    -8640000000000000
  ], [
    6
  ], [
    TimeZone(732000, isDst: false, abbreviation: 'LMT'),
    TimeZone(561000, isDst: false, abbreviation: 'PMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST')
  ]),
  'Africa/Asmara': Location('Africa/Asmara', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Africa/Bamako': Location('Africa/Bamako', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Bangui': Location('Africa/Bangui', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Banjul': Location('Africa/Banjul', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Bissau': Location('Africa/Bissau', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-3740000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Blantyre': Location('Africa/Blantyre', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Brazzaville': Location('Africa/Brazzaville', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Bujumbura': Location('Africa/Bujumbura', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Cairo': Location('Africa/Cairo', [
    -8640000000000000,
    1698354000000,
    1714082400000,
    1730408400000,
    1745532000000,
    1761858000000,
    1776981600000,
    1793307600000,
    1809036000000,
    1824757200000,
    1840485600000,
    1856206800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(7509000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST')
  ]),
  'Africa/Casablanca': Location('Africa/Casablanca', [
    -8640000000000000,
    1560045600000,
    1587261600000,
    1590890400000,
    1618106400000,
    1621130400000,
    1648346400000,
    1651975200000,
    1679191200000,
    1682215200000,
    1710036000000,
    1713060000000,
    1740276000000,
    1743904800000,
    1771120800000,
    1774144800000,
    1801965600000,
    1804989600000,
    1832205600000,
    1835834400000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(-1820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: '+01'),
    TimeZone(0, isDst: false, abbreviation: '+00'),
    TimeZone(3600000, isDst: false, abbreviation: '+01'),
    TimeZone(0, isDst: true, abbreviation: '+00')
  ]),
  'Africa/Ceuta': Location('Africa/Ceuta', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-1276000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Africa/Conakry': Location('Africa/Conakry', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Dakar': Location('Africa/Dakar', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Dar_es_Salaam': Location('Africa/Dar_es_Salaam', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Africa/Djibouti': Location('Africa/Djibouti', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Africa/Douala': Location('Africa/Douala', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/El_Aaiun': Location('Africa/El_Aaiun', [
    -8640000000000000,
    1560045600000,
    1587261600000,
    1590890400000,
    1618106400000,
    1621130400000,
    1648346400000,
    1651975200000,
    1679191200000,
    1682215200000,
    1710036000000,
    1713060000000,
    1740276000000,
    1743904800000,
    1771120800000,
    1774144800000,
    1801965600000,
    1804989600000,
    1832205600000,
    1835834400000
  ], [
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5
  ], [
    TimeZone(-3168000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(3600000, isDst: true, abbreviation: '+01'),
    TimeZone(0, isDst: false, abbreviation: '+00'),
    TimeZone(0, isDst: true, abbreviation: '+00'),
    TimeZone(3600000, isDst: false, abbreviation: '+01')
  ]),
  'Africa/Freetown': Location('Africa/Freetown', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Gaborone': Location('Africa/Gaborone', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Harare': Location('Africa/Harare', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Johannesburg': Location('Africa/Johannesburg', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(6720000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5400000, isDst: false, abbreviation: 'SAST'),
    TimeZone(10800000, isDst: true, abbreviation: 'SAST'),
    TimeZone(7200000, isDst: false, abbreviation: 'SAST')
  ]),
  'Africa/Juba': Location('Africa/Juba', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(7588000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'CAST'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Kampala': Location('Africa/Kampala', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Africa/Khartoum': Location('Africa/Khartoum', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(7808000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'CAST'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Kigali': Location('Africa/Kigali', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Kinshasa': Location('Africa/Kinshasa', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Lagos': Location('Africa/Lagos', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Libreville': Location('Africa/Libreville', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Lome': Location('Africa/Lome', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Luanda': Location('Africa/Luanda', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Lubumbashi': Location('Africa/Lubumbashi', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Lusaka': Location('Africa/Lusaka', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Malabo': Location('Africa/Malabo', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Maputo': Location('Africa/Maputo', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(7820000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'Africa/Maseru': Location('Africa/Maseru', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(6720000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5400000, isDst: false, abbreviation: 'SAST'),
    TimeZone(10800000, isDst: true, abbreviation: 'SAST'),
    TimeZone(7200000, isDst: false, abbreviation: 'SAST')
  ]),
  'Africa/Mbabane': Location('Africa/Mbabane', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(6720000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5400000, isDst: false, abbreviation: 'SAST'),
    TimeZone(10800000, isDst: true, abbreviation: 'SAST'),
    TimeZone(7200000, isDst: false, abbreviation: 'SAST')
  ]),
  'Africa/Mogadishu': Location('Africa/Mogadishu', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Africa/Monrovia': Location('Africa/Monrovia', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-2588000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-2588000, isDst: false, abbreviation: 'MMT'),
    TimeZone(-2670000, isDst: false, abbreviation: 'MMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Nairobi': Location('Africa/Nairobi', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Africa/Ndjamena': Location('Africa/Ndjamena', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(3612000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT'),
    TimeZone(7200000, isDst: true, abbreviation: 'WAST')
  ]),
  'Africa/Niamey': Location('Africa/Niamey', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Nouakchott': Location('Africa/Nouakchott', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Ouagadougou': Location('Africa/Ouagadougou', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Porto-Novo': Location('Africa/Porto-Novo', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(815000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(1800000, isDst: false, abbreviation: '+0030'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT')
  ]),
  'Africa/Sao_Tome': Location('Africa/Sao_Tome', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(1616000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-2205000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'WAT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Africa/Tripoli': Location('Africa/Tripoli', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(3164000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Africa/Tunis': Location('Africa/Tunis', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(2444000, isDst: false, abbreviation: 'LMT'),
    TimeZone(561000, isDst: false, abbreviation: 'PMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST')
  ]),
  'Africa/Windhoek': Location('Africa/Windhoek', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(4104000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5400000, isDst: false, abbreviation: '+0130'),
    TimeZone(7200000, isDst: false, abbreviation: 'SAST'),
    TimeZone(10800000, isDst: true, abbreviation: 'SAST'),
    TimeZone(3600000, isDst: true, abbreviation: 'WAT'),
    TimeZone(7200000, isDst: false, abbreviation: 'CAT')
  ]),
  'America/Adak': Location('America/Adak', [
    -8640000000000000,
    1572778800000,
    1583668800000,
    1604228400000,
    1615723200000,
    1636282800000,
    1647172800000,
    1667732400000,
    1678622400000,
    1699182000000,
    1710072000000,
    1730631600000,
    1741521600000,
    1762081200000,
    1772971200000,
    1793530800000,
    1805025600000,
    1825585200000,
    1836475200000,
    1857034800000
  ], [
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9
  ], [
    TimeZone(44002000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-42398000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-39600000, isDst: false, abbreviation: 'NST'),
    TimeZone(-36000000, isDst: true, abbreviation: 'NWT'),
    TimeZone(-36000000, isDst: true, abbreviation: 'NPT'),
    TimeZone(-39600000, isDst: false, abbreviation: 'BST'),
    TimeZone(-36000000, isDst: true, abbreviation: 'BDT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'AHST'),
    TimeZone(-32400000, isDst: true, abbreviation: 'HDT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'HST')
  ]),
  'America/Anchorage': Location('America/Anchorage', [
    -8640000000000000,
    1572775200000,
    1583665200000,
    1604224800000,
    1615719600000,
    1636279200000,
    1647169200000,
    1667728800000,
    1678618800000,
    1699178400000,
    1710068400000,
    1730628000000,
    1741518000000,
    1762077600000,
    1772967600000,
    1793527200000,
    1805022000000,
    1825581600000,
    1836471600000,
    1857031200000
  ], [
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9
  ], [
    TimeZone(50424000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-35976000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'AST'),
    TimeZone(-32400000, isDst: true, abbreviation: 'AWT'),
    TimeZone(-32400000, isDst: true, abbreviation: 'APT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'AHST'),
    TimeZone(-32400000, isDst: true, abbreviation: 'AHDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'AKDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'AKST')
  ]),
  'America/Anguilla': Location('America/Anguilla', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Antigua': Location('America/Antigua', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Araguaina': Location('America/Araguaina', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-11568000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Buenos_Aires': Location('America/Argentina/Buenos_Aires', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-14028000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Catamarca': Location('America/Argentina/Catamarca', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-15788000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Cordoba': Location('America/Argentina/Cordoba', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-15408000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Jujuy': Location('America/Argentina/Jujuy', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-15672000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/La_Rioja': Location('America/Argentina/La_Rioja', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-16044000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Mendoza': Location('America/Argentina/Mendoza', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-16516000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Rio_Gallegos': Location('America/Argentina/Rio_Gallegos', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-16612000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Salta': Location('America/Argentina/Salta', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-15700000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/San_Juan': Location('America/Argentina/San_Juan', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-16444000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/San_Luis': Location('America/Argentina/San_Luis', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-15924000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03')
  ]),
  'America/Argentina/Tucuman': Location('America/Argentina/Tucuman', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-15652000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Argentina/Ushuaia': Location('America/Argentina/Ushuaia', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-16392000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-15408000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Aruba': Location('America/Aruba', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Asuncion': Location('America/Asuncion', [
    -8640000000000000,
    1570334400000,
    1584846000000,
    1601784000000,
    1616900400000,
    1633233600000,
    1648350000000,
    1664683200000,
    1679799600000,
    1696132800000,
    1711249200000,
    1728187200000,
    1742698800000,
    1759636800000,
    1774148400000,
    1791086400000,
    1806202800000,
    1822536000000,
    1837652400000,
    1853985600000
  ], [
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4
  ], [
    TimeZone(-13840000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-13840000, isDst: false, abbreviation: 'AMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Atikokan': Location('America/Atikokan', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-19088000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-19176000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Bahia': Location('America/Bahia', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-9244000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Bahia_Banderas': Location('America/Bahia_Banderas', [
    -8640000000000000,
    1572159600000,
    1586073600000,
    1603609200000,
    1617523200000,
    1635663600000,
    1648972800000,
    1667113200000
  ], [
    6,
    2,
    6,
    2,
    6,
    2,
    6,
    2
  ], [
    TimeZone(-25260000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Barbados': Location('America/Barbados', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-14309000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-12600000, isDst: true, abbreviation: '-0330'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT')
  ]),
  'America/Belem': Location('America/Belem', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-11636000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Belize': Location('America/Belize', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-21168000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-19800000, isDst: true, abbreviation: '-0530'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT')
  ]),
  'America/Blanc-Sablon': Location('America/Blanc-Sablon', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Boa_Vista': Location('America/Boa_Vista', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-14560000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Bogota': Location('America/Bogota', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-17776000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-17776000, isDst: false, abbreviation: 'BMT'),
    TimeZone(-14400000, isDst: true, abbreviation: '-04'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05')
  ]),
  'America/Boise': Location('America/Boise', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-27889000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT')
  ]),
  'America/Cambridge_Bay': Location('America/Cambridge_Bay', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Campo_Grande': Location('America/Campo_Grande', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-13108000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Cancun': Location('America/Cancun', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-20824000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Caracas': Location('America/Caracas', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-16064000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-16060000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-16200000, isDst: false, abbreviation: '-0430'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Cayenne': Location('America/Cayenne', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-12560000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Cayman': Location('America/Cayman', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-19088000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-19176000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Chicago': Location('America/Chicago', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-21036000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Chihuahua': Location('America/Chihuahua', [
    -8640000000000000,
    1572163200000,
    1586077200000,
    1603612800000,
    1617526800000,
    1635667200000,
    1648976400000,
    1667116800000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    2
  ], [
    TimeZone(-25460000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Costa_Rica': Location('America/Costa_Rica', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-20173000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-20173000, isDst: false, abbreviation: 'SJMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Creston': Location('America/Creston', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-26898000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Cuiaba': Location('America/Cuiaba', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-13460000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Curacao': Location('America/Curacao', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Danmarkshavn': Location('America/Danmarkshavn', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-4480000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'America/Dawson': Location('America/Dawson', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604214000000
  ], [
    7,
    6,
    7,
    8
  ], [
    TimeZone(-33460000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YWT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YPT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'YDDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Dawson_Creek': Location('America/Dawson_Creek', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-28856000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Denver': Location('America/Denver', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-25196000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT')
  ]),
  'America/Detroit': Location('America/Detroit', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2
  ], [
    TimeZone(-19931000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Dominica': Location('America/Dominica', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Edmonton': Location('America/Edmonton', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-27232000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT')
  ]),
  'America/Eirunepe': Location('America/Eirunepe', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-16768000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: '-04'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05')
  ]),
  'America/El_Salvador': Location('America/El_Salvador', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-21408000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Fortaleza': Location('America/Fortaleza', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-9240000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Glace_Bay': Location('America/Glace_Bay', [
    -8640000000000000,
    1572757200000,
    1583647200000,
    1604206800000,
    1615701600000,
    1636261200000,
    1647151200000,
    1667710800000,
    1678600800000,
    1699160400000,
    1710050400000,
    1730610000000,
    1741500000000,
    1762059600000,
    1772949600000,
    1793509200000,
    1805004000000,
    1825563600000,
    1836453600000,
    1857013200000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-14388000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT')
  ]),
  'America/Godthab': Location('America/Godthab', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5
  ], [
    TimeZone(-12416000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(-3600000, isDst: true, abbreviation: '-01')
  ]),
  'America/Goose_Bay': Location('America/Goose_Bay', [
    -8640000000000000,
    1572757200000,
    1583647200000,
    1604206800000,
    1615701600000,
    1636261200000,
    1647151200000,
    1667710800000,
    1678600800000,
    1699160400000,
    1710050400000,
    1730610000000,
    1741500000000,
    1762059600000,
    1772949600000,
    1793509200000,
    1805004000000,
    1825563600000,
    1836453600000,
    1857013200000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(-14500000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-12652000, isDst: false, abbreviation: 'NST'),
    TimeZone(-9052000, isDst: true, abbreviation: 'NDT'),
    TimeZone(-12600000, isDst: false, abbreviation: 'NST'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NDT'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NPT'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NWT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-7200000, isDst: true, abbreviation: 'ADDT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT')
  ]),
  'America/Grand_Turk': Location('America/Grand_Turk', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2
  ], [
    TimeZone(-17072000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18430000, isDst: false, abbreviation: 'KMT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Grenada': Location('America/Grenada', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Guadeloupe': Location('America/Guadeloupe', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Guatemala': Location('America/Guatemala', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-21724000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Guayaquil': Location('America/Guayaquil', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-19160000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18840000, isDst: false, abbreviation: 'QMT'),
    TimeZone(-14400000, isDst: true, abbreviation: '-04'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05')
  ]),
  'America/Guyana': Location('America/Guyana', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-13959000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-13500000, isDst: false, abbreviation: '-0345'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Halifax': Location('America/Halifax', [
    -8640000000000000,
    1572757200000,
    1583647200000,
    1604206800000,
    1615701600000,
    1636261200000,
    1647151200000,
    1667710800000,
    1678600800000,
    1699160400000,
    1710050400000,
    1730610000000,
    1741500000000,
    1762059600000,
    1772949600000,
    1793509200000,
    1805004000000,
    1825563600000,
    1836453600000,
    1857013200000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-15264000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT')
  ]),
  'America/Havana': Location('America/Havana', [
    -8640000000000000,
    1572757200000,
    1583643600000,
    1604206800000,
    1615698000000,
    1636261200000,
    1647147600000,
    1667710800000,
    1678597200000,
    1699160400000,
    1710046800000,
    1730610000000,
    1741496400000,
    1762059600000,
    1772946000000,
    1793509200000,
    1805000400000,
    1825563600000,
    1836450000000,
    1857013200000
  ], [
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4
  ], [
    TimeZone(-19768000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-19776000, isDst: false, abbreviation: 'HMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'CST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'CDT')
  ]),
  'America/Hermosillo': Location('America/Hermosillo', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(-26632000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Indiana/Indianapolis': Location('America/Indiana/Indianapolis', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-20678000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Indiana/Knox': Location('America/Indiana/Knox', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-20790000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Indiana/Marengo': Location('America/Indiana/Marengo', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-20723000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Indiana/Petersburg': Location('America/Indiana/Petersburg', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-20947000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Indiana/Tell_City': Location('America/Indiana/Tell_City', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-20823000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Indiana/Vevay': Location('America/Indiana/Vevay', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-20416000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Indiana/Vincennes': Location('America/Indiana/Vincennes', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-21007000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Indiana/Winamac': Location('America/Indiana/Winamac', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-20785000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Inuvik': Location('America/Inuvik', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT')
  ]),
  'America/Iqaluit': Location('America/Iqaluit', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Jamaica': Location('America/Jamaica', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-18430000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18430000, isDst: false, abbreviation: 'KMT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Juneau': Location('America/Juneau', [
    -8640000000000000,
    1572775200000,
    1583665200000,
    1604224800000,
    1615719600000,
    1636279200000,
    1647169200000,
    1667728800000,
    1678618800000,
    1699178400000,
    1710068400000,
    1730628000000,
    1741518000000,
    1762077600000,
    1772967600000,
    1793527200000,
    1805022000000,
    1825581600000,
    1836471600000,
    1857031200000
  ], [
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9
  ], [
    TimeZone(54139000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-32261000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'AKDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'AKST')
  ]),
  'America/Kentucky/Louisville': Location('America/Kentucky/Louisville', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-20582000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT')
  ]),
  'America/Kentucky/Monticello': Location('America/Kentucky/Monticello', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-20364000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Kralendijk': Location('America/Kralendijk', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/La_Paz': Location('America/La_Paz', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-16356000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-16356000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-12756000, isDst: true, abbreviation: 'BST'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Lima': Location('America/Lima', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-18492000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18516000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: '-04'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05')
  ]),
  'America/Los_Angeles': Location('America/Los_Angeles', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604221200000,
    1615716000000,
    1636275600000,
    1647165600000,
    1667725200000,
    1678615200000,
    1699174800000,
    1710064800000,
    1730624400000,
    1741514400000,
    1762074000000,
    1772964000000,
    1793523600000,
    1805018400000,
    1825578000000,
    1836468000000,
    1857027600000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-28378000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST')
  ]),
  'America/Lower_Princes': Location('America/Lower_Princes', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Maceio': Location('America/Maceio', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-8572000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Managua': Location('America/Managua', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-20708000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-20712000, isDst: false, abbreviation: 'MMT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Manaus': Location('America/Manaus', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-14404000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Marigot': Location('America/Marigot', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Martinique': Location('America/Martinique', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-14660000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14660000, isDst: false, abbreviation: 'FFMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT')
  ]),
  'America/Matamoros': Location('America/Matamoros', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3
  ], [
    TimeZone(-23400000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Mazatlan': Location('America/Mazatlan', [
    -8640000000000000,
    1572163200000,
    1586077200000,
    1603612800000,
    1617526800000,
    1635667200000,
    1648976400000,
    1667116800000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4
  ], [
    TimeZone(-25540000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Menominee': Location('America/Menominee', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-21027000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Merida': Location('America/Merida', [
    -8640000000000000,
    1572159600000,
    1586073600000,
    1603609200000,
    1617523200000,
    1635663600000,
    1648972800000,
    1667113200000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4
  ], [
    TimeZone(-21508000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Metlakatla': Location('America/Metlakatla', [
    -8640000000000000,
    1552215600000,
    1572775200000,
    1583665200000,
    1604224800000,
    1615719600000,
    1636279200000,
    1647169200000,
    1667728800000,
    1678618800000,
    1699178400000,
    1710068400000,
    1730628000000,
    1741518000000,
    1762077600000,
    1772967600000,
    1793527200000,
    1805022000000,
    1825581600000,
    1836471600000,
    1857031200000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(54822000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-31578000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'AKST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'AKDT')
  ]),
  'America/Mexico_City': Location('America/Mexico_City', [
    -8640000000000000,
    1572159600000,
    1586073600000,
    1603609200000,
    1617523200000,
    1635663600000,
    1648972800000,
    1667113200000
  ], [
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2
  ], [
    TimeZone(-23796000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Miquelon': Location('America/Miquelon', [
    -8640000000000000,
    1572753600000,
    1583643600000,
    1604203200000,
    1615698000000,
    1636257600000,
    1647147600000,
    1667707200000,
    1678597200000,
    1699156800000,
    1710046800000,
    1730606400000,
    1741496400000,
    1762056000000,
    1772946000000,
    1793505600000,
    1805000400000,
    1825560000000,
    1836450000000,
    1857009600000
  ], [
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2
  ], [
    TimeZone(-13480000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02')
  ]),
  'America/Moncton': Location('America/Moncton', [
    -8640000000000000,
    1572757200000,
    1583647200000,
    1604206800000,
    1615701600000,
    1636261200000,
    1647151200000,
    1667710800000,
    1678600800000,
    1699160400000,
    1710050400000,
    1730610000000,
    1741500000000,
    1762059600000,
    1772949600000,
    1793509200000,
    1805004000000,
    1825563600000,
    1836453600000,
    1857013200000
  ], [
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3
  ], [
    TimeZone(-15548000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT')
  ]),
  'America/Monterrey': Location('America/Monterrey', [
    -8640000000000000,
    1572159600000,
    1586073600000,
    1603609200000,
    1617523200000,
    1635663600000,
    1648972800000,
    1667113200000
  ], [
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3
  ], [
    TimeZone(-24076000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Montevideo': Location('America/Montevideo', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-13491000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-13491000, isDst: false, abbreviation: 'MMT'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-12600000, isDst: false, abbreviation: '-0330'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-9000000, isDst: true, abbreviation: '-0230'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-5400000, isDst: true, abbreviation: '-0130'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02')
  ]),
  'America/Montreal': Location('America/Montreal', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-19052000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'America/Montserrat': Location('America/Montserrat', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Nassau': Location('America/Nassau', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-19052000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'America/New_York': Location('America/New_York', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-17762000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'America/Nipigon': Location('America/Nipigon', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-19052000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'America/Nome': Location('America/Nome', [
    -8640000000000000,
    1572775200000,
    1583665200000,
    1604224800000,
    1615719600000,
    1636279200000,
    1647169200000,
    1667728800000,
    1678618800000,
    1699178400000,
    1710068400000,
    1730628000000,
    1741518000000,
    1762077600000,
    1772967600000,
    1793527200000,
    1805022000000,
    1825581600000,
    1836471600000,
    1857031200000
  ], [
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9
  ], [
    TimeZone(46702000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-39698000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-39600000, isDst: false, abbreviation: 'NST'),
    TimeZone(-36000000, isDst: true, abbreviation: 'NWT'),
    TimeZone(-36000000, isDst: true, abbreviation: 'NPT'),
    TimeZone(-39600000, isDst: false, abbreviation: 'BST'),
    TimeZone(-36000000, isDst: true, abbreviation: 'BDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'AKDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'AKST')
  ]),
  'America/Noronha': Location('America/Noronha', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-7780000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-3600000, isDst: true, abbreviation: '-01'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02')
  ]),
  'America/North_Dakota/Beulah': Location('America/North_Dakota/Beulah', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-24427000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/North_Dakota/Center': Location('America/North_Dakota/Center', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-24312000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/North_Dakota/New_Salem': Location('America/North_Dakota/New_Salem', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-24339000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Ojinaga': Location('America/Ojinaga', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667116800000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2,
    5,
    2
  ], [
    TimeZone(-25060000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Panama': Location('America/Panama', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-19088000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-19176000, isDst: false, abbreviation: 'CMT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Pangnirtung': Location('America/Pangnirtung', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Paramaribo': Location('America/Paramaribo', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(-13240000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-13252000, isDst: false, abbreviation: 'PMT'),
    TimeZone(-13236000, isDst: false, abbreviation: 'PMT'),
    TimeZone(-12600000, isDst: false, abbreviation: '-0330'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Phoenix': Location('America/Phoenix', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-26898000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Port-au-Prince': Location('America/Port-au-Prince', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3
  ], [
    TimeZone(-17360000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-17340000, isDst: false, abbreviation: 'PPMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST')
  ]),
  'America/Port_of_Spain': Location('America/Port_of_Spain', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Porto_Velho': Location('America/Porto_Velho', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-15336000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Puerto_Rico': Location('America/Puerto_Rico', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Rainy_River': Location('America/Rainy_River', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-23316000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Rankin_Inlet': Location('America/Rankin_Inlet', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Recife': Location('America/Recife', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-8376000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Regina': Location('America/Regina', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-25116000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Resolute': Location('America/Resolute', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Rio_Branco': Location('America/Rio_Branco', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-16272000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: '-04'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05')
  ]),
  'America/Santa_Isabel': Location('America/Santa_Isabel', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604221200000,
    1615716000000,
    1636275600000,
    1647165600000,
    1667725200000,
    1678615200000,
    1699174800000,
    1710064800000,
    1730624400000,
    1741514400000,
    1762074000000,
    1772964000000,
    1793523600000,
    1805018400000,
    1825578000000,
    1836468000000,
    1857027600000
  ], [
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2
  ], [
    TimeZone(-28084000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST')
  ]),
  'America/Santarem': Location('America/Santarem', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-13128000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Santiago': Location('America/Santiago', [
    -8640000000000000,
    1567915200000,
    1586055600000,
    1599364800000,
    1617505200000,
    1630814400000,
    1648954800000,
    1662868800000,
    1680404400000,
    1693713600000,
    1712458800000,
    1725768000000,
    1743908400000,
    1757217600000,
    1775358000000,
    1788667200000,
    1806807600000,
    1820116800000,
    1838257200000,
    1851566400000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(-16965000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-16965000, isDst: false, abbreviation: 'SMT'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-14400000, isDst: true, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04')
  ]),
  'America/Santo_Domingo': Location('America/Santo_Domingo', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-16776000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-16800000, isDst: false, abbreviation: 'SDMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-16200000, isDst: true, abbreviation: '-0430'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST')
  ]),
  'America/Sao_Paulo': Location('America/Sao_Paulo', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-11188000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'America/Scoresbysund': Location('America/Scoresbysund', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(-5272000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(-3600000, isDst: true, abbreviation: '-01'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(0, isDst: true, abbreviation: '+00'),
    TimeZone(0, isDst: true, abbreviation: '+00'),
    TimeZone(-3600000, isDst: true, abbreviation: '-01'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02')
  ]),
  'America/Sitka': Location('America/Sitka', [
    -8640000000000000,
    1572775200000,
    1583665200000,
    1604224800000,
    1615719600000,
    1636279200000,
    1647169200000,
    1667728800000,
    1678618800000,
    1699178400000,
    1710068400000,
    1730628000000,
    1741518000000,
    1762077600000,
    1772967600000,
    1793527200000,
    1805022000000,
    1825581600000,
    1836471600000,
    1857031200000
  ], [
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9
  ], [
    TimeZone(53927000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-32473000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YDT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'AKDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'AKST')
  ]),
  'America/St_Barthelemy': Location('America/St_Barthelemy', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/St_Johns': Location('America/St_Johns', [
    -8640000000000000,
    1572755400000,
    1583645400000,
    1604205000000,
    1615699800000,
    1636259400000,
    1647149400000,
    1667709000000,
    1678599000000,
    1699158600000,
    1710048600000,
    1730608200000,
    1741498200000,
    1762057800000,
    1772947800000,
    1793507400000,
    1805002200000,
    1825561800000,
    1836451800000,
    1857011400000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4
  ], [
    TimeZone(-12652000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-9052000, isDst: true, abbreviation: 'NDT'),
    TimeZone(-12652000, isDst: false, abbreviation: 'NST'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NDT'),
    TimeZone(-12600000, isDst: false, abbreviation: 'NST'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NPT'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NWT'),
    TimeZone(-5400000, isDst: true, abbreviation: 'NDDT'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NDT')
  ]),
  'America/St_Kitts': Location('America/St_Kitts', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/St_Lucia': Location('America/St_Lucia', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/St_Thomas': Location('America/St_Thomas', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/St_Vincent': Location('America/St_Vincent', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Swift_Current': Location('America/Swift_Current', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-25880000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Tegucigalpa': Location('America/Tegucigalpa', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-20932000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Thule': Location('America/Thule', [
    -8640000000000000,
    1572757200000,
    1583647200000,
    1604206800000,
    1615701600000,
    1636261200000,
    1647151200000,
    1667710800000,
    1678600800000,
    1699160400000,
    1710050400000,
    1730610000000,
    1741500000000,
    1762059600000,
    1772949600000,
    1793509200000,
    1805004000000,
    1825563600000,
    1836453600000,
    1857013200000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-16508000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST')
  ]),
  'America/Thunder_Bay': Location('America/Thunder_Bay', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-19052000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'America/Tijuana': Location('America/Tijuana', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604221200000,
    1615716000000,
    1636275600000,
    1647165600000,
    1667725200000,
    1678615200000,
    1699174800000,
    1710064800000,
    1730624400000,
    1741514400000,
    1762074000000,
    1772964000000,
    1793523600000,
    1805018400000,
    1825578000000,
    1836468000000,
    1857027600000
  ], [
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2,
    4,
    2
  ], [
    TimeZone(-28084000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST')
  ]),
  'America/Toronto': Location('America/Toronto', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-19052000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'America/Tortola': Location('America/Tortola', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-15865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT')
  ]),
  'America/Vancouver': Location('America/Vancouver', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604221200000,
    1615716000000,
    1636275600000,
    1647165600000,
    1667725200000,
    1678615200000,
    1699174800000,
    1710064800000,
    1730624400000,
    1741514400000,
    1762074000000,
    1772964000000,
    1793523600000,
    1805018400000,
    1825578000000,
    1836468000000,
    1857027600000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-29548000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT')
  ]),
  'America/Whitehorse': Location('America/Whitehorse', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604214000000
  ], [
    7,
    6,
    7,
    8
  ], [
    TimeZone(-32412000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YWT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YPT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'YDDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'America/Winnipeg': Location('America/Winnipeg', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-23316000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'America/Yakutat': Location('America/Yakutat', [
    -8640000000000000,
    1572775200000,
    1583665200000,
    1604224800000,
    1615719600000,
    1636279200000,
    1647169200000,
    1667728800000,
    1678618800000,
    1699178400000,
    1710068400000,
    1730628000000,
    1741518000000,
    1762077600000,
    1772967600000,
    1793527200000,
    1805022000000,
    1825581600000,
    1836471600000,
    1857031200000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(52865000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-33535000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YWT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YPT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'YDT'),
    TimeZone(-28800000, isDst: true, abbreviation: 'AKDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'AKST')
  ]),
  'America/Yellowknife': Location('America/Yellowknife', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-27232000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT')
  ]),
  'Antarctica/Casey': Location('Antarctica/Casey', [
    -8640000000000000,
    1570129200000,
    1583596800000,
    1601740860000,
    1615640400000,
    1633190460000,
    1647090000000,
    1664640060000,
    1678291200000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Antarctica/Davis': Location('Antarctica/Davis', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Antarctica/DumontDUrville': Location('Antarctica/DumontDUrville', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(35320000, isDst: false, abbreviation: 'LMT'),
    TimeZone(35312000, isDst: false, abbreviation: 'PMMT'),
    TimeZone(36000000, isDst: false, abbreviation: '+10')
  ]),
  'Antarctica/Macquarie': Location('Antarctica/Macquarie', [
    -8640000000000000,
    1570291200000,
    1586016000000,
    1601740800000,
    1617465600000,
    1633190400000,
    1648915200000,
    1664640000000,
    1680364800000,
    1696089600000,
    1712419200000,
    1728144000000,
    1743868800000,
    1759593600000,
    1775318400000,
    1791043200000,
    1806768000000,
    1822492800000,
    1838217600000,
    1853942400000
  ], [
    3,
    5,
    3,
    5,
    3,
    5,
    3,
    5,
    3,
    5,
    3,
    5,
    3,
    5,
    3,
    5,
    3,
    5,
    3,
    5
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST')
  ]),
  'Antarctica/Mawson': Location('Antarctica/Mawson', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Antarctica/McMurdo': Location('Antarctica/McMurdo', [
    -8640000000000000,
    1569679200000,
    1586008800000,
    1601128800000,
    1617458400000,
    1632578400000,
    1648908000000,
    1664028000000,
    1680357600000,
    1695477600000,
    1712412000000,
    1727532000000,
    1743861600000,
    1758981600000,
    1775311200000,
    1790431200000,
    1806760800000,
    1821880800000,
    1838210400000,
    1853330400000
  ], [
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4
  ], [
    TimeZone(41944000, isDst: false, abbreviation: 'LMT'),
    TimeZone(45000000, isDst: true, abbreviation: 'NZST'),
    TimeZone(41400000, isDst: false, abbreviation: 'NZMT'),
    TimeZone(43200000, isDst: true, abbreviation: 'NZST'),
    TimeZone(46800000, isDst: true, abbreviation: 'NZDT'),
    TimeZone(43200000, isDst: false, abbreviation: 'NZST'),
    TimeZone(43200000, isDst: false, abbreviation: 'NZST')
  ]),
  'Antarctica/Palmer': Location('Antarctica/Palmer', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'Antarctica/Rothera': Location('Antarctica/Rothera', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03')
  ]),
  'Antarctica/Syowa': Location('Antarctica/Syowa', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(11212000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Antarctica/Troll': Location('Antarctica/Troll', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(7200000, isDst: true, abbreviation: '+02'),
    TimeZone(0, isDst: false, abbreviation: '+00'),
    TimeZone(0, isDst: false, abbreviation: '+00')
  ]),
  'Antarctica/Vostok': Location('Antarctica/Vostok', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Arctic/Longyearbyen': Location('Arctic/Longyearbyen', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(3208000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Asia/Aden': Location('Asia/Aden', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(11212000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Asia/Almaty': Location('Asia/Almaty', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(18468000, isDst: false, abbreviation: 'LMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: true, abbreviation: '+07')
  ]),
  'Asia/Amman': Location('Asia/Amman', [
    -8640000000000000,
    1571954400000,
    1585260000000,
    1604008800000,
    1616709600000,
    1635458400000,
    1645740000000,
    1666908000000
  ], [
    1,
    3,
    1,
    3,
    1,
    3,
    1,
    5
  ], [
    TimeZone(8624000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Asia/Anadyr': Location('Asia/Anadyr', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(42596000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(50400000, isDst: true, abbreviation: '+14'),
    TimeZone(46800000, isDst: false, abbreviation: '+13'),
    TimeZone(46800000, isDst: true, abbreviation: '+13'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(46800000, isDst: true, abbreviation: '+13'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Asia/Aqtau': Location('Asia/Aqtau', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(12064000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Aqtobe': Location('Asia/Aqtobe', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(13720000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Ashgabat': Location('Asia/Ashgabat', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(14012000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Baghdad': Location('Asia/Baghdad', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(10660000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10656000, isDst: false, abbreviation: 'BMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(14400000, isDst: true, abbreviation: '+04')
  ]),
  'Asia/Bahrain': Location('Asia/Bahrain', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(12368000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Asia/Baku': Location('Asia/Baku', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(11964000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Asia/Bangkok': Location('Asia/Bangkok', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(24124000, isDst: false, abbreviation: 'LMT'),
    TimeZone(24124000, isDst: false, abbreviation: 'BMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Beirut': Location('Asia/Beirut', [
    -8640000000000000,
    1572123600000,
    1585432800000,
    1603573200000,
    1616882400000,
    1635627600000,
    1648332000000,
    1667077200000,
    1679781600000,
    1698526800000,
    1711836000000,
    1729976400000,
    1743285600000,
    1761426000000,
    1774735200000,
    1792875600000,
    1806184800000,
    1824930000000,
    1837634400000,
    1856379600000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(8520000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Asia/Bishkek': Location('Asia/Bishkek', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(17904000, isDst: false, abbreviation: 'LMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06')
  ]),
  'Asia/Brunei': Location('Asia/Brunei', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(26480000, isDst: false, abbreviation: 'LMT'),
    TimeZone(27000000, isDst: false, abbreviation: '+0730'),
    TimeZone(30000000, isDst: true, abbreviation: '+0820'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Asia/Chita': Location('Asia/Chita', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(27232000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09')
  ]),
  'Asia/Choibalsan': Location('Asia/Choibalsan', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(27480000, isDst: false, abbreviation: 'LMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Asia/Colombo': Location('Asia/Colombo', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(19164000, isDst: false, abbreviation: 'LMT'),
    TimeZone(19172000, isDst: false, abbreviation: 'MMT'),
    TimeZone(19800000, isDst: false, abbreviation: '+0530'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(23400000, isDst: true, abbreviation: '+0630'),
    TimeZone(23400000, isDst: false, abbreviation: '+0630'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(19800000, isDst: false, abbreviation: '+0530')
  ]),
  'Asia/Damascus': Location('Asia/Damascus', [
    -8640000000000000,
    1571950800000,
    1585260000000,
    1604005200000,
    1616709600000,
    1635454800000,
    1648159200000,
    1666904400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    3
  ], [
    TimeZone(8712000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Asia/Dhaka': Location('Asia/Dhaka', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(21700000, isDst: false, abbreviation: 'LMT'),
    TimeZone(21200000, isDst: false, abbreviation: 'HMT'),
    TimeZone(23400000, isDst: false, abbreviation: '+0630'),
    TimeZone(19800000, isDst: false, abbreviation: '+0530'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: true, abbreviation: '+07')
  ]),
  'Asia/Dili': Location('Asia/Dili', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(30140000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: false, abbreviation: '+09')
  ]),
  'Asia/Dubai': Location('Asia/Dubai', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(13272000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Asia/Dushanbe': Location('Asia/Dushanbe', [
    -8640000000000000
  ], [
    7
  ], [
    TimeZone(16512000, isDst: false, abbreviation: 'LMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Gaza': Location('Asia/Gaza', [
    -8640000000000000,
    1572037200000,
    1585346400000,
    1603490400000,
    1616796000000,
    1635458400000,
    1648332000000,
    1666998000000,
    1682726400000,
    1698447600000,
    1713571200000,
    1729897200000,
    1744416000000,
    1761346800000,
    1774656000000,
    1792796400000,
    1806105600000,
    1824850800000,
    1837555200000,
    1856300400000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(8272000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(10800000, isDst: true, abbreviation: 'IDT'),
    TimeZone(7200000, isDst: false, abbreviation: 'IST'),
    TimeZone(10800000, isDst: true, abbreviation: 'IDT'),
    TimeZone(7200000, isDst: false, abbreviation: 'IST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Asia/Hebron': Location('Asia/Hebron', [
    -8640000000000000,
    1572037200000,
    1585346400000,
    1603490400000,
    1616796000000,
    1635458400000,
    1648332000000,
    1666998000000,
    1682726400000,
    1698447600000,
    1713571200000,
    1729897200000,
    1744416000000,
    1761346800000,
    1774656000000,
    1792796400000,
    1806105600000,
    1824850800000,
    1837555200000,
    1856300400000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(8423000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(10800000, isDst: true, abbreviation: 'IDT'),
    TimeZone(7200000, isDst: false, abbreviation: 'IST'),
    TimeZone(10800000, isDst: true, abbreviation: 'IDT'),
    TimeZone(7200000, isDst: false, abbreviation: 'IST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Asia/Ho_Chi_Minh': Location('Asia/Ho_Chi_Minh', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(25590000, isDst: false, abbreviation: 'LMT'),
    TimeZone(25590000, isDst: false, abbreviation: 'PLMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Hong_Kong': Location('Asia/Hong_Kong', [
    -8640000000000000
  ], [
    7
  ], [
    TimeZone(27402000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: 'HKT'),
    TimeZone(32400000, isDst: true, abbreviation: 'HKST'),
    TimeZone(30600000, isDst: true, abbreviation: 'HKWT'),
    TimeZone(32400000, isDst: false, abbreviation: 'JST'),
    TimeZone(28800000, isDst: false, abbreviation: 'HKT'),
    TimeZone(32400000, isDst: true, abbreviation: 'HKST'),
    TimeZone(28800000, isDst: false, abbreviation: 'HKT')
  ]),
  'Asia/Hovd': Location('Asia/Hovd', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(21996000, isDst: false, abbreviation: 'LMT'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Irkutsk': Location('Asia/Irkutsk', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(25025000, isDst: false, abbreviation: 'LMT'),
    TimeZone(25025000, isDst: false, abbreviation: 'IMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Asia/Jakarta': Location('Asia/Jakarta', [
    -8640000000000000
  ], [
    6
  ], [
    TimeZone(25632000, isDst: false, abbreviation: 'LMT'),
    TimeZone(25632000, isDst: false, abbreviation: 'BMT'),
    TimeZone(26400000, isDst: false, abbreviation: '+0720'),
    TimeZone(27000000, isDst: false, abbreviation: '+0730'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(25200000, isDst: false, abbreviation: 'WIB')
  ]),
  'Asia/Jayapura': Location('Asia/Jayapura', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(33768000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(34200000, isDst: false, abbreviation: '+0930'),
    TimeZone(32400000, isDst: false, abbreviation: 'WIT')
  ]),
  'Asia/Jerusalem': Location('Asia/Jerusalem', [
    -8640000000000000,
    1572130800000,
    1585267200000,
    1603580400000,
    1616716800000,
    1635634800000,
    1648166400000,
    1667084400000,
    1679616000000,
    1698534000000,
    1711670400000,
    1729983600000,
    1743120000000,
    1761433200000,
    1774569600000,
    1792882800000,
    1806019200000,
    1824937200000,
    1837468800000,
    1856386800000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(8454000, isDst: false, abbreviation: 'LMT'),
    TimeZone(8440000, isDst: false, abbreviation: 'JMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'IDT'),
    TimeZone(7200000, isDst: false, abbreviation: 'IST'),
    TimeZone(14400000, isDst: true, abbreviation: 'IDDT'),
    TimeZone(10800000, isDst: true, abbreviation: 'IDT'),
    TimeZone(7200000, isDst: false, abbreviation: 'IST'),
    TimeZone(10800000, isDst: true, abbreviation: 'IDT'),
    TimeZone(7200000, isDst: false, abbreviation: 'IST')
  ]),
  'Asia/Kabul': Location('Asia/Kabul', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(16608000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(16200000, isDst: false, abbreviation: '+0430')
  ]),
  'Asia/Kamchatka': Location('Asia/Kamchatka', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(38076000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(46800000, isDst: true, abbreviation: '+13'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(46800000, isDst: true, abbreviation: '+13'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Asia/Karachi': Location('Asia/Karachi', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(16092000, isDst: false, abbreviation: 'LMT'),
    TimeZone(19800000, isDst: false, abbreviation: '+0530'),
    TimeZone(23400000, isDst: true, abbreviation: '+0630'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: 'PKST'),
    TimeZone(18000000, isDst: false, abbreviation: 'PKT')
  ]),
  'Asia/Kathmandu': Location('Asia/Kathmandu', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(20476000, isDst: false, abbreviation: 'LMT'),
    TimeZone(19800000, isDst: false, abbreviation: '+0530'),
    TimeZone(20700000, isDst: false, abbreviation: '+0545')
  ]),
  'Asia/Khandyga': Location('Asia/Khandyga', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(32533000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(32400000, isDst: false, abbreviation: '+09')
  ]),
  'Asia/Kolkata': Location('Asia/Kolkata', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(21208000, isDst: false, abbreviation: 'LMT'),
    TimeZone(21200000, isDst: false, abbreviation: 'HMT'),
    TimeZone(19270000, isDst: false, abbreviation: 'MMT'),
    TimeZone(19800000, isDst: false, abbreviation: 'IST'),
    TimeZone(23400000, isDst: true, abbreviation: '+0630')
  ]),
  'Asia/Krasnoyarsk': Location('Asia/Krasnoyarsk', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(22286000, isDst: false, abbreviation: 'LMT'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Kuala_Lumpur': Location('Asia/Kuala_Lumpur', [
    -8640000000000000
  ], [
    7
  ], [
    TimeZone(24925000, isDst: false, abbreviation: 'LMT'),
    TimeZone(24925000, isDst: false, abbreviation: 'SMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(26400000, isDst: true, abbreviation: '+0720'),
    TimeZone(26400000, isDst: false, abbreviation: '+0720'),
    TimeZone(27000000, isDst: false, abbreviation: '+0730'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Asia/Kuching': Location('Asia/Kuching', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(26480000, isDst: false, abbreviation: 'LMT'),
    TimeZone(27000000, isDst: false, abbreviation: '+0730'),
    TimeZone(30000000, isDst: true, abbreviation: '+0820'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Asia/Kuwait': Location('Asia/Kuwait', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(11212000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Asia/Macau': Location('Asia/Macau', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(27250000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: 'CST'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(32400000, isDst: true, abbreviation: 'CDT'),
    TimeZone(28800000, isDst: false, abbreviation: 'CST'),
    TimeZone(32400000, isDst: true, abbreviation: 'CDT')
  ]),
  'Asia/Magadan': Location('Asia/Magadan', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(36192000, isDst: false, abbreviation: 'LMT'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Asia/Makassar': Location('Asia/Makassar', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(28656000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28656000, isDst: false, abbreviation: 'MMT'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: 'WITA')
  ]),
  'Asia/Manila': Location('Asia/Manila', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-57360000, isDst: false, abbreviation: 'LMT'),
    TimeZone(29040000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: true, abbreviation: 'PDT'),
    TimeZone(28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(32400000, isDst: false, abbreviation: 'JST'),
    TimeZone(28800000, isDst: false, abbreviation: 'PST')
  ]),
  'Asia/Muscat': Location('Asia/Muscat', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(13272000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Asia/Nicosia': Location('Asia/Nicosia', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(8008000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST')
  ]),
  'Asia/Novokuznetsk': Location('Asia/Novokuznetsk', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(20928000, isDst: false, abbreviation: 'LMT'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Novosibirsk': Location('Asia/Novosibirsk', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(19900000, isDst: false, abbreviation: 'LMT'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(28800000, isDst: true, abbreviation: '+08'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Omsk': Location('Asia/Omsk', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(17610000, isDst: false, abbreviation: 'LMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06')
  ]),
  'Asia/Oral': Location('Asia/Oral', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(12324000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Phnom_Penh': Location('Asia/Phnom_Penh', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(24124000, isDst: false, abbreviation: 'LMT'),
    TimeZone(24124000, isDst: false, abbreviation: 'BMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Pontianak': Location('Asia/Pontianak', [
    -8640000000000000
  ], [
    6
  ], [
    TimeZone(26240000, isDst: false, abbreviation: 'LMT'),
    TimeZone(26240000, isDst: false, abbreviation: 'PMT'),
    TimeZone(27000000, isDst: false, abbreviation: '+0730'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(28800000, isDst: false, abbreviation: 'WITA'),
    TimeZone(25200000, isDst: false, abbreviation: 'WIB')
  ]),
  'Asia/Pyongyang': Location('Asia/Pyongyang', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(30180000, isDst: false, abbreviation: 'LMT'),
    TimeZone(30600000, isDst: false, abbreviation: 'KST'),
    TimeZone(32400000, isDst: false, abbreviation: 'JST'),
    TimeZone(32400000, isDst: false, abbreviation: 'KST')
  ]),
  'Asia/Qatar': Location('Asia/Qatar', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(12368000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Asia/Qyzylorda': Location('Asia/Qyzylorda', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(15712000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Rangoon': Location('Asia/Rangoon', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(23087000, isDst: false, abbreviation: 'LMT'),
    TimeZone(23087000, isDst: false, abbreviation: 'RMT'),
    TimeZone(23400000, isDst: false, abbreviation: '+0630'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(23400000, isDst: false, abbreviation: '+0630')
  ]),
  'Asia/Riyadh': Location('Asia/Riyadh', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(11212000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Asia/Sakhalin': Location('Asia/Sakhalin', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(34248000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Asia/Samarkand': Location('Asia/Samarkand', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(16073000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06')
  ]),
  'Asia/Seoul': Location('Asia/Seoul', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(30472000, isDst: false, abbreviation: 'LMT'),
    TimeZone(30600000, isDst: false, abbreviation: 'KST'),
    TimeZone(32400000, isDst: false, abbreviation: 'JST'),
    TimeZone(36000000, isDst: true, abbreviation: 'KDT'),
    TimeZone(32400000, isDst: false, abbreviation: 'KST'),
    TimeZone(34200000, isDst: true, abbreviation: 'KDT'),
    TimeZone(36000000, isDst: true, abbreviation: 'KDT')
  ]),
  'Asia/Shanghai': Location('Asia/Shanghai', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(29143000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: true, abbreviation: 'CDT'),
    TimeZone(28800000, isDst: false, abbreviation: 'CST')
  ]),
  'Asia/Singapore': Location('Asia/Singapore', [
    -8640000000000000
  ], [
    7
  ], [
    TimeZone(24925000, isDst: false, abbreviation: 'LMT'),
    TimeZone(24925000, isDst: false, abbreviation: 'SMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(26400000, isDst: true, abbreviation: '+0720'),
    TimeZone(26400000, isDst: false, abbreviation: '+0720'),
    TimeZone(27000000, isDst: false, abbreviation: '+0730'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Asia/Srednekolymsk': Location('Asia/Srednekolymsk', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(36892000, isDst: false, abbreviation: 'LMT'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Asia/Taipei': Location('Asia/Taipei', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(29160000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: 'CST'),
    TimeZone(32400000, isDst: false, abbreviation: 'JST'),
    TimeZone(32400000, isDst: true, abbreviation: 'CDT'),
    TimeZone(28800000, isDst: false, abbreviation: 'CST')
  ]),
  'Asia/Tashkent': Location('Asia/Tashkent', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(16631000, isDst: false, abbreviation: 'LMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(25200000, isDst: true, abbreviation: '+07'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Tbilisi': Location('Asia/Tbilisi', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(10751000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10751000, isDst: false, abbreviation: 'TBMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Asia/Tehran': Location('Asia/Tehran', [
    -8640000000000000,
    1569094200000,
    1584736200000,
    1600630200000,
    1616358600000,
    1632252600000,
    1647894600000,
    1663788600000
  ], [
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3
  ], [
    TimeZone(12344000, isDst: false, abbreviation: 'LMT'),
    TimeZone(12344000, isDst: false, abbreviation: 'TMT'),
    TimeZone(16200000, isDst: true, abbreviation: '+0430'),
    TimeZone(12600000, isDst: false, abbreviation: '+0330'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(16200000, isDst: true, abbreviation: '+0430'),
    TimeZone(12600000, isDst: false, abbreviation: '+0330')
  ]),
  'Asia/Thimphu': Location('Asia/Thimphu', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(21516000, isDst: false, abbreviation: 'LMT'),
    TimeZone(19800000, isDst: false, abbreviation: '+0530'),
    TimeZone(21600000, isDst: false, abbreviation: '+06')
  ]),
  'Asia/Tokyo': Location('Asia/Tokyo', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(33539000, isDst: false, abbreviation: 'LMT'),
    TimeZone(36000000, isDst: true, abbreviation: 'JDT'),
    TimeZone(32400000, isDst: false, abbreviation: 'JST'),
    TimeZone(32400000, isDst: false, abbreviation: 'JST')
  ]),
  'Asia/Ulaanbaatar': Location('Asia/Ulaanbaatar', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(25652000, isDst: false, abbreviation: 'LMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08')
  ]),
  'Asia/Urumqi': Location('Asia/Urumqi', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(21020000, isDst: false, abbreviation: 'LMT'),
    TimeZone(21600000, isDst: false, abbreviation: '+06')
  ]),
  'Asia/Ust-Nera': Location('Asia/Ust-Nera', [
    -8640000000000000
  ], [
    8
  ], [
    TimeZone(34374000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(36000000, isDst: false, abbreviation: '+10')
  ]),
  'Asia/Vientiane': Location('Asia/Vientiane', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(24124000, isDst: false, abbreviation: 'LMT'),
    TimeZone(24124000, isDst: false, abbreviation: 'BMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Asia/Vladivostok': Location('Asia/Vladivostok', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(31651000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(39600000, isDst: true, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10')
  ]),
  'Asia/Yakutsk': Location('Asia/Yakutsk', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(31138000, isDst: false, abbreviation: 'LMT'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: true, abbreviation: '+09'),
    TimeZone(28800000, isDst: false, abbreviation: '+08'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(36000000, isDst: true, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09')
  ]),
  'Asia/Yekaterinburg': Location('Asia/Yekaterinburg', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(14553000, isDst: false, abbreviation: 'LMT'),
    TimeZone(13505000, isDst: false, abbreviation: 'PMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(21600000, isDst: false, abbreviation: '+06'),
    TimeZone(21600000, isDst: true, abbreviation: '+06'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Asia/Yerevan': Location('Asia/Yerevan', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(10680000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Atlantic/Azores': Location('Atlantic/Azores', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12
  ], [
    TimeZone(-6160000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-6872000, isDst: false, abbreviation: 'HMT'),
    TimeZone(-3600000, isDst: true, abbreviation: '-01'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(-3600000, isDst: true, abbreviation: '-01'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(0, isDst: true, abbreviation: '+00'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: true, abbreviation: '+00'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01')
  ]),
  'Atlantic/Bermuda': Location('Atlantic/Bermuda', [
    -8640000000000000,
    1572757200000,
    1583647200000,
    1604206800000,
    1615701600000,
    1636261200000,
    1647151200000,
    1667710800000,
    1678600800000,
    1699160400000,
    1710050400000,
    1730610000000,
    1741500000000,
    1762059600000,
    1772949600000,
    1793509200000,
    1805004000000,
    1825563600000,
    1836453600000,
    1857013200000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4
  ], [
    TimeZone(-15558000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-11958000, isDst: true, abbreviation: 'BST'),
    TimeZone(-15558000, isDst: false, abbreviation: 'BMT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST')
  ]),
  'Atlantic/Canary': Location('Atlantic/Canary', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4
  ], [
    TimeZone(-3696000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST')
  ]),
  'Atlantic/Cape_Verde': Location('Atlantic/Cape_Verde', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(-5644000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(-3600000, isDst: true, abbreviation: '-01'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01')
  ]),
  'Atlantic/Faroe': Location('Atlantic/Faroe', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3
  ], [
    TimeZone(-1624000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET')
  ]),
  'Atlantic/Madeira': Location('Atlantic/Madeira', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11
  ], [
    TimeZone(-4056000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-4056000, isDst: false, abbreviation: 'FMT'),
    TimeZone(0, isDst: true, abbreviation: '+00'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(0, isDst: true, abbreviation: '+00'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(-3600000, isDst: false, abbreviation: '-01'),
    TimeZone(3600000, isDst: true, abbreviation: '+01'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST')
  ]),
  'Atlantic/Reykjavik': Location('Atlantic/Reykjavik', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Atlantic/South_Georgia': Location('Atlantic/South_Georgia', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-8768000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-7200000, isDst: false, abbreviation: '-02')
  ]),
  'Atlantic/St_Helena': Location('Atlantic/St_Helena', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Atlantic/Stanley': Location('Atlantic/Stanley', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-13884000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-13884000, isDst: false, abbreviation: 'SMT'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03'),
    TimeZone(-14400000, isDst: false, abbreviation: '-04'),
    TimeZone(-7200000, isDst: true, abbreviation: '-02'),
    TimeZone(-10800000, isDst: false, abbreviation: '-03'),
    TimeZone(-10800000, isDst: true, abbreviation: '-03')
  ]),
  'Australia/Adelaide': Location('Australia/Adelaide', [
    -8640000000000000,
    1570293000000,
    1586017800000,
    1601742600000,
    1617467400000,
    1633192200000,
    1648917000000,
    1664641800000,
    1680366600000,
    1696091400000,
    1712421000000,
    1728145800000,
    1743870600000,
    1759595400000,
    1775320200000,
    1791045000000,
    1806769800000,
    1822494600000,
    1838219400000,
    1853944200000
  ], [
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2
  ], [
    TimeZone(33260000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: false, abbreviation: 'ACST'),
    TimeZone(37800000, isDst: true, abbreviation: 'ACDT'),
    TimeZone(34200000, isDst: false, abbreviation: 'ACST'),
    TimeZone(34200000, isDst: false, abbreviation: 'ACST')
  ]),
  'Australia/Brisbane': Location('Australia/Brisbane', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(36728000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST')
  ]),
  'Australia/Broken_Hill': Location('Australia/Broken_Hill', [
    -8640000000000000,
    1570293000000,
    1586017800000,
    1601742600000,
    1617467400000,
    1633192200000,
    1648917000000,
    1664641800000,
    1680366600000,
    1696091400000,
    1712421000000,
    1728145800000,
    1743870600000,
    1759595400000,
    1775320200000,
    1791045000000,
    1806769800000,
    1822494600000,
    1838219400000,
    1853944200000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(33948000, isDst: false, abbreviation: 'LMT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(32400000, isDst: false, abbreviation: 'ACST'),
    TimeZone(37800000, isDst: true, abbreviation: 'ACDT'),
    TimeZone(34200000, isDst: false, abbreviation: 'ACST'),
    TimeZone(34200000, isDst: false, abbreviation: 'ACST'),
    TimeZone(37800000, isDst: true, abbreviation: 'ACDT')
  ]),
  'Australia/Currie': Location('Australia/Currie', [
    -8640000000000000,
    1570291200000,
    1586016000000,
    1601740800000,
    1617465600000,
    1633190400000,
    1648915200000,
    1664640000000,
    1680364800000,
    1696089600000,
    1712419200000,
    1728144000000,
    1743868800000,
    1759593600000,
    1775318400000,
    1791043200000,
    1806768000000,
    1822492800000,
    1838217600000,
    1853942400000
  ], [
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1
  ], [
    TimeZone(35356000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST')
  ]),
  'Australia/Darwin': Location('Australia/Darwin', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(31400000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: false, abbreviation: 'ACST'),
    TimeZone(37800000, isDst: true, abbreviation: 'ACDT'),
    TimeZone(34200000, isDst: false, abbreviation: 'ACST'),
    TimeZone(34200000, isDst: false, abbreviation: 'ACST')
  ]),
  'Australia/Eucla': Location('Australia/Eucla', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(30928000, isDst: false, abbreviation: 'LMT'),
    TimeZone(35100000, isDst: true, abbreviation: '+0945'),
    TimeZone(31500000, isDst: false, abbreviation: '+0845'),
    TimeZone(31500000, isDst: false, abbreviation: '+0845')
  ]),
  'Australia/Hobart': Location('Australia/Hobart', [
    -8640000000000000,
    1570291200000,
    1586016000000,
    1601740800000,
    1617465600000,
    1633190400000,
    1648915200000,
    1664640000000,
    1680364800000,
    1696089600000,
    1712419200000,
    1728144000000,
    1743868800000,
    1759593600000,
    1775318400000,
    1791043200000,
    1806768000000,
    1822492800000,
    1838217600000,
    1853942400000
  ], [
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1
  ], [
    TimeZone(35356000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST')
  ]),
  'Australia/Lindeman': Location('Australia/Lindeman', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(35756000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST')
  ]),
  'Australia/Lord_Howe': Location('Australia/Lord_Howe', [
    -8640000000000000,
    1570289400000,
    1586012400000,
    1601739000000,
    1617462000000,
    1633188600000,
    1648911600000,
    1664638200000,
    1680361200000,
    1696087800000,
    1712415600000,
    1728142200000,
    1743865200000,
    1759591800000,
    1775314800000,
    1791041400000,
    1806764400000,
    1822491000000,
    1838214000000,
    1853940600000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4
  ], [
    TimeZone(38180000, isDst: false, abbreviation: 'LMT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(41400000, isDst: true, abbreviation: '+1130'),
    TimeZone(37800000, isDst: false, abbreviation: '+1030'),
    TimeZone(39600000, isDst: true, abbreviation: '+11')
  ]),
  'Australia/Melbourne': Location('Australia/Melbourne', [
    -8640000000000000,
    1570291200000,
    1586016000000,
    1601740800000,
    1617465600000,
    1633190400000,
    1648915200000,
    1664640000000,
    1680364800000,
    1696089600000,
    1712419200000,
    1728144000000,
    1743868800000,
    1759593600000,
    1775318400000,
    1791043200000,
    1806768000000,
    1822492800000,
    1838217600000,
    1853942400000
  ], [
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1
  ], [
    TimeZone(34792000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST')
  ]),
  'Australia/Perth': Location('Australia/Perth', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(27804000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: true, abbreviation: 'AWDT'),
    TimeZone(28800000, isDst: false, abbreviation: 'AWST'),
    TimeZone(28800000, isDst: false, abbreviation: 'AWST')
  ]),
  'Australia/Sydney': Location('Australia/Sydney', [
    -8640000000000000,
    1570291200000,
    1586016000000,
    1601740800000,
    1617465600000,
    1633190400000,
    1648915200000,
    1664640000000,
    1680364800000,
    1696089600000,
    1712419200000,
    1728144000000,
    1743868800000,
    1759593600000,
    1775318400000,
    1791043200000,
    1806768000000,
    1822492800000,
    1838217600000,
    1853942400000
  ], [
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1
  ], [
    TimeZone(36292000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: true, abbreviation: 'AEDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST'),
    TimeZone(36000000, isDst: false, abbreviation: 'AEST')
  ]),
  'Canada/Atlantic': Location('Canada/Atlantic', [
    -8640000000000000,
    1572757200000,
    1583647200000,
    1604206800000,
    1615701600000,
    1636261200000,
    1647151200000,
    1667710800000,
    1678600800000,
    1699160400000,
    1710050400000,
    1730610000000,
    1741500000000,
    1762059600000,
    1772949600000,
    1793509200000,
    1805004000000,
    1825563600000,
    1836453600000,
    1857013200000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-15264000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'ADT'),
    TimeZone(-14400000, isDst: false, abbreviation: 'AST'),
    TimeZone(-10800000, isDst: true, abbreviation: 'AWT'),
    TimeZone(-10800000, isDst: true, abbreviation: 'APT')
  ]),
  'Canada/Central': Location('Canada/Central', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-23316000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'Canada/Eastern': Location('Canada/Eastern', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-19052000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'Canada/Mountain': Location('Canada/Mountain', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-27232000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT')
  ]),
  'Canada/Newfoundland': Location('Canada/Newfoundland', [
    -8640000000000000,
    1572755400000,
    1583645400000,
    1604205000000,
    1615699800000,
    1636259400000,
    1647149400000,
    1667709000000,
    1678599000000,
    1699158600000,
    1710048600000,
    1730608200000,
    1741498200000,
    1762057800000,
    1772947800000,
    1793507400000,
    1805002200000,
    1825561800000,
    1836451800000,
    1857011400000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4
  ], [
    TimeZone(-12652000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-9052000, isDst: true, abbreviation: 'NDT'),
    TimeZone(-12652000, isDst: false, abbreviation: 'NST'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NDT'),
    TimeZone(-12600000, isDst: false, abbreviation: 'NST'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NPT'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NWT'),
    TimeZone(-5400000, isDst: true, abbreviation: 'NDDT'),
    TimeZone(-9000000, isDst: true, abbreviation: 'NDT')
  ]),
  'Canada/Pacific': Location('Canada/Pacific', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604221200000,
    1615716000000,
    1636275600000,
    1647165600000,
    1667725200000,
    1678615200000,
    1699174800000,
    1710064800000,
    1730624400000,
    1741514400000,
    1762074000000,
    1772964000000,
    1793523600000,
    1805018400000,
    1825578000000,
    1836468000000,
    1857027600000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-29548000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT')
  ]),
  'Europe/Amsterdam': Location('Europe/Amsterdam', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11
  ], [
    TimeZone(1050000, isDst: false, abbreviation: 'LMT'),
    TimeZone(1050000, isDst: false, abbreviation: 'BMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Andorra': Location('Europe/Andorra', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4
  ], [
    TimeZone(364000, isDst: false, abbreviation: 'LMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Athens': Location('Europe/Athens', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9
  ], [
    TimeZone(5692000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5692000, isDst: false, abbreviation: 'AMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Belgrade': Location('Europe/Belgrade', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(4920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Berlin': Location('Europe/Berlin', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(3208000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Bratislava': Location('Europe/Bratislava', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(3464000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3464000, isDst: false, abbreviation: 'PMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(0, isDst: true, abbreviation: 'GMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Brussels': Location('Europe/Brussels', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11
  ], [
    TimeZone(1050000, isDst: false, abbreviation: 'LMT'),
    TimeZone(1050000, isDst: false, abbreviation: 'BMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Bucharest': Location('Europe/Bucharest', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(6264000, isDst: false, abbreviation: 'LMT'),
    TimeZone(6264000, isDst: false, abbreviation: 'BMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Budapest': Location('Europe/Budapest', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(4580000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Busingen': Location('Europe/Busingen', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5
  ], [
    TimeZone(2048000, isDst: false, abbreviation: 'LMT'),
    TimeZone(1786000, isDst: false, abbreviation: 'BMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Chisinau': Location('Europe/Chisinau', [
    -8640000000000000,
    1572134400000,
    1585440000000,
    1603584000000,
    1616889600000,
    1635638400000,
    1648339200000,
    1667088000000,
    1679788800000,
    1698537600000,
    1711843200000,
    1729987200000,
    1743292800000,
    1761436800000,
    1774742400000,
    1792886400000,
    1806192000000,
    1824940800000,
    1837641600000,
    1856390400000
  ], [
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5
  ], [
    TimeZone(6920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(6900000, isDst: false, abbreviation: 'CMT'),
    TimeZone(6264000, isDst: false, abbreviation: 'BMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Copenhagen': Location('Europe/Copenhagen', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(3208000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Dublin': Location('Europe/Dublin', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7
  ], [
    TimeZone(-1521000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-1521000, isDst: false, abbreviation: 'DMT'),
    TimeZone(2079000, isDst: true, abbreviation: 'IST'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'IST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(0, isDst: true, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'IST'),
    TimeZone(3600000, isDst: false, abbreviation: 'IST')
  ]),
  'Europe/Gibraltar': Location('Europe/Gibraltar', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-1284000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'BDST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Guernsey': Location('Europe/Guernsey', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-75000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'BDST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'BST'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Europe/Helsinki': Location('Europe/Helsinki', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5
  ], [
    TimeZone(5989000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5989000, isDst: false, abbreviation: 'HMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Isle_of_Man': Location('Europe/Isle_of_Man', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-75000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'BDST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'BST'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Europe/Istanbul': Location('Europe/Istanbul', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(6952000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7016000, isDst: false, abbreviation: 'IMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Europe/Jersey': Location('Europe/Jersey', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-75000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'BDST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'BST'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Europe/Kaliningrad': Location('Europe/Kaliningrad', [
    -8640000000000000
  ], [
    12
  ], [
    TimeZone(4920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Kyiv': Location('Europe/Kyiv', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13
  ], [
    TimeZone(7324000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7324000, isDst: false, abbreviation: 'KMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST')
  ]),
  'Europe/Lisbon': Location('Europe/Lisbon', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    10,
    6,
    10,
    6,
    10,
    6,
    10,
    6,
    10,
    6,
    10,
    6,
    10,
    6,
    10,
    6,
    10,
    6,
    10,
    6
  ], [
    TimeZone(-2205000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(7200000, isDst: true, abbreviation: 'WEMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET')
  ]),
  'Europe/Ljubljana': Location('Europe/Ljubljana', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(4920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/London': Location('Europe/London', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7
  ], [
    TimeZone(-75000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'BDST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'BST'),
    TimeZone(3600000, isDst: true, abbreviation: 'BST'),
    TimeZone(0, isDst: false, abbreviation: 'GMT')
  ]),
  'Europe/Luxembourg': Location('Europe/Luxembourg', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11,
    10,
    11
  ], [
    TimeZone(1050000, isDst: false, abbreviation: 'LMT'),
    TimeZone(1050000, isDst: false, abbreviation: 'BMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Madrid': Location('Europe/Madrid', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10
  ], [
    TimeZone(-884000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(7200000, isDst: true, abbreviation: 'WEMT'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Malta': Location('Europe/Malta', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(3484000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Mariehamn': Location('Europe/Mariehamn', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5
  ], [
    TimeZone(5989000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5989000, isDst: false, abbreviation: 'HMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Minsk': Location('Europe/Minsk', [
    -8640000000000000
  ], [
    12
  ], [
    TimeZone(6616000, isDst: false, abbreviation: 'LMT'),
    TimeZone(6600000, isDst: false, abbreviation: 'MMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: '+03')
  ]),
  'Europe/Monaco': Location('Europe/Monaco', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12
  ], [
    TimeZone(561000, isDst: false, abbreviation: 'LMT'),
    TimeZone(561000, isDst: false, abbreviation: 'PMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'WEMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Moscow': Location('Europe/Moscow', [
    -8640000000000000
  ], [
    10
  ], [
    TimeZone(9017000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9017000, isDst: false, abbreviation: 'MMT'),
    TimeZone(12679000, isDst: true, abbreviation: 'MST'),
    TimeZone(9079000, isDst: false, abbreviation: 'MMT'),
    TimeZone(16279000, isDst: true, abbreviation: 'MDST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(14400000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK')
  ]),
  'Europe/Oslo': Location('Europe/Oslo', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(3208000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Paris': Location('Europe/Paris', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12,
    11,
    12
  ], [
    TimeZone(561000, isDst: false, abbreviation: 'LMT'),
    TimeZone(561000, isDst: false, abbreviation: 'PMT'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: true, abbreviation: 'WEST'),
    TimeZone(0, isDst: false, abbreviation: 'WET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'WEMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Podgorica': Location('Europe/Podgorica', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(4920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Prague': Location('Europe/Prague', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(3464000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3464000, isDst: false, abbreviation: 'PMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(0, isDst: true, abbreviation: 'GMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Riga': Location('Europe/Riga', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14
  ], [
    TimeZone(5794000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5794000, isDst: false, abbreviation: 'RMT'),
    TimeZone(9394000, isDst: true, abbreviation: 'LST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Rome': Location('Europe/Rome', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(2996000, isDst: false, abbreviation: 'LMT'),
    TimeZone(2996000, isDst: false, abbreviation: 'RMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST')
  ]),
  'Europe/Samara': Location('Europe/Samara', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(12020000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(10800000, isDst: true, abbreviation: '+03'),
    TimeZone(7200000, isDst: false, abbreviation: '+02'),
    TimeZone(14400000, isDst: true, abbreviation: '+04'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Europe/San_Marino': Location('Europe/San_Marino', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(2996000, isDst: false, abbreviation: 'LMT'),
    TimeZone(2996000, isDst: false, abbreviation: 'RMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST')
  ]),
  'Europe/Sarajevo': Location('Europe/Sarajevo', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(4920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Simferopol': Location('Europe/Simferopol', [
    -8640000000000000
  ], [
    8
  ], [
    TimeZone(8184000, isDst: false, abbreviation: 'LMT'),
    TimeZone(8160000, isDst: false, abbreviation: 'SMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(14400000, isDst: false, abbreviation: 'MSK'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK')
  ]),
  'Europe/Skopje': Location('Europe/Skopje', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(4920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Sofia': Location('Europe/Sofia', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10
  ], [
    TimeZone(5596000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7016000, isDst: false, abbreviation: 'IMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET')
  ]),
  'Europe/Stockholm': Location('Europe/Stockholm', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8,
    7,
    8
  ], [
    TimeZone(3208000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(10800000, isDst: true, abbreviation: 'CEMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Tallinn': Location('Europe/Tallinn', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13
  ], [
    TimeZone(5940000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5940000, isDst: false, abbreviation: 'TMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST')
  ]),
  'Europe/Tirane': Location('Europe/Tirane', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3,
    4,
    3
  ], [
    TimeZone(4760000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST')
  ]),
  'Europe/Uzhgorod': Location('Europe/Uzhgorod', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13
  ], [
    TimeZone(7324000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7324000, isDst: false, abbreviation: 'KMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST')
  ]),
  'Europe/Vaduz': Location('Europe/Vaduz', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5
  ], [
    TimeZone(2048000, isDst: false, abbreviation: 'LMT'),
    TimeZone(1786000, isDst: false, abbreviation: 'BMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Vatican': Location('Europe/Vatican', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6,
    7,
    6
  ], [
    TimeZone(2996000, isDst: false, abbreviation: 'LMT'),
    TimeZone(2996000, isDst: false, abbreviation: 'RMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST')
  ]),
  'Europe/Vienna': Location('Europe/Vienna', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(3921000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Vilnius': Location('Europe/Vilnius', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    17,
    16,
    17,
    16,
    17,
    16,
    17,
    16,
    17,
    16,
    17,
    16,
    17,
    16,
    17,
    16,
    17,
    16,
    17,
    16
  ], [
    TimeZone(6076000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5040000, isDst: false, abbreviation: 'WMT'),
    TimeZone(5736000, isDst: false, abbreviation: 'KMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST')
  ]),
  'Europe/Volgograd': Location('Europe/Volgograd', [
    -8640000000000000
  ], [
    7
  ], [
    TimeZone(10660000, isDst: false, abbreviation: 'LMT'),
    TimeZone(10800000, isDst: false, abbreviation: '+03'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: false, abbreviation: 'MSK'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK')
  ]),
  'Europe/Warsaw': Location('Europe/Warsaw', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10,
    9,
    10
  ], [
    TimeZone(5040000, isDst: false, abbreviation: 'LMT'),
    TimeZone(5040000, isDst: false, abbreviation: 'WMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Zagreb': Location('Europe/Zagreb', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(4920000, isDst: false, abbreviation: 'LMT'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'Europe/Zaporozhye': Location('Europe/Zaporozhye', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13,
    14,
    13
  ], [
    TimeZone(7324000, isDst: false, abbreviation: 'LMT'),
    TimeZone(7324000, isDst: false, abbreviation: 'KMT'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: false, abbreviation: 'MSK'),
    TimeZone(14400000, isDst: true, abbreviation: 'MSD'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST'),
    TimeZone(7200000, isDst: false, abbreviation: 'EET'),
    TimeZone(10800000, isDst: true, abbreviation: 'EEST')
  ]),
  'Europe/Zurich': Location('Europe/Zurich', [
    -8640000000000000,
    1572138000000,
    1585443600000,
    1603587600000,
    1616893200000,
    1635642000000,
    1648342800000,
    1667091600000,
    1679792400000,
    1698541200000,
    1711846800000,
    1729990800000,
    1743296400000,
    1761440400000,
    1774746000000,
    1792890000000,
    1806195600000,
    1824944400000,
    1837645200000,
    1856394000000
  ], [
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5
  ], [
    TimeZone(2048000, isDst: false, abbreviation: 'LMT'),
    TimeZone(1786000, isDst: false, abbreviation: 'BMT'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET'),
    TimeZone(7200000, isDst: true, abbreviation: 'CEST'),
    TimeZone(3600000, isDst: false, abbreviation: 'CET')
  ]),
  'GMT':
      Location('GMT', [], [], [TimeZone(0, isDst: false, abbreviation: 'GMT')]),
  'Indian/Antananarivo': Location('Indian/Antananarivo', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Indian/Chagos': Location('Indian/Chagos', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(17380000, isDst: false, abbreviation: 'LMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05'),
    TimeZone(21600000, isDst: false, abbreviation: '+06')
  ]),
  'Indian/Christmas': Location('Indian/Christmas', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(24124000, isDst: false, abbreviation: 'LMT'),
    TimeZone(24124000, isDst: false, abbreviation: 'BMT'),
    TimeZone(25200000, isDst: false, abbreviation: '+07')
  ]),
  'Indian/Cocos': Location('Indian/Cocos', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(23087000, isDst: false, abbreviation: 'LMT'),
    TimeZone(23087000, isDst: false, abbreviation: 'RMT'),
    TimeZone(23400000, isDst: false, abbreviation: '+0630'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(23400000, isDst: false, abbreviation: '+0630')
  ]),
  'Indian/Comoro': Location('Indian/Comoro', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Indian/Kerguelen': Location('Indian/Kerguelen', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(17640000, isDst: false, abbreviation: 'LMT'),
    TimeZone(17640000, isDst: false, abbreviation: 'MMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Indian/Mahe': Location('Indian/Mahe', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(13272000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Indian/Maldives': Location('Indian/Maldives', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(17640000, isDst: false, abbreviation: 'LMT'),
    TimeZone(17640000, isDst: false, abbreviation: 'MMT'),
    TimeZone(18000000, isDst: false, abbreviation: '+05')
  ]),
  'Indian/Mauritius': Location('Indian/Mauritius', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(13800000, isDst: false, abbreviation: 'LMT'),
    TimeZone(18000000, isDst: true, abbreviation: '+05'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Indian/Mayotte': Location('Indian/Mayotte', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(8836000, isDst: false, abbreviation: 'LMT'),
    TimeZone(9000000, isDst: false, abbreviation: '+0230'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT'),
    TimeZone(9900000, isDst: false, abbreviation: '+0245'),
    TimeZone(10800000, isDst: false, abbreviation: 'EAT')
  ]),
  'Indian/Reunion': Location('Indian/Reunion', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(13272000, isDst: false, abbreviation: 'LMT'),
    TimeZone(14400000, isDst: false, abbreviation: '+04')
  ]),
  'Pacific/Apia': Location('Pacific/Apia', [
    -8640000000000000,
    1569679200000,
    1586008800000,
    1601128800000,
    1617458400000
  ], [
    5,
    6,
    5,
    6,
    5
  ], [
    TimeZone(45184000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-41216000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-41400000, isDst: false, abbreviation: '-1130'),
    TimeZone(-36000000, isDst: true, abbreviation: '-10'),
    TimeZone(-39600000, isDst: false, abbreviation: '-11'),
    TimeZone(46800000, isDst: false, abbreviation: '+13'),
    TimeZone(50400000, isDst: true, abbreviation: '+14')
  ]),
  'Pacific/Auckland': Location('Pacific/Auckland', [
    -8640000000000000,
    1569679200000,
    1586008800000,
    1601128800000,
    1617458400000,
    1632578400000,
    1648908000000,
    1664028000000,
    1680357600000,
    1695477600000,
    1712412000000,
    1727532000000,
    1743861600000,
    1758981600000,
    1775311200000,
    1790431200000,
    1806760800000,
    1821880800000,
    1838210400000,
    1853330400000
  ], [
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4,
    5,
    4
  ], [
    TimeZone(41944000, isDst: false, abbreviation: 'LMT'),
    TimeZone(45000000, isDst: true, abbreviation: 'NZST'),
    TimeZone(41400000, isDst: false, abbreviation: 'NZMT'),
    TimeZone(43200000, isDst: true, abbreviation: 'NZST'),
    TimeZone(46800000, isDst: true, abbreviation: 'NZDT'),
    TimeZone(43200000, isDst: false, abbreviation: 'NZST'),
    TimeZone(43200000, isDst: false, abbreviation: 'NZST')
  ]),
  'Pacific/Chatham': Location('Pacific/Chatham', [
    -8640000000000000,
    1569679200000,
    1586008800000,
    1601128800000,
    1617458400000,
    1632578400000,
    1648908000000,
    1664028000000,
    1680357600000,
    1695477600000,
    1712412000000,
    1727532000000,
    1743861600000,
    1758981600000,
    1775311200000,
    1790431200000,
    1806760800000,
    1821880800000,
    1838210400000,
    1853330400000
  ], [
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2,
    3,
    2
  ], [
    TimeZone(44028000, isDst: false, abbreviation: 'LMT'),
    TimeZone(44100000, isDst: false, abbreviation: '+1215'),
    TimeZone(49500000, isDst: true, abbreviation: '+1345'),
    TimeZone(45900000, isDst: false, abbreviation: '+1245'),
    TimeZone(45900000, isDst: false, abbreviation: '+1245')
  ]),
  'Pacific/Chuuk': Location('Pacific/Chuuk', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(35320000, isDst: false, abbreviation: 'LMT'),
    TimeZone(35312000, isDst: false, abbreviation: 'PMMT'),
    TimeZone(36000000, isDst: false, abbreviation: '+10')
  ]),
  'Pacific/Easter': Location('Pacific/Easter', [
    -8640000000000000,
    1567915200000,
    1586055600000,
    1599364800000,
    1617505200000,
    1630814400000,
    1648954800000,
    1662868800000,
    1680404400000,
    1693713600000,
    1712458800000,
    1725768000000,
    1743908400000,
    1757217600000,
    1775358000000,
    1788667200000,
    1806807600000,
    1820116800000,
    1838257200000,
    1851566400000
  ], [
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(-26248000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-26248000, isDst: false, abbreviation: 'EMT'),
    TimeZone(-21600000, isDst: true, abbreviation: '-06'),
    TimeZone(-25200000, isDst: false, abbreviation: '-07'),
    TimeZone(-25200000, isDst: false, abbreviation: '-07'),
    TimeZone(-21600000, isDst: false, abbreviation: '-06'),
    TimeZone(-18000000, isDst: true, abbreviation: '-05')
  ]),
  'Pacific/Efate': Location('Pacific/Efate', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(40396000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Pacific/Enderbury': Location('Pacific/Enderbury', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(0, isDst: false, abbreviation: '-00'),
    TimeZone(-43200000, isDst: false, abbreviation: '-12'),
    TimeZone(-39600000, isDst: false, abbreviation: '-11'),
    TimeZone(46800000, isDst: false, abbreviation: '+13')
  ]),
  'Pacific/Fakaofo': Location('Pacific/Fakaofo', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-41096000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-39600000, isDst: false, abbreviation: '-11'),
    TimeZone(46800000, isDst: false, abbreviation: '+13')
  ]),
  'Pacific/Fiji': Location('Pacific/Fiji', [
    -8640000000000000,
    1573308000000,
    1578751200000,
    1608386400000,
    1610805600000
  ], [
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(42944000, isDst: false, abbreviation: 'LMT'),
    TimeZone(46800000, isDst: true, abbreviation: '+13'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Pacific/Funafuti': Location('Pacific/Funafuti', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(41524000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Pacific/Galapagos': Location('Pacific/Galapagos', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-21504000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: false, abbreviation: '-05'),
    TimeZone(-18000000, isDst: true, abbreviation: '-05'),
    TimeZone(-21600000, isDst: false, abbreviation: '-06')
  ]),
  'Pacific/Gambier': Location('Pacific/Gambier', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-32388000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-32400000, isDst: false, abbreviation: '-09')
  ]),
  'Pacific/Guadalcanal': Location('Pacific/Guadalcanal', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(38388000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Pacific/Guam': Location('Pacific/Guam', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-51660000, isDst: false, abbreviation: 'LMT'),
    TimeZone(34740000, isDst: false, abbreviation: 'LMT'),
    TimeZone(36000000, isDst: false, abbreviation: 'GST'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(39600000, isDst: true, abbreviation: 'GDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'ChST')
  ]),
  'Pacific/Honolulu': Location('Pacific/Honolulu', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-37886000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-37800000, isDst: false, abbreviation: 'HST'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HDT'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HWT'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HPT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'HST')
  ]),
  'Pacific/Johnston': Location('Pacific/Johnston', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-37886000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-37800000, isDst: false, abbreviation: 'HST'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HDT'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HWT'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HPT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'HST')
  ]),
  'Pacific/Kiritimati': Location('Pacific/Kiritimati', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(-37760000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-38400000, isDst: false, abbreviation: '-1040'),
    TimeZone(-36000000, isDst: false, abbreviation: '-10'),
    TimeZone(50400000, isDst: false, abbreviation: '+14')
  ]),
  'Pacific/Kosrae': Location('Pacific/Kosrae', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-47284000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39116000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(43200000, isDst: false, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Pacific/Kwajalein': Location('Pacific/Kwajalein', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(40160000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(36000000, isDst: false, abbreviation: '+10'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(-43200000, isDst: false, abbreviation: '-12'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Pacific/Majuro': Location('Pacific/Majuro', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(41524000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Pacific/Marquesas': Location('Pacific/Marquesas', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-33480000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-34200000, isDst: false, abbreviation: '-0930')
  ]),
  'Pacific/Midway': Location('Pacific/Midway', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(45432000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-40968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-39600000, isDst: false, abbreviation: 'SST')
  ]),
  'Pacific/Nauru': Location('Pacific/Nauru', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(40060000, isDst: false, abbreviation: 'LMT'),
    TimeZone(41400000, isDst: false, abbreviation: '+1130'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Pacific/Niue': Location('Pacific/Niue', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-40780000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-40800000, isDst: false, abbreviation: '-1120'),
    TimeZone(-39600000, isDst: false, abbreviation: '-11')
  ]),
  'Pacific/Norfolk': Location('Pacific/Norfolk', [
    -8640000000000000,
    1570287600000,
    1586012400000,
    1601737200000,
    1617462000000,
    1633186800000,
    1648911600000,
    1664636400000,
    1680361200000,
    1696086000000,
    1712415600000,
    1728140400000,
    1743865200000,
    1759590000000,
    1775314800000,
    1791039600000,
    1806764400000,
    1822489200000,
    1838214000000,
    1853938800000
  ], [
    7,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6,
    5,
    6
  ], [
    TimeZone(40312000, isDst: false, abbreviation: 'LMT'),
    TimeZone(40320000, isDst: false, abbreviation: '+1112'),
    TimeZone(41400000, isDst: false, abbreviation: '+1130'),
    TimeZone(45000000, isDst: true, abbreviation: '+1230'),
    TimeZone(41400000, isDst: false, abbreviation: '+1130'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Pacific/Noumea': Location('Pacific/Noumea', [
    -8640000000000000
  ], [
    4
  ], [
    TimeZone(39948000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11'),
    TimeZone(43200000, isDst: true, abbreviation: '+12'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Pacific/Pago_Pago': Location('Pacific/Pago_Pago', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(45432000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-40968000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-39600000, isDst: false, abbreviation: 'SST')
  ]),
  'Pacific/Palau': Location('Pacific/Palau', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-54124000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32276000, isDst: false, abbreviation: 'LMT'),
    TimeZone(32400000, isDst: false, abbreviation: '+09')
  ]),
  'Pacific/Pitcairn': Location('Pacific/Pitcairn', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-31220000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-30600000, isDst: false, abbreviation: '-0830'),
    TimeZone(-28800000, isDst: false, abbreviation: '-08')
  ]),
  'Pacific/Pohnpei': Location('Pacific/Pohnpei', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(38388000, isDst: false, abbreviation: 'LMT'),
    TimeZone(39600000, isDst: false, abbreviation: '+11')
  ]),
  'Pacific/Port_Moresby': Location('Pacific/Port_Moresby', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(35320000, isDst: false, abbreviation: 'LMT'),
    TimeZone(35312000, isDst: false, abbreviation: 'PMMT'),
    TimeZone(36000000, isDst: false, abbreviation: '+10')
  ]),
  'Pacific/Rarotonga': Location('Pacific/Rarotonga', [
    -8640000000000000
  ], [
    3
  ], [
    TimeZone(48056000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-38344000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-37800000, isDst: false, abbreviation: '-1030'),
    TimeZone(-36000000, isDst: false, abbreviation: '-10'),
    TimeZone(-34200000, isDst: true, abbreviation: '-0930')
  ]),
  'Pacific/Saipan': Location('Pacific/Saipan', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-51660000, isDst: false, abbreviation: 'LMT'),
    TimeZone(34740000, isDst: false, abbreviation: 'LMT'),
    TimeZone(36000000, isDst: false, abbreviation: 'GST'),
    TimeZone(32400000, isDst: false, abbreviation: '+09'),
    TimeZone(39600000, isDst: true, abbreviation: 'GDT'),
    TimeZone(36000000, isDst: false, abbreviation: 'ChST')
  ]),
  'Pacific/Tahiti': Location('Pacific/Tahiti', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(-35896000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-36000000, isDst: false, abbreviation: '-10')
  ]),
  'Pacific/Tarawa': Location('Pacific/Tarawa', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(41524000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Pacific/Tongatapu': Location('Pacific/Tongatapu', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(44352000, isDst: false, abbreviation: 'LMT'),
    TimeZone(44400000, isDst: false, abbreviation: '+1220'),
    TimeZone(46800000, isDst: false, abbreviation: '+13'),
    TimeZone(50400000, isDst: true, abbreviation: '+14'),
    TimeZone(46800000, isDst: false, abbreviation: '+13'),
    TimeZone(50400000, isDst: true, abbreviation: '+14')
  ]),
  'Pacific/Wake': Location('Pacific/Wake', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(41524000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'Pacific/Wallis': Location('Pacific/Wallis', [
    -8640000000000000
  ], [
    1
  ], [
    TimeZone(41524000, isDst: false, abbreviation: 'LMT'),
    TimeZone(43200000, isDst: false, abbreviation: '+12')
  ]),
  'US/Alaska': Location('US/Alaska', [
    -8640000000000000,
    1572775200000,
    1583665200000,
    1604224800000,
    1615719600000,
    1636279200000,
    1647169200000,
    1667728800000,
    1678618800000,
    1699178400000,
    1710068400000,
    1730628000000,
    1741518000000,
    1762077600000,
    1772967600000,
    1793527200000,
    1805022000000,
    1825581600000,
    1836471600000,
    1857031200000
  ], [
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9,
    8,
    9
  ], [
    TimeZone(50424000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-35976000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'AST'),
    TimeZone(-32400000, isDst: true, abbreviation: 'AWT'),
    TimeZone(-32400000, isDst: true, abbreviation: 'APT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'AHST'),
    TimeZone(-32400000, isDst: true, abbreviation: 'AHDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'YST'),
    TimeZone(-28800000, isDst: true, abbreviation: 'AKDT'),
    TimeZone(-32400000, isDst: false, abbreviation: 'AKST')
  ]),
  'US/Arizona': Location('US/Arizona', [
    -8640000000000000
  ], [
    2
  ], [
    TimeZone(-26898000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST')
  ]),
  'US/Central': Location('US/Central', [
    -8640000000000000,
    1572764400000,
    1583654400000,
    1604214000000,
    1615708800000,
    1636268400000,
    1647158400000,
    1667718000000,
    1678608000000,
    1699167600000,
    1710057600000,
    1730617200000,
    1741507200000,
    1762066800000,
    1772956800000,
    1793516400000,
    1805011200000,
    1825570800000,
    1836460800000,
    1857020400000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-21036000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CDT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CWT'),
    TimeZone(-18000000, isDst: true, abbreviation: 'CPT'),
    TimeZone(-21600000, isDst: false, abbreviation: 'CST')
  ]),
  'US/Eastern': Location('US/Eastern', [
    -8640000000000000,
    1572760800000,
    1583650800000,
    1604210400000,
    1615705200000,
    1636264800000,
    1647154800000,
    1667714400000,
    1678604400000,
    1699164000000,
    1710054000000,
    1730613600000,
    1741503600000,
    1762063200000,
    1772953200000,
    1793512800000,
    1805007600000,
    1825567200000,
    1836457200000,
    1857016800000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-17762000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EDT'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-18000000, isDst: false, abbreviation: 'EST'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EWT'),
    TimeZone(-14400000, isDst: true, abbreviation: 'EPT')
  ]),
  'US/Hawaii': Location('US/Hawaii', [
    -8640000000000000
  ], [
    5
  ], [
    TimeZone(-37886000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-37800000, isDst: false, abbreviation: 'HST'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HDT'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HWT'),
    TimeZone(-34200000, isDst: true, abbreviation: 'HPT'),
    TimeZone(-36000000, isDst: false, abbreviation: 'HST')
  ]),
  'US/Mountain': Location('US/Mountain', [
    -8640000000000000,
    1572768000000,
    1583658000000,
    1604217600000,
    1615712400000,
    1636272000000,
    1647162000000,
    1667721600000,
    1678611600000,
    1699171200000,
    1710061200000,
    1730620800000,
    1741510800000,
    1762070400000,
    1772960400000,
    1793520000000,
    1805014800000,
    1825574400000,
    1836464400000,
    1857024000000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-25196000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MDT'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-25200000, isDst: false, abbreviation: 'MST'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MWT'),
    TimeZone(-21600000, isDst: true, abbreviation: 'MPT')
  ]),
  'US/Pacific': Location('US/Pacific', [
    -8640000000000000,
    1572771600000,
    1583661600000,
    1604221200000,
    1615716000000,
    1636275600000,
    1647165600000,
    1667725200000,
    1678615200000,
    1699174800000,
    1710064800000,
    1730624400000,
    1741514400000,
    1762074000000,
    1772964000000,
    1793523600000,
    1805018400000,
    1825578000000,
    1836468000000,
    1857027600000
  ], [
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2,
    1,
    2
  ], [
    TimeZone(-28378000, isDst: false, abbreviation: 'LMT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PDT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PWT'),
    TimeZone(-25200000, isDst: true, abbreviation: 'PPT'),
    TimeZone(-28800000, isDst: false, abbreviation: 'PST')
  ]),
  'UTC':
      Location('UTC', [], [], [TimeZone(0, isDst: false, abbreviation: 'UTC')]),
};

class TimeZoneInitException implements Exception {
  final String msg;

  TimeZoneInitException(this.msg);

  @override
  String toString() => msg;
}

class LocationNotFoundException implements Exception {
  final String msg;

  LocationNotFoundException(this.msg);

  @override
  String toString() => msg;
}

/// LocationDatabase provides interface to find [Location]s by their name.
///
///     List<int> data = load(); // load database
///
///     LocationDatabase db = LocationDatabase.fromBytes(data);
///     Location loc = db.get('US/Eastern');
///
class LocationDatabase {
  /// Mapping between [Location] name and [Location].
  final locations = _databaseMap; //<String, Location>{};

  /// Adds [Location] to the database.
  void add(Location location) {
    locations[location.name] = location;
  }

  /// Finds [Location] by its name.
  Location get(String name) {
    if (!isInitialized) {
      // Before you can get a location, you need to manually initialize the
      // timezone location database by calling initializeDatabase or similar.
      throw LocationNotFoundException(
          'Tried to get location before initializing timezone database');
    }

    final loc = locations[name];
    if (loc == null) {
      throw LocationNotFoundException(
          'Location with the name "$name" doesn\'t exist');
    }
    return loc;
  }

  /// Clears the database of all [Location] entries.
  void clear() => locations.clear();

  /// Returns whether the database is empty, or has [Location] entries.
  @Deprecated("Use 'isInitialized' instead")
  bool get isEmpty => isInitialized;

  /// Returns whether the database is empty, or has [Location] entries.
  bool get isInitialized => locations.isNotEmpty;
}

/// File name of the Time Zone default database.
//const String tzDataDefaultFilename = 'latest.tzf';


final _UTC = Location('UTC', [minTime], [0], [TimeZone.UTC]);

final _database = LocationDatabase();
Location _local = _UTC;

/// Global TimeZone database
LocationDatabase get timeZoneDatabase => _database;

/// UTC Location
Location get UTC => _UTC;

/// Local Location
///
/// By default it is instantiated with UTC [Location]
Location get local => _local;

/// Find [Location] by its name.
///
/// ```dart
/// final detroit = getLocation('America/Detroit');
/// ```
Location getLocation(String locationName) {
  return _database.get(locationName);
}

/// Set local [Location]
///
/// ```dart
/// final detroit = getLocation('America/Detroit')
/// setLocalLocation(detroit);
/// ```
void setLocalLocation(Location location) {
  _local = location;
}

/// Maximum value for time instants.
const int maxTime = 8640000000000000;

/// Minimum value for time instants.
const int minTime = -maxTime;

/// A [Location] maps time instants to the zone in use at that time.
/// Typically, the Location represents the collection of time offsets
/// in use in a geographical area, such as CEST and CET for central Europe.
class Location {
  /// [Location] name.
  final String name;

  /// Transition time, in milliseconds since 1970 UTC.
  final List<int> transitionAt;

  /// The index of the zone that goes into effect at that time.
  final List<int> transitionZone;

  /// [TimeZone]s at this [Location].
  final List<TimeZone> zones;

  /// [TimeZone] for the current time.
  TimeZone get currentTimeZone =>
      timeZone(DateTime.now().millisecondsSinceEpoch);

  // Most lookups will be for the current time.
  // To avoid the binary search through tx, keep a
  // static one-element cache that gives the correct
  // zone for the time when the Location was created.
  // if cacheStart <= t <= cacheEnd,
  // lookup can return cacheZone.
  // The units for cacheStart and cacheEnd are milliseconds
  // since January 1, 1970 UTC, to match the argument
  // to lookup.
  static final int _cacheNow = DateTime.now().millisecondsSinceEpoch;
  int _cacheStart = 0;
  int _cacheEnd = 0;
  late TimeZone _cacheZone;

  Location(this.name, this.transitionAt, this.transitionZone, this.zones) {
    // Fill in the cache with information about right now,
    // since that will be the most common lookup.
    for (var i = 0; i < transitionAt.length; i++) {
      final tAt = transitionAt[i];

      if ((tAt <= _cacheNow) &&
          ((i + 1 == transitionAt.length) ||
              (_cacheNow < transitionAt[i + 1]))) {
        _cacheStart = tAt;
        _cacheEnd = maxTime;
        if (i + 1 < transitionAt.length) {
          _cacheEnd = transitionAt[i + 1];
        }
        _cacheZone = zones[transitionZone[i]];
      }
    }
  }

  /// translate instant in time expressed as milliseconds since
  /// January 1, 1970 00:00:00 UTC to this [Location].
  int translate(int millisecondsSinceEpoch) {
    return millisecondsSinceEpoch + timeZone(millisecondsSinceEpoch).offset;
  }

  /// translate instant in time expressed as milliseconds since
  /// January 1, 1970 00:00:00 to UTC.
  int translateToUtc(int millisecondsSinceEpoch) {
    final t = lookupTimeZone(millisecondsSinceEpoch);
    final tz = t.timeZone;
    final start = t.start;
    final end = t.end;

    var utc = millisecondsSinceEpoch;

    if (tz.offset != 0) {
      utc -= tz.offset;

      if (utc < start) {
        utc =
            millisecondsSinceEpoch - lookupTimeZone(start - 1).timeZone.offset;
      } else if (utc >= end) {
        utc = millisecondsSinceEpoch - lookupTimeZone(end).timeZone.offset;
      }
    }

    return utc;
  }

  /// lookup for [TimeZone] and its boundaries for an instant in time expressed
  /// as milliseconds since January 1, 1970 00:00:00 UTC.
  TzInstant lookupTimeZone(int millisecondsSinceEpoch) {
    if (zones.isEmpty) {
      return const TzInstant(TimeZone.UTC, minTime, maxTime);
    }

    if (millisecondsSinceEpoch >= _cacheStart &&
        millisecondsSinceEpoch < _cacheEnd) {
      return TzInstant(_cacheZone, _cacheStart, _cacheEnd);
    }

    if (transitionAt.isEmpty || millisecondsSinceEpoch < transitionAt[0]) {
      final zone = _firstZone();
      final start = minTime;
      final end = transitionAt.isEmpty ? maxTime : transitionAt.first;
      return TzInstant(zone, start, end);
    }

    // Binary search for entry with largest millisecondsSinceEpoch <= sec.
    var lo = 0;
    var hi = transitionAt.length;
    var end = maxTime;

    while (hi - lo > 1) {
      final m = lo + (hi - lo) ~/ 2;
      final at = transitionAt[m];

      if (millisecondsSinceEpoch < at) {
        end = at;
        hi = m;
      } else {
        lo = m;
      }
    }

    return TzInstant(zones[transitionZone[lo]], transitionAt[lo], end);
  }

  /// timeZone method returns [TimeZone] in use at an instant in time expressed
  /// as milliseconds since January 1, 1970 00:00:00 UTC.
  TimeZone timeZone(int millisecondsSinceEpoch) {
    return lookupTimeZone(millisecondsSinceEpoch).timeZone;
  }

  /// timeZoneFromLocal method returns [TimeZone] in use at an instant in time
  /// expressed as milliseconds since January 1, 1970 00:00:00.
  TimeZone timeZoneFromLocal(int millisecondsSinceEpoch) {
    final t = lookupTimeZone(millisecondsSinceEpoch);
    var tz = t.timeZone;
    final start = t.start;
    final end = t.end;

    if (tz.offset != 0) {
      final utc = millisecondsSinceEpoch - tz.offset;

      if (utc < start) {
        tz = lookupTimeZone(start - 1).timeZone;
      } else if (utc >= end) {
        tz = lookupTimeZone(end).timeZone;
      }
    }

    return tz;
  }

  /// This method returns the [TimeZone] to use for times before the first
  /// transition time, or when there are no transition times.
  ///
  /// The reference implementation in localtime.c from
  /// http://www.iana.org/time-zones/repository/releases/tzcode2013g.tar.gz
  /// implements the following algorithm for these cases:
  ///
  /// 1. If the first zone is unused by the transitions, use it.
  /// 2. Otherwise, if there are transition times, and the first
  ///    transition is to a zone in daylight time, find the first
  ///    non-daylight-time zone before and closest to the first transition
  ///    zone.
  /// 3. Otherwise, use the first zone that is not daylight time, if
  ///    there is one.
  /// 4. Otherwise, use the first zone.
  ///
  TimeZone _firstZone() {
    // case 1
    if (!_firstZoneIsUsed()) {
      return zones.first;
    }

    // case 2
    if (transitionZone.isNotEmpty && zones[transitionZone.first].isDst) {
      for (var zi = transitionZone.first - 1; zi >= 0; zi--) {
        final z = zones[zi];
        if (!z.isDst) {
          return z;
        }
      }
    }

    // case 3
    for (final zi in transitionZone) {
      final z = zones[zi];
      if (!z.isDst) {
        return z;
      }
    }

    // case 4
    return zones.first;
  }

  /// firstZoneUsed returns whether the first zone is used by some transition.
  bool _firstZoneIsUsed() {
    for (final i in transitionZone) {
      if (i == 0) {
        return true;
      }
    }

    return false;
  }

  @override
  String toString() => name;

  // Override equals and hashCode to support comparing
  // Locations created in different isolates.

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Location &&
            runtimeType == other.runtimeType &&
            name == other.name;
  }

  @override
  int get hashCode {
    return name.hashCode;
  }
}

/// A [TimeZone] represents a single time zone such as CEST or CET.
class TimeZone {
  // ignore: constant_identifier_names
  static const TimeZone UTC = TimeZone(0, isDst: false, abbreviation: 'UTC');

  /// Milliseconds east of UTC.
  final int offset;

  /// Is this [TimeZone] Daylight Savings Time?
  final bool isDst;

  /// Abbreviated name, "CET".
  final String abbreviation;

  const TimeZone(this.offset,
      {required this.isDst, required this.abbreviation});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TimeZone &&
            offset == other.offset &&
            isDst == other.isDst &&
            abbreviation == other.abbreviation;
  }

  @override
  int get hashCode {
    var result = 17;
    result = 37 * result + offset.hashCode;
    result = 37 * result + isDst.hashCode;
    result = 37 * result + abbreviation.hashCode;
    return result;
  }

  @override
  String toString() => '[$abbreviation offset=$offset dst=$isDst]';
}

/// A [TzInstant] represents a timezone and an instant in time.
class TzInstant {
  final TimeZone timeZone;
  final int start;
  final int end;

  const TzInstant(this.timeZone, this.start, this.end);
}

/// TimeZone aware DateTime.
class TZDateTime implements DateTime {
  /// Maximum value for time instants.
  static const int maxMillisecondsSinceEpoch = 8640000000000000;

  /// Minimum value for time instants.
  static const int minMillisecondsSinceEpoch = -maxMillisecondsSinceEpoch;

  /// Returns the native [DateTime] object.
  static DateTime _toNative(DateTime t) => t is TZDateTime ? t._native : t;

  /// Converts a [_localDateTime] into a correct [DateTime].
  static DateTime _utcFromLocalDateTime(DateTime local, Location location) {
    // Adapted from https://github.com/JodaOrg/joda-time/blob/main/src/main/java/org/joda/time/DateTimeZone.java#L951
    // Get the offset at local (first estimate).
    final localInstant = local.millisecondsSinceEpoch;
    final localTimezone = location.lookupTimeZone(localInstant);
    final localOffset = localTimezone.timeZone.offset;

    // Adjust localInstant using the estimate and recalculate the offset.
    final adjustedInstant = localInstant - localOffset;
    final adjustedTimezone = location.lookupTimeZone(adjustedInstant);
    final adjustedOffset = adjustedTimezone.timeZone.offset;

    var milliseconds = localInstant - adjustedOffset;

    // If the offsets differ, we must be near a DST boundary
    if (localOffset != adjustedOffset) {
      // We need to ensure that time is always after the DST gap
      // this happens naturally for positive offsets, but not for negative.
      // If we just use adjustedOffset then the time is pushed back before the
      // transition, whereas it should be on or after the transition
      if (localOffset - adjustedOffset < 0 &&
          adjustedOffset !=
              location
                  .lookupTimeZone(localInstant - adjustedOffset)
                  .timeZone
                  .offset) {
        milliseconds = adjustedInstant;
      }
    }

    // Ensure original microseconds are preserved regardless of TZ shift.
    final microsecondsSinceEpoch =
        Duration(milliseconds: milliseconds, microseconds: local.microsecond)
            .inMicroseconds;
    return DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
        isUtc: true);
  }

  /// Native [DateTime] used as a Calendar object.
  ///
  /// Represents the same date and time as this [TZDateTime], but in the UTC
  /// time zone. For example, for a [TZDateTime] representing
  /// 2000-03-17T12:00:00-0700, this will store the [DateTime] representing
  /// 2000-03-17T12:00:00Z.
  final DateTime _localDateTime;

  /// Native [DateTime] used as canonical, utc representation.
  ///
  /// Represents the same moment as this [TZDateTime].
  final DateTime _native;

  /// The number of milliseconds since
  /// the "Unix epoch" 1970-01-01T00:00:00Z (UTC).
  ///
  /// This value is independent of the time zone.
  ///
  /// This value is at most
  /// 8,640,000,000,000,000ms (100,000,000 days) from the Unix epoch.
  /// In other words: [:millisecondsSinceEpoch.abs() <= 8640000000000000:].
  @override
  int get millisecondsSinceEpoch => _native.millisecondsSinceEpoch;

  /// The number of microseconds since the "Unix epoch"
  /// 1970-01-01T00:00:00Z (UTC).
  ///
  /// This value is independent of the time zone.
  ///
  /// This value is at most 8,640,000,000,000,000,000us (100,000,000 days) from
  /// the Unix epoch. In other words:
  /// microsecondsSinceEpoch.abs() <= 8640000000000000000.
  ///
  /// Note that this value does not fit into 53 bits (the size of a IEEE
  /// double).  A JavaScript number is not able to hold this value.
  @override
  int get microsecondsSinceEpoch => _native.microsecondsSinceEpoch;

  /// [Location]
  final Location location;

  /// [TimeZone]
  final TimeZone timeZone;

  /// True if this [TZDateTime] is set to UTC time.
  ///
  /// ```dart
  /// final dDay = TZDateTime.utc(1944, 6, 6);
  /// assert(dDay.isUtc);
  /// ```
  ///
  @override
  bool get isUtc => _isUtc(location);

  static bool _isUtc(Location l) => identical(l, UTC);

  /// True if this [TZDateTime] is set to Local time.
  ///
  /// ```dart
  /// final dDay = TZDateTime.local(1944, 6, 6);
  /// assert(dDay.isLocal);
  /// ```
  ///
  bool get isLocal => identical(location, local);

  /// Constructs a [TZDateTime] instance specified at [location] time zone.
  ///
  /// For example,
  /// to create a new TZDateTime object representing April 29, 2014, 6:04am
  /// in America/Detroit:
  ///
  /// ```dart
  /// final detroit = getLocation('America/Detroit');
  ///
  /// final annularEclipse = TZDateTime(location,
  ///     2014, DateTime.APRIL, 29, 6, 4);
  /// ```
  TZDateTime(Location location, int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : this.from(
            _utcFromLocalDateTime(
                DateTime.utc(year, month, day, hour, minute, second,
                    millisecond, microsecond),
                location),
            location);

  /// Constructs a [TZDateTime] instance specified in the UTC time zone.
  ///
  /// ```dart
  /// final dDay = TZDateTime.utc(1944, TZDateTime.JUNE, 6);
  /// ```
  TZDateTime.utc(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : this(UTC, year, month, day, hour, minute, second, millisecond,
            microsecond);

  /// Constructs a [TZDateTime] instance specified in the local time zone.
  ///
  /// ```dart
  /// final dDay = TZDateTime.utc(1944, TZDateTime.JUNE, 6);
  /// ```
  TZDateTime.local(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : this(local, year, month, day, hour, minute, second, millisecond,
            microsecond);

  /// Constructs a [TZDateTime] instance with current date and time in the
  /// [location] time zone.
  ///
  /// ```dart
  /// final detroit = getLocation('America/Detroit');
  ///
  /// final thisInstant = TZDateTime.now(detroit);
  /// ```
  TZDateTime.now(Location location) : this.from(DateTime.now(), location);

  /// Constructs a new [TZDateTime] instance with the given
  /// [millisecondsSinceEpoch].
  ///
  /// The constructed [TZDateTime] represents
  /// 1970-01-01T00:00:00Z + [millisecondsSinceEpoch] ms in the given
  /// time zone [location].
  TZDateTime.fromMillisecondsSinceEpoch(
      Location location, int millisecondsSinceEpoch)
      : this.from(
            DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                isUtc: true),
            location);

  TZDateTime.fromMicrosecondsSinceEpoch(
      Location location, int microsecondsSinceEpoch)
      : this.from(
            DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
                isUtc: true),
            location);

  /// Constructs a new [TZDateTime] instance from the given [DateTime]
  /// in the specified [location].
  ///
  /// ```dart
  /// final laTime = TZDateTime(la, 2010, 1, 1);
  /// final detroitTime = TZDateTime.from(laTime, detroit);
  /// ```
  TZDateTime.from(DateTime other, Location location)
      : this._(
            _toNative(other).toUtc(),
            location,
            _isUtc(location)
                ? TimeZone.UTC
                : location.timeZone(other.millisecondsSinceEpoch));

  TZDateTime._(DateTime native, this.location, this.timeZone)
      : _native = native,
        _localDateTime =
            _isUtc(location) ? native : native.add(_timeZoneOffset(timeZone));

  /// Constructs a new [TZDateTime] instance based on [formattedString].
  ///
  /// Throws a [FormatException] if the input cannot be parsed.
  ///
  /// The function parses a subset of ISO 8601
  /// which includes the subset accepted by RFC 3339.
  ///
  /// The result is always in the time zone of the provided location.
  ///
  /// Examples of accepted strings:
  ///
  /// * `"2012-02-27 13:27:00"`
  /// * `"2012-02-27 13:27:00.123456z"`
  /// * `"20120227 13:27:00"`
  /// * `"20120227T132700"`
  /// * `"20120227"`
  /// * `"+20120227"`
  /// * `"2012-02-27T14Z"`
  /// * `"2012-02-27T14+00:00"`
  /// * `"-123450101 00:00:00 Z"`: in the year -12345.
  /// * `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
  static TZDateTime parse(Location location, String formattedString) {
    return TZDateTime.from(DateTime.parse(formattedString), location);
  }

  /// Returns this DateTime value in the UTC time zone.
  ///
  /// Returns [this] if it is already in UTC.
  @override
  TZDateTime toUtc() => isUtc ? this : TZDateTime.from(_native, UTC);

  /// Returns this DateTime value in the local time zone.
  ///
  /// Returns [this] if it is already in the local time zone.
  @override
  TZDateTime toLocal() => isLocal ? this : TZDateTime.from(_native, local);

  static String _fourDigits(int n) {
    var absN = n.abs();
    var sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  static String _threeDigits(int n) {
    if (n >= 100) return "$n";
    if (n >= 10) return "0$n";
    return "00$n";
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  /// Returns a human-readable string for this instance.
  ///
  /// The returned string is constructed for the time zone of this instance.
  /// The `toString()` method provides a simply formatted string.
  /// It does not support internationalized strings.
  /// Use the [intl](http://pub.dartlang.org/packages/intl) package
  /// at the pub shared packages repo.
  @override
  String toString() => _toString(iso8601: false);

  /// Returns an ISO-8601 full-precision extended format representation.
  ///
  /// The format is yyyy-MM-ddTHH:mm:ss.mmmuuuZ for UTC time, and
  /// yyyy-MM-ddTHH:mm:ss.mmmuuu±hhmm for local/non-UTC time, where:
  ///
  /// *   yyyy is a, possibly negative, four digit representation of the year,
  ///     if the year is in the range -9999 to 9999, otherwise it is a signed
  ///     six digit representation of the year.
  /// *   MM is the month in the range 01 to 12,
  /// *   dd is the day of the month in the range 01 to 31,
  /// *   HH are hours in the range 00 to 23,
  /// *   mm are minutes in the range 00 to 59,
  /// *   ss are seconds in the range 00 to 59 (no leap seconds),
  /// *   mmm are milliseconds in the range 000 to 999, and
  /// *   uuu are microseconds in the range 001 to 999. If microsecond equals 0,
  ///     then this part is omitted.
  ///
  ///The resulting string can be parsed back using parse.
  @override
  String toIso8601String() => _toString(iso8601: true);

  String _toString({bool iso8601 = true}) {
    var offset = timeZone.offset;

    var y = _fourDigits(year);
    var m = _twoDigits(month);
    var d = _twoDigits(day);
    var sep = iso8601 ? "T" : " ";
    var h = _twoDigits(hour);
    var min = _twoDigits(minute);
    var sec = _twoDigits(second);
    var ms = _threeDigits(millisecond);
    var us = microsecond == 0 ? "" : _threeDigits(microsecond);

    if (isUtc) {
      return "$y-$m-$d$sep$h:$min:$sec.$ms${us}Z";
    } else {
      var offSign = offset.sign >= 0 ? '+' : '-';
      offset = offset.abs() ~/ 1000;
      var offH = _twoDigits(offset ~/ 3600);
      var offM = _twoDigits((offset % 3600) ~/ 60);

      return "$y-$m-$d$sep$h:$min:$sec.$ms$us$offSign$offH$offM";
    }
  }

  /// Returns a new [TZDateTime] instance with [duration] added to [this].
  @override
  TZDateTime add(Duration duration) =>
      TZDateTime.from(_native.add(duration), location);

  /// Returns a new [TZDateTime] instance with [duration] subtracted from
  /// [this].
  @override
  TZDateTime subtract(Duration duration) =>
      TZDateTime.from(_native.subtract(duration), location);

  /// Returns a [Duration] with the difference between [this] and [other].
  @override
  Duration difference(DateTime other) => _native.difference(_toNative(other));

  /// Returns true if [other] is a [TZDateTime] at the same moment and in the
  /// same [Location].
  ///
  /// ```dart
  /// final detroit   = getLocation('America/Detroit');
  /// final dDayUtc   = TZDateTime.utc(1944, DateTime.JUNE, 6);
  /// final dDayLocal = TZDateTime(detroit, 1944, DateTime.JUNE, 6);
  ///
  /// assert(dDayUtc.isAtSameMomentAs(dDayLocal) == false);
  /// ````
  ///
  /// See [isAtSameMomentAs] for a comparison that adjusts for time zone.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TZDateTime &&
            _native.isAtSameMomentAs(other._native) &&
            location == other.location;
  }

  /// Returns true if [this] occurs before [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  ///
  /// ```dart
  /// final berlinWallFell = TZDateTime(UTC, 1989, 11, 9);
  /// final moonLanding    = TZDateTime(UTC, 1969, 7, 20);
  ///
  /// assert(berlinWallFell.isBefore(moonLanding) == false);
  /// ```
  @override
  bool isBefore(DateTime other) => _native.isBefore(_toNative(other));

  /// Returns true if [this] occurs after [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  ///
  /// ```dart
  /// final berlinWallFell = TZDateTime(UTC, 1989, 11, 9);
  /// final moonLanding    = TZDateTime(UTC, 1969, 7, 20);
  ///
  /// assert(berlinWallFell.isAfter(moonLanding) == true);
  /// ```
  @override
  bool isAfter(DateTime other) => _native.isAfter(_toNative(other));

  /// Returns true if [this] occurs at the same moment as [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  ///
  /// ```dart
  /// final berlinWallFell = TZDateTime(UTC, 1989, 11, 9);
  /// final moonLanding    = TZDateTime(UTC, 1969, 7, 20);
  ///
  /// assert(berlinWallFell.isAtSameMomentAs(moonLanding) == false);
  /// ```
  @override
  bool isAtSameMomentAs(DateTime other) =>
      _native.isAtSameMomentAs(_toNative(other));

  /// Compares this [TZDateTime] object to [other],
  /// returning zero if the values occur at the same moment.
  ///
  /// This function returns a negative integer
  /// if this [TZDateTime] is smaller (earlier) than [other],
  /// or a positive integer if it is greater (later).
  @override
  int compareTo(DateTime other) => _native.compareTo(_toNative(other));

  @override
  int get hashCode => _native.hashCode;

  /// The abbreviated time zone name&mdash;for example,
  /// [:"CET":] or [:"CEST":].
  @override
  String get timeZoneName => timeZone.abbreviation;

  /// The time zone offset, which is the difference between time at [location]
  /// and UTC.
  ///
  /// The offset is positive for time zones east of UTC.
  ///
  /// Note, that JavaScript, Python and C return the difference between UTC and
  /// local time. Java, C# and Ruby return the difference between local time and
  /// UTC.
  @override
  Duration get timeZoneOffset => _timeZoneOffset(timeZone);

  static Duration _timeZoneOffset(TimeZone timeZone) =>
      Duration(milliseconds: timeZone.offset);

  /// The year.
  @override
  int get year => _localDateTime.year;

  /// The month [1..12].
  @override
  int get month => _localDateTime.month;

  /// The day of the month [1..31].
  @override
  int get day => _localDateTime.day;

  /// The hour of the day, expressed as in a 24-hour clock [0..23].
  @override
  int get hour => _localDateTime.hour;

  /// The minute [0...59].
  @override
  int get minute => _localDateTime.minute;

  /// The second [0...59].
  @override
  int get second => _localDateTime.second;

  /// The millisecond [0...999].
  @override
  int get millisecond => _localDateTime.millisecond;

  /// The microsecond [0...999].
  @override
  int get microsecond => _localDateTime.microsecond;

  /// The day of the week.
  ///
  /// In accordance with ISO 8601
  /// a week starts with Monday, which has the value 1.
  @override
  int get weekday => _localDateTime.weekday;
}
