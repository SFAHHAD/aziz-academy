import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

extension BadgeIdStrings on AppLocalizations {
  String badgeName(BadgeId id) {
    switch (id) {
      case BadgeId.capitalsExplorer:
        return badge_capitals_explorer_name;
      case BadgeId.capitalsExpert:
        return badge_capitals_expert_name;
      case BadgeId.mapMaster:
        return badge_map_master_name;
      case BadgeId.logoDetective:
        return badge_logo_detective_name;
      case BadgeId.logoHunter:
        return badge_logo_hunter_name;
      case BadgeId.triviaTitan:
        return badge_trivia_titan_name;
      case BadgeId.scienceGenius:
        return badge_science_genius_name;
      case BadgeId.mathChampion:
        return badge_math_champion_name;
      case BadgeId.perfectScholar:
        return badge_perfect_scholar_name;
      case BadgeId.academyStar:
        return badge_academy_star_name;
    }
  }

  String badgeSubtitle(BadgeId id) {
    switch (id) {
      case BadgeId.capitalsExplorer:
        return badge_capitals_explorer_desc;
      case BadgeId.capitalsExpert:
        return badge_capitals_expert_desc;
      case BadgeId.mapMaster:
        return badge_map_master_desc;
      case BadgeId.logoDetective:
        return badge_logo_detective_desc;
      case BadgeId.logoHunter:
        return badge_logo_hunter_desc;
      case BadgeId.triviaTitan:
        return badge_trivia_titan_desc;
      case BadgeId.scienceGenius:
        return badge_science_genius_desc;
      case BadgeId.mathChampion:
        return badge_math_champion_desc;
      case BadgeId.perfectScholar:
        return badge_perfect_scholar_desc;
      case BadgeId.academyStar:
        return badge_academy_star_desc;
    }
  }

  String badgeCondition(BadgeId id) {
    switch (id) {
      case BadgeId.capitalsExplorer:
        return badge_capitals_explorer_condition;
      case BadgeId.capitalsExpert:
        return badge_capitals_expert_condition;
      case BadgeId.mapMaster:
        return badge_map_master_condition;
      case BadgeId.logoDetective:
        return badge_logo_detective_condition;
      case BadgeId.logoHunter:
        return badge_logo_hunter_condition;
      case BadgeId.triviaTitan:
        return badge_trivia_titan_condition;
      case BadgeId.scienceGenius:
        return badge_science_genius_condition;
      case BadgeId.mathChampion:
        return badge_math_champion_condition;
      case BadgeId.perfectScholar:
        return badge_perfect_scholar_condition;
      case BadgeId.academyStar:
        return badge_academy_star_condition;
    }
  }
}
