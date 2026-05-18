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
  /// **'Try Again Now »'**
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

  /// No description provided for @homeBrandName.
  ///
  /// In en, this message translates to:
  /// **'Aziz Academy'**
  String get homeBrandName;

  /// No description provided for @homeSectionLearn.
  ///
  /// In en, this message translates to:
  /// **'What do you want to learn today?'**
  String get homeSectionLearn;

  /// No description provided for @homeHeroWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, explorer! 🌟'**
  String get homeHeroWelcome;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The stars are aligned for a new discovery today.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeCorrectTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct answers'**
  String get homeCorrectTotalLabel;

  /// No description provided for @homeStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String homeStreakLabel(int days);

  /// No description provided for @homeProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String homeProgressPercent(int percent);

  /// No description provided for @homeRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick review'**
  String get homeRecapTitle;

  /// No description provided for @homeRecapBody.
  ///
  /// In en, this message translates to:
  /// **'{count} questions saved from mistakes — review now'**
  String homeRecapBody(int count);

  /// No description provided for @homeRecapStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeRecapStart;

  /// No description provided for @dailyMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Mission'**
  String get dailyMissionTitle;

  /// No description provided for @dailyMissionSubtitleMaps.
  ///
  /// In en, this message translates to:
  /// **'Explore the maps and discover a new continent'**
  String get dailyMissionSubtitleMaps;

  /// No description provided for @dailyMissionSubtitleCapitals.
  ///
  /// In en, this message translates to:
  /// **'Capitals round — match countries to capitals'**
  String get dailyMissionSubtitleCapitals;

  /// No description provided for @dailyMissionSubtitleFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags challenge — guess the country'**
  String get dailyMissionSubtitleFlags;

  /// No description provided for @dailyMissionSubtitleSciences.
  ///
  /// In en, this message translates to:
  /// **'Science & discovery journey'**
  String get dailyMissionSubtitleSciences;

  /// No description provided for @dailyMissionSubtitleMath.
  ///
  /// In en, this message translates to:
  /// **'Mental math practice'**
  String get dailyMissionSubtitleMath;

  /// No description provided for @dailyMissionCtaToMaps.
  ///
  /// In en, this message translates to:
  /// **'To maps'**
  String get dailyMissionCtaToMaps;

  /// No description provided for @dailyMissionCtaStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get dailyMissionCtaStart;

  /// No description provided for @seasonalWinter.
  ///
  /// In en, this message translates to:
  /// **'Cozy winter vibes for learning ☃️'**
  String get seasonalWinter;

  /// No description provided for @seasonalSpring.
  ///
  /// In en, this message translates to:
  /// **'A season of knowledge starts with one question 🌸'**
  String get seasonalSpring;

  /// No description provided for @seasonalSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer of discovery — learn a little every day ☀️'**
  String get seasonalSummer;

  /// No description provided for @seasonalAutumn.
  ///
  /// In en, this message translates to:
  /// **'Focus time and a strong return to routine 📚'**
  String get seasonalAutumn;

  /// No description provided for @langSwitchEn.
  ///
  /// In en, this message translates to:
  /// **'🌐 EN'**
  String get langSwitchEn;

  /// No description provided for @langSwitchAr.
  ///
  /// In en, this message translates to:
  /// **'🌐 AR'**
  String get langSwitchAr;

  /// No description provided for @streakSnack.
  ///
  /// In en, this message translates to:
  /// **'🔥 {days} days in a row — great job!'**
  String streakSnack(int days);

  /// No description provided for @quiz_flags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get quiz_flags;

  /// No description provided for @quiz_maps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get quiz_maps;

  /// No description provided for @quiz_logos.
  ///
  /// In en, this message translates to:
  /// **'Logos'**
  String get quiz_logos;

  /// No description provided for @quiz_sciences.
  ///
  /// In en, this message translates to:
  /// **'Sciences'**
  String get quiz_sciences;

  /// No description provided for @quiz_math.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get quiz_math;

  /// No description provided for @moduleCapitalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match countries to their capitals'**
  String get moduleCapitalsSubtitle;

  /// No description provided for @moduleFlagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guess the country from the flag'**
  String get moduleFlagsSubtitle;

  /// No description provided for @moduleMapsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore continents and regions'**
  String get moduleMapsSubtitle;

  /// No description provided for @moduleLogosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recognise world brands'**
  String get moduleLogosSubtitle;

  /// No description provided for @moduleSciencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Journey of knowledge and discovery'**
  String get moduleSciencesSubtitle;

  /// No description provided for @moduleMathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arithmetic and mental math challenges'**
  String get moduleMathSubtitle;

  /// No description provided for @subjectStripCapitals.
  ///
  /// In en, this message translates to:
  /// **'Capitals'**
  String get subjectStripCapitals;

  /// No description provided for @subjectStripFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get subjectStripFlags;

  /// No description provided for @subjectStripLogos.
  ///
  /// In en, this message translates to:
  /// **'Logos'**
  String get subjectStripLogos;

  /// No description provided for @subjectStripSciences.
  ///
  /// In en, this message translates to:
  /// **'Sciences'**
  String get subjectStripSciences;

  /// No description provided for @subjectStripMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get subjectStripMath;

  /// No description provided for @settingsParentTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent settings'**
  String get settingsParentTitle;

  /// No description provided for @settingsSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound & voice'**
  String get settingsSoundTitle;

  /// No description provided for @settingsSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Effects and text-to-speech'**
  String get settingsSoundSubtitle;

  /// No description provided for @settingsReducedMotionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReducedMotionTitle;

  /// No description provided for @settingsReducedMotionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Less motion on success screens'**
  String get settingsReducedMotionSubtitle;

  /// No description provided for @settingsCoPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Play with parents'**
  String get settingsCoPlayTitle;

  /// No description provided for @settingsCoPlaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide choices until you reveal them'**
  String get settingsCoPlaySubtitle;

  /// No description provided for @settingsPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice without losing hearts'**
  String get settingsPracticeTitle;

  /// No description provided for @settingsPracticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Badges are not saved in this mode'**
  String get settingsPracticeSubtitle;

  /// No description provided for @settingsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export local backup (JSON)'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a text file for backup or support — no auto-upload'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup (JSON)'**
  String get settingsImportTitle;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace progress on this device — parents only'**
  String get settingsImportSubtitle;

  /// No description provided for @backupImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup?'**
  String get backupImportTitle;

  /// No description provided for @backupImportBody.
  ///
  /// In en, this message translates to:
  /// **'Achievements and the review queue on this device will be replaced with the file data. This cannot be undone automatically.'**
  String get backupImportBody;

  /// No description provided for @backupCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get backupCancel;

  /// No description provided for @backupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get backupConfirm;

  /// No description provided for @backupReadFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file.'**
  String get backupReadFileError;

  /// No description provided for @backupInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'The file is not valid JSON.'**
  String get backupInvalidJson;

  /// No description provided for @backupInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file.'**
  String get backupInvalidFile;

  /// No description provided for @backupUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'Unsupported backup version.'**
  String get backupUnsupportedVersion;

  /// No description provided for @backupMissingAchievements.
  ///
  /// In en, this message translates to:
  /// **'Invalid achievements data.'**
  String get backupMissingAchievements;

  /// No description provided for @backupMissingRecap.
  ///
  /// In en, this message translates to:
  /// **'Invalid review queue data.'**
  String get backupMissingRecap;

  /// No description provided for @backupSnackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully.'**
  String get backupSnackSuccess;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Aziz Academy progress backup'**
  String get backupShareSubject;

  /// No description provided for @errorPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorPageTitle;

  /// No description provided for @errorPageHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get errorPageHome;

  /// No description provided for @badge_capitals_explorer_condition.
  ///
  /// In en, this message translates to:
  /// **'Complete the capitals quiz successfully at least once.'**
  String get badge_capitals_explorer_condition;

  /// No description provided for @badge_capitals_expert_condition.
  ///
  /// In en, this message translates to:
  /// **'Finish the capitals quiz perfectly (3 stars / 0 mistakes).'**
  String get badge_capitals_expert_condition;

  /// No description provided for @badge_map_master_condition.
  ///
  /// In en, this message translates to:
  /// **'Open and try the maps section for all 6 continents.'**
  String get badge_map_master_condition;

  /// No description provided for @badge_logo_detective_condition.
  ///
  /// In en, this message translates to:
  /// **'Complete the logos quiz successfully at least once.'**
  String get badge_logo_detective_condition;

  /// No description provided for @badge_logo_hunter_condition.
  ///
  /// In en, this message translates to:
  /// **'Finish the logos quiz perfectly (3 stars / 0 mistakes).'**
  String get badge_logo_hunter_condition;

  /// No description provided for @badge_trivia_titan_condition.
  ///
  /// In en, this message translates to:
  /// **'Answer 25 questions correctly across all academy modules.'**
  String get badge_trivia_titan_condition;

  /// No description provided for @badge_science_genius_name.
  ///
  /// In en, this message translates to:
  /// **'Science Genius'**
  String get badge_science_genius_name;

  /// No description provided for @badge_science_genius_desc.
  ///
  /// In en, this message translates to:
  /// **'For excelling in science challenges'**
  String get badge_science_genius_desc;

  /// No description provided for @badge_science_genius_condition.
  ///
  /// In en, this message translates to:
  /// **'Complete the science quiz with 3 stars (0 mistakes).'**
  String get badge_science_genius_condition;

  /// No description provided for @badge_math_champion_name.
  ///
  /// In en, this message translates to:
  /// **'Math Champion'**
  String get badge_math_champion_name;

  /// No description provided for @badge_math_champion_desc.
  ///
  /// In en, this message translates to:
  /// **'For mastering the math challenge'**
  String get badge_math_champion_desc;

  /// No description provided for @badge_math_champion_condition.
  ///
  /// In en, this message translates to:
  /// **'Complete the math quiz with 3 stars (0 mistakes).'**
  String get badge_math_champion_condition;

  /// No description provided for @badge_perfect_scholar_condition.
  ///
  /// In en, this message translates to:
  /// **'Earn gold-level performance in Capitals, Logos, Sciences, and Math.'**
  String get badge_perfect_scholar_condition;

  /// No description provided for @badge_academy_star_condition.
  ///
  /// In en, this message translates to:
  /// **'Final badge: unlock all 9 other badges first!'**
  String get badge_academy_star_condition;

  /// No description provided for @trophyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load trophies. Try again later.'**
  String get trophyLoadError;

  /// No description provided for @trophyTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a badge to see how to earn it'**
  String get trophyTapHint;

  /// No description provided for @trophyLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Keep playing to unlock this badge'**
  String get trophyLockedHint;

  /// No description provided for @trophyOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get trophyOk;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLabel;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @funFactCorrectPrefix.
  ///
  /// In en, this message translates to:
  /// **'Correct answer:'**
  String get funFactCorrectPrefix;

  /// No description provided for @networkRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get networkRetry;

  /// No description provided for @networkImageError.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get networkImageError;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn. Play. Discover.'**
  String get splashTagline;

  /// No description provided for @splashStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get splashStartButton;

  /// No description provided for @mapsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load maps. Check your connection and try again.'**
  String get mapsLoadError;

  /// No description provided for @gameOverBack.
  ///
  /// In en, this message translates to:
  /// **'Back to menu'**
  String get gameOverBack;

  /// No description provided for @gameOverRoundScore.
  ///
  /// In en, this message translates to:
  /// **'Round score'**
  String get gameOverRoundScore;

  /// No description provided for @victoryShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get victoryShare;

  /// Victory-overlay CTA that restarts the same quiz.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get victoryPlayAgain;

  /// No description provided for @quizLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get quizLoadingError;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @trophyAchievementDone.
  ///
  /// In en, this message translates to:
  /// **'Achievement complete!'**
  String get trophyAchievementDone;

  /// No description provided for @trophyHowToEarnBadge.
  ///
  /// In en, this message translates to:
  /// **'How to earn this badge:'**
  String get trophyHowToEarnBadge;

  /// No description provided for @trophyHallTitle.
  ///
  /// In en, this message translates to:
  /// **'Trophy Hall'**
  String get trophyHallTitle;

  /// No description provided for @trophyBadgeCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} badges'**
  String trophyBadgeCount(int unlocked, int total);

  /// Victory screen heading for the flags quiz.
  ///
  /// In en, this message translates to:
  /// **'Flags Champion!'**
  String get victoryFlagsTitle;

  /// Victory screen heading for the logos quiz.
  ///
  /// In en, this message translates to:
  /// **'Logos Champion!'**
  String get victoryLogosTitle;

  /// Victory screen heading for the sciences quiz.
  ///
  /// In en, this message translates to:
  /// **'Science Champion!'**
  String get victorySciencesTitle;

  /// Victory screen heading for the maths quiz.
  ///
  /// In en, this message translates to:
  /// **'Maths Champion!'**
  String get victoryMathTitle;

  /// Share text for the flags quiz.
  ///
  /// In en, this message translates to:
  /// **'Flags Round — Aziz Academy'**
  String get shareModuleFlags;

  /// Share text for the logos quiz.
  ///
  /// In en, this message translates to:
  /// **'Logos Round — Aziz Academy'**
  String get shareModuleLogos;

  /// Share text for the sciences quiz.
  ///
  /// In en, this message translates to:
  /// **'Science Round — Aziz Academy'**
  String get shareModuleSciences;

  /// Share text for the maths quiz.
  ///
  /// In en, this message translates to:
  /// **'Maths Round — Aziz Academy'**
  String get shareModuleMath;

  /// Button to reveal choices in co-play mode.
  ///
  /// In en, this message translates to:
  /// **'Reveal answer choices'**
  String get coPlayRevealChoices;

  /// App-bar title for the sciences screen.
  ///
  /// In en, this message translates to:
  /// **'Scientific Discoveries'**
  String get sciencesScreenTitle;

  /// Button to start the full sciences quiz.
  ///
  /// In en, this message translates to:
  /// **'Start the full science challenge'**
  String get sciencesStartFull;

  /// Section label for topic picker on the sciences screen.
  ///
  /// In en, this message translates to:
  /// **'Or choose a science topic'**
  String get sciencesOrChooseCategory;

  /// Question count for the full sciences quiz.
  ///
  /// In en, this message translates to:
  /// **'{count} questions total'**
  String sciencesComprehensiveCount(int count);

  /// Question count for a specific science topic.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String sciencesCategoryCount(int count);

  /// App-bar title for the maths screen.
  ///
  /// In en, this message translates to:
  /// **'Maths Challenge'**
  String get mathScreenTitle;

  /// Button to start the full maths quiz.
  ///
  /// In en, this message translates to:
  /// **'Full intelligence test'**
  String get mathStartFull;

  /// Section label for operation picker on the maths screen.
  ///
  /// In en, this message translates to:
  /// **'Or choose an operation type'**
  String get mathOrChooseOperation;

  /// General retry button label on error states.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryAction;

  /// Error message when quiz questions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Sorry! Could not load the quiz.'**
  String get quizLoadError;

  /// Button to advance to the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextAction;

  /// Title of the smart review mode screen.
  ///
  /// In en, this message translates to:
  /// **'Review Mode'**
  String get reviewModeTitle;

  /// Subtitle on the review card.
  ///
  /// In en, this message translates to:
  /// **'{count} questions to review'**
  String reviewModeSubtitle(int count);

  /// Button to launch review mode.
  ///
  /// In en, this message translates to:
  /// **'Start Review'**
  String get reviewModeStart;

  /// Progress indicator in review mode.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String reviewModeQuestionOf(int current, int total);

  /// Heading on the review result screen.
  ///
  /// In en, this message translates to:
  /// **'Review Complete!'**
  String get reviewModeComplete;

  /// Score summary on result screen.
  ///
  /// In en, this message translates to:
  /// **'{score} / {total} correct'**
  String reviewModeScore(int score, int total);

  /// Number of questions removed from queue.
  ///
  /// In en, this message translates to:
  /// **'{count} question(s) mastered'**
  String reviewModeMastered(int count);

  /// Button to return home from review mode.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get reviewModeGoHome;

  /// Message shown when the review queue is empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review — great job!'**
  String get reviewModeEmpty;

  /// Label shown on module cards with review items.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get reviewModeNeedsReview;

  /// Badge on module card showing review count.
  ///
  /// In en, this message translates to:
  /// **'{count} to review'**
  String reviewModeCountBadge(int count);

  /// Title of the review card on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Smart Review'**
  String get reviewModeCardTitle;

  /// Subtitle of the review card on the home screen.
  ///
  /// In en, this message translates to:
  /// **'{count} question(s) need extra attention'**
  String reviewModeCardSubtitle(int count);

  /// Title of the daily challenge feature.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallengeTitle;

  /// Subtitle shown on the daily challenge card.
  ///
  /// In en, this message translates to:
  /// **'10 mixed questions · 2× XP'**
  String get dailyChallengeSubtitle;

  /// Button to start the daily challenge.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get dailyChallengeStart;

  /// Status when the daily challenge is done.
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get dailyChallengeCompleted;

  /// Countdown label.
  ///
  /// In en, this message translates to:
  /// **'Resets in {time}'**
  String dailyChallengeResetsIn(String time);

  /// Double XP badge label.
  ///
  /// In en, this message translates to:
  /// **'2× XP'**
  String get dailyChallengeDoubleXp;

  /// XP earned message on completion.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP earned!'**
  String dailyChallengeXpEarned(int xp);

  /// Score summary.
  ///
  /// In en, this message translates to:
  /// **'{score} / {total} correct'**
  String dailyChallengeScore(int score, int total);

  /// Question progress indicator.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String dailyChallengeQuestionOf(int current, int total);

  /// Celebration heading on the result screen.
  ///
  /// In en, this message translates to:
  /// **'Great job today!'**
  String get dailyChallengeGreatJob;

  /// Button to return home after challenge.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get dailyChallengeGoHome;

  /// Label for the progress strip in the trophy room.
  ///
  /// In en, this message translates to:
  /// **'Collection Progress'**
  String get trophyCollectionProgress;

  /// Heading inside the celebration overlay.
  ///
  /// In en, this message translates to:
  /// **'New Badge Unlocked!'**
  String get trophyNewBadgeTitle;

  /// Dismiss hint in the celebration overlay.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to continue'**
  String get trophyTapToDismiss;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Flag Master'**
  String get badge_flag_master_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Completed 10 Flags quiz sessions'**
  String get badge_flag_master_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Finish 10 Flags quiz sessions'**
  String get badge_flag_master_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Math Genius'**
  String get badge_math_genius_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'5 perfect Math rounds — not a single mistake!'**
  String get badge_math_genius_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Finish 5 Math quizzes without losing any lives'**
  String get badge_math_genius_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Streak Champion'**
  String get badge_streak_champion_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'7-day learning streak achieved!'**
  String get badge_streak_champion_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Open the app every day for 7 consecutive days'**
  String get badge_streak_champion_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Grand Scholar'**
  String get badge_grand_scholar_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'50 total correct answers across all modules'**
  String get badge_grand_scholar_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Answer 50 questions correctly across all quiz modules'**
  String get badge_grand_scholar_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'All-Rounder'**
  String get badge_all_rounder_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Tried every single quiz module!'**
  String get badge_all_rounder_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Complete at least one quiz in every module: Capitals, Flags, Logos, Math, and Sciences'**
  String get badge_all_rounder_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Brain Boost Beginner'**
  String get badge_brain_boost_beginner_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Started training your brain — keep going!'**
  String get badge_brain_boost_beginner_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Complete your first Brain Boost daily challenge'**
  String get badge_brain_boost_beginner_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Streak Master'**
  String get badge_brain_boost_streak_master_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Practiced 7 days in a row — that\'s dedication!'**
  String get badge_brain_boost_streak_master_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Reach a 7-day Brain Boost streak'**
  String get badge_brain_boost_streak_master_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Brain Boost Champion'**
  String get badge_brain_boost_champion_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'A perfect Champion Mode run!'**
  String get badge_brain_boost_champion_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Get 12/12 in Brain Boost Champion Mode'**
  String get badge_brain_boost_champion_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Dragon Slayer'**
  String get badge_boss_rush_perfect_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'All 12 questions correct in Boss Rush!'**
  String get badge_boss_rush_perfect_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Score 12/12 in Boss Rush'**
  String get badge_boss_rush_perfect_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Pass-Play Champion'**
  String get badge_pass_play_winner_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'Won 3 Pass-and-Play matches!'**
  String get badge_pass_play_winner_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Win 3 Pass-and-Play matches'**
  String get badge_pass_play_winner_condition;

  /// Badge name.
  ///
  /// In en, this message translates to:
  /// **'Weekly Champion'**
  String get badge_tourney_champion_name;

  /// Badge description.
  ///
  /// In en, this message translates to:
  /// **'First place on the family weekly tournament!'**
  String get badge_tourney_champion_desc;

  /// Badge unlock condition.
  ///
  /// In en, this message translates to:
  /// **'Finish #1 on the Weekly Tournament'**
  String get badge_tourney_champion_condition;

  /// Title of the blitz round screen and home card.
  ///
  /// In en, this message translates to:
  /// **'Blitz Round'**
  String get blitzTitle;

  /// Intro paragraph on the blitz ready screen.
  ///
  /// In en, this message translates to:
  /// **'60 seconds. As many correct answers as you can. Questions from every module.'**
  String get blitzDescription;

  /// Best score pill on the blitz ready screen.
  ///
  /// In en, this message translates to:
  /// **'Best: {score}'**
  String blitzBest(int score);

  /// Button to start the blitz round.
  ///
  /// In en, this message translates to:
  /// **'Start Blitz'**
  String get blitzStartButton;

  /// Score pill label in the blitz round.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get blitzScoreLabel;

  /// Streak pill label in the blitz round.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get blitzStreakLabel;

  /// Heading on the blitz result screen when a new high score is set.
  ///
  /// In en, this message translates to:
  /// **'New Best!'**
  String get blitzNewBest;

  /// Heading on the blitz result screen when time runs out.
  ///
  /// In en, this message translates to:
  /// **'Time’s up!'**
  String get blitzTimesUp;

  /// Longest streak achieved during the blitz round.
  ///
  /// In en, this message translates to:
  /// **'Best streak: {streak}'**
  String blitzBestStreak(int streak);

  /// Button to replay the blitz round.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get blitzPlayAgain;

  /// Button to leave the blitz round and return home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get blitzHome;

  /// Subtitle of the blitz card on the home screen.
  ///
  /// In en, this message translates to:
  /// **'60 seconds. Rapid-fire from every module'**
  String get blitzCardSubtitle;

  /// App-bar and home card title for the Brain Boost (formerly IQ) feature.
  ///
  /// In en, this message translates to:
  /// **'Brain Boost'**
  String get iqTitle;

  /// Hero card label on the Brain Boost intro screen.
  ///
  /// In en, this message translates to:
  /// **'Start full challenge'**
  String get iqHeroStartFull;

  /// First-open disclaimer header for the Brain Boost section.
  ///
  /// In en, this message translates to:
  /// **'About Brain Boost'**
  String get brainBoostDisclaimerTitle;

  /// First-open disclaimer body in plain kid-and-parent language.
  ///
  /// In en, this message translates to:
  /// **'Brain Boost is a fun way to practice logical thinking — it is not a real IQ test. Your scores stay on this device and are never compared with other children.'**
  String get brainBoostDisclaimerBody;

  /// Disclaimer dismiss button label.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get brainBoostDisclaimerOk;

  /// Section label for IQ topic picker.
  ///
  /// In en, this message translates to:
  /// **'Or choose a category'**
  String get iqOrChooseCategory;

  /// Error shown when IQ questions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load questions.'**
  String get iqLoadError;

  /// Question count for the full IQ challenge.
  ///
  /// In en, this message translates to:
  /// **'{count} comprehensive questions'**
  String iqComprehensiveCount(int count);

  /// Question count for a specific IQ category.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String iqCategoryCount(int count);

  /// Victory heading on the IQ quiz.
  ///
  /// In en, this message translates to:
  /// **'IQ Champion!'**
  String get iqVictoryTitle;

  /// Share text for the IQ quiz.
  ///
  /// In en, this message translates to:
  /// **'IQ Challenge — Aziz Academy'**
  String get iqShareLabel;

  /// Score badge label inside the IQ quiz.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get iqScoreLabel;

  /// Button to reveal choices in co-play mode (IQ quiz).
  ///
  /// In en, this message translates to:
  /// **'Reveal choices'**
  String get iqRevealChoices;

  /// Next question button in the IQ quiz.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get iqNextQuestion;

  /// Loading indicator label for IQ questions.
  ///
  /// In en, this message translates to:
  /// **'Loading IQ questions...'**
  String get iqLoading;

  /// Error heading when IQ questions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load questions'**
  String get iqLoadFailed;

  /// Subtitle of the IQ card on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Patterns, math, analogies & logic'**
  String get iqCardSubtitle;

  /// App-bar and home card title for the general quiz feature.
  ///
  /// In en, this message translates to:
  /// **'General Knowledge'**
  String get generalQuizTitle;

  /// Hero card label on the general quiz intro screen.
  ///
  /// In en, this message translates to:
  /// **'Start full general challenge'**
  String get generalQuizHeroStartFull;

  /// Section label for general quiz topic picker.
  ///
  /// In en, this message translates to:
  /// **'Or choose a category'**
  String get generalQuizOrChooseCategory;

  /// Error shown when general quiz questions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load questions.'**
  String get generalQuizLoadError;

  /// Question count label for general quiz hero/category cards.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String generalQuizCount(int count);

  /// Victory heading on the general quiz.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Champion!'**
  String get generalQuizVictoryTitle;

  /// Share text for the general quiz.
  ///
  /// In en, this message translates to:
  /// **'General Knowledge Challenge — Aziz Academy'**
  String get generalQuizShareLabel;

  /// Button to reveal choices in co-play mode (general quiz).
  ///
  /// In en, this message translates to:
  /// **'Reveal choices'**
  String get generalQuizRevealChoices;

  /// Next question button in the general quiz.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get generalQuizNextQuestion;

  /// Loading indicator label for general quiz questions.
  ///
  /// In en, this message translates to:
  /// **'Loading questions...'**
  String get generalQuizLoading;

  /// Error heading when general quiz questions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load questions'**
  String get generalQuizLoadFailed;

  /// Subtitle of the general knowledge card on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Geography, Islamic, Arabic & Math'**
  String get generalQuizCardSubtitle;

  /// Victory heading on the capitals quiz.
  ///
  /// In en, this message translates to:
  /// **'Capitals Champion!'**
  String get capitalsVictoryTitle;

  /// Share text for the capitals quiz.
  ///
  /// In en, this message translates to:
  /// **'Capitals Round — Aziz Academy'**
  String get capitalsShareLabel;

  /// Lock hint shown on the logos card before it is unlocked.
  ///
  /// In en, this message translates to:
  /// **'Level {level} or {count} Capitals quizzes'**
  String homeLogosLockHint(int level, int count);

  /// Lock hint shown on the sciences card before it is unlocked.
  ///
  /// In en, this message translates to:
  /// **'Level {level} or {count} Flags quizzes'**
  String homeSciencesLockHint(int level, int count);

  /// Lock hint shown on the math card before it is unlocked.
  ///
  /// In en, this message translates to:
  /// **'Level {level} or {count} Flags quizzes'**
  String homeMathLockHint(int level, int count);

  /// Lifeline that removes two wrong answers.
  ///
  /// In en, this message translates to:
  /// **'50/50'**
  String get lifelineFiftyFifty;

  /// Lifeline that skips the current question.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get lifelineSkip;

  /// Lifeline that reveals a clue toward the correct answer.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get lifelineHint;

  /// Snackbar when the learner cannot afford a lifeline.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins. Earn more by answering correctly!'**
  String get lifelineNotEnoughCoins;

  /// Generic coin balance label.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coinsLabel;

  /// First onboarding card title.
  ///
  /// In en, this message translates to:
  /// **'Pick a subject'**
  String get onboardingTitle1;

  /// First onboarding card body.
  ///
  /// In en, this message translates to:
  /// **'Choose a learning module from the home screen — Capitals, Sciences, IQ, Math, and many more.'**
  String get onboardingBody1;

  /// Second onboarding card title.
  ///
  /// In en, this message translates to:
  /// **'Earn stars and coins'**
  String get onboardingTitle2;

  /// Second onboarding card body.
  ///
  /// In en, this message translates to:
  /// **'Answer correctly to earn XP, stars, and coins. Use coins to unlock helpful lifelines.'**
  String get onboardingBody2;

  /// Third onboarding card title.
  ///
  /// In en, this message translates to:
  /// **'Build a daily streak'**
  String get onboardingTitle3;

  /// Third onboarding card body.
  ///
  /// In en, this message translates to:
  /// **'Play every day to keep your streak alive — bigger streaks unlock bigger rewards!'**
  String get onboardingBody3;

  /// Skip the intro.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Advance to the next onboarding card.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Final onboarding CTA.
  ///
  /// In en, this message translates to:
  /// **'Let’s play!'**
  String get onboardingGotIt;

  /// Title for survival mode.
  ///
  /// In en, this message translates to:
  /// **'Survival Mode'**
  String get survivalTitle;

  /// Survival intro text.
  ///
  /// In en, this message translates to:
  /// **'One life. Endless questions. How far can you go?'**
  String get survivalIntro;

  /// Best score label.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get survivalBest;

  /// Start survival button.
  ///
  /// In en, this message translates to:
  /// **'Start Survival'**
  String get survivalStart;

  /// Survival new best heading.
  ///
  /// In en, this message translates to:
  /// **'New best!'**
  String get survivalNewBest;

  /// Survival game over heading.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get survivalGameOver;

  /// Coin reward suffix.
  ///
  /// In en, this message translates to:
  /// **'coins earned'**
  String get survivalReward;

  /// Home navigation button.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeButton;

  /// Boss round title.
  ///
  /// In en, this message translates to:
  /// **'Boss Round'**
  String get bossTitle;

  /// Boss intro text.
  ///
  /// In en, this message translates to:
  /// **'5 toughest questions. 1 life. Triple coin reward!'**
  String get bossIntro;

  /// Start boss button.
  ///
  /// In en, this message translates to:
  /// **'Face the Boss'**
  String get bossStart;

  /// Boss win heading.
  ///
  /// In en, this message translates to:
  /// **'Boss defeated!'**
  String get bossWin;

  /// Boss loss heading.
  ///
  /// In en, this message translates to:
  /// **'The boss won this round'**
  String get bossLoss;

  /// Home tile for Survival.
  ///
  /// In en, this message translates to:
  /// **'Survival'**
  String get homeSurvivalTitle;

  /// Home tile subtitle for Survival.
  ///
  /// In en, this message translates to:
  /// **'One life. Endless questions.'**
  String get homeSurvivalSubtitle;

  /// Home tile for Boss.
  ///
  /// In en, this message translates to:
  /// **'Boss Round'**
  String get homeBossTitle;

  /// Home tile subtitle for Boss.
  ///
  /// In en, this message translates to:
  /// **'5 hard questions. Triple reward.'**
  String get homeBossSubtitle;

  /// Shown on the flags screen when the regions list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Error loading regions'**
  String get errorLoadingRegions;

  /// Settings toggle label.
  ///
  /// In en, this message translates to:
  /// **'Dyslexia-friendly font'**
  String get settingsDyslexiaFriendlyFont;

  /// Settings toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use OpenDyslexic-style spacing'**
  String get settingsDyslexiaFriendlyFontDesc;

  /// Settings toggle label.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get settingsLargerText;

  /// Settings toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bigger letters across the whole app'**
  String get settingsLargerTextDesc;

  /// Settings toggle label.
  ///
  /// In en, this message translates to:
  /// **'Shorter rounds'**
  String get settingsShorterRounds;

  /// Settings toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Default to 3-question rounds'**
  String get settingsShorterRoundsDesc;

  /// Settings toggle label.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get settingsLightTheme;

  /// Settings toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch the whole app to a light look'**
  String get settingsLightThemeDesc;

  /// Settings toggle for text-to-speech narration.
  ///
  /// In en, this message translates to:
  /// **'Read questions aloud'**
  String get settingsReadAloud;

  /// Tooltip on the TTS button that narrates the current question.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get ttsButtonTooltip;

  /// Generic 'go back' label for screen-reader tooltips on back-arrow IconButtons across the app.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Title of the parent zone entry tile.
  ///
  /// In en, this message translates to:
  /// **'Parent area'**
  String get parentArea;

  /// Header on the parent dashboard screen.
  ///
  /// In en, this message translates to:
  /// **'Parent dashboard'**
  String get parentDashboard;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Reset profile'**
  String get parentResetProfile;

  /// Body text under the reset profile section.
  ///
  /// In en, this message translates to:
  /// **'Wipes all on-device learning data: stars, XP, coins, skill estimates, mistakes, favorites, and shop items. Cannot be undone.'**
  String get parentResetProfileDescription;

  /// Button — confirms reset.
  ///
  /// In en, this message translates to:
  /// **'Reset everything'**
  String get parentResetEverything;

  /// Confirmation dialog title for full reset.
  ///
  /// In en, this message translates to:
  /// **'Reset all data?'**
  String get parentResetConfirmTitle;

  /// Confirmation dialog body for full reset.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes everything stored on this device. Are you sure?'**
  String get parentResetConfirmBody;

  /// Confirmation dialog 'reset' action.
  ///
  /// In en, this message translates to:
  /// **'Yes, reset'**
  String get parentResetConfirmYes;

  /// Snackbar after successful reset.
  ///
  /// In en, this message translates to:
  /// **'Profile reset.'**
  String get parentResetSuccess;

  /// Section header showing this-week stats.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get parentThisWeek;

  /// Section header showing skill breakdown by topic.
  ///
  /// In en, this message translates to:
  /// **'Skill by topic'**
  String get parentSkillByTopic;

  /// Snackbar when a kid tries to buy a shop item they can't afford.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins yet — keep playing!'**
  String get shopNotEnoughCoins;

  /// Shop tile CTA when an item is currently equipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get shopEquipped;

  /// Shop tile CTA when an item is owned but not equipped.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get shopEquip;

  /// Surprise-me flash snackbar before navigating to a random module.
  ///
  /// In en, this message translates to:
  /// **'🎲 Heading to {destination}!'**
  String surpriseGoingTo(String destination);

  /// Snackbar shown when a learner gets a previously-missed IQ question right on retry.
  ///
  /// In en, this message translates to:
  /// **'You got it! Better than last time.'**
  String get iqComebackSnack;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — got it.'**
  String get feedbackThanks;

  /// Math-gate prompt shown on the parent-area lock screen.
  ///
  /// In en, this message translates to:
  /// **'Solve to enter:  {a} + {b} = ?'**
  String parentGatePrompt(int a, int b);

  /// Button label on the parent-area math gate.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get parentGateUnlock;

  /// Error text under the parent-area math gate when answer is wrong.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get parentGateTryAgain;

  /// Heading on parent dashboard listing the kid's hot mistake patterns.
  ///
  /// In en, this message translates to:
  /// **'Where they\'re stuck'**
  String get parentStuckHeading;

  /// Row format under the 'Where they're stuck' section.
  ///
  /// In en, this message translates to:
  /// **'• {module} — {category} ({count} misses)'**
  String parentStuckRow(String module, String category, int count);

  /// Heading inside the parent-dashboard privacy footer note.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get parentPrivacyHeading;

  /// Body of the parent-dashboard privacy footer note.
  ///
  /// In en, this message translates to:
  /// **'All learning data shown here lives on this device only. Nothing is uploaded. Reset from Settings » Reset profile if needed.'**
  String get parentPrivacyNote;

  /// Title on the Maps game intro screen.
  ///
  /// In en, this message translates to:
  /// **'Map explorer'**
  String get mapsIntroTitle;

  /// Subtitle on the Maps game intro screen.
  ///
  /// In en, this message translates to:
  /// **'Find countries by their location on the map. Ready for the challenge?'**
  String get mapsIntroBody;

  /// CTA on the Maps intro that starts the quiz.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get mapsIntroStart;

  /// Feedback dialog title after a correct Maps answer.
  ///
  /// In en, this message translates to:
  /// **'✅ Correct!'**
  String get mapsCorrectTitle;

  /// Feedback dialog title after a wrong Maps answer.
  ///
  /// In en, this message translates to:
  /// **'❌ Wrong answer'**
  String get mapsIncorrectTitle;

  /// Reveals the correct country in the Maps feedback dialog.
  ///
  /// In en, this message translates to:
  /// **'The country is: {country}'**
  String mapsAnswerReveal(String country);

  /// Button in a quiz feedback dialog/screen to advance to the next question.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get quizNextQuestion;

  /// Loading-state caption shown while a quiz pool is being fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading quiz…'**
  String get quizLoading;

  /// Secondary CTA on a game-over screen that returns to the module's menu.
  ///
  /// In en, this message translates to:
  /// **'Back to menu'**
  String get quizBackToMenu;

  /// Label above the round-final score on a game-over overlay.
  ///
  /// In en, this message translates to:
  /// **'This round\'s score'**
  String get quizRoundScore;

  /// Capitals quiz fallback button that switches from type-in mode to multiple-choice.
  ///
  /// In en, this message translates to:
  /// **'Show answer options'**
  String get capitalsRevealChoices;

  /// Madrasati quiz post-score button to start the quiz over.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get madrasatiRestart;

  /// Madrasati quiz post-score button that returns to the Madrasati feature home (kept as the proper-noun brand name in both locales).
  ///
  /// In en, this message translates to:
  /// **'Madrasati'**
  String get madrasatiHome;

  /// Button on the final question that advances to the result screen.
  ///
  /// In en, this message translates to:
  /// **'Show result'**
  String get quizShowResult;

  /// Score line on the Madrasati post-quiz result screen.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / {total}'**
  String madrasatiResultScore(String score, String total);

  /// Default subtitle on the post-quiz victory overlay shared across modules.
  ///
  /// In en, this message translates to:
  /// **'You crushed the quiz! 🎉'**
  String get victoryDefaultSubtitle;

  /// Victory-overlay tally line under the score pill.
  ///
  /// In en, this message translates to:
  /// **'Correct: {score}  •  Wrong: {wrong}'**
  String victoryScoreLine(int score, int wrong);

  /// Encouragement line for a 3-star victory (no lives lost).
  ///
  /// In en, this message translates to:
  /// **'⚡ Total mastery! Zero mistakes!'**
  String get victoryStarsPerfect;

  /// Encouragement line for a 2-star victory.
  ///
  /// In en, this message translates to:
  /// **'👍 Excellent! Nearly perfect!'**
  String get victoryStarsExcellent;

  /// Encouragement line for a 1-star (or fallback) victory.
  ///
  /// In en, this message translates to:
  /// **'✅ Well done! Keep practicing!'**
  String get victoryStarsGood;

  /// Victory-overlay primary CTA that opens the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share achievement'**
  String get victoryShareAchievement;

  /// Text shared to social/IM when a kid taps the share button on the post-quiz victory overlay. Concatenated under the module title in the share payload.
  ///
  /// In en, this message translates to:
  /// **'{score}/{total} correct  •  {wrong} wrong\nStars: {stars}/3 ⭐'**
  String victoryShareBody(int score, int total, int wrong, int stars);

  /// Default text body shared alongside an exported certificate image.
  ///
  /// In en, this message translates to:
  /// **'Certificate from Aziz Academy 🌟'**
  String get certificateShareText;

  /// Default text body shared alongside an exported parent progress report image.
  ///
  /// In en, this message translates to:
  /// **'Aziz Academy progress report'**
  String get progressReportShareText;

  /// Fallback display name when a kid skips the name field in onboarding. Stored persistently in the profile, so it shows up on the home greeting and any place the display name renders later.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get onboardingDefaultName;

  /// Label on the home XP header showing the kid's current level.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelLabel(String n);

  /// XP progress text on the home XP header (e.g. "120 / 250 XP").
  ///
  /// In en, this message translates to:
  /// **'{current} / {needed} XP'**
  String levelXpProgress(String current, String needed);

  /// Total-XP indicator when the kid has hit the max level.
  ///
  /// In en, this message translates to:
  /// **'{total} XP'**
  String levelMaxXp(String total);

  /// Caption shown under the XP bar when the kid is at the highest level.
  ///
  /// In en, this message translates to:
  /// **'Max Level!'**
  String get levelMaxBanner;

  /// Caption under the XP bar showing the next level and lifetime XP total.
  ///
  /// In en, this message translates to:
  /// **'Next: Level {n}  •  {total} XP total'**
  String levelNextInfo(String n, String total);

  /// Title on the Maps game-over screen.
  ///
  /// In en, this message translates to:
  /// **'Challenge complete!'**
  String get mapsGameOverTitle;

  /// Score line on the Maps game-over screen.
  ///
  /// In en, this message translates to:
  /// **'Your score: {score}'**
  String mapsScore(String score);
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
