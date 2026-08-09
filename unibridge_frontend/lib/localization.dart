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
      
      'note_gpa': 'Note: If you are unsure of your GPA or are a junior student, enter 105 to view all potential options.',
      'note_mbti': 'Don\'t know your type? Take the test at 16personalities.com',
      'link_mbti': 'https://www.16personalities.com/free-personality-test',

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
      'other': 'Other',
      'login_msg': 'Authentication Required',
      'username': 'Username',
      'password': 'Password',
      
      'Sci': 'Science',
      'Literary': 'Literature',
      'Arts': 'Arts',
      'Low': 'Low (< 500k)',
      'Medium': 'Medium (500k-1.5M)',
      'High': 'High (> 1.5M)',
      
      'Muslim': 'Muslim',
      'Christian': 'Christian',
      'Yazidi': 'Yazidi',
      'Sabean': 'Sabean',
      'Agnostic': 'Agnostic',

      'Profit': 'Maximize financial return',
      'Family': 'Family legacy/pride',
      'Dreams': 'Personal self-actualization',
      'Fulfillment': 'Societal contribution/Fulfillment',

      // LIKERT SCALE
      'likert_1': 'Strongly Disagree',
      'likert_2': 'Disagree',
      'likert_3': 'Neutral',
      'likert_4': 'Agree',
      'likert_5': 'Strongly Agree',

      // Screen Titles
      'USER_PROFILE_V1': 'USER_PROFILE_V1',
      'ASSESSMENT_MODULE': 'ASSESSMENT_MODULE',
      'ANALYSIS_REPORT': 'ANALYSIS_REPORT',
      'SYS_FEEDBACK': 'SYS_FEEDBACK',
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

      'note_gpa': 'ملاحظة: إذا كنت غير متأكد من معدلك أو لا تزال طالباً، أدخل 105 للاطلاع على جميع الخيارات المتاحة.',
      'note_mbti': 'لا تعرف نمطك؟ قم بإجراء الاختبار على 16personalities.com',
      'link_mbti': 'https://www.16personalities.com/free-personality-test',
      
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
      'other': 'آخر',
      'login_msg': 'المصادقة مطلوبة',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',

      'Sci': 'علمي',
      'Lit': 'أدبي',
      'Arts': 'فنون',
      'Low': 'منخفض (< 500 ألف)',
      'Medium': 'متوسط (500 ألف - 1.5 مليون)',
      'High': 'مرتفع (> 1.5 مليون)',

      'Muslim': 'مسلم',
      'Christian': 'مسيحي',
      'Yazidi': 'إيزيدي',
      'Sabean': 'صابئي',
      'Agnostic': 'لا ديني / آخر',

      'Profit': 'تحقيق عائد مادي مجزي',
      'Family': 'فخر العائلة وإرثها',
      'Dreams': 'تحقيق الطموح الشخصي',
      'Fulfillment': 'حياة أكثر إشباعاً ومساهمة',

      // LIKERT SCALE
      'likert_1': 'أعارض بشدة',
      'likert_2': 'أعارض',
      'likert_3': 'محايد',
      'likert_4': 'أوافق',
      'likert_5': 'أوافق بشدة',

      // Screen Titles
      'USER_PROFILE_V1': 'ملف المستخدم V1',
      'ASSESSMENT_MODULE': 'وحدة التقييم',
      'ANALYSIS_REPORT': 'تقرير التحليل',
      'SYS_FEEDBACK': 'نظام التعليقات',
    },
  };

  // --- STATIC DICTIONARY FOR BACKEND QUESTIONS ---
  // EXTRACTED DIRECTLY FROM concept_questions.json TO ENSURE EXACT MATCHES
  static const Map<String, String> _backendTranslations = {
      // ID 1-10
      "I'm definitely more of a math and science person than a humanities type.": "بالتأكيد أنا أميل إلى الرياضيات والعلوم أكثر من الإنسانيات.",
      "I've always leaned more towards the arts and humanities than math or science.": "لطالما كنت أميل إلى الفنون والإنسانيات أكثر من الرياضيات أو العلوم.",
      "The idea of literally saving lives and helping people means everything to me.": "فكرة إنقاذ الأرواح ومساعدة الناس حرفياً تعني لي كل شيء.",
      "I'm a very visual person": "أنا شخص بصري جداً",
      "People fascinate me—I love figuring out what makes us tick as a society.": "يذهلني الناس — أحب معرفة ما يحركنا كمجتمع.",
      "Whenever I'm in a group, I naturally end up taking charge—and honestly, I enjoy it.": "كلما كنت في مجموعة، أجد نفسي طبيعياً أتولى القيادة — وبصراحة، أنا أستمتع بذلك.",
      "I'm the kind of person who actually does math problems for fun.": "أنا من النوع الذي يحل مسائل الرياضيات من أجل المتعة حقاً.",
      "Put me in a lab coat with some pipettes and I'm happy—I absolutely love hands-on lab work.": "احب العمل في المختبر",
      "I'm a total tech geek": "أنا مهووس جداً بالتقنية",
      "I'm usually the \"therapist\" of my friend group. I love trying to understand how the mind works and helping people process their feelings.": "أنا عادة \"المعالج النفسي\" في مجموعة أصدقائي. أحب محاولة فهم كيف يعمل العقل ومساعدة الناس في التعامل مع مشاعرهم.",

      // ID 11-20
      "Look, at the end of the day, I just want a career that pays really well.": "اسمع، في نهاية المطاف، أريد فقط مهنة تدر الكثير من المال.",
      "I write all the time. Journals, essays, random notes—I just love putting words on paper.": "أنا أكتب طوال الوقت. يوميات، مقالات، ملاحظات عشوائية — أحب تدوين الكلمات على الورق وحسب.",
      "I love tinkering in my head, coming up with new gadgets or figuring out how machines are built.": "أحب التفكير العميق، وابتكار أدوات جديدة أو اكتشاف كيف تُبنى الآلات.",
      "I just have a natural feel for aesthetics—colors, layouts, and how things look together.": "لدي فقط حس طبيعي بالجماليات — الألوان، والتخطيطات، وكيف تبدو الأشياء معاً.",
      "Picking up new languages just clicks for me": "تعلم لغات جديدة يبدو بديهياً وسهلاً بالنسبة لي",
      "I can't stand the idea of being trapped in a cubicle all day": "لا أطيق فكرة أن أكون محبوساً في مقصورة مكتبية طوال اليوم",
      "I'm perfectly fine taking a risk on a passion, even if the job market isn't a guaranteed safe bet.": "أنا بخير تماماً مع المخاطرة من أجل الشغف، حتى لو لم يكن سوق العمل خياراً مضموناً وآمناً.",
      "I need structure. I can't handle chaos": "أحتاج إلى التنظيم. لا أستطيع التعامل مع الفوضى",
      "I get bored doing the exact same thing every day—I need a job that keeps me on my toes.": "أشعر بالملل من فعل نفس الشيء تماماً كل يوم — أحتاج إلى وظيفة تبقيني متيقظاً.",
      "I thrive in a team environment": "أزدهر في بيئة العمل الجماعي",

      // ID 21-30
      "Honestly, I'm a total introvert. I just want to put my headphones in and work completely alone.": "بصراحة، أنا انطوائي تماماً. أريد فقط وضع سماعات الرأس والعمل بمفردي بالكامل.",
      "Bring on the pressure—I actually don't mind a packed schedule and a high-stress environment.": "مرحباً بالضغوط — أنا في الواقع لا أمانع الجدول المزدحم والبيئة عالية التوتر.",
      "Public speaking doesn't scare me at all": "التحدث أمام الجمهور لا يخيفني على الإطلاق",
      "I have really steady hands and love doing hyper-focused, delicate, precise work.": "لدي يدان ثابتتان جداً وأحب القيام بأعمال شديدة التركيز ودقيقة وحساسة.",
      "I'm definitely a hands-on person, whether that's fixing things around the house or building stuff from scratch.": "أنا بالتأكيد شخص عملي، سواء كان ذلك إصلاح الأشياء في المنزل أو بناء الأشياء من الصفر.",
      "I don't mind wading through paperwork or dealing with red tape if it's just part of the job.": "لا أمانع الخوض في الأعمال الورقية أو التعامل مع الروتين المعقد إذا كان ذلك جزءاً من الوظيفة.",
      "I need to know my work matters and is making a real difference in people's lives.": "أحتاج أن أعرف أن عملي يهم ويحدث فرقاً حقيقياً في حياة الناس.",
      "I actually find it super interesting to dive deep into biology and learn exactly how living things function.": "أجد أنه من المثير للاهتمام حقاً التعمق في علم الأحياء ومعرفة كيف تعمل الكائنات الحية بالضبط.",
      "Nothing excites me more than looking through a microscope and studying the tiny building blocks of life.": "لا شيء يثيرني أكثر من النظر عبر المجهر ودراسة اللبنات الأساسية الصغيرة للحياة.",
      "Physics just makes sense to my brain. I love using math to explain how reality actually works.": "الفيزياء تبدو منطقية لعقلي. أحب استخدام الرياضيات لشرح كيف يعمل الواقع حقاً.",

      // ID 31-40
      "Chemistry just clicks for me—balancing equations and predicting reactions feels like second nature.": "الكيمياء تبدو بديهية بالنسبة لي — موازنة المعادلات وتوقع التفاعلات يبدو كطبيعة ثانية لي.",
      "I could spend hours happily lost in code or trying to solve a tough algorithm.": "يمكنني قضاء ساعات سعيداً منغمساً في البرمجة أو محاولة حل خوارزمية صعبة.",
      "I love building stuff, whether it's hacking together a quick prototype or messing around with DIY tech projects.": "أحب بناء الأشياء، سواء كان ذلك تجميع نموذج أولي سريع أو العبث بمشاريع تقنية اصنعها بنفسك (DIY).",
      "Give me a spreadsheet full of data, stats, and graphs, and I'm totally in my element.": "أعطني جدول بيانات مليئاً بالبيانات والإحصائيات والرسوم البيانية، وسأكون في عنصري تماماً.",
      "I genuinely enjoy digging into dense scientific research papers to learn new concepts.": "أستمتع حقاً بالتعمق في الأوراق البحثية العلمية الدسمة لتعلم مفاهيم جديدة.",
      "I think a lot about right and wrong, and I take the ethical consequences of our actions really seriously.": "أفكر كثيراً في الصواب والخطأ، وآخذ العواقب الأخلاقية لأفعالنا على محمل الجد حقاً.",
      "I love getting lost in the weeds of big, abstract ideas, theories, and complex models.": "أحب الغوص في تفاصيل الأفكار الكبيرة والمجردة والنظريات والنماذج المعقدة.",
      "I probably spend way too much time having existential thoughts and wondering about the meaning of life.": "ربما أقضي الكثير من الوقت في التفكير في الوجود والتساؤل حول معنى الحياة.",
      "It's fascinating to me how different religions and belief systems have shaped human history.": "إنه لأمر مذهل بالنسبة لي كيف شكلت الأديان ونظم المعتقدات المختلفة تاريخ البشرية.",
      "I love looking at the big picture of history—like why massive empires rise and eventually collapse.": "أحب النظر إلى الصورة الكبرى للتاريخ — مثل سبب صعود الإمبراطوريات الضخمة وانهيارها في النهاية.",

      // ID 41-50
      "I can argue about politics, government, and how society should be run for hours.": "يمكنني المجادلة حول السياسة والحكومة وكيفية إدارة المجتمع لساعات.",
      "I get a kick out of solving tricky physics problems and just thinking about the mechanics of the universe.": "أستمتع بحل مسائل الفيزياء المخادعة والتفكير فقط في ميكانيكا الكون.",
      "I'm happiest in a chem lab, doing titrations and figuring out exactly what a substance is made of.": "أنا في قمة سعادتي في مختبر الكيمياء، أقوم بالمعايرة واكتشاف مم تتكون المادة بالضبط.",
      "I'm really into building software systems and playing around with the latest AI tech.": "أنا مهتم حقاً ببناء أنظمة البرمجيات واللعب بأحدث تقنيات الذكاء الاصطناعي.",
      "I could literally spend all night talking about philosophy and debating big, unanswerable questions.": "يمكنني حرفياً قضاء الليل كله في التحدث عن الفلسفة ومناقشة الأسئلة الكبيرة التي لا يمكن الإجابة عليها.",
      "I find it super interesting to study sacred texts and see how different cultures practice their rituals.": "أجد أنه من المثير للاهتمام للغاية دراسة النصوص المقدسة ورؤية كيف تمارس الثقافات المختلفة طقوسها.",
      "I love diving deep into moral dilemmas and debating what actually makes people \"good\" or \"evil.\"": "أحب التعمق في المعضلات الأخلاقية ومناقشة ما يجعل الناس حقاً \"أخياراً\" أو \"أشراراً\".",
      "I'm constantly looking at architecture and wondering how cities and buildings are planned out.": "أنا أنظر باستمرار إلى الهندسة المعمارية وأتساءل كيف يتم تخطيط المدن والمباني.",
      "The way electricity, circuits, and electrons work just totally fascinates me.": "طريقة عمل الكهرباء والدوائر والإلكترونات تذهلني تماماً.",
      "I'm obsessed with how machines work—gears, engines, you name it.": "أنا مهووس بكيفية عمل الآلات — التروس، المحركات، وكل ما يتعلق بها.",

      // ID 51-60
      "Anything involving robotics, mechatronics, or automation gets me totally hyped.": "أي شيء يتعلق بالروبوتات أو الميكاترونكس أو الأتمتة يحمسني تماماً.",
      "I'm really curious about what things are made of at a base level and how we can engineer new materials.": "أنا فضولي حقاً بشأن مم تتكون الأشياء على المستوى الأساسي وكيف يمكننا هندسة مواد جديدة.",
      "I think massive industrial chemistry and turning raw materials into new products is incredibly cool.": "أعتقد أن الكيمياء الصناعية الضخمة وتحويل المواد الخام إلى منتجات جديدة أمر رائع بشكل لا يصدق.",
      "The idea of building medical technology and machines that literally keep humans alive is amazing to me.": "فكرة بناء التكنولوجيا الطبية والآلات التي تبقي البشر على قيد الحياة حرفياً مدهشة بالنسبة لي.",
      "Rockets, jets, space exploration—if it flies or goes into orbit, I'm all about it.": "الصواريخ، الطائرات النفاثة، استكشاف الفضاء — إذا كان يطير أو يذهب إلى المدار، فأنا مهتم به تماماً.",
      "I actually think a lot about how cities manage their water, waste, and environmental systems.": "أنا في الواقع أفكر كثيراً في كيفية إدارة المدن لأنظمة المياه والنفايات والبيئة الخاصة بها.",
      "The logistics of massive factories, assembly lines, and industrial automation really appeal to me.": "لوجستيات المصانع الضخمة وخطوط التجميع والأتمتة الصناعية تروق لي حقاً.",
      "I'm super drawn to decoding dead languages, ancient scripts, and historical texts.": "أنا منجذب جداً لفك رموز اللغات الميتة والمخطوطات القديمة والنصوص التاريخية.",
      "I spend a lot of time thinking through tricky moral gray areas, like in medicine or law.": "أقضي الكثير من الوقت في التفكير في المناطق الرمادية الأخلاقية الشائكة، كما هو الحال في الطب أو القانون.",
      "I love putting different worldviews side by side—like Greek philosophy against Eastern religions or Islamic theology—to see how they compare.": "أحب وضع وجهات النظر العالمية المختلفة جنباً إلى جنب — مثل الفلسفة اليونانية مقابل الأديان الشرقية أو اللاهوت الإسلامي — لمعرفة كيف تتقارن.",
  };
  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String translateBackendText(String? input) {
    if (input == null || input.isEmpty) return "";
    
    // Normalize input (trim spaces)
    String cleanInput = input.trim();

    // Return original if English
    if (locale.languageCode == 'en') return cleanInput;
    
    // Check static dictionary with EXACT match
    if (_backendTranslations.containsKey(cleanInput)) {
      return _backendTranslations[cleanInput]!;
    }
    
    // Fallback: Try removing trailing periods if exact match fails
    if (cleanInput.endsWith('.') || cleanInput.endsWith('?')) {
       String noPunct = cleanInput.substring(0, cleanInput.length - 1);
       if (_backendTranslations.containsKey(noPunct)) {
         return _backendTranslations[noPunct]!;
       }
    }
    
    // Fallback: Return original input if translation not found
    return cleanInput; 
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