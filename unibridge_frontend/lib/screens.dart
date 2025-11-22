import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // For MBTI Link
import 'theme.dart';
import 'localization.dart'; 
import 'api_service.dart';

// --- DATA CONSTANTS ---
const List<String> iraqiCities = [
  "Baghdad", "Basra", "Nineveh", "Erbil", "Kirkuk", "Najaf", "Karbala", 
  "Sulaymaniyah", "Dhi Qar", "Babil", "Anbar", "Maysan", "Diyala", 
  "Wasit", "Salah al-Din", "Muthanna", "Qadisiyah", "Duhok", "Halabja"
];
const List<String> languages = ["Arabic", "Kurdish", "Turkmen"];
const List<String> hsTracksBackend = ["Scientific", "Literary", "Arts"];
const List<String> mbtiTypes = [
  "INTJ", "INTP", "ENTJ", "ENTP", "INFJ", "INFP", "ENFJ", "ENFP",
  "ISTJ", "ISFJ", "ESTJ", "ESFJ", "ISTP", "ISFP", "ESTP", "ESFP"
];
const List<String> religionOptions = ["Muslim", "Christian", "Yazidi", "Sabean", "Agnostic"];
const List<String> careerGoalsBackend = ["Profit", "Family", "Dreams", "Fulfillment"];
const Map<int, String> incomeMap = { 1: 'Low', 2: 'Medium', 3: 'High' };

// --- HELPER WIDGETS ---
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  const ResponsiveContainer({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Center(child: Container(constraints: const BoxConstraints(maxWidth: 600), child: child));
  }
}

// Retro Button with "Clicky" feel
class TechButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  const TechButton({super.key, required this.text, required this.onPressed, this.isPrimary = true, this.icon});
  @override
  State<TechButton> createState() => _TechButtonState();
}

class _TechButtonState extends State<TechButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: widget.isPrimary ? TechTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: TechTheme.textMain, width: 1.5),
          boxShadow: _isPressed 
            ? [] // No shadow when pressed (flat effect)
            : [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(3, 3), blurRadius: 0)],
        ),
        transform: _isPressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.text, style: TechTheme.textTheme.labelLarge?.copyWith(
              color: widget.isPrimary ? Colors.white : TechTheme.textMain,
              letterSpacing: 1.0
            )),
            if (widget.icon != null) ...[const SizedBox(width: 8), Icon(widget.icon, color: widget.isPrimary ? Colors.white : TechTheme.textMain, size: 18)]
          ],
        ),
      ),
    );
  }
}

// New Top Bar with Language Toggle
class TechAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const TechAppBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocale>(context);
    final isEn = loc.locale.languageCode == 'en';
    
    return AppBar(
      backgroundColor: TechTheme.backgroundGrey,
      elevation: 0,
      centerTitle: true,
      leading: Navigator.canPop(context) 
        ? IconButton(icon: const Icon(Icons.arrow_back, color: TechTheme.textMain), onPressed: () => Navigator.pop(context))
        : null,
      title: title != null ? Text(title!, style: TechTheme.textTheme.displayMedium) : const Icon(Icons.terminal, color: TechTheme.textMain),
      actions: [
        Center(
          child: InkWell(
            onTap: () => loc.changeLocale(isEn ? const Locale('ar') : const Locale('en')),
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: TechTheme.textMain),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))]
              ),
              child: Text(isEn ? 'LANG: EN' : 'LANG: AR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TechTheme.textMain)),
            ),
          ),
        )
      ],
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionHeader({super.key, required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: TechTheme.secondaryBlue,
        border: Border.all(color: TechTheme.primaryBlue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: TechTheme.textMain, size: 18),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: TechTheme.textTheme.labelLarge?.copyWith(color: TechTheme.textMain)),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String label;
  const FieldLabel(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 12.0),
      child: Text(label, style: TechTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: TechTheme.textMain)),
    );
  }
}

class InfoNote extends StatelessWidget {
  final String text;
  final bool isLink;
  final VoidCallback? onTap;
  const InfoNote(this.text, {super.key, this.isLink = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: isLink ? onTap : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isLink ? Icons.link : Icons.info_outline, size: 14, color: isLink ? TechTheme.primaryBlue : TechTheme.textSoft),
            const SizedBox(width: 6),
            Expanded(child: Text(text, 
              style: TechTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 12, 
                color: isLink ? TechTheme.primaryBlue : TechTheme.textSoft,
                decoration: isLink ? TextDecoration.underline : null,
                fontStyle: isLink ? FontStyle.italic : FontStyle.normal
              )
            )),
          ],
        ),
      ),
    );
  }
}

// --- SCREENS ---

// 1. Splash
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    });
  }
  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    return Scaffold(
      backgroundColor: TechTheme.backgroundGrey,
      body: ResponsiveContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 2, color: TechTheme.textMain),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(6, 6))]
              ),
              child: const Icon(Icons.terminal, size: 64, color: TechTheme.textMain),
            ).animate().fadeIn().moveY(begin: 20, end: 0),
            const SizedBox(height: 32),
            Text(t.t('app_title'), style: TechTheme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text("[ ${t.t('splash_subtitle')} ]", style: TechTheme.textTheme.bodyMedium?.copyWith(fontFamily: 'RobotoMono')),
            const SizedBox(height: 40),
            const SizedBox(width: 100, child: LinearProgressIndicator(color: TechTheme.textMain, backgroundColor: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// 2. Onboarding
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    return Scaffold(
      backgroundColor: TechTheme.backgroundGrey,
      appBar: const TechAppBar(), // Use custom bar for lang switch
      body: ResponsiveContainer(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: TechTheme.cardDecoration,
                child: Column(
                  children: [
                    const Icon(Icons.settings_suggest, size: 60, color: TechTheme.textMain),
                    const SizedBox(height: 24),
                    Text(t.t('intro_title'), style: TechTheme.textTheme.displayLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(t.t('intro_desc'), style: TechTheme.textTheme.bodyLarge, textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: TechButton(text: "> ${t.t('btn_start')}", icon: Icons.login, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserInitScreen()))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. User Init (Form)
class UserInitScreen extends StatefulWidget {
  const UserInitScreen({super.key});
  @override
  State<UserInitScreen> createState() => _UserInitScreenState();
}
class _UserInitScreenState extends State<UserInitScreen> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _selectedDate;
  String _gender = 'F'; 
  String _selectedCity = iraqiCities[0];
  String _selectedLanguage = languages[0];
  int _incomeLevel = 2; 
  String _selectedHS = hsTracksBackend[0]; 
  String? _selectedMBTI; 
  String _selectedReligion = religionOptions[0];
  String _selectedCareer = careerGoalsBackend[0];

  final _gpaController = TextEditingController();
  
  bool _preferClose = false;
  double? _lat;
  double? _lon;
  bool _isLocationLoading = false;
  String? _locationStatus;
  bool _isLoading = false;

  int get _age {
    if (_selectedDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month || (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) age--;
    return age;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365 * 50)); 
    final lastDate = now.subtract(const Duration(days: 365 * 13));
    
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: lastDate, firstDate: firstDate, lastDate: lastDate,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: TechTheme.primaryBlue)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _launchMBTI() async {
    const url = 'https://www.16personalities.com/free-personality-test';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch link")));
    }
  }

  Future<void> _getLocation() async {
    setState(() { _isLocationLoading = true; _locationStatus = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() { _isLocationLoading = false; _locationStatus = "Service Disabled"; }); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { setState(() { _isLocationLoading = false; _locationStatus = "Permission Denied"; }); return; }
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _lat = position.latitude; _lon = position.longitude; _isLocationLoading = false; _locationStatus = "Success"; });
    } catch (e) { setState(() { _isLocationLoading = false; _locationStatus = "Error"; }); }
  }

  Future<void> _submit(BuildContext context) async {
    final t = AppTranslations(Provider.of<AppLocale>(context, listen: false).locale);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('msg_select_date')))); return; }
    
    if (_preferClose && (_lat == null || _lon == null)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GPS required for proximity feature.")));
       return;
    }

    setState(() => _isLoading = true);
    final api = Provider.of<UniBridgeApi>(context, listen: false);
    
    final success = await api.initializeUser({
      "age": _age,
      "gender": _gender,
      "income": _incomeLevel.toString(),
      "city": _selectedCity,
      "religion": _selectedReligion, 
      "language": _selectedLanguage,
      "gpa": double.tryParse(_gpaController.text) ?? 0.0,
      "hs": _selectedHS,
      "mbti": _selectedMBTI ?? "INTJ",
      "career_goal": _selectedCareer, 
      "app_version": "2.5.0-retro",
      "lat": _lat,
      "lon": _lon,
      "prefer_close": _preferClose
    });

    setState(() => _isLoading = false);
    if (success && mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
    else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Error. Check connection.")));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);

    return Scaffold(
      backgroundColor: TechTheme.backgroundGrey,
      appBar: const TechAppBar(title: "USER_PROFILE_V1"),
      body: ResponsiveContainer(
        child: _isLoading ? const Center(child: LoadingTechWidget()) : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: t.t('section_about'), icon: Icons.account_circle),
                
                FieldLabel(t.t('lbl_age')),
                InfoNote(t.t('lbl_age_hint')),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: TechTheme.cardDecoration,
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_selectedDate == null ? "DD/MM/YYYY" : intl.DateFormat('yyyy-MM-dd').format(_selectedDate!), style: TechTheme.textTheme.bodyLarge),
                      const Icon(Icons.calendar_today, size: 18, color: TechTheme.textMain),
                    ]),
                  ),
                ),
                
                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_gender')),
                Row(children: [
                    Expanded(child: _techGenderSelect(t.t('female'), 'F')),
                    const SizedBox(width: 10),
                    Expanded(child: _techGenderSelect(t.t('male'), 'M')),
                ]),
                
                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_city')),
                _buildDropdown(_selectedCity, iraqiCities, (val) => setState(() => _selectedCity = val!)),

                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_religion')),
                DropdownButtonFormField<String>(
                  value: _selectedReligion,
                  decoration: TechTheme.inputDecoration(""),
                  items: religionOptions.map((val) => DropdownMenuItem(value: val, child: Text(t.t(val)))).toList(),
                  onChanged: (val) => setState(() => _selectedReligion = val!),
                ),

                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_language')),
                _buildDropdown(_selectedLanguage, languages, (val) => setState(() => _selectedLanguage = val!)),

                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_income')),
                InfoNote(t.t('lbl_income_hint')),
                DropdownButtonFormField<int>(
                  value: _incomeLevel,
                  decoration: TechTheme.inputDecoration(""),
                  items: incomeMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(t.t(e.value)))).toList(),
                  onChanged: (val) => setState(() => _incomeLevel = val!),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: TechTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(t.t('lbl_prefer_close'), style: TechTheme.textTheme.bodyLarge)),
                          Switch(value: _preferClose, activeColor: TechTheme.primaryBlue, onChanged: (val) => setState(() => _preferClose = val)),
                        ],
                      ),
                      if (_preferClose) ...[
                        const SizedBox(height: 12),
                        _isLocationLoading 
                          ? const LinearProgressIndicator(color: TechTheme.primaryBlue)
                          : TechButton(
                              text: _lat != null ? t.t('gps_success') : t.t('btn_get_gps'),
                              isPrimary: _lat == null,
                              onPressed: _getLocation,
                              icon: Icons.my_location,
                            ),
                         if (_locationStatus != null && _locationStatus != "Success") 
                           Padding(padding: const EdgeInsets.only(top:8), child: Text(_locationStatus!, style: const TextStyle(color: TechTheme.dangerRed))),
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                SectionHeader(title: t.t('section_studies'), icon: Icons.school),
                
                FieldLabel(t.t('lbl_gpa')),
                InfoNote(t.t('note_gpa')),
                TextFormField(
                  controller: _gpaController,
                  decoration: TechTheme.inputDecoration("0.0 - 105.0"),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  validator: (val) {
                    final n = double.tryParse(val ?? "");
                    if (n == null || n < 0 || n > 105) return "Invalid";
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_hs')),
                DropdownButtonFormField<String>(
                  value: _selectedHS,
                  decoration: TechTheme.inputDecoration(""),
                  items: hsTracksBackend.map((val) => DropdownMenuItem(value: val, child: Text(t.t(val)))).toList(),
                  onChanged: (val) => setState(() => _selectedHS = val!),
                ),

                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_mbti')),
                // Clickable Link
                InfoNote(t.t('note_mbti'), isLink: true, onTap: _launchMBTI),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMBTI,
                  decoration: TechTheme.inputDecoration("Select Type (Optional)"),
                  items: mbtiTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedMBTI = val),
                ),

                const SizedBox(height: 32),
                SectionHeader(title: t.t('section_goals'), icon: Icons.flag),
                
                FieldLabel(t.t('lbl_career')),
                DropdownButtonFormField<String>(
                  value: _selectedCareer,
                  decoration: TechTheme.inputDecoration(""),
                  items: careerGoalsBackend.map((val) => DropdownMenuItem(value: val, child: Text(t.t(val)))).toList(),
                  onChanged: (val) => setState(() => _selectedCareer = val!),
                ),
                
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, child: TechButton(text: t.t('btn_next'), onPressed: () => _submit(context))),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _techGenderSelect(String label, String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? TechTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: TechTheme.textMain),
          boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(2,2))],
        ),
        alignment: Alignment.center,
        transform: isSelected ? Matrix4.translationValues(1, 1, 0) : Matrix4.identity(),
        child: Text(label, style: TechTheme.textTheme.bodyLarge?.copyWith(color: isSelected ? Colors.white : TechTheme.textMain)),
      ),
    );
  }

  Widget _buildDropdown(String currentVal, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: currentVal,
      decoration: TechTheme.inputDecoration(""),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}

// 4. Quiz
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}
class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic>? currentQuestion;
  bool _isLoading = true;
  int? _selectedAnswer;
  @override void initState() { super.initState(); _loadNextQuestion(); }
  Future<void> _loadNextQuestion() async {
    setState(() => _isLoading = true);
    final api = Provider.of<UniBridgeApi>(context, listen: false);
    final q = await api.getNextQuestion();
    if (q == null || q['status'] == 'completed') { if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ResultsScreen())); return; }
    if (mounted) setState(() { currentQuestion = q; _selectedAnswer = null; _isLoading = false; });
  }
  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) return;
    final api = Provider.of<UniBridgeApi>(context, listen: false);
    await api.processAnswer(_selectedAnswer!);
    _loadNextQuestion();
  }
  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    return Scaffold(
      backgroundColor: TechTheme.backgroundGrey,
      appBar: const TechAppBar(title: "ASSESSMENT_MODULE"),
      body: ResponsiveContainer(child: _isLoading ? const Center(child: LoadingTechWidget()) : Padding(padding: const EdgeInsets.all(24.0), child: Column(children: [
              LinearProgressIndicator(value: 0.3, backgroundColor: const Color(0xFFE2E8F0), color: TechTheme.primaryBlue, minHeight: 8, borderRadius: BorderRadius.circular(0)),
              const SizedBox(height: 40),
              Expanded(child: Container(width: double.infinity, decoration: TechTheme.cardDecoration, padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t.translateBackendText(currentQuestion?['question_text']), style: TechTheme.textTheme.displayMedium, textAlign: TextAlign.center)])).animate().fadeIn().moveY(begin: 20, end: 0)),
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(5, (index) { final val = index + 1; final isSelected = _selectedAnswer == val; return GestureDetector(onTap: () => setState(() => _selectedAnswer = val), child: AnimatedContainer(duration: const Duration(milliseconds: 100), width: 56, height: 56, decoration: BoxDecoration(color: isSelected ? TechTheme.primaryBlue : Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: TechTheme.textMain), boxShadow: isSelected ? [] : [const BoxShadow(color: Colors.black12, offset: Offset(3,3))]), transform: isSelected ? Matrix4.translationValues(2,2,0) : Matrix4.identity(), child: Center(child: Text("$val", style: TextStyle(color: isSelected ? Colors.white : TechTheme.textMain, fontWeight: FontWeight.bold, fontSize: 20))))); })),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: TechButton(text: t.t('btn_next'), onPressed: _submitAnswer)),
            ]))),
    );
  }
}

// 5. Results
class ResultsScreen extends StatefulWidget { const ResultsScreen({super.key}); @override State<ResultsScreen> createState() => _ResultsScreenState(); }
class _ResultsScreenState extends State<ResultsScreen> {
  final _userController = TextEditingController(); final _passController = TextEditingController(); List<dynamic> results = []; bool _showLogin = true; bool _isLoading = false;
  Future<void> _fetchResults() async { setState(() => _isLoading = true); final api = Provider.of<UniBridgeApi>(context, listen: false); final data = await api.getResults(_userController.text, _passController.text); setState(() { results = data; _showLogin = false; _isLoading = false; }); }
  @override Widget build(BuildContext context) { final t = AppTranslations(Provider.of<AppLocale>(context).locale); return Scaffold(backgroundColor: TechTheme.backgroundGrey, appBar: const TechAppBar(title: "ANALYSIS_REPORT"), body: ResponsiveContainer(child: _isLoading ? const Center(child: LoadingTechWidget()) : _showLogin ? _buildLoginForm(t) : _buildResultsList(t))); }
  Widget _buildLoginForm(AppTranslations t) { return Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock, size: 64, color: TechTheme.textMain), const SizedBox(height: 24), Text(t.t('login_msg'), style: TechTheme.textTheme.displayMedium), const SizedBox(height: 32), TextField(controller: _userController, decoration: TechTheme.inputDecoration(t.t('username'))), const SizedBox(height: 16), TextField(controller: _passController, obscureText: true, decoration: TechTheme.inputDecoration(t.t('password'))), const SizedBox(height: 32), SizedBox(width: double.infinity, child: TechButton(text: t.t('btn_submit'), onPressed: _fetchResults))])); }
  Widget _buildResultsList(AppTranslations t) { return Column(children: [Padding(padding: const EdgeInsets.all(24), child: Column(children: [Text(t.t('results_title'), style: TechTheme.textTheme.displayMedium), Text(t.t('results_sub'), style: TechTheme.textTheme.bodyMedium)])), Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: results.length, itemBuilder: (ctx, i) { final item = results[i]; return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20), decoration: TechTheme.cardDecoration, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(t.translateBackendText(item['full_name']), style: TechTheme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(border: Border.all(color: TechTheme.textMain), borderRadius: BorderRadius.circular(4)), child: Text("${(item['score']*100).toInt()}%", style: const TextStyle(fontSize: 12, color: TechTheme.textMain, fontWeight: FontWeight.bold)))]), const SizedBox(height: 8), Text(t.translateBackendText(item['description']), style: TechTheme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis)])).animate().fadeIn().moveY(begin: 20, end: 0, delay: Duration(milliseconds: i * 100)); })), Padding(padding: const EdgeInsets.all(24), child: TechButton(text: "Feedback", isPrimary: false, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()))))]); }
}

// 6. Feedback
class FeedbackScreen extends StatelessWidget { const FeedbackScreen({super.key}); @override Widget build(BuildContext context) { final t = AppTranslations(Provider.of<AppLocale>(context).locale); return Scaffold(backgroundColor: TechTheme.backgroundGrey, appBar: const TechAppBar(title: "SYS_FEEDBACK"), body: ResponsiveContainer(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t.t('feedback_title'), style: TechTheme.textTheme.displayMedium), const SizedBox(height: 40), Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text("😡", style: TextStyle(fontSize: 32)), SizedBox(width: 20), Text("😐", style: TextStyle(fontSize: 32)), SizedBox(width: 20), Text("😊", style: TextStyle(fontSize: 32)), SizedBox(width: 20), Text("🤩", style: TextStyle(fontSize: 32))]), const SizedBox(height: 40), SizedBox(width: 200, child: TechButton(text: t.t('feedback_submit'), onPressed: () => Navigator.pop(context)))])))); }
}

class LoadingTechWidget extends StatelessWidget { const LoadingTechWidget({super.key}); @override Widget build(BuildContext context) { final t = AppTranslations(Provider.of<AppLocale>(context).locale); return Column(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: TechTheme.primaryBlue, strokeWidth: 3)), const SizedBox(height: 24), Text(t.t('loading_text'), style: TechTheme.textTheme.bodyMedium)]); } }