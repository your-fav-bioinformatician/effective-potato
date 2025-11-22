import 'package:flutter/material.dart';

class AppTranslations {
  final Locale locale;

  AppTranslations(this.locale);

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'UniBridge',
      'splash_subtitle': 'Engineering your future career path.',
      'intro_title': 'Welcome to UniBridge',
      'intro_desc': 'A data-driven assessment to match your profile with optimal university majors.',
      'btn_start': 'INITIALIZE',
      'btn_next': 'NEXT',
      'btn_submit': 'SUBMIT',
      'section_about': 'Demographics',
      'section_studies': 'Academic Profile',
      'section_goals': 'Career Objectives',
      
      // TITLES & LABELS
      'lbl_age': 'Date of Birth',
      'lbl_age_hint': 'User must be between 13 and 50 years old',
      'lbl_gender': 'Biological Sex',
      'lbl_city': 'Residence City',
      'lbl_gpa': 'GPA Score',
      'lbl_career': 'Primary Career Objective',
      'lbl_income': 'Estimated Family Income',
      'lbl_income_hint': 'Please approximate your monthly family income range',
      'lbl_language': 'Primary Language',
      'lbl_hs': 'High School Track',
      'lbl_mbti': 'MBTI Personality Type',
      'lbl_religion': 'Religion / Belief System',
      
      // NOTES
      'note_gpa': 'Note: If you are unsure of your GPA or are a junior student, enter 105 to view all potential options.',
      'note_mbti': 'Don\'t know your type? Take the test at 16personalities.com',
      'link_mbti': 'https://www.16personalities.com/free-personality-test',

      // NEW LOCATION KEYS
      'lbl_prefer_close': 'Prioritize proximity to my location',
      'btn_get_gps': 'Acquire GPS Coordinates',
      'gps_success': 'Coordinates Acquired',
      'gps_error': 'Signal Lost / Permission Denied',
      
      'msg_select_date': 'Birth date required.',
      'loading_text': 'Processing algorithm...',
      'results_title': 'Optimal Matches',
      'results_sub': 'Generated based on your psychometric profile.',
      'feedback_title': 'System Feedback',
      'feedback_submit': 'Submit Report',
      'male': 'Male',
      'female': 'Female',
      'login_msg': 'Authentication Required',
      'username': 'Username',
      'password': 'Password',
      
      // DROPDOWN VALUES
      'Sci': 'Sci',
      'Lit': 'Lit',
      'Arts': 'Arts',
      'Low': 'Low (< 500k)',
      'Medium': 'Medium (500k-1.5M)',
      'High': 'High (> 1.5M)',
      
      // RELIGION
      'Muslim': 'Muslim',
      'Christian': 'Christian',
      'Yazidi': 'Yazidi',
      'Sabean': 'Sabean',
      'Agnostic': 'Agnostic',

      // CAREER GOALS
      'Profit': 'Maximize financial return',
      'Family': 'Family legacy/pride',
      'Dreams': 'Personal self-actualization',
      'Fulfillment': 'Societal contribution/Fulfillment',
    },
    'ar': {
      'app_title': 'يوني بريدج',
      'splash_subtitle': 'هندسة مسارك المهني المستقبلي.',
      'intro_title': 'مرحباً بك في يوني بريدج',
      'intro_desc': 'تقييم مبني على البيانات لمطابقة ملفك الشخصي مع التخصصات الجامعية المثلى.',
      'btn_start': 'بدء النظام',
      'btn_next': 'التالي',
      'btn_submit': 'إرسال البيانات',
      'section_about': 'البيانات الديموغرافية',
      'section_studies': 'الملف الأكاديمي',
      'section_goals': 'الأهداف المهنية',
      
      // TITLES & LABELS
      'lbl_age': 'تاريخ الميلاد',
      'lbl_age_hint': 'يجب أن يكون العمر بين 13 و 50 عاماً',
      'lbl_gender': 'الجنس',
      'lbl_city': 'مدينة الإقامة',
      'lbl_gpa': 'المعدل التراكمي',
      'lbl_career': 'الهدف المهني الأساسي',
      'lbl_income': 'دخل الأسرة التقديري',
      'lbl_income_hint': 'يرجى تقدير نطاق الدخل الشهري للأسرة',
      'lbl_language': 'اللغة الأساسية',
      'lbl_hs': 'الفرع الدراسي',
      'lbl_mbti': 'نمط الشخصية MBTI',
      'lbl_religion': 'الديانة / المعتقد',

      // NOTES
      'note_gpa': 'ملاحظة: إذا كنت غير متأكد من معدلك أو لا تزال طالباً، أدخل 105 للاطلاع على جميع الخيارات المتاحة.',
      'note_mbti': 'لا تعرف نمطك؟ قم بإجراء الاختبار على 16personalities.com',
      'link_mbti': 'https://www.16personalities.com/free-personality-test',
      
      // NEW LOCATION KEYS
      'lbl_prefer_close': 'تفضيل الجامعات القريبة جغرافياً',
      'btn_get_gps': 'تحديد الإحداثيات GPS',
      'gps_success': 'تم تحديد الموقع',
      'gps_error': 'فشل الإشارة / الإذن مرفوض',

      'msg_select_date': 'تاريخ الميلاد مطلوب.',
      'loading_text': 'جاري معالجة الخوارزمية...',
      'results_title': 'النتائج المطابقة',
      'results_sub': 'تم الإنشاء بناءً على ملفك السيكومتري.',
      'feedback_title': 'تقييم النظام',
      'feedback_submit': 'إرسال التقرير',
      'male': 'ذكر',
      'female': 'أنثى',
      'login_msg': 'المصادقة مطلوبة',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',

      // DROPDOWN VALUES
      'Sci': 'علمي',
      'Lit': 'أدبي',
      'Arts': 'فنون',
      'Low': 'منخفض (< 500 ألف)',
      'Medium': 'متوسط (500 ألف - 1.5 مليون)',
      'High': 'مرتفع (> 1.5 مليون)',

      // RELIGION
      'Muslim': 'مسلم',
      'Christian': 'مسيحي',
      'Yazidi': 'إيزيدي',
      'Sabean': 'صابئي',
      'Agnostic': 'لا ديني / آخر',

      // CAREER GOALS
      'Profit': 'تحقيق عائد مادي مجزي',
      'Family': 'فخر العائلة وإرثها',
      'Dreams': 'تحقيق الطموح الشخصي',
      'Fulfillment': 'حياة أكثر إشباعاً ومساهمة',
    },
  };

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String translateBackendText(String? input) {
    if (input == null) return "";
    if (locale.languageCode == 'en') return input;
    
    final Map<String, String> dictionary = {
      "Computer Science": "علوم الحاسوب",
      "High Salary": "راتب مرتفع",
      "Creative": "إبداعي",
      "Low Stress": "ضغط منخفض",
    };

    if (dictionary.containsKey(input)) return dictionary[input]!;
    return input; 
  }
}

class AppLocale extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  void changeLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
}