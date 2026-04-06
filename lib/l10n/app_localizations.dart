import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The full application name.
  ///
  /// In en, this message translates to:
  /// **'Aziz Academy'**
  String get appTitle;

  /// Label for the player's score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// Label for the player's remaining lives (hearts).
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get hearts;

  /// Button to restart the quiz.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// Button to advance to the next question.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// General congratulatory message.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// Victory screen heading.
  ///
  /// In en, this message translates to:
  /// **'Master of Capitals!'**
  String get masterOfCapitals;

  /// Game-over screen heading.
  ///
  /// In en, this message translates to:
  /// **'Nice Try!'**
  String get niceTry;

  /// Button to navigate back to the module map.
  ///
  /// In en, this message translates to:
  /// **'Back to Map'**
  String get backToMap;

  /// Loading indicator text.
  ///
  /// In en, this message translates to:
  /// **'Loading quiz…'**
  String get loadingQuiz;

  /// Heading shown when the player finishes all questions.
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete!'**
  String get quizComplete;

  /// Sub-label beneath the score on the results screen.
  ///
  /// In en, this message translates to:
  /// **'correct answers'**
  String get correctAnswers;

  /// Encouraging message on the game-over screen.
  ///
  /// In en, this message translates to:
  /// **'Don\'t give up — every expert was once a beginner! 💪'**
  String get encouragement;

  /// Label while the heart-refill animation plays.
  ///
  /// In en, this message translates to:
  /// **'Refilling hearts…'**
  String get refillHearts;

  /// Label when the heart-refill animation completes.
  ///
  /// In en, this message translates to:
  /// **'❤️ Hearts Refilled!'**
  String get heartsRefilled;

  /// Try-again button label before refill completes.
  ///
  /// In en, this message translates to:
  /// **'Try Again Now →'**
  String get tryAgainNow;

  /// Try-again button label after refill completes.
  ///
  /// In en, this message translates to:
  /// **'Ready! Let\'s Go 🚀'**
  String get readyLetsGo;

  /// Accessibility label for quiz progress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionProgress(int current, int total);

  /// Button to begin quiz for a continent.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuiz;

  /// Hint label on the map screen.
  ///
  /// In en, this message translates to:
  /// **'Tap a continent to explore!'**
  String get tapContinentHint;

  /// Number of quiz questions for a continent.
  ///
  /// In en, this message translates to:
  /// **'{count} countries to explore'**
  String questionsAvailable(int count);

  /// Title of the map screen.
  ///
  /// In en, this message translates to:
  /// **'Map Explorer'**
  String get mapExplorer;

  /// Continent name.
  ///
  /// In en, this message translates to:
  /// **'Africa'**
  String get continentAfrica;

  /// Continent name.
  ///
  /// In en, this message translates to:
  /// **'Asia'**
  String get continentAsia;

  /// Continent name.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get continentEurope;

  /// Continent name.
  ///
  /// In en, this message translates to:
  /// **'North America'**
  String get continentNorthAmerica;

  /// Continent name.
  ///
  /// In en, this message translates to:
  /// **'South America'**
  String get continentSouthAmerica;

  /// Continent name.
  ///
  /// In en, this message translates to:
  /// **'Oceania'**
  String get continentOceania;

  /// Title of the logos quiz screen.
  ///
  /// In en, this message translates to:
  /// **'Logo Quiz'**
  String get logoQuizTitle;

  /// Label while logo blur clears.
  ///
  /// In en, this message translates to:
  /// **'Revealing logo…'**
  String get revealingLogo;

  /// Heading of the fun-fact card after answering.
  ///
  /// In en, this message translates to:
  /// **'Did You Know?'**
  String get knowledgeCard;

  /// YouTube brand description.
  ///
  /// In en, this message translates to:
  /// **'The world\'s largest video-sharing platform'**
  String get brand_youtube_desc;

  /// YouTube fun fact.
  ///
  /// In en, this message translates to:
  /// **'YouTube was founded in 2005 by three former PayPal employees. The very first video uploaded was called \'Me at the zoo\'!'**
  String get brand_youtube_fact;

  /// Apple brand description.
  ///
  /// In en, this message translates to:
  /// **'The company that makes iPhones and Macs'**
  String get brand_apple_desc;

  /// Apple fun fact.
  ///
  /// In en, this message translates to:
  /// **'Apple\'s logo has a bite taken out of it so people won\'t confuse it with a cherry! The company was co-founded by Steve Jobs in 1976.'**
  String get brand_apple_fact;

  /// LEGO brand description.
  ///
  /// In en, this message translates to:
  /// **'The world\'s most famous toy brick company'**
  String get brand_lego_desc;

  /// LEGO fun fact.
  ///
  /// In en, this message translates to:
  /// **'LEGO bricks are so precise that only 18 out of every 1 million pieces made are rejected. If you stacked all LEGO bricks ever made, they\'d reach the Moon and back — 10 times!'**
  String get brand_lego_fact;

  /// NASA brand description.
  ///
  /// In en, this message translates to:
  /// **'The US space agency exploring the universe'**
  String get brand_nasa_desc;

  /// NASA fun fact.
  ///
  /// In en, this message translates to:
  /// **'NASA stands for National Aeronautics and Space Administration. It was founded in 1958 and landed humans on the Moon just 11 years later!'**
  String get brand_nasa_fact;

  /// Nike brand description.
  ///
  /// In en, this message translates to:
  /// **'The world\'s largest sportswear brand'**
  String get brand_nike_desc;

  /// Nike fun fact.
  ///
  /// In en, this message translates to:
  /// **'Nike\'s famous swoosh logo was designed by a graphic design student for just USD 35 in 1971! The word Nike comes from the Greek goddess of victory.'**
  String get brand_nike_fact;

  /// McDonald's brand description.
  ///
  /// In en, this message translates to:
  /// **'The world\'s most visited fast-food restaurant'**
  String get brand_mcdonalds_desc;

  /// McDonald's fun fact.
  ///
  /// In en, this message translates to:
  /// **'McDonald\'s serves about 69 million people every day — that\'s more than the entire population of the UK! The golden arches are recognised by more people than the Christian cross.'**
  String get brand_mcdonalds_fact;

  /// Google brand description.
  ///
  /// In en, this message translates to:
  /// **'The search engine that knows almost everything'**
  String get brand_google_desc;

  /// Google fun fact.
  ///
  /// In en, this message translates to:
  /// **'Google was originally named \'BackRub\'! The name Google comes from \'googol\', the number 1 followed by 100 zeros — showing how much information it searches.'**
  String get brand_google_fact;

  /// Amazon brand description.
  ///
  /// In en, this message translates to:
  /// **'The world\'s biggest online shopping store'**
  String get brand_amazon_desc;

  /// Amazon fun fact.
  ///
  /// In en, this message translates to:
  /// **'Amazon\'s arrow logo goes from A to Z, showing that the store sells everything from A to Z. It also looks like a smile! Amazon started as an online bookstore in 1994.'**
  String get brand_amazon_fact;

  /// Title of the trophy room screen.
  ///
  /// In en, this message translates to:
  /// **'Trophy Room'**
  String get trophyRoom;

  /// Section heading for badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// Suffix after badge count, e.g. '3 / 8 unlocked'.
  ///
  /// In en, this message translates to:
  /// **'unlocked'**
  String get badgesUnlocked;

  /// Progress bar label.
  ///
  /// In en, this message translates to:
  /// **'Total Progress'**
  String get totalProgress;

  /// Suffix for progress percentage, e.g. '45% complete'.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get progressComplete;

  /// Module label for capitals module.
  ///
  /// In en, this message translates to:
  /// **'Capitals'**
  String get quiz_capitals;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Capitals Explorer'**
  String get badge_capitals_explorer_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Completed your first capitals quiz'**
  String get badge_capitals_explorer_desc;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Capitals Expert'**
  String get badge_capitals_expert_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Scored 3 stars without losing a life'**
  String get badge_capitals_expert_desc;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Map Master'**
  String get badge_map_master_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Tapped all 6 continents on the map'**
  String get badge_map_master_desc;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Logo Detective'**
  String get badge_logo_detective_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Completed your first logo quiz'**
  String get badge_logo_detective_desc;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Logo Hunter'**
  String get badge_logo_hunter_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Scored 3 stars in the logo quiz'**
  String get badge_logo_hunter_desc;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Trivia Titan'**
  String get badge_trivia_titan_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Answered 25 questions correctly'**
  String get badge_trivia_titan_desc;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Perfect Scholar'**
  String get badge_perfect_scholar_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'3 stars in both Capitals and Logos'**
  String get badge_perfect_scholar_desc;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Academy Star'**
  String get badge_academy_star_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Unlocked every single badge'**
  String get badge_academy_star_desc;

  /// Twitter/X brand description.
  ///
  /// In en, this message translates to:
  /// **'The social media platform now called X'**
  String get brand_twitter_desc;

  /// Twitter/X fun fact.
  ///
  /// In en, this message translates to:
  /// **'Twitter was founded in 2006. The original name idea was \'twttr\' — no vowels! In 2023 Elon Musk rebranded it to X. Its bird mascot was named Larry after basketball legend Larry Bird.'**
  String get brand_twitter_fact;

  /// Facebook brand description.
  ///
  /// In en, this message translates to:
  /// **'The world\'s most popular social network'**
  String get brand_facebook_desc;

  /// Facebook fun fact.
  ///
  /// In en, this message translates to:
  /// **'Facebook was started in a Harvard dorm room in 2004 by Mark Zuckerberg. It now has over 3 billion users — that\'s almost half of all people on Earth!'**
  String get brand_facebook_fact;

  /// Instagram brand description.
  ///
  /// In en, this message translates to:
  /// **'The world\'s favourite photo-sharing app'**
  String get brand_instagram_desc;

  /// Instagram fun fact.
  ///
  /// In en, this message translates to:
  /// **'Instagram was launched in 2010 and grew to 1 million users in just 2 months! It was bought by Facebook (now Meta) for USD 1 billion — at the time Instagram had only 13 employees.'**
  String get brand_instagram_fact;

  /// Netflix brand description.
  ///
  /// In en, this message translates to:
  /// **'The biggest video streaming service on Earth'**
  String get brand_netflix_desc;

  /// Netflix fun fact.
  ///
  /// In en, this message translates to:
  /// **'Netflix started in 1997 as a DVD-by-mail service! Today it has over 260 million subscribers in 190 countries. Its recommendation algorithm saves it over USD 1 billion per year by helping people find shows they love.'**
  String get brand_netflix_fact;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
