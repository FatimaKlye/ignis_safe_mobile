import 'package:flutter/widgets.dart';

const Map<String, Map<String, String>> _strings = {
  'app_title': {
    'en': 'Ignis Safe',
    'tl': 'Ignis Safe',
  },
  'language': {
    'en': 'Language',
    'tl': 'Wika',
  },
  'english': {
    'en': 'English',
    'tl': 'Ingles',
  },
  'tagalog': {
    'en': 'Tagalog',
    'tl': 'Tagalog',
  },
  'language_change_note_title': {
    'en': 'Note',
    'tl': 'Paalala',
  },
  'language_change_note_message': {
    'en': 'You can only change the app language before logging in. To change language again, please log out, select another language, then log in again.',
    'tl': 'Maaari mo lang palitan ang wika ng app bago mag-login. Para palitan muli ang wika, mag-log out muna, pumili ng ibang wika, pagkatapos ay mag-login ulit.',
  },
  'login': {
    'en': 'Login',
    'tl': 'Mag-login',
  },
  'welcome_to_ignis_safe': {
    'en': 'Welcome to, IGNIS SAFE',
    'tl': 'Mabuhay, IGNIS SAFE',
  },
  'email_address': {
    'en': 'EMAIL ADDRESS:',
    'tl': 'EMAIL ADDRESS:',
  },
  'enter_email': {
    'en': 'Enter your email address',
    'tl': 'Ilagay ang iyong email address',
  },
  'password': {
    'en': 'PASSWORD:',
    'tl': 'PASSWORD:',
  },
  'enter_password': {
    'en': 'Enter your password',
    'tl': 'Ilagay ang iyong password',
  },
  'show': {
    'en': 'SHOW',
    'tl': 'IPAKITA',
  },
  'hide': {
    'en': 'HIDE',
    'tl': 'ITAGO',
  },
  'forgot_password': {
    'en': 'Forgot Password?',
    'tl': 'Nakalimutan ang Password?',
  },
  'or': {
    'en': 'OR',
    'tl': 'O',
  },
  'no_account': {
    'en': "Don't have an account?",
    'tl': 'Wala ka pang account?',
  },
  'sign_up': {
    'en': 'Sign Up',
    'tl': 'Mag-sign up',
  },
  'terms_privacy': {
    'en': 'Terms and Conditions and Privacy Policy.',
    'tl': 'Mga Tuntunin at Kundisyon at Patakaran sa Privacy.',
  },
  'email_required': {
    'en': 'Email is required',
    'tl': 'Kailangan ang email',
  },
  'email_invalid': {
    'en': 'Enter a valid email',
    'tl': 'Maglagay ng wastong email',
  },
  'password_required': {
    'en': 'Password is required',
    'tl': 'Kailangan ang password',
  },
  'password_min_8': {
    'en': 'Password must be at least 8 characters',
    'tl': 'Ang password ay dapat may hindi bababa sa 8 character',
  },
  'login_failed': {
    'en': 'Login failed.',
    'tl': 'Hindi nagtagumpay ang pag-login.',
  },
  'login_success': {
    'en': 'Login successful.',
    'tl': 'Matagumpay ang pag-login.',
  },
  'unexpected_error': {
    'en': 'Unexpected error.',
    'tl': 'May hindi inaasahang error.',
  },
  'google_signin_failed': {
    'en': 'Google sign-in failed.',
    'tl': 'Hindi nagtagumpay ang Google sign-in.',
  },
  'must_accept_terms': {
    'en': 'You must read and agree to the Terms and Conditions before logging in.',
    'tl': 'Kailangan mong basahin at tanggapin ang Mga Tuntunin at Kundisyon bago mag-login.',
  },
  'account_deactivated': {
    'en': 'Your account has been deactivated. Please contact an administrator.',
    'tl': 'Ang iyong account ay na-deactivate. Mangyaring makipag-ugnayan sa isang administrator.',
  },
  'mobile_access_not_enabled': {
    'en': 'Your account is not active. Please contact your administrator.',
    'tl': 'Hindi active ang iyong account. Makipag-ugnayan sa iyong administrator.',
  },
  'terms_accepted': {
    'en': 'Terms accepted.',
    'tl': 'Tinanggap ang mga tuntunin.',
  },
  'learn': {
    'en': 'Learn',
    'tl': 'Aralin',
  },
  'fire_module': {
    'en': 'Fire Module',
    'tl': 'Modulong Sunog',
  },
  'profile': {
    'en': 'Profile',
    'tl': 'Profile',
  },
  'about': {
    'en': 'About',
    'tl': 'Tungkol',
  },
  'refresh_and_check_updates': {
    'en': 'Refresh & Check Updates',
    'tl': 'I-refresh at Tingnan ang Updates',
  },
  'log_out': {
    'en': 'Log Out',
    'tl': 'Mag-logout',
  },
  'welcome_to_ignis_safe_short': {
    'en': 'Welcome to Ignis Safe',
    'tl': 'Mabuhay, Ignis Safe',
  },
  'learning_materials': {
    'en': 'Learning Materials',
    'tl': 'Materyal sa Pag-aaral',
  },
  'fire_scenario_module': {
    'en': 'Fire Scenario',
    'tl': 'Senaryo ng Sunog',
  },
  'search': {
    'en': 'Search',
    'tl': 'Maghanap',
  },
  'filter': {
    'en': 'Filter',
    'tl': 'Salain',
  },
  'view': {
    'en': 'View',
    'tl': 'Tingnan',
  },
  'all': {
    'en': 'All',
    'tl': 'Lahat',
  },
  'pending_not_started': {
    'en': 'Pending / Not Started',
    'tl': 'Nakahinto / Hindi pa nasisimulan',
  },
  'in_progress': {
    'en': 'In Progress',
    'tl': 'Kasalukuyang ginagawa',
  },
  'completed': {
    'en': 'Completed',
    'tl': 'Nakumpleto',
  },
  'pre_assessment': {
    'en': 'PRE -\nASSESSMENT',
    'tl': 'PAUNANG -\nPAGSUSULIT',
  },
  'simulation': {
    'en': 'SIMULATION',
    'tl': 'SIMULASYON',
  },
  'post_assessment': {
    'en': 'POST -\nASSESSMENT',
    'tl': 'PANGHULING -\nPAGSUSULIT',
  },
  'simulation_required': {
    'en': 'Simulation Required',
    'tl': 'Kailangan ang Simulasyon',
  },
  'simulation_required_message': {
    'en': 'You need to finish the simulation first before the post-assessment will open.\n\nThe questions on the post-assessment are connected to the simulation.',
    'tl': 'Kailangan mo munang tapusin ang simulasyon bago mabuksan ang panghuling pagsusulit.\n\nAng mga tanong sa panghuling pagsusulit ay konektado sa simulasyon.',
  },
  'ok': {
    'en': 'OK',
    'tl': 'Sige',
  },
  'hi': {
    'en': 'Hi!',
    'tl': 'Kumusta!',
  },
  'hi_name': {
    'en': 'Hi, {name}',
    'tl': 'Kumusta, {name}',
  },
  'module_1': {
    'en': 'MODULE 1',
    'tl': 'MODYUL 1',
  },
  'module_2': {
    'en': 'MODULE 2',
    'tl': 'MODYUL 2',
  },
  'module_3': {
    'en': 'MODULE 3',
    'tl': 'MODYUL 3',
  },
  'module_4': {
    'en': 'MODULE 4',
    'tl': 'MODYUL 4',
  },
  'module_5': {
    'en': 'MODULE 5',
    'tl': 'MODYUL 5',
  },
  'module_1_full_title': {
    'en': 'Module 1: Fire Extinguisher: Safe Use and Emergency Response',
    'tl': 'Modyul 1: Pamatay-Sunog: Ligtas na Paggamit at Pagtugon sa Emergency',
   },
  'module_1_full_header': {
    'en': 'Fire Extinguisher: Basics, Types, and Proper Use',
    'tl': 'Pamatay-Sunog: Mga Batayan, Uri, at Tamang Paggamit',
  },
  'module_2_full_title': {
    'en': 'Module 2: House Fire: How to Get Out Safely During a Fire',
    'tl': 'Modyul 2: Sunog sa Bahay: Paano Ligtas na Makalabas Habang May Sunog',
  },
  'module_2_full_header': {
    'en': 'House Fire: How to Get Out Safely During a Fire',
    'tl': 'Sunog sa Bahay: Paano Ligtas na Makalabas Habang May Sunog',
  },
  'module_3_full_title': {
    'en': 'Module 3: Electrical Fire: Causes, Safe Actions, and Prevention',
    'tl': 'Modyul 3: Sunog sa Kuryente: Mga Sanhi, Ligtas na Gawain, at Pag-iwas',
  },
  'module_3_full_header': {
    'en': 'Electrical Fire: Causes, Safe Actions, and Prevention',
    'tl': 'Sunog sa Kuryente: Mga Sanhi, Ligtas na Gawain, at Pag-iwas',
  },
  'module_4_full_title': {
    'en': 'Module 4: Kitchen Fire: What It Is, Common Types, and What To Do',
    'tl': 'Modyul 4: Sunog sa Kusina: Ano Ito, Karaniwang Uri, at Ano ang Dapat Gawin',
  },
  'module_4_full_header': {
    'en': 'Kitchen Fire: What It Is, Common Types, and What To Do',
    'tl': 'Sunog sa Kusina: Ano Ito, Karaniwang Uri, at Ano ang Dapat Gawin',
  },
  'title_fire_extinguisher': {
    'en': 'FIRE EXTINGUISHER',
    'tl': 'PAMATAY-SUNOG',
  },
  'title_house_fire': {
    'en': 'HOUSE FIRE',
    'tl': 'SUNOG SA BAHAY',
  },
  'title_electrical_fire': {
    'en': 'ELECTRICAL FIRE',
    'tl': 'SUNOG SA KURYENTE',
  },
  'title_kitchen_fire': {
    'en': 'KITCHEN FIRE',
    'tl': 'SUNOG SA KUSINA',
  },
  'title_building_fire': {
    'en': 'BUILDING FIRE',
    'tl': 'SUNOG SA GUSALI',
  },
  'title_tenement_fire': {
    'en': 'TENEMENT FIRE',
    'tl': 'SUNOG SA TENEMENT',
  },
  'desc_m1': {
    'en': 'Learn the proper and safe use of fire extinguishers for effective response during fire emergencies.',
    'tl': 'Alamin ang tama at ligtas na paggamit ng pamatay-sunog para sa epektibong pagtugon sa mga emerhensiyang may sunog.',
  },
  'desc_m2_learning': {
    'en': 'Learn the common causes of house fires and the correct actions to take during a residential fire emergency.',
    'tl': 'Alamin ang karaniwang sanhi ng sunog sa bahay at ang tamang mga hakbang sa oras ng emerhensiya sa tahanan.',
  },
  'desc_m2_fire_modules': {
    'en': 'Learn how household fires begin, recognize home fire hazards, and respond safely and effectively during emergencies at home.',
    'tl': 'Alamin kung paano nagsisimula ang sunog sa bahay, kilalanin ang mga panganib, at tumugon nang ligtas at epektibo sa emerhensiya.',
  },
  'desc_m3_learning': {
    'en': 'Learn how electrical fires occur and the correct actions to take during an electrical fire emergency.',
    'tl': 'Alamin kung paano nagkakaroon ng sunog dahil sa kuryente at ang tamang aksyon sa ganitong emerhensiya.',
  },
  'desc_m3_fire_modules': {
    'en': 'Learn how electrical fires start, identify common hazards, and apply the correct fire safety response for electrical-related incidents.',
    'tl': 'Alamin kung paano nagsisimula ang sunog sa kuryente, tukuyin ang karaniwang panganib, at ilapat ang tamang tugon sa kaligtasan sa sunog.',
  },
  'desc_m4_learning': {
    'en': 'Understand safe cooking practices and proper response to grease and oil fires.',
    'tl': 'Unawain ang ligtas na gawi sa pagluluto at tamang pagtugon sa sunog ng mantika at langis.',
  },
  'desc_m4_fire_modules': {
    'en': 'Understand common kitchen fire risks and learn the proper fire safety practices and emergency response steps in cooking areas.',
    'tl': 'Unawain ang karaniwang panganib ng sunog sa kusina at ang tamang hakbang sa kaligtasan at pagtugon sa emerhensiya.',
  },
  'desc_m5_learning': {
    'en': 'Learn how to respond safely during building fire incidents, including evacuation and hazard awareness.',
    'tl': 'Alamin kung paano tumugon nang ligtas sa sunog sa gusali, kabilang ang paglikas at pag-iwas sa panganib.',
  },
  'desc_m5_fire_modules': {
    'en':
        'Understand building fire risks, evacuation procedures, and the correct fire safety response in larger structures and shared spaces.',
    'tl':
        'Unawain ang panganib ng sunog sa gusali, proseso ng paglikas, at tamang tugon sa kaligtasan sa malalaking istruktura at pinaghahatiang lugar.',
  },


  'module_5_full_title': {
    'en':
        'Module 5: Tenement Fire: What It Is, Common Causes, and What To Do',
    'tl':
        'Modyul 5: Sunog sa Tenement: Ano Ito, Karaniwang Sanhi, at Ano ang Dapat Gawin',
  },
  'module_5_full_header': {
    'en': 'Tenement Fire: What It Is, Common Causes, and What To Do',
    'tl': 'Sunog sa Tenement: Ano Ito, Karaniwang Sanhi, at Ano ang Dapat Gawin',
  },


  'total_attempts_count': {
    'en': 'Total Attempts: {count}',
    'tl': 'Kabuuang Pagsubok: {count}',
  },
  'retakes_count': {
    'en': 'Retakes: {count}',
    'tl': 'Ulit na Pagsubok: {count}',
  },
  'attempt_number': {
    'en': 'Attempt No. {number}',
    'tl': 'Pagsubok Blg. {number}',
  },
  'score_value': {
    'en': 'Score: {score}',
    'tl': 'Iskor: {score}',
  },
  'status_value': {
    'en': 'Status: {status}',
    'tl': 'Katayuan: {status}',
  },
  'submitted_value': {
    'en': 'Submitted: {date}',
    'tl': 'Naipasa: {date}',
  },

  // Generic status text
  'done': {
    'en': 'Done',
    'tl': 'Tapos Na',
  },
  'not_done': {
    'en': 'Not Done',
    'tl': 'Hindi Pa Tapos',
  },
  'status_submitted': {
    'en': 'Submitted',
    'tl': 'Naipasa',
  },
  'status_done': {
    'en': 'Done',
    'tl': 'Tapos Na',
  },
  'status_in_progress': {
    'en': 'In Progress',
    'tl': 'Kasalukuyang Isinasagawa',
  },
  'status_pending': {
    'en': 'Pending',
    'tl': 'Nakahinto',
  },
  'status_cancelled': {
    'en': 'Cancelled',
    'tl': 'Kinansela',
  },

  // Simulation history helper text
  'simulation_history_completed': {
    'en': 'You have completed this simulation.',
    'tl': 'Natapos mo na ang simulasyong ito.',
  },
  'simulation_history_not_completed': {
    'en': 'You have not completed this simulation yet.',
    'tl': 'Hindi mo pa natatapos ang simulasyong ito.',
  },

  // Module history titles and empty states
  'module_history': {
    'en': 'Module History',
    'tl': 'Kasaysayan ng Modyul',
  },
  'no_attempts_yet': {
    'en': 'No attempt yet',
    'tl': 'Wala pang pagsubok',
  },
};

String appText(
  BuildContext context,
  String key, {
  Map<String, String> params = const {},
}) {
  final code = Localizations.localeOf(context).languageCode;
  final values = _strings[key];
  if (values == null) return key;

  var text = values[code] ?? values['en'] ?? key;
  for (final entry in params.entries) {
    text = text.replaceAll('{${entry.key}}', entry.value);
  }
  return text;
}

extension AppTextX on BuildContext {
  String tr(String key, {Map<String, String> params = const {}}) {
    return appText(this, key, params: params);
  }
}
