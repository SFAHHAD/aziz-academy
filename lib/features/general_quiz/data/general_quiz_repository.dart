import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

class GeneralQuizEntry {
  const GeneralQuizEntry({
    required this.id,
    required this.question,
    required this.questionAr,
    required this.options,
    required this.optionsAr,
    required this.correctAnswer,
    required this.correctAnswerAr,
    required this.category,
    this.funFact,
    this.funFactAr,
    this.difficulty = 1,
    this.objective,
    this.bloomLevel,
  });

  final String id;
  final String question;
  final String questionAr;
  final List<String> options;
  final List<String> optionsAr;
  final String correctAnswer;
  final String correctAnswerAr;
  final String category;
  final String? funFact;
  final String? funFactAr;
  final int difficulty;

  /// Optional pedagogy scaffolding — what skill the item teaches in
  /// a single line ("identify a logical fallacy"). Pack-authored.
  final String? objective;

  /// Optional Bloom's level: 'remember' / 'understand' / 'apply'.
  /// Future adaptive engine sorts by mastery using this signal.
  final String? bloomLevel;

  factory GeneralQuizEntry.fromJson(Map<String, dynamic> json) {
    return GeneralQuizEntry(
      id: json['id'] as String,
      question: json['question'] as String,
      questionAr:
          (json['question_ar'] as String?) ?? json['question'] as String,
      options: List<String>.from(json['options'] as List),
      optionsAr: json['options_ar'] != null
          ? List<String>.from(json['options_ar'] as List)
          : List<String>.from(json['options'] as List),
      correctAnswer: json['correct_answer'] as String,
      correctAnswerAr:
          (json['correct_answer_ar'] as String?) ??
          json['correct_answer'] as String,
      category: json['category'] as String,
      funFact: json['fun_fact'] as String?,
      funFactAr: json['fun_fact_ar'] as String?,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      objective: json['objective'] as String?,
      bloomLevel: json['bloom_level'] as String?,
    );
  }

  /// Some entries have AR-only categories (e.g. "تربية إسلامية"). When viewing
  /// in English, fall back to a transliterated/EN-labelled equivalent for grouping.
  String _englishCategoryFor(String ar) {
    switch (ar) {
      case 'جغرافيا':
        return 'Geography';
      case 'تربية إسلامية':
        return 'Islamic Studies';
      case 'لغة عربية':
        return 'Arabic';
      case 'رياضيات':
        return 'Math';
      case 'معلومات عامة':
        return 'General Knowledge';
      default:
        return ar;
    }
  }

  QuizQuestion toQuizQuestion({required bool arabic}) {
    final opts = arabic
        ? List<String>.from(optionsAr)
        : List<String>.from(options);
    opts.shuffle(math.Random());
    return QuizQuestion(
      id: id,
      question: arabic ? questionAr : question,
      options: opts,
      correctAnswer: arabic ? correctAnswerAr : correctAnswer,
      category: arabic ? category : _englishCategoryFor(category),
      funFact: arabic
          ? (funFactAr ?? 'هل تعلم أن المعرفة العامة تنمّي ذكاءك؟')
          : (funFact ?? 'Did you know general knowledge sharpens your mind?'),
      difficulty: difficulty,
    );
  }
}

class GeneralQuizRepository {
  const GeneralQuizRepository();

  static const _kBase = 'assets/data/general_quiz.json';
  static const _kVocabulary = 'assets/data/vocabulary.json';
  static const _kMathWord = 'assets/data/math_word_problems.json';
  static const _kMathWordGcc = 'assets/data/math_word_problems_gcc.json';
  static const _kLandmarks = 'assets/data/landmarks.json';
  static const _kHistorical = 'assets/data/historical_figures.json';
  static const _kAnimals = 'assets/data/animals_nature.json';
  static const _kGeography = 'assets/data/geography.json';
  static const _kEnglishGrammar = 'assets/data/english_grammar.json';
  static const _kArabicGrammar = 'assets/data/arabic_grammar.json';
  static const _kFiqhBasics = 'assets/data/fiqh_basics.json';
  static const _kSirah = 'assets/data/sirah_prophets.json';
  static const _kAsma = 'assets/data/asma_ul_husna.json';
  static const _kHadith = 'assets/data/hadith_kids.json';
  static const _kIslamicHistory = 'assets/data/islamic_history.json';
  static const _kFinLit = 'assets/data/financial_literacy.json';
  static const _kHealth = 'assets/data/health_body.json';
  static const _kEnv = 'assets/data/environment_sustainability.json';
  static const _kCoding = 'assets/data/coding_for_kids.json';
  static const _kArt = 'assets/data/art_culture.json';
  static const _kSports = 'assets/data/sports_games.json';
  static const _kChem = 'assets/data/chemistry_deep.json';
  static const _kAstro = 'assets/data/astronomy_space.json';
  static const _kInventions = 'assets/data/famous_inventions.json';
  static const _kWorldHistory = 'assets/data/world_history.json';
  static const _kRiddles = 'assets/data/riddles_puzzles.json';
  static const _kPlants = 'assets/data/plants_botany.json';
  static const _kCooking = 'assets/data/cooking_nutrition.json';
  static const _kMusic = 'assets/data/music_instruments.json';
  static const _kProphetStories = 'assets/data/quran_prophet_stories.json';
  static const _kArabicPoetry = 'assets/data/arabic_poetry_literature.json';
  static const _kDinos = 'assets/data/dinosaurs_prehistoric.json';
  static const _kWeather = 'assets/data/weather_natural_phenomena.json';
  static const _kBody = 'assets/data/body_anatomy.json';
  static const _kKuwait = 'assets/data/kuwait_heritage.json';
  static const _kSign = 'assets/data/sign_language.json';
  static const _kMythology = 'assets/data/world_mythology.json';
  static const _kOcean = 'assets/data/oceanography.json';
  static const _kLogicCT = 'assets/data/logic_critical_thinking.json';
  static const _kArch = 'assets/data/architecture_marvels.json';
  static const _kExperiments = 'assets/data/famous_experiments.json';
  static const _kChess = 'assets/data/chess_fundamentals.json';
  static const _kFirstAid = 'assets/data/first_aid_basics.json';
  static const _kRivers = 'assets/data/rivers_lakes.json';
  static const _kElements = 'assets/data/periodic_elements.json';
  static const _kCyber = 'assets/data/cybersecurity_kids.json';
  static const _kClouds = 'assets/data/clouds_atmosphere.json';
  static const _kScientists = 'assets/data/famous_scientists_deep.json';
  static const _kEI = 'assets/data/emotional_intelligence.json';
  static const _kAntiquity = 'assets/data/inventions_antiquity.json';
  static const _kQuranSci = 'assets/data/quran_sciences.json';
  static const _kEntrep = 'assets/data/entrepreneurship_kids.json';
  static const _kMapsCart = 'assets/data/maps_cartography.json';
  static const _kRobotics = 'assets/data/robotics_ai_kids.json';
  static const _kModernTech = 'assets/data/modern_tech_basics.json';
  static const _kBrain = 'assets/data/human_brain.json';
  static const _kClimate = 'assets/data/climate_change_kids.json';
  static const _kOpticalVision = 'assets/data/optical_illusions_vision.json';
  static const _kInsects = 'assets/data/insects_bugs.json';
  static const _kFemaleScholars = 'assets/data/female_scholars_pioneers.json';
  static const _kAncientEgypt = 'assets/data/ancient_egypt.json';
  static const _kVolcanoesEQ = 'assets/data/volcanoes_earthquakes.json';
  static const _kMicrobes = 'assets/data/microbes_cells.json';
  static const _kMaritime = 'assets/data/maritime_exploration.json';
  static const _kTelescopes = 'assets/data/telescopes_discoveries.json';
  static const _kMoneyHist = 'assets/data/money_trade_history.json';
  static const _kCalligraphy = 'assets/data/calligraphy_writing.json';
  static const _kMountains = 'assets/data/mountains_peaks.json';
  static const _kCiphers = 'assets/data/codes_ciphers.json';
  static const _kMesopotamia = 'assets/data/ancient_mesopotamia.json';
  static const _kDeserts = 'assets/data/deserts_world.json';
  static const _kAviation = 'assets/data/aviation_history.json';
  static const _kMedicinePion = 'assets/data/medicine_pioneers.json';
  static const _kAncientChina = 'assets/data/ancient_china.json';
  static const _kMathematicians = 'assets/data/famous_mathematicians.json';
  static const _kAfricanCiv = 'assets/data/african_civilizations.json';
  static const _kTimeClocks = 'assets/data/time_clocks.json';
  static const _kPhotography = 'assets/data/photography.json';
  static const _kForestsBiomes = 'assets/data/forests_biomes.json';
  static const _kFamousBattles = 'assets/data/famous_battles.json';
  static const _kOlympics = 'assets/data/olympic_games.json';
  static const _kCars = 'assets/data/cars_engineering.json';
  static const _kLanguages = 'assets/data/languages_world.json';
  static const _kAncientIndia = 'assets/data/ancient_india.json';
  static const _kBridges = 'assets/data/bridges_tunnels.json';
  static const _kTreaties = 'assets/data/treaties_diplomacy.json';
  static const _kSleepDreams = 'assets/data/sleep_dreams.json';
  static const _kTrains = 'assets/data/trains_railways.json';
  static const _kRenaissance = 'assets/data/renaissance_art.json';
  static const _kSubmarines = 'assets/data/submarines_ocean_tech.json';
  static const _kWildlife = 'assets/data/wildlife_conservation.json';
  static const _kSimpleMachines = 'assets/data/simple_machines.json';
  static const _kMusicGenres = 'assets/data/music_genres.json';
  static const _kInternetHistory = 'assets/data/internet_history.json';
  static const _kModernInventions = 'assets/data/modern_inventions.json';
  static const _kEconomics = 'assets/data/economics_basics.json';
  static const _kFamousMosques = 'assets/data/famous_mosques.json';
  static const _kMarineBiology = 'assets/data/marine_biology.json';
  static const _kAncientGreece = 'assets/data/ancient_greece.json';
  static const _kPolarRegions = 'assets/data/polar_regions.json';
  static const _kGemstones = 'assets/data/gemstones_minerals.json';
  static const _kWorldFestivals = 'assets/data/world_festivals.json';
  static const _kLighthouses = 'assets/data/famous_lighthouses.json';
  static const _kPharaohs = 'assets/data/egyptian_pharaohs.json';
  static const _kFairyTales = 'assets/data/fairy_tales_world.json';
  static const _kLibraries = 'assets/data/famous_libraries.json';
  static const _kBeekeeping = 'assets/data/beekeeping_pollinators.json';
  static const _kComposers = 'assets/data/classical_composers.json';
  static const _kUniversities = 'assets/data/famous_universities.json';
  static const _kCurrencies = 'assets/data/currencies_history.json';
  static const _kStadiums = 'assets/data/famous_stadiums.json';
  static const _kCastles = 'assets/data/famous_castles.json';
  static const _kTeaCoffee = 'assets/data/tea_coffee_history.json';
  static const _kSpiceTrade = 'assets/data/spice_trade.json';
  static const _kRenewable = 'assets/data/renewable_energy.json';
  static const _kMountaineers = 'assets/data/famous_mountaineers.json';
  static const _kChocolate = 'assets/data/chocolate_history.json';
  static const _kArchitects = 'assets/data/famous_architects.json';
  static const _kBirdsPrey = 'assets/data/birds_of_prey.json';
  static const _kMagnets = 'assets/data/magnets_electromagnetism.json';
  static const _kTrees = 'assets/data/iconic_trees_world.json';
  static const _kSenses = 'assets/data/anatomy_senses.json';
  static const _kToys = 'assets/data/toys_history.json';
  static const _kRomanEmpire = 'assets/data/roman_empire.json';
  static const _kVikings = 'assets/data/vikings_norse.json';
  static const _kHajj = 'assets/data/hajj_umrah.json';
  static const _kOttoman = 'assets/data/ottoman_empire.json';
  static const _kMesoamerica = 'assets/data/mesoamerica_civilizations.json';
  static const _kSalah = 'assets/data/salah_prayer.json';
  static const _kMughal = 'assets/data/mughal_empire.json';
  static const _kCompPioneers = 'assets/data/computer_pioneers.json';
  static const _kSoundAcoustics = 'assets/data/sound_acoustics.json';
  static const _kMongolEmpire = 'assets/data/mongolian_empire.json';
  static const _kSahaba = 'assets/data/sahaba_companions.json';
  static const _kDetectivesLit = 'assets/data/famous_detectives_lit.json';
  static const _kDisasters = 'assets/data/famous_disasters_history.json';
  static const _kImamsMadhabs = 'assets/data/the_imams_madhabs.json';
  static const _kAuthorsKids = 'assets/data/famous_authors_kids.json';
  static const _kBlackHoles = 'assets/data/black_holes_cosmology.json';
  static const _kStarsLife = 'assets/data/stars_life_cycle.json';
  static const _kConstellations = 'assets/data/constellations_stories.json';
  static const _kModernCities = 'assets/data/famous_modern_cities.json';
  static const _kPirates = 'assets/data/famous_pirates_real.json';
  static const _kModernChefs = 'assets/data/famous_modern_chefs.json';
  static const _kDnaGenes = 'assets/data/dna_genes_basics.json';
  static const _kPlateTectonics = 'assets/data/plate_tectonics_deep.json';
  static const _kWorldRecords = 'assets/data/world_records_guinness.json';
  static const _kWhalesDolphins = 'assets/data/whales_dolphins_deep.json';
  static const _kModernAthletes = 'assets/data/famous_modern_athletes.json';
  static const _kIslamicCalendar = 'assets/data/islamic_calendar_months.json';
  static const _kVolcanoesDeep = 'assets/data/famous_volcanoes_deep.json';
  static const _kPeriodicTable = 'assets/data/periodic_table_basics.json';
  static const _kSharksDeep = 'assets/data/sharks_world_deep.json';
  static const _kBridgesWorld = 'assets/data/famous_bridges_world.json';
  static const _kRobotsAi = 'assets/data/robots_ai_history.json';
  static const _kInsectsWorld = 'assets/data/insects_world.json';
  static const _kBigCatsWorld = 'assets/data/big_cats_world.json';
  static const _kCastlesWorld = 'assets/data/famous_castles_world.json';
  static const _kCurrencyMoney = 'assets/data/currency_money_history.json';
  static const _kSkyscrapers = 'assets/data/famous_skyscrapers.json';
  static const _kMythCreatures = 'assets/data/mythological_creatures.json';
  static const _kAutomobile = 'assets/data/automobile_history.json';
  static const _kMuseumsWorld = 'assets/data/famous_museums_world.json';
  static const _kBirdsWorld = 'assets/data/birds_world.json';
  static const _kFrogs = 'assets/data/frogs_amphibians.json';
  static const _kComicHeroes = 'assets/data/comic_book_heroes.json';
  static const _kColdWar = 'assets/data/cold_war_spies.json';
  static const _kUnesco = 'assets/data/unesco_heritage_sites.json';
  static const _kPenguinsDeep = 'assets/data/penguins_world_deep.json';
  static const _kCoralReefs = 'assets/data/coral_reefs_world.json';
  static const _kSnakesWorld = 'assets/data/snakes_world.json';
  static const _kSpidersArach = 'assets/data/spiders_arachnids.json';
  static const _kCavesWorld = 'assets/data/famous_caves_world.json';
  static const _kMoviesHist = 'assets/data/movies_cinema_history.json';
  static const _kPhotographers = 'assets/data/famous_photographers.json';
  static const _kBeaches = 'assets/data/famous_beaches.json';
  static const _kFoodsWorld = 'assets/data/famous_foods_world.json';
  static const _kRoadsRoutes = 'assets/data/famous_roads_routes.json';
  static const _kShipsBoats = 'assets/data/famous_ships_boats.json';
  static const _kMagicians = 'assets/data/famous_magicians.json';
  static const _kWalls = 'assets/data/famous_walls.json';
  static const _kHotels = 'assets/data/famous_hotels.json';
  static const _kComets = 'assets/data/famous_comets.json';
  static const _kAntarcticExp = 'assets/data/antarctic_explorers.json';
  static const _kStatues = 'assets/data/famous_statues.json';
  static const _kOperas = 'assets/data/famous_operas_musicals.json';
  static const _kAquariums = 'assets/data/famous_aquariums_zoos.json';
  static const _kFossils = 'assets/data/famous_fossils.json';
  static const _kDiamonds = 'assets/data/famous_diamonds.json';
  static const _kPlays = 'assets/data/famous_plays.json';
  static const _kDancers = 'assets/data/famous_dancers_ballet.json';
  static const _kNationalParks = 'assets/data/famous_national_parks.json';
  static const _kAnimalsHist = 'assets/data/famous_animals_history.json';
  static const _kMusicFest = 'assets/data/famous_music_festivals.json';
  static const _kPainters = 'assets/data/famous_painters.json';
  static const _kAstronauts = 'assets/data/famous_astronauts.json';
  static const _kLogos = 'assets/data/famous_logos.json';
  static const _kInventors = 'assets/data/famous_inventors.json';
  static const _kThemeParks = 'assets/data/famous_theme_parks.json';
  static const _kVideoGames = 'assets/data/famous_video_games.json';
  static const _kTennis = 'assets/data/famous_tennis_players.json';
  static const _kCartoons = 'assets/data/famous_cartoons.json';
  static const _kAircraft = 'assets/data/famous_aircraft_spacecraft.json';
  static const _kProgLang = 'assets/data/famous_programming_languages.json';
  static const _kKidsTV = 'assets/data/famous_childrens_tv.json';
  static const _kPets = 'assets/data/famous_pets_history.json';
  static const _kF1 = 'assets/data/famous_f1_drivers.json';
  static const _kChessPlayers = 'assets/data/famous_chess_players.json';
  static const _kGalaxies = 'assets/data/famous_galaxies_cosmic.json';
  static const _kPalaces = 'assets/data/famous_palaces_world.json';
  static const _kBoxers = 'assets/data/famous_boxers.json';
  static const _kConsoles = 'assets/data/famous_game_consoles.json';

  Future<List<GeneralQuizEntry>> loadEntries() async {
    final base = await _read(_kBase) ?? const <GeneralQuizEntry>[];
    final extras = await Future.wait([
      _read(_kVocabulary),
      _read(_kMathWord),
      _read(_kMathWordGcc),
      _read(_kLandmarks),
      _read(_kHistorical),
      _read(_kAnimals),
      _read(_kGeography),
      _read(_kEnglishGrammar),
      _read(_kArabicGrammar),
      _read(_kFiqhBasics),
      _read(_kSirah),
      _read(_kAsma),
      _read(_kHadith),
      _read(_kIslamicHistory),
      _read(_kFinLit),
      _read(_kHealth),
      _read(_kEnv),
      _read(_kCoding),
      _read(_kArt),
      _read(_kSports),
      _read(_kChem),
      _read(_kAstro),
      _read(_kInventions),
      _read(_kWorldHistory),
      _read(_kRiddles),
      _read(_kPlants),
      _read(_kCooking),
      _read(_kMusic),
      _read(_kProphetStories),
      _read(_kArabicPoetry),
      _read(_kDinos),
      _read(_kWeather),
      _read(_kBody),
      _read(_kKuwait),
      _read(_kSign),
      _read(_kMythology),
      _read(_kOcean),
      _read(_kLogicCT),
      _read(_kArch),
      _read(_kExperiments),
      _read(_kChess),
      _read(_kFirstAid),
      _read(_kRivers),
      _read(_kElements),
      _read(_kCyber),
      _read(_kClouds),
      _read(_kScientists),
      _read(_kEI),
      _read(_kAntiquity),
      _read(_kQuranSci),
      _read(_kEntrep),
      _read(_kMapsCart),
      _read(_kRobotics),
      _read(_kModernTech),
      _read(_kBrain),
      _read(_kClimate),
      _read(_kOpticalVision),
      _read(_kInsects),
      _read(_kFemaleScholars),
      _read(_kAncientEgypt),
      _read(_kVolcanoesEQ),
      _read(_kMicrobes),
      _read(_kMaritime),
      _read(_kTelescopes),
      _read(_kMoneyHist),
      _read(_kCalligraphy),
      _read(_kMountains),
      _read(_kCiphers),
      _read(_kMesopotamia),
      _read(_kDeserts),
      _read(_kAviation),
      _read(_kMedicinePion),
      _read(_kAncientChina),
      _read(_kMathematicians),
      _read(_kAfricanCiv),
      _read(_kTimeClocks),
      _read(_kPhotography),
      _read(_kForestsBiomes),
      _read(_kFamousBattles),
      _read(_kOlympics),
      _read(_kCars),
      _read(_kLanguages),
      _read(_kAncientIndia),
      _read(_kBridges),
      _read(_kTreaties),
      _read(_kSleepDreams),
      _read(_kTrains),
      _read(_kRenaissance),
      _read(_kSubmarines),
      _read(_kWildlife),
      _read(_kSimpleMachines),
      _read(_kMusicGenres),
      _read(_kInternetHistory),
      _read(_kModernInventions),
      _read(_kEconomics),
      _read(_kFamousMosques),
      _read(_kMarineBiology),
      _read(_kAncientGreece),
      _read(_kPolarRegions),
      _read(_kGemstones),
      _read(_kWorldFestivals),
      _read(_kLighthouses),
      _read(_kPharaohs),
      _read(_kFairyTales),
      _read(_kLibraries),
      _read(_kBeekeeping),
      _read(_kComposers),
      _read(_kUniversities),
      _read(_kCurrencies),
      _read(_kStadiums),
      _read(_kCastles),
      _read(_kTeaCoffee),
      _read(_kSpiceTrade),
      _read(_kRenewable),
      _read(_kMountaineers),
      _read(_kChocolate),
      _read(_kArchitects),
      _read(_kBirdsPrey),
      _read(_kMagnets),
      _read(_kTrees),
      _read(_kSenses),
      _read(_kToys),
      _read(_kRomanEmpire),
      _read(_kVikings),
      _read(_kHajj),
      _read(_kOttoman),
      _read(_kMesoamerica),
      _read(_kSalah),
      _read(_kMughal),
      _read(_kCompPioneers),
      _read(_kSoundAcoustics),
      _read(_kMongolEmpire),
      _read(_kSahaba),
      _read(_kDetectivesLit),
      _read(_kDisasters),
      _read(_kImamsMadhabs),
      _read(_kAuthorsKids),
      _read(_kBlackHoles),
      _read(_kStarsLife),
      _read(_kConstellations),
      _read(_kModernCities),
      _read(_kPirates),
      _read(_kModernChefs),
      _read(_kDnaGenes),
      _read(_kPlateTectonics),
      _read(_kWorldRecords),
      _read(_kWhalesDolphins),
      _read(_kModernAthletes),
      _read(_kIslamicCalendar),
      _read(_kVolcanoesDeep),
      _read(_kPeriodicTable),
      _read(_kSharksDeep),
      _read(_kBridgesWorld),
      _read(_kRobotsAi),
      _read(_kInsectsWorld),
      _read(_kBigCatsWorld),
      _read(_kCastlesWorld),
      _read(_kCurrencyMoney),
      _read(_kSkyscrapers),
      _read(_kMythCreatures),
      _read(_kAutomobile),
      _read(_kMuseumsWorld),
      _read(_kBirdsWorld),
      _read(_kFrogs),
      _read(_kComicHeroes),
      _read(_kColdWar),
      _read(_kUnesco),
      _read(_kPenguinsDeep),
      _read(_kCoralReefs),
      _read(_kSnakesWorld),
      _read(_kSpidersArach),
      _read(_kCavesWorld),
      _read(_kMoviesHist),
      _read(_kPhotographers),
      _read(_kBeaches),
      _read(_kFoodsWorld),
      _read(_kRoadsRoutes),
      _read(_kShipsBoats),
      _read(_kMagicians),
      _read(_kWalls),
      _read(_kHotels),
      _read(_kComets),
      _read(_kAntarcticExp),
      _read(_kStatues),
      _read(_kOperas),
      _read(_kAquariums),
      _read(_kFossils),
      _read(_kDiamonds),
      _read(_kPlays),
      _read(_kDancers),
      _read(_kNationalParks),
      _read(_kAnimalsHist),
      _read(_kMusicFest),
      _read(_kPainters),
      _read(_kAstronauts),
      _read(_kLogos),
      _read(_kInventors),
      _read(_kThemeParks),
      _read(_kVideoGames),
      _read(_kTennis),
      _read(_kCartoons),
      _read(_kAircraft),
      _read(_kProgLang),
      _read(_kKidsTV),
      _read(_kPets),
      _read(_kF1),
      _read(_kChessPlayers),
      _read(_kGalaxies),
      _read(_kPalaces),
      _read(_kBoxers),
      _read(_kConsoles),
    ]);
    final out = <GeneralQuizEntry>[...base];
    final seen = base.map((e) => e.id).toSet();
    for (final pack in extras) {
      if (pack == null) continue;
      for (final e in pack) {
        if (seen.add(e.id)) out.add(e);
      }
    }
    return out;
  }

  Future<List<GeneralQuizEntry>?> _read(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      final jsonString = utf8.decode(byteData.buffer.asUint8List());
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => GeneralQuizEntry.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
