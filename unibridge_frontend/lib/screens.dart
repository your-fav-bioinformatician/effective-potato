import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; 
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
const List<String> hsTracksBackend = ["Sci", "Lit", "Arts"];
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
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}

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
          color: widget.isPrimary ? TechTheme.neonMagenta.withValues(alpha: 0.2) : TechTheme.deepPurpleBG,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: widget.isPrimary ? TechTheme.neonMagenta : TechTheme.neonCyan, width: 2),
          boxShadow: _isPressed 
            ? [] 
            : [BoxShadow(color: (widget.isPrimary ? TechTheme.neonMagenta : TechTheme.neonCyan).withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(3, 3))],
        ),
        transform: _isPressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.text, style: TechTheme.textTheme.labelLarge?.copyWith(
              color: widget.isPrimary ? TechTheme.neonMagenta : TechTheme.neonCyan,
            )),
            if (widget.icon != null) ...[const SizedBox(width: 8), Icon(widget.icon, color: widget.isPrimary ? TechTheme.neonMagenta : TechTheme.neonCyan, size: 18)]
          ],
        ),
      ),
    );
  }
}

class TechAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const TechAppBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocale>(context);
    final api = Provider.of<UniBridgeApi>(context);
    final t = AppTranslations(loc.locale);
    final isEn = loc.locale.languageCode == 'en';
    
    return AppBar(
      backgroundColor: TechTheme.deepPurpleBG,
      elevation: 0,
      centerTitle: true,
      leading: Navigator.canPop(context) 
        ? IconButton(icon: const Icon(Icons.arrow_back, color: TechTheme.neonCyan), onPressed: () => Navigator.pop(context))
        : null,
      title: title != null 
        ? Text(t.t(title!), style: TechTheme.textTheme.displayMedium?.copyWith(fontSize: 20)) 
        : const Icon(Icons.terminal, color: TechTheme.neonCyan),
      actions: [
        if (api.currentUserId != null)
          IconButton(
            icon: const Icon(Icons.logout, color: TechTheme.neonMagenta, size: 20),
            onPressed: () async {
              await api.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
          ),
        Center(
          child: InkWell(
            onTap: () => loc.changeLocale(isEn ? const Locale('ar') : const Locale('en')),
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TechTheme.cardPurple,
                border: Border.all(color: TechTheme.neonCyan),
                boxShadow: [BoxShadow(color: TechTheme.neonCyan.withValues(alpha: 0.3), blurRadius: 5)]
              ),
              child: Text(isEn ? 'EN' : 'AR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TechTheme.neonCyan)),
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
        color: TechTheme.cardPurple,
        border: Border.all(color: TechTheme.neonMagenta),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        children: [
          Icon(icon, color: TechTheme.neonMagenta, size: 18),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: TechTheme.textTheme.labelLarge?.copyWith(color: TechTheme.neonMagenta)),
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
      child: Text(label, style: TechTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            Icon(isLink ? Icons.link : Icons.info_outline, size: 14, color: isLink ? TechTheme.neonCyan : TechTheme.textSoft),
            const SizedBox(width: 6),
            Expanded(child: Text(text, 
              style: TechTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 12, 
                color: isLink ? TechTheme.neonCyan : TechTheme.textSoft,
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

class LoadingTechWidget extends StatelessWidget { 
  const LoadingTechWidget({super.key}); 
  @override Widget build(BuildContext context) { final t = AppTranslations(Provider.of<AppLocale>(context).locale); return Column(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: TechTheme.neonCyan, strokeWidth: 3)), const SizedBox(height: 24), Text(t.t('loading_text'), style: TechTheme.textTheme.bodyMedium?.copyWith(color: TechTheme.neonMagenta))]); } 
}

// --- MAIN WEB LAYOUT (Replaces NavBar.tsx) ---
class MainWebLayout extends StatefulWidget {
  final Widget child;
  const MainWebLayout({super.key, required this.child});

  @override
  State<MainWebLayout> createState() => _MainWebLayoutState();
}

class _MainWebLayoutState extends State<MainWebLayout> {
  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: TechTheme.deepPurpleBG,
      appBar: const TechAppBar(),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: TechTheme.neonCyan, width: 2)),
                color: TechTheme.cardPurple,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildNavButton(t.t('nav_dashboard'), Icons.dashboard, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardWindow()))),
                  _buildNavButton(t.t('nav_catalog'), Icons.book, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CatalogWindow()))),
                  _buildNavButton(t.t('nav_search'), Icons.search, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchWindow()))),
                  _buildNavButton(t.t('nav_articles'), Icons.article, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ArticlesWindow()))),
                  const Spacer(),
                  _buildNavButton(t.t('auth_title'), Icons.security, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWindow()))),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildNavButton(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: TechTheme.neonMagenta),
      title: Text(title, style: TechTheme.textTheme.bodyLarge?.copyWith(color: TechTheme.readableWhite)),
      onTap: onTap,
      hoverColor: TechTheme.neonCyan.withValues(alpha: 0.1),
    );
  }
}

// --- CORE SCREENS ---

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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final api = Provider.of<UniBridgeApi>(context, listen: false);
    final bool hasValidSession = await api.restoreSession();

    if (!mounted) return;

    if (hasValidSession) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardWindow()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }
  
    @override
    Widget build(BuildContext context) {
      return const Scaffold(
        backgroundColor: TechTheme.deepPurpleBG,
        body: ResponsiveContainer(child: Center(child: LoadingTechWidget())),
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
      backgroundColor: TechTheme.deepPurpleBG,
      appBar: const TechAppBar(), 
      body: ResponsiveContainer(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: TechTheme.cardDecoration,
                child: Column(
                  children: [
                    const Icon(Icons.settings_suggest, size: 60, color: TechTheme.neonMagenta),
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
              const Spacer(),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: TechTheme.neonCyan,
            surface: TechTheme.cardPurple,
          )
        ), 
        child: child!
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _launchMBTI() async {
    const url = 'https://www.16personalities.com/free-personality-test';
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text("Could not launch link")));
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
      const settings = LocationSettings(accuracy: LocationAccuracy.high);
      Position position = await Geolocator.getCurrentPosition(locationSettings: settings);
      setState(() { _lat = position.latitude; _lon = position.longitude; _isLocationLoading = false; _locationStatus = "Success"; });
    } catch (e) { setState(() { _isLocationLoading = false; _locationStatus = "Error"; }); }
  }

  Future<void> _submit(BuildContext context) async {
    if (_isLoading) return; 

    final locale = Provider.of<AppLocale>(context, listen: false).locale;
    final t = AppTranslations(locale);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final api = Provider.of<UniBridgeApi>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.t('msg_select_date'))));
      return;
    }

    if (_preferClose && (_lat == null || _lon == null)) {
      messenger.showSnackBar(const SnackBar(content: Text("GPS required for proximity feature.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
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
        "app_version": "2.5.0-neon",
        "lat": _lat,
        "lon": _lon,
        "prefer_close": _preferClose
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => const QuizScreen()));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red, 
          duration: const Duration(seconds: 5), 
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);

    return Scaffold(
      backgroundColor: TechTheme.deepPurpleBG,
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
                    decoration: const BoxDecoration(color: TechTheme.deepPurpleBG),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_selectedDate == null ? "DD/MM/YYYY" : intl.DateFormat('yyyy-MM-dd').format(_selectedDate!), style: TechTheme.textTheme.bodyLarge),
                      const Icon(Icons.calendar_today, size: 18, color: TechTheme.neonCyan),
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
                  dropdownColor: TechTheme.cardPurple,
                  style: TechTheme.textTheme.bodyLarge,
                  initialValue: _selectedReligion,
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
                  dropdownColor: TechTheme.cardPurple,
                  style: TechTheme.textTheme.bodyLarge,
                  initialValue: _incomeLevel,
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
                          Switch(value: _preferClose, activeThumbColor: TechTheme.neonMagenta, activeTrackColor: TechTheme.cardPurple, inactiveTrackColor: TechTheme.deepPurpleBG, onChanged: (val) => setState(() => _preferClose = val)),
                        ],
                      ),
                      if (_preferClose) ...[
                        const SizedBox(height: 12),
                        _isLocationLoading 
                          ? const LinearProgressIndicator(color: TechTheme.neonCyan, backgroundColor: TechTheme.deepPurpleBG)
                          : TechButton(
                              text: _lat != null ? t.t('gps_success') : t.t('btn_get_gps'),
                              isPrimary: _lat == null,
                              onPressed: _getLocation,
                              icon: Icons.my_location,
                            ),
                         if (_locationStatus != null && _locationStatus != "Success") 
                           Padding(padding: const EdgeInsets.only(top:8), child: Text(_locationStatus!, style: const TextStyle(color: Colors.redAccent))),
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
                  style: TechTheme.textTheme.bodyLarge,
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
                  dropdownColor: TechTheme.cardPurple,
                  style: TechTheme.textTheme.bodyLarge,
                  initialValue: _selectedHS,
                  decoration: TechTheme.inputDecoration(""),
                  items: hsTracksBackend.map((val) => DropdownMenuItem(value: val, child: Text(t.t(val)))).toList(),
                  onChanged: (val) => setState(() => _selectedHS = val!),
                ),

                const SizedBox(height: 16),
                FieldLabel(t.t('lbl_mbti')),
                InfoNote(t.t('note_mbti'), isLink: true, onTap: _launchMBTI),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: TechTheme.cardPurple,
                  style: TechTheme.textTheme.bodyLarge,
                  initialValue: _selectedMBTI,
                  decoration: TechTheme.inputDecoration("Select Type (Optional)"),
                  items: mbtiTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedMBTI = val),
                ),

                const SizedBox(height: 32),
                SectionHeader(title: t.t('section_goals'), icon: Icons.flag),
                
                FieldLabel(t.t('lbl_career')),
                DropdownButtonFormField<String>(
                  dropdownColor: TechTheme.cardPurple,
                  style: TechTheme.textTheme.bodyLarge,
                  initialValue: _selectedCareer,
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
          color: isSelected ? TechTheme.neonCyan.withValues(alpha: 0.2) : TechTheme.deepPurpleBG,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: isSelected ? TechTheme.neonCyan : TechTheme.textSoft),
          boxShadow: isSelected ? [BoxShadow(color: TechTheme.neonCyan.withValues(alpha: 0.4), blurRadius: 8)] : [],
        ),
        alignment: Alignment.center,
        child: Text(label, style: TechTheme.textTheme.bodyLarge?.copyWith(color: isSelected ? TechTheme.neonCyan : TechTheme.textSoft)),
      ),
    );
  }

  Widget _buildDropdown(String currentVal, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      dropdownColor: TechTheme.cardPurple,
      style: TechTheme.textTheme.bodyLarge,
      initialValue: currentVal,
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
    if (q == null || q['status'] == 'completed') { if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWindow())); return; }
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
    final currentLayer = currentQuestion?['layer'];
    
    return Scaffold(
      backgroundColor: TechTheme.deepPurpleBG,
      appBar: const TechAppBar(title: "ASSESSMENT_MODULE"),
      body: ResponsiveContainer(
        child: _isLoading 
          ? const Center(child: LoadingTechWidget()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const LinearProgressIndicator(value: 0.3, backgroundColor: TechTheme.cardPurple, color: TechTheme.neonCyan, minHeight: 4),
                  
                  if (currentLayer != null) ...[
                     const SizedBox(height: 16),
                     Text("[ ACCESSING SYSTEM LAYER: $currentLayer ]", style: TechTheme.textTheme.bodyMedium?.copyWith(color: TechTheme.neonMagenta)),
                  ],
                  
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity, 
                    decoration: TechTheme.cardDecoration, 
                    padding: const EdgeInsets.all(32), 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Text(
                          t.translateBackendText(currentQuestion?['question_data']?['question']), 
                          style: TechTheme.textTheme.displayMedium, 
                          textAlign: TextAlign.center
                        )
                      ]
                    )
                  ).animate().fadeIn().moveY(begin: 20, end: 0),
                  const SizedBox(height: 32),
                  
                  Column(
                    children: List.generate(5, (index) { 
                      final val = 5 - index; 
                      final isSelected = _selectedAnswer == val;
                      final label = t.t('likert_$val');
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAnswer = val),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? TechTheme.neonCyan.withValues(alpha: 0.2) : TechTheme.cardPurple,
                            borderRadius: BorderRadius.circular(0),
                            border: Border.all(color: isSelected ? TechTheme.neonCyan : TechTheme.textSoft),
                            boxShadow: isSelected ? [BoxShadow(color: TechTheme.neonCyan.withValues(alpha: 0.5), blurRadius: 8)] : []
                          ),
                          transform: isSelected ? Matrix4.translationValues(2,0,0) : Matrix4.identity(),
                          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? TechTheme.neonCyan : TechTheme.readableWhite, fontWeight: FontWeight.bold, fontSize: 14))
                        ),
                      ); 
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, child: TechButton(text: t.t('btn_next'), onPressed: _submitAnswer)),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
      ),
    );
  }
}

// 5. Results (Legacy fallback for Mobile/direct routing, usually replaced by Dashboard flow)
class ResultsScreen extends StatefulWidget { 
  const ResultsScreen({super.key}); 
  @override 
  State<ResultsScreen> createState() => _ResultsScreenState(); 
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<dynamic> results = []; 
  bool _isLoading = true;

  @override void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
     final api = Provider.of<UniBridgeApi>(context, listen: false);
     final data = await api.getResults(api.currentUsername ?? "", "");
     if (mounted) setState(() { results = data; _isLoading = false; });
  }

  @override 
  Widget build(BuildContext context) { 
    final t = AppTranslations(Provider.of<AppLocale>(context).locale); 
    return Scaffold(
      backgroundColor: TechTheme.deepPurpleBG, 
      appBar: const TechAppBar(title: "ANALYSIS_REPORT"), 
      body: ResponsiveContainer(
        child: _isLoading 
          ? const Center(child: LoadingTechWidget()) 
          : _buildResultsList(t)
      )
    ); 
  }
  
  Widget _buildResultsList(AppTranslations t) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(24), 
        child: Column(children: [
          Text(t.t('results_title'), style: TechTheme.textTheme.displayMedium), 
          const SizedBox(height: 8), 
          Text(t.t('results_sub'), style: TechTheme.textTheme.bodyMedium)
        ])
      ), 
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24), 
          itemCount: results.length, 
          itemBuilder: (ctx, i) { 
            final item = results[i]; 
            return Container(
              margin: const EdgeInsets.only(bottom: 16), 
              padding: const EdgeInsets.all(20), 
              decoration: TechTheme.cardDecoration, 
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(t.translateBackendText(item['full_name']), style: TechTheme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: TechTheme.neonCyan))), 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                    decoration: BoxDecoration(border: Border.all(color: TechTheme.neonMagenta), color: TechTheme.neonMagenta.withValues(alpha: 0.1)), 
                    child: Text("${(item['score']*100).toInt()}%", style: const TextStyle(fontSize: 12, color: TechTheme.neonMagenta, fontWeight: FontWeight.bold))
                  )
                ]), 
                const SizedBox(height: 8), 
                Text(t.translateBackendText(item['description']), style: TechTheme.textTheme.bodyLarge, maxLines: 3, overflow: TextOverflow.ellipsis)
              ])
            ).animate().fadeIn().moveY(begin: 20, end: 0, delay: Duration(milliseconds: i * 100)); 
          }
        )
      ), 
      Padding(
        padding: const EdgeInsets.all(24), 
        child: TechButton(text: "Feedback", isPrimary: false, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen())))
      )
    ]); 
  }
}

// 6. Feedback
class FeedbackScreen extends StatelessWidget { 
  const FeedbackScreen({super.key}); 
  @override Widget build(BuildContext context) { final t = AppTranslations(Provider.of<AppLocale>(context).locale); return Scaffold(backgroundColor: TechTheme.deepPurpleBG, appBar: const TechAppBar(title: "SYS_FEEDBACK"), body: ResponsiveContainer(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(t.t('feedback_title'), style: TechTheme.textTheme.displayMedium), const SizedBox(height: 40), const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("😡", style: TextStyle(fontSize: 32)), SizedBox(width: 20), Text("😐", style: TextStyle(fontSize: 32)), SizedBox(width: 20), Text("😊", style: TextStyle(fontSize: 32)), SizedBox(width: 20), Text("🤩", style: TextStyle(fontSize: 32))]), const SizedBox(height: 40), SizedBox(width: 200, child: TechButton(text: t.t('feedback_submit'), onPressed: () => Navigator.pop(context)))])))); }
}

// --- NEW WEB WINDOWS ---

// --- DASHBOARD WINDOW (DashboardWindow.tsx equivalent) ---
class DashboardWindow extends StatelessWidget {
  const DashboardWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    
    return MainWebLayout(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.t('nav_dashboard'), style: TechTheme.textTheme.displayMedium),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard("SYSTEM STATUS", "ONLINE", Icons.check_circle),
                    _buildStatCard("MATCHES FOUND", "12", Icons.data_usage),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen())),
                      child: _buildStatCard("PROFILE SCORE", "VIEW RESULTS", Icons.person),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: TechTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: TechTheme.neonMagenta),
          const SizedBox(height: 16),
          Text(title, style: TechTheme.textTheme.bodyMedium?.copyWith(color: TechTheme.neonCyan)),
          const SizedBox(height: 8),
          Text(value, style: TechTheme.textTheme.displayLarge, textAlign: TextAlign.center,),
        ],
      ),
    );
  }
}

// --- SEARCH WINDOW (SearchWindow.tsx equivalent) ---
class SearchWindow extends StatelessWidget {
  const SearchWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    return MainWebLayout(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.t('nav_search'), style: TechTheme.textTheme.displayMedium),
              const SizedBox(height: 32),
              TextField(
                style: TechTheme.textTheme.bodyLarge,
                decoration: TechTheme.inputDecoration(t.t('search_hint')).copyWith(
                  prefixIcon: const Icon(Icons.search, color: TechTheme.neonCyan),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Text("NO QUERIES DETECTED", style: TechTheme.textTheme.bodyMedium),
                ),
              )
            ],
          ).animate().fade(),
        ),
      ),
    );
  }
}

// --- CATALOG WINDOW (CatalogWindow.tsx equivalent) ---
class CatalogWindow extends StatelessWidget {
  const CatalogWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    return MainWebLayout(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.t('catalog_title'), style: TechTheme.textTheme.displayMedium),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: TechTheme.cardDecoration,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("MODULE 0${index + 1}", style: TechTheme.textTheme.bodyLarge?.copyWith(color: TechTheme.neonCyan)),
                          TechButton(text: "VIEW", onPressed: () {}, isPrimary: false),
                        ],
                      ),
                    ).animate().slideX(delay: (index * 100).ms);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ARTICLES WINDOW (ArticlesWindow.tsx equivalent) ---
class ArticlesWindow extends StatelessWidget {
  const ArticlesWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    return MainWebLayout(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.t('articles_title'), style: TechTheme.textTheme.displayMedium),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: TechTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("DATA ENTRY LOG #0${index + 1}", style: TechTheme.textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Text("Encrypted sector data detailing future career trajectories based on algorithm results...", style: TechTheme.textTheme.bodyMedium),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 150).ms);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- AUTH WINDOW (AuthWindow.tsx equivalent extracted from Results) ---
class AuthWindow extends StatefulWidget {
  const AuthWindow({super.key});

  @override
  State<AuthWindow> createState() => _AuthWindowState();
}

class _AuthWindowState extends State<AuthWindow> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isSignupMode = false;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    final api = Provider.of<UniBridgeApi>(context, listen: false);
    
    bool success = _isSignupMode 
        ? await api.signup(_userController.text, _passController.text) 
        : await api.login(_userController.text, _passController.text);

    setState(() => _isLoading = false);
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardWindow()));
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authentication failed. Check credentials.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTranslations(Provider.of<AppLocale>(context).locale);
    
    return MainWebLayout(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(40),
          decoration: TechTheme.cardDecoration,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: TechTheme.neonCyan))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 64, color: TechTheme.neonMagenta),
                  const SizedBox(height: 24),
                  Text(t.t('auth_title'), style: TechTheme.textTheme.displayMedium),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _userController,
                    style: TechTheme.textTheme.bodyLarge,
                    decoration: TechTheme.inputDecoration(t.t('username')),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    style: TechTheme.textTheme.bodyLarge,
                    decoration: TechTheme.inputDecoration(t.t('password')),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: TechButton(
                      text: _isSignupMode ? t.t('auth_register_btn') : t.t('auth_login_btn'), 
                      onPressed: _handleAuth
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isSignupMode = !_isSignupMode),
                    child: Text(
                      _isSignupMode ? "RETURNING USER? LOGIN" : "NEW USER? REGISTER",
                      style: const TextStyle(color: TechTheme.neonCyan),
                    ),
                  ),
                ],
              ).animate().scale(duration: 400.ms),
        ),
      ),
    );
  }
}