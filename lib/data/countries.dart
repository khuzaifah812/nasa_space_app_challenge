// African countries with their main languages, five cities each (capital
// first) and the usual rain pattern. Coordinates are approximate, good to
// about 0.05 degrees, which is finer than the NASA weather grid.
//
// rain pattern numbers refer to seasonPatterns in engine/models.dart.

class City {
  const City(this.name, this.lat, this.lon);
  final String name;
  final double lat;
  final double lon;
}

class Country {
  const Country(this.name, this.region, this.west, this.south, this.east,
      this.north, this.pattern, this.languages, this.cities);
  final String name;
  final String region;
  final double west, south, east, north; // rough bounding box
  final int pattern;
  final List<String> languages;
  final List<City> cities;
}

const countries = <Country>[
  Country('Algeria', 'North Africa', -8.7, 19.0, 12.0, 37.1, 7, ['Arabic', 'Tamazight', 'French'],
      [City('Algiers', 36.75, 3.06), City('Oran', 35.70, -0.63), City('Constantine', 36.37, 6.61), City('Annaba', 36.90, 7.77), City('Blida', 36.47, 2.83)]),
  Country('Angola', 'Southern Africa', 11.6, -18.1, 24.1, -4.3, 6, ['Portuguese', 'Umbundu', 'Kimbundu', 'Kikongo'],
      [City('Luanda', -8.84, 13.23), City('Huambo', -12.78, 15.74), City('Lobito', -12.35, 13.55), City('Lubango', -14.92, 13.49), City('Malanje', -9.54, 16.34)]),
  Country('Benin', 'West Africa', 0.8, 6.2, 3.9, 12.4, 5, ['French', 'Fon', 'Yoruba', 'Bariba'],
      [City('Porto-Novo', 6.50, 2.60), City('Cotonou', 6.37, 2.39), City('Parakou', 9.34, 2.63), City('Abomey', 7.18, 1.99), City('Natitingou', 10.30, 1.38)]),
  Country('Botswana', 'Southern Africa', 19.9, -26.9, 29.4, -17.7, 6, ['English', 'Setswana'],
      [City('Gaborone', -24.65, 25.91), City('Francistown', -21.17, 27.51), City('Maun', -19.98, 23.42), City('Serowe', -22.39, 26.71), City('Kasane', -17.80, 25.15)]),
  Country('Burkina Faso', 'West Africa', -5.5, 9.4, 2.4, 15.1, 3, ['French', 'Mooré', 'Dioula', 'Fulfulde'],
      [City('Ouagadougou', 12.37, -1.52), City('Bobo-Dioulasso', 11.18, -4.30), City('Koudougou', 12.25, -2.36), City('Banfora', 10.63, -4.76), City('Ouahigouya', 13.58, -2.42)]),
  Country('Burundi', 'East Africa', 29.0, -4.5, 30.9, -2.3, 1, ['Kirundi', 'French', 'English'],
      [City('Gitega', -3.43, 29.92), City('Bujumbura', -3.38, 29.36), City('Ngozi', -2.91, 29.83), City('Muyinga', -2.85, 30.34), City('Rumonge', -3.97, 29.44)]),
  Country('Cabo Verde', 'West Africa', -25.4, 14.8, -22.7, 17.2, 3, ['Portuguese', 'Cape Verdean Creole'],
      [City('Praia', 14.93, -23.51), City('Mindelo', 16.89, -24.98), City('Santa Maria', 16.60, -22.91), City('Assomada', 15.10, -23.68), City('São Filipe', 14.90, -24.50)]),
  Country('Cameroon', 'Central Africa', 8.4, 1.6, 16.2, 13.1, 2, ['French', 'English', 'Fulfulde', 'Ewondo'],
      [City('Yaoundé', 3.87, 11.52), City('Douala', 4.05, 9.70), City('Garoua', 9.30, 13.40), City('Bamenda', 5.96, 10.15), City('Maroua', 10.59, 14.32)]),
  Country('Central African Republic', 'Central Africa', 14.4, 2.2, 27.5, 11.0, 2, ['French', 'Sango'],
      [City('Bangui', 4.39, 18.56), City('Bimbo', 4.26, 18.42), City('Berbérati', 4.26, 15.79), City('Bambari', 5.77, 20.67), City('Bouar', 5.93, 15.60)]),
  Country('Chad', 'Central Africa', 13.4, 7.4, 24.0, 23.5, 3, ['French', 'Arabic', 'Sara'],
      [City("N'Djamena", 12.13, 15.06), City('Moundou', 8.57, 16.08), City('Sarh', 9.14, 18.39), City('Abéché', 13.83, 20.83), City('Doba', 8.66, 16.85)]),
  Country('Comoros', 'East Africa', 43.2, -12.5, 44.6, -11.3, 6, ['Comorian', 'Arabic', 'French'],
      [City('Moroni', -11.70, 43.26), City('Mutsamudu', -12.17, 44.40), City('Fomboni', -12.28, 43.74), City('Domoni', -12.26, 44.53), City('Mitsamiouli', -11.38, 43.28)]),
  Country('Congo (Brazzaville)', 'Central Africa', 11.0, -5.1, 18.7, 3.8, 6, ['French', 'Lingala', 'Kituba'],
      [City('Brazzaville', -4.27, 15.28), City('Pointe-Noire', -4.78, 11.86), City('Dolisie', -4.20, 12.67), City('Nkayi', -4.18, 13.28), City('Ouesso', 1.61, 16.05)]),
  Country("Côte d'Ivoire", 'West Africa', -8.6, 4.3, -2.5, 10.7, 5, ['French', 'Baoulé', 'Dioula', 'Bété'],
      [City('Yamoussoukro', 6.83, -5.29), City('Abidjan', 5.36, -4.01), City('Bouaké', 7.69, -5.03), City('Daloa', 6.88, -6.45), City('Korhogo', 9.46, -5.63)]),
  Country('DR Congo', 'Central Africa', 12.2, -13.5, 31.3, 5.4, 6, ['French', 'Lingala', 'Swahili', 'Kikongo', 'Tshiluba'],
      [City('Kinshasa', -4.32, 15.31), City('Lubumbashi', -11.66, 27.48), City('Mbuji-Mayi', -6.14, 23.59), City('Kisangani', 0.52, 25.19), City('Goma', -1.68, 29.22)]),
  Country('Djibouti', 'East Africa', 41.7, 10.9, 43.5, 12.8, 3, ['French', 'Arabic', 'Somali', 'Afar'],
      [City('Djibouti', 11.59, 43.15), City('Ali Sabieh', 11.16, 42.71), City('Tadjoura', 11.79, 42.88), City('Obock', 11.96, 43.29), City('Dikhil', 11.11, 42.37)]),
  Country('Egypt', 'North Africa', 24.7, 22.0, 36.9, 31.7, 7, ['Arabic', 'English'],
      [City('Cairo', 30.04, 31.24), City('Alexandria', 31.20, 29.92), City('Giza', 30.01, 31.21), City('Luxor', 25.69, 32.64), City('Aswan', 24.09, 32.90)]),
  Country('Equatorial Guinea', 'Central Africa', 5.6, 0.9, 11.4, 3.8, 0, ['Spanish', 'French', 'Portuguese', 'Fang'],
      [City('Malabo', 3.75, 8.78), City('Bata', 1.86, 9.77), City('Ebebiyín', 2.15, 11.33), City('Mongomo', 1.63, 11.32), City('Evinayong', 1.44, 10.55)]),
  Country('Eritrea', 'East Africa', 36.4, 12.3, 43.2, 18.1, 3, ['Tigrinya', 'Arabic', 'English'],
      [City('Asmara', 15.32, 38.93), City('Keren', 15.78, 38.45), City('Massawa', 15.61, 39.45), City('Assab', 13.01, 42.74), City('Mendefera', 14.89, 38.82)]),
  Country('Eswatini', 'Southern Africa', 30.7, -27.4, 32.2, -25.7, 6, ['siSwati', 'English'],
      [City('Mbabane', -26.31, 31.14), City('Manzini', -26.50, 31.38), City('Lobamba', -26.45, 31.20), City('Siteki', -26.45, 31.95), City('Nhlangano', -27.11, 31.20)]),
  Country('Ethiopia', 'East Africa', 33.0, 3.4, 48.0, 14.9, 3, ['Amharic', 'Oromo', 'Tigrinya', 'Somali'],
      [City('Addis Ababa', 9.03, 38.74), City('Dire Dawa', 9.60, 41.87), City('Mekelle', 13.50, 39.47), City('Bahir Dar', 11.59, 37.39), City('Hawassa', 7.06, 38.48)]),
  Country('Gabon', 'Central Africa', 8.7, -4.0, 14.5, 2.3, 1, ['French', 'Fang'],
      [City('Libreville', 0.39, 9.45), City('Port-Gentil', -0.72, 8.78), City('Franceville', -1.63, 13.58), City('Oyem', 1.60, 11.58), City('Lambaréné', -0.70, 10.24)]),
  Country('Gambia', 'West Africa', -16.9, 13.0, -13.8, 13.9, 3, ['English', 'Mandinka', 'Wolof', 'Fula'],
      [City('Banjul', 13.45, -16.58), City('Serekunda', 13.44, -16.68), City('Brikama', 13.27, -16.65), City('Farafenni', 13.57, -15.60), City('Basse Santa Su', 13.31, -14.22)]),
  Country('Ghana', 'West Africa', -3.3, 4.7, 1.2, 11.2, 5, ['English', 'Akan (Twi)', 'Ewe', 'Dagbani', 'Ga'],
      [City('Accra', 5.60, -0.19), City('Kumasi', 6.69, -1.62), City('Tamale', 9.40, -0.84), City('Takoradi', 4.90, -1.76), City('Cape Coast', 5.11, -1.25)]),
  Country('Guinea', 'West Africa', -15.1, 7.2, -7.6, 12.7, 4, ['French', 'Pular', 'Malinké', 'Susu'],
      [City('Conakry', 9.64, -13.58), City('Kankan', 10.39, -9.31), City('Kindia', 10.06, -12.87), City('Labé', 11.32, -12.29), City('Nzérékoré', 7.76, -8.82)]),
  Country('Guinea-Bissau', 'West Africa', -16.7, 10.9, -13.6, 12.7, 4, ['Portuguese', 'Crioulo'],
      [City('Bissau', 11.86, -15.60), City('Bafatá', 12.17, -14.66), City('Gabú', 12.28, -14.22), City('Cacheu', 12.27, -16.17), City('Bolama', 11.58, -15.48)]),
  Country('Kenya', 'East Africa', 33.9, -4.7, 41.9, 5.5, 1, ['Swahili', 'English', 'Kikuyu', 'Luo', 'Luhya'],
      [City('Nairobi', -1.29, 36.82), City('Mombasa', -4.04, 39.67), City('Kisumu', -0.09, 34.77), City('Nakuru', -0.30, 36.07), City('Eldoret', 0.51, 35.27)]),
  Country('Lesotho', 'Southern Africa', 27.0, -30.7, 29.5, -28.5, 6, ['Sesotho', 'English'],
      [City('Maseru', -29.31, 27.48), City('Teyateyaneng', -29.15, 27.74), City('Mafeteng', -29.82, 27.24), City('Hlotse', -28.87, 28.05), City("Mohale's Hoek", -30.15, 27.47)]),
  Country('Liberia', 'West Africa', -11.5, 4.3, -7.4, 8.6, 4, ['English', 'Kpelle', 'Bassa'],
      [City('Monrovia', 6.30, -10.80), City('Gbarnga', 7.00, -9.47), City('Buchanan', 5.88, -10.05), City('Kakata', 6.53, -10.35), City('Harper', 4.38, -7.72)]),
  Country('Libya', 'North Africa', 9.4, 19.5, 25.2, 33.2, 7, ['Arabic', 'Tamazight'],
      [City('Tripoli', 32.89, 13.19), City('Benghazi', 32.12, 20.07), City('Misrata', 32.38, 15.09), City('Sabha', 27.04, 14.43), City('Tobruk', 32.08, 23.96)]),
  Country('Madagascar', 'East Africa', 43.2, -25.6, 50.5, -11.9, 6, ['Malagasy', 'French'],
      [City('Antananarivo', -18.88, 47.51), City('Toamasina', -18.15, 49.40), City('Antsirabe', -19.87, 47.03), City('Mahajanga', -15.72, 46.32), City('Fianarantsoa', -21.44, 47.09)]),
  Country('Malawi', 'Southern Africa', 32.7, -17.1, 35.9, -9.4, 6, ['English', 'Chichewa', 'Tumbuka', 'Yao'],
      [City('Lilongwe', -13.96, 33.77), City('Blantyre', -15.79, 35.01), City('Mzuzu', -11.46, 34.02), City('Zomba', -15.38, 35.32), City('Kasungu', -13.03, 33.48)]),
  Country('Mali', 'West Africa', -12.3, 10.1, 4.3, 25.0, 3, ['French', 'Bambara', 'Fulfulde', 'Songhai'],
      [City('Bamako', 12.64, -8.00), City('Sikasso', 11.32, -5.67), City('Ségou', 13.43, -6.26), City('Mopti', 14.49, -4.20), City('Kayes', 14.45, -11.44)]),
  Country('Mauritania', 'West Africa', -17.1, 14.7, -4.8, 27.3, 3, ['Arabic', 'French', 'Pulaar', 'Soninke'],
      [City('Nouakchott', 18.08, -15.98), City('Nouadhibou', 20.94, -17.04), City('Kiffa', 16.62, -11.40), City('Kaédi', 16.15, -13.50), City('Rosso', 16.51, -15.81)]),
  Country('Mauritius', 'East Africa', 57.3, -20.5, 57.8, -19.9, 6, ['English', 'French', 'Mauritian Creole'],
      [City('Port Louis', -20.16, 57.50), City('Curepipe', -20.32, 57.52), City('Vacoas', -20.30, 57.48), City('Quatre Bornes', -20.26, 57.48), City('Mahébourg', -20.41, 57.70)]),
  Country('Morocco', 'North Africa', -13.2, 27.6, -1.0, 35.9, 7, ['Arabic', 'Tamazight', 'French'],
      [City('Rabat', 34.02, -6.84), City('Casablanca', 33.57, -7.59), City('Marrakesh', 31.63, -8.01), City('Fes', 34.03, -5.00), City('Tangier', 35.76, -5.83)]),
  Country('Mozambique', 'Southern Africa', 30.2, -26.9, 40.9, -10.5, 6, ['Portuguese', 'Makhuwa', 'Tsonga', 'Sena'],
      [City('Maputo', -25.97, 32.57), City('Beira', -19.84, 34.84), City('Nampula', -15.12, 39.27), City('Chimoio', -19.12, 33.48), City('Tete', -16.16, 33.59)]),
  Country('Namibia', 'Southern Africa', 11.7, -29.0, 25.3, -16.9, 6, ['English', 'Oshiwambo', 'Afrikaans', 'Otjiherero'],
      [City('Windhoek', -22.56, 17.08), City('Rundu', -17.93, 19.77), City('Walvis Bay', -22.96, 14.51), City('Oshakati', -17.79, 15.70), City('Katima Mulilo', -17.50, 24.27)]),
  Country('Niger', 'West Africa', 0.1, 11.7, 16.0, 23.5, 3, ['French', 'Hausa', 'Zarma', 'Tamasheq'],
      [City('Niamey', 13.51, 2.11), City('Zinder', 13.81, 8.99), City('Maradi', 13.50, 7.10), City('Agadez', 16.97, 7.99), City('Tahoua', 14.89, 5.26)]),
  Country('Nigeria', 'West Africa', 2.7, 4.2, 14.7, 13.9, 4, ['English', 'Hausa', 'Yoruba', 'Igbo', 'Nigerian Pidgin'],
      [City('Abuja', 9.06, 7.49), City('Lagos', 6.52, 3.38), City('Kano', 12.00, 8.52), City('Ibadan', 7.38, 3.90), City('Port Harcourt', 4.82, 7.03)]),
  Country('Rwanda', 'East Africa', 28.8, -2.9, 30.9, -1.0, 1, ['Kinyarwanda', 'English', 'French', 'Swahili'],
      [City('Kigali', -1.95, 30.06), City('Huye', -2.60, 29.74), City('Musanze', -1.50, 29.63), City('Rubavu', -1.70, 29.26), City('Muhanga', -2.08, 29.76)]),
  Country('São Tomé and Príncipe', 'Central Africa', 6.4, -0.1, 7.5, 1.8, 1, ['Portuguese', 'Forro'],
      [City('São Tomé', 0.34, 6.73), City('Santo António', 1.64, 7.42), City('Neves', 0.36, 6.55), City('Santana', 0.26, 6.74), City('Trindade', 0.30, 6.68)]),
  Country('Senegal', 'West Africa', -17.6, 12.3, -11.3, 16.7, 3, ['French', 'Wolof', 'Pulaar', 'Serer'],
      [City('Dakar', 14.69, -17.45), City('Touba', 14.85, -15.88), City('Thiès', 14.79, -16.93), City('Kaolack', 14.15, -16.07), City('Ziguinchor', 12.57, -16.27)]),
  Country('Seychelles', 'East Africa', 55.2, -4.9, 56.0, -4.2, 6, ['Seychellois Creole', 'English', 'French'],
      [City('Victoria', -4.62, 55.45), City('Anse Boileau', -4.71, 55.48), City('Beau Vallon', -4.61, 55.43), City('Takamaka', -4.77, 55.50), City('Baie Sainte Anne', -4.32, 55.75)]),
  Country('Sierra Leone', 'West Africa', -13.4, 6.9, -10.2, 10.0, 4, ['English', 'Krio', 'Mende', 'Temne'],
      [City('Freetown', 8.48, -13.23), City('Bo', 7.96, -11.74), City('Kenema', 7.88, -11.19), City('Makeni', 8.88, -12.04), City('Koidu', 8.64, -10.97)]),
  Country('Somalia', 'East Africa', 40.9, -1.7, 51.5, 12.0, 1, ['Somali', 'Arabic'],
      [City('Mogadishu', 2.05, 45.32), City('Hargeisa', 9.56, 44.06), City('Kismayo', -0.36, 42.55), City('Baidoa', 3.11, 43.65), City('Bosaso', 11.28, 49.18)]),
  Country('South Africa', 'Southern Africa', 16.4, -34.9, 32.9, -22.1, 6, ['isiZulu', 'isiXhosa', 'Afrikaans', 'English', 'Sesotho'],
      [City('Pretoria', -25.75, 28.19), City('Johannesburg', -26.20, 28.05), City('Cape Town', -33.92, 18.42), City('Durban', -29.86, 31.02), City('Bloemfontein', -29.12, 26.21)]),
  Country('South Sudan', 'East Africa', 24.0, 3.5, 36.0, 12.3, 2, ['English', 'Juba Arabic', 'Dinka', 'Nuer'],
      [City('Juba', 4.85, 31.58), City('Wau', 7.70, 28.00), City('Malakal', 9.53, 31.66), City('Yei', 4.09, 30.68), City('Bor', 6.21, 31.56)]),
  Country('Sudan', 'North Africa', 21.8, 8.7, 38.6, 22.2, 3, ['Arabic', 'English'],
      [City('Khartoum', 15.50, 32.56), City('Omdurman', 15.65, 32.48), City('Port Sudan', 19.62, 37.22), City('Kassala', 15.45, 36.40), City('El Obeid', 13.18, 30.22)]),
  Country('Tanzania', 'East Africa', 29.3, -11.8, 40.5, -0.9, 6, ['Swahili', 'English', 'Sukuma'],
      [City('Dodoma', -6.16, 35.75), City('Dar es Salaam', -6.79, 39.21), City('Mwanza', -2.52, 32.90), City('Arusha', -3.37, 36.68), City('Mbeya', -8.90, 33.46)]),
  Country('Togo', 'West Africa', -0.2, 6.1, 1.9, 11.2, 5, ['French', 'Ewe', 'Kabiyè'],
      [City('Lomé', 6.13, 1.22), City('Sokodé', 8.98, 1.13), City('Kara', 9.55, 1.19), City('Kpalimé', 6.90, 0.63), City('Atakpamé', 7.53, 1.13)]),
  Country('Tunisia', 'North Africa', 7.5, 30.2, 11.6, 37.4, 7, ['Arabic', 'French'],
      [City('Tunis', 36.81, 10.18), City('Sfax', 34.74, 10.76), City('Sousse', 35.83, 10.64), City('Kairouan', 35.68, 10.10), City('Gabès', 33.88, 10.10)]),
  Country('Uganda', 'East Africa', 29.5, -1.5, 35.1, 4.3, 0, ['English', 'Swahili', 'Luganda', 'Runyankore', 'Acholi'],
      [City('Kampala', 0.35, 32.58), City('Luweero', 0.84, 32.49), City('Gulu', 2.77, 32.30), City('Mbarara', -0.61, 30.66), City('Mbale', 1.08, 34.18)]),
  Country('Zambia', 'Southern Africa', 21.9, -18.1, 33.7, -8.2, 6, ['English', 'Bemba', 'Nyanja', 'Tonga'],
      [City('Lusaka', -15.42, 28.28), City('Kitwe', -12.80, 28.21), City('Ndola', -12.97, 28.63), City('Livingstone', -17.85, 25.86), City('Chipata', -13.63, 32.65)]),
  Country('Zimbabwe', 'Southern Africa', 25.2, -22.4, 33.1, -15.6, 6, ['English', 'Shona', 'Ndebele'],
      [City('Harare', -17.83, 31.05), City('Bulawayo', -20.15, 28.58), City('Mutare', -18.97, 32.67), City('Gweru', -19.45, 29.82), City('Masvingo', -20.07, 30.83)]),
];

final ugandaIndex = countries.indexWhere((c) => c.name == 'Uganda');

/// ISO 3166-1 alpha-2 codes, used for place search.
const isoCodes = <String, String>{
  'Algeria': 'DZ', 'Angola': 'AO', 'Benin': 'BJ', 'Botswana': 'BW', 'Burkina Faso': 'BF',
  'Burundi': 'BI', 'Cabo Verde': 'CV', 'Cameroon': 'CM', 'Central African Republic': 'CF',
  'Chad': 'TD', 'Comoros': 'KM', 'Congo (Brazzaville)': 'CG', "Côte d'Ivoire": 'CI',
  'DR Congo': 'CD', 'Djibouti': 'DJ', 'Egypt': 'EG', 'Equatorial Guinea': 'GQ',
  'Eritrea': 'ER', 'Eswatini': 'SZ', 'Ethiopia': 'ET', 'Gabon': 'GA', 'Gambia': 'GM',
  'Ghana': 'GH', 'Guinea': 'GN', 'Guinea-Bissau': 'GW', 'Kenya': 'KE', 'Lesotho': 'LS',
  'Liberia': 'LR', 'Libya': 'LY', 'Madagascar': 'MG', 'Malawi': 'MW', 'Mali': 'ML',
  'Mauritania': 'MR', 'Mauritius': 'MU', 'Morocco': 'MA', 'Mozambique': 'MZ',
  'Namibia': 'NA', 'Niger': 'NE', 'Nigeria': 'NG', 'Rwanda': 'RW',
  'São Tomé and Príncipe': 'ST', 'Senegal': 'SN', 'Seychelles': 'SC', 'Sierra Leone': 'SL',
  'Somalia': 'SO', 'South Africa': 'ZA', 'South Sudan': 'SS', 'Sudan': 'SD', 'Tanzania': 'TZ',
  'Togo': 'TG', 'Tunisia': 'TN', 'Uganda': 'UG', 'Zambia': 'ZM', 'Zimbabwe': 'ZW',
};

/// The built-in entry for a country code, if it is an African country.
Country? countryByCode(String code) {
  for (final e in isoCodes.entries) {
    if (e.value == code.toUpperCase()) {
      for (final c in countries) {
        if (c.name == e.key) return c;
      }
    }
  }
  return null;
}
