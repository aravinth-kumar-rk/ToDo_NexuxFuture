// TaskFlow — Flutter to-do app (single file, no extra packages)
// Replace the contents of lib/main.dart with this file, then run:
//   flutter run -d chrome

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const TaskFlowApp());

// ───────────────────────── THEME / COLOURS ─────────────────────────

class C {
  static const bg = Color(0xFF0A0A0A);
  static const panel = Color(0xFF121212);
  static const panel2 = Color(0xFF1B1B1B);
  static const line = Color(0xFF2A2A2A);
  static const white = Color(0xFFF5F5F5);
  static const muted = Color(0xFF8A8A8A);
  static const orange = Color(0xFFFF5A1F);
  static const orangeHover = Color(0xFFFF7A45);
  static const green = Color(0xFF3DDC97);
}

// ───────────────────────── DATA MODELS ─────────────────────────

enum Cat {
  work('Work', Color(0xFF4DA3FF)),
  personal('Personal', Color(0xFFB794F6)),
  gym('Gym', Color(0xFF3DDC97)),
  physical('Physical', Color(0xFFFFC53D)),
  school('School', Color(0xFF2EC4D6));

  const Cat(this.label, this.color);
  final String label;
  final Color color;
}

class Task {
  Task(this.id, this.title, this.cat);
  final String id;
  final String title;
  final Cat cat;
  bool done = false;
}

class TaskPage {
  TaskPage(this.id, this.name);
  final String id;
  String name;
  final List<Task> tasks = [];
}

// ───────────────────────── APP STATE ─────────────────────────

class AppState extends ChangeNotifier {
  bool loggedIn = false;
  String name = '', work = '', hobbies = '', skills = '', email = '';

  final List<TaskPage> pages = [];
  String? currentPageId; // null = Home (quotes)
  bool showProfile = false;

  int created = 0; // every task ever created
  int completed = 0; // every task ever completed
  int _seq = 0;
  String _id() => '${_seq++}';

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  TaskPage? get currentPage =>
      pages.where((p) => p.id == currentPageId).firstOrNull;

  Iterable<Task> get allTasks => pages.expand((p) => p.tasks);
  int get pending => allTasks.where((t) => !t.done).length;

  /// (done, total) for one category, or for everything when [c] is null.
  (int, int) stats(Cat? c) {
    final list = c == null ? allTasks : allTasks.where((t) => t.cat == c);
    final total = list.length;
    final done = list.where((t) => t.done).length;
    return (done, total);
  }

  void login({
    required String name,
    required String work,
    required String hobbies,
    required String skills,
    required String email,
  }) {
    this.name = name;
    this.work = work;
    this.hobbies = hobbies;
    this.skills = skills;
    this.email = email;
    pages
      ..clear()
      ..add(TaskPage(_id(), 'My Tasks'));
    created = 0;
    completed = 0;
    currentPageId = null;
    showProfile = false;
    loggedIn = true;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    notifyListeners();
  }

  void goHome() {
    currentPageId = null;
    showProfile = false;
    notifyListeners();
  }

  void openPage(String id) {
    currentPageId = id;
    showProfile = false;
    notifyListeners();
  }

  void toggleProfile() {
    showProfile = !showProfile;
    notifyListeners();
  }

  void addPage(String pageName) {
    final p = TaskPage(_id(), pageName);
    pages.add(p);
    openPage(p.id);
  }

  void deletePage(String id) {
    pages.removeWhere((p) => p.id == id);
    if (currentPageId == id) currentPageId = null;
    notifyListeners();
  }

  void addTask(TaskPage p, String title, Cat cat) {
    p.tasks.insert(0, Task(_id(), title, cat));
    created++;
    notifyListeners();
  }

  void toggle(Task t) {
    t.done = !t.done;
    completed += t.done ? 1 : -1;
    notifyListeners();
  }

  void removeTask(TaskPage p, Task t) {
    p.tasks.remove(t);
    notifyListeners();
  }
}

final AppState app = AppState();

// ───────────────────────── SMALL HELPERS ─────────────────────────

Widget fadeSlide(Widget child, Animation<double> a) => FadeTransition(
  opacity: a,
  child: SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(a),
    child: child,
  ),
);

Future<T?> slideDialog<T>(BuildContext context, Widget child) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => Center(child: child),
    transitionBuilder: (_, anim, _, c) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: c,
        ),
      );
    },
  );
}

InputDecoration inputDeco(String label, {String? hint, Widget? suffix}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: C.line),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: C.bg,
    labelStyle: const TextStyle(color: C.muted),
    floatingLabelStyle: const TextStyle(color: C.orange),
    hintStyle: const TextStyle(color: Color(0xFF555555)),
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: C.orange, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFFFF3B30)),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFFFF3B30), width: 1.5),
    ),
  );
}

/// Hover + click wrapper used by all custom buttons/tiles.
class Hover extends StatefulWidget {
  const Hover({super.key, required this.builder, this.onTap});
  final Widget Function(bool hovering) builder;
  final VoidCallback? onTap;

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(_h),
      ),
    );
  }
}

class OrangeButton extends StatelessWidget {
  const OrangeButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expand = false,
    this.height = 48,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Hover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: h ? C.orangeHover : C.orange,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades + slides its child in after an optional delay (staggered reveal).
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_a),
        child: widget.child,
      ),
    );
  }
}

class SmallLabel extends StatelessWidget {
  const SmallLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      color: C.muted,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w600,
    ),
  );
}

// ───────────────────────── ROOT APP ─────────────────────────

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        colorScheme: const ColorScheme.dark(
          primary: C.orange,
          surface: C.panel,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: C.orange,
          selectionColor: C.orange.withValues(alpha: 0.3),
        ),
      ),
      home: ListenableBuilder(
        listenable: app,
        builder: (_, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, a) =>
              FadeTransition(opacity: a, child: child),
          child: app.loggedIn
              ? const Shell(key: ValueKey('shell'))
              : const LoginPage(key: ValueKey('login')),
        ),
      ),
    );
  }
}

// ───────────────────────── LOGIN PAGE ─────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _work = TextEditingController();
  final _hobbies = TextEditingController();
  final _skills = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  static final _emailRe = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  @override
  void dispose() {
    for (final c in [_name, _work, _hobbies, _skills, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? 'Please enter $what' : null;

  void _submit() {
    if (_form.currentState!.validate()) {
      app.login(
        name: _name.text.trim(),
        work: _work.text.trim(),
        hobbies: _hobbies.text.trim(),
        skills: _skills.text.trim(),
        email: _email.text.trim(),
      );
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    String? Function(String?)? validator,
    String? hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
    void Function(String)? onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        validator: validator,
        onFieldSubmitted: onSubmit,
        style: const TextStyle(color: C.white),
        cursorColor: C.orange,
        decoration: inputDeco(label, hint: hint, suffix: suffix),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 28 * (1 - v)),
                  child: child,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: C.panel,
                  border: Border.all(color: C.line),
                ),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            color: C.orange,
                            child: const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'TaskFlow',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Welcome 👋',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tell us a little about you, then log in.',
                        style: TextStyle(color: C.muted),
                      ),
                      const SizedBox(height: 28),
                      _field(
                        'Your name',
                        _name,
                        validator: (v) => _req(v, 'your name'),
                      ),
                      _field(
                        'What work are you doing?',
                        _work,
                        hint: 'e.g. CSE student, designer',
                        validator: (v) => _req(v, 'your work'),
                      ),
                      _field(
                        'Hobbies',
                        _hobbies,
                        hint: 'e.g. coding, football, music',
                        validator: (v) => _req(v, 'your hobbies'),
                      ),
                      _field(
                        'Something you know',
                        _skills,
                        hint: 'e.g. Python basics, video editing',
                        validator: (v) => _req(v, 'something you know'),
                      ),
                      _field(
                        'Email',
                        _email,
                        type: TextInputType.emailAddress,
                        hint: 'you@example.com',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!_emailRe.hasMatch(v.trim())) {
                            return 'Enter a valid email like name@mail.com';
                          }
                          return null;
                        },
                      ),
                      _field(
                        'Password',
                        _pass,
                        obscure: _hide,
                        onSubmit: (_) => _submit(),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'At least 6 characters'
                            : null,
                        suffix: IconButton(
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: C.muted,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OrangeButton(
                          label: 'LOGIN',
                          icon: Icons.arrow_forward,
                          expand: true,
                          onTap: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── SHELL (sidebar + content) ─────────────────────────

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 860;
        return Scaffold(
          drawer: wide
              ? null
              : const Drawer(
                  width: 272,
                  backgroundColor: C.panel,
                  shape: RoundedRectangleBorder(),
                  child: Sidebar(inDrawer: true),
                ),
          body: Row(
            children: [
              if (wide) ...[
                const Sidebar(),
                const VerticalDivider(width: 1, color: C.line),
              ],
              Expanded(
                child: Column(
                  children: [
                    Builder(
                      builder: (ctx) => TopBar(
                        onMenu: wide
                            ? null
                            : () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    const Expanded(child: ContentArea()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ContentArea extends StatelessWidget {
  const ContentArea({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) {
        final Widget view;
        if (app.showProfile) {
          view = const ProfileView(key: ValueKey('profile'));
        } else if (app.currentPage != null) {
          final p = app.currentPage!;
          view = TaskPageView(key: ValueKey(p.id), page: p);
        } else {
          view = const HomeView(key: ValueKey('home'));
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, a) => fadeSlide(child, a),
          child: view,
        );
      },
    );
  }
}

// ───────────────────────── TOP BAR ─────────────────────────

class TopBar extends StatelessWidget {
  const TopBar({super.key, this.onMenu});
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) {
        final title = app.showProfile
            ? 'Profile'
            : (app.currentPage?.name ?? 'Home');
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: C.line)),
          ),
          child: Row(
            children: [
              if (onMenu != null)
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu, color: C.white),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) =>
                      FadeTransition(opacity: a, child: c),
                  child: Align(
                    key: ValueKey(title),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Hover(
                onTap: app.toggleProfile,
                builder: (h) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: app.showProfile
                        ? C.orange
                        : (h ? C.panel2 : C.panel),
                    border: Border.all(
                      color: (app.showProfile || h) ? C.orange : C.line,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    app.initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: app.showProfile ? Colors.black : C.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── SIDEBAR ─────────────────────────

class Sidebar extends StatefulWidget {
  const Sidebar({super.key, this.inDrawer = false});
  final bool inDrawer;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final _sc = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _close() {
    if (widget.inDrawer && mounted) Navigator.of(context).pop();
  }

  Future<void> _newPage() async {
    final name = await slideDialog<String>(context, const _NewPageDialog());
    if (name != null) app.addPage(name);
    _close();
  }

  Future<void> _deletePage(TaskPage p) async {
    final ok = await slideDialog<bool>(
      context,
      _ConfirmDialog(
        title: 'Delete "${p.name}"?',
        body: 'This page and its ${p.tasks.length} task(s) will be removed.',
      ),
    );
    if (ok == true) app.deletePage(p.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final q = _q.trim().toLowerCase();
        final pages = app.pages
            .where(
              (p) =>
                  q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.tasks.any((t) => t.title.toLowerCase().contains(q)),
            )
            .toList();

        return Container(
          width: 272,
          color: C.panel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      color: C.orange,
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'TaskFlow',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SideItem(icon: Icons.add, label: 'New page', onTap: _newPage),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _sc,
                  onChanged: (v) => setState(() => _q = v),
                  style: const TextStyle(fontSize: 14, color: C.white),
                  cursorColor: C.orange,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search pages & tasks',
                    hintStyle: const TextStyle(color: C.muted, fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: C.muted,
                    ),
                    filled: true,
                    fillColor: C.bg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: C.line),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: C.orange),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _SideItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: !app.showProfile && app.currentPageId == null,
                onTap: () {
                  app.goHome();
                  _close();
                },
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: SmallLabel('Task pages'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: pages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          q.isEmpty ? 'No task pages yet.' : 'No matches.',
                          style: const TextStyle(color: C.muted, fontSize: 13),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final p in pages)
                            _SideItem(
                              icon: Icons.checklist_rounded,
                              label: p.name,
                              selected:
                                  !app.showProfile && app.currentPageId == p.id,
                              onTap: () {
                                app.openPage(p.id);
                                _close();
                              },
                              trailing: (h) {
                                if (h) {
                                  return Hover(
                                    onTap: () => _deletePage(p),
                                    builder: (hh) => Icon(
                                      Icons.close,
                                      size: 16,
                                      color: hh ? C.orange : C.muted,
                                    ),
                                  );
                                }
                                final n = p.tasks.where((t) => !t.done).length;
                                return n > 0
                                    ? Text(
                                        '$n',
                                        style: const TextStyle(
                                          color: C.muted,
                                          fontSize: 12,
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: C.line)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      color: C.orange,
                      alignment: Alignment.center,
                      child: Text(
                        app.initial,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            app.work,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: C.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Hover(
                      onTap: app.logout,
                      builder: (h) => Icon(
                        Icons.logout,
                        size: 18,
                        color: h ? C.orange : C.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget Function(bool hovering)? trailing;

  @override
  Widget build(BuildContext context) {
    return Hover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: selected
              ? C.panel2
              : (h ? C.panel2.withValues(alpha: 0.6) : Colors.transparent),
          border: Border(
            left: BorderSide(
              color: selected ? C.orange : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? C.orange : C.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: (selected || h) ? C.white : const Color(0xFFBDBDBD),
                ),
              ),
            ),
            if (trailing != null) trailing!(h),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── DIALOGS ─────────────────────────

class _NewPageDialog extends StatefulWidget {
  const _NewPageDialog();

  @override
  State<_NewPageDialog> createState() => _NewPageDialogState();
}

class _NewPageDialogState extends State<_NewPageDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ok() {
    final t = _c.text.trim();
    if (t.isNotEmpty) Navigator.of(context).pop(t);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: C.panel,
      shape: const RoundedRectangleBorder(side: BorderSide(color: C.line)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallLabel('New task page'),
              const SizedBox(height: 16),
              TextField(
                controller: _c,
                autofocus: true,
                onSubmitted: (_) => _ok(),
                style: const TextStyle(color: C.white),
                decoration: inputDeco('Page name', hint: 'e.g. Exam prep'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: C.muted,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OrangeButton(label: 'CREATE', onTap: _ok, height: 42),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: C.panel,
      shape: const RoundedRectangleBorder(side: BorderSide(color: C.line)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(body, style: const TextStyle(color: C.muted)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: C.muted,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OrangeButton(
                    label: 'DELETE',
                    height: 42,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── HOME (motivation quotes) ─────────────────────────

const _quotes = [
  ('It always seems impossible until it is done.', 'Nelson Mandela'),
  ('Do what you can, with what you have, where you are.', 'Theodore Roosevelt'),
  ('Small steps every day lead to big results.', 'Unknown'),
  (
    'Discipline is choosing between what you want now and what you want most.',
    'Unknown',
  ),
  (
    'The best time to start was yesterday. The next best time is now.',
    'Unknown',
  ),
  ('Focus on progress, not perfection.', 'Unknown'),
  (
    'You do not rise to the level of your goals. You fall to the level of your systems.',
    'James Clear',
  ),
  ('Done is better than perfect.', 'Unknown'),
];

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late int _i = math.Random().nextInt(_quotes.length);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) setState(() => _i = (_i + 1) % _quotes.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _quotes[_i];
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) {
        final total = app.allTasks.length;
        final pending = app.pending;
        final String status;
        final IconData icon;
        if (total == 0) {
          status = 'No tasks to complete. Create one from a task page.';
          icon = Icons.inbox_outlined;
        } else if (pending == 0) {
          status = 'All caught up. Every task is complete.';
          icon = Icons.check_circle_outline;
        } else {
          status =
              'You have $pending pending task${pending == 1 ? '' : 's'} waiting.';
          icon = Icons.pending_actions_outlined;
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 48, height: 3, color: C.orange),
                  const SizedBox(height: 28),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 150),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (c, a) => fadeSlide(c, a),
                      child: Column(
                        key: ValueKey(_i),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '“${q.$1}”',
                            style: const TextStyle(
                              fontSize: 30,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '— ${q.$2}',
                            style: const TextStyle(
                              color: C.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      key: ValueKey(status),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: C.panel,
                        border: Border.all(color: C.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: C.muted, size: 20),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              status,
                              style: const TextStyle(color: C.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── TASK PAGE ─────────────────────────

class TaskPageView extends StatefulWidget {
  const TaskPageView({super.key, required this.page});
  final TaskPage page;

  @override
  State<TaskPageView> createState() => _TaskPageViewState();
}

class _TaskPageViewState extends State<TaskPageView> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Cat _cat = Cat.work;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    app.addTask(widget.page, t, _cat);
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) {
        final p = widget.page;
        final pending = p.tasks.where((t) => !t.done).length;
        final done = p.tasks.length - pending;
        final progress = p.tasks.isEmpty ? 0.0 : done / p.tasks.length;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$pending pending',
                        style: const TextStyle(
                          color: C.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '   ·   $done completed',
                        style: const TextStyle(color: C.muted),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(color: C.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 3,
                    color: C.line,
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => FractionallySizedBox(
                        widthFactor: v,
                        child: Container(color: C.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          onSubmitted: (_) => _add(),
                          style: const TextStyle(color: C.white),
                          decoration: inputDeco(
                            'New task',
                            hint: 'What needs to be done?',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OrangeButton(
                        label: 'ADD',
                        icon: Icons.add,
                        onTap: _add,
                        height: 56,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in Cat.values)
                        _CatChip(
                          cat: c,
                          selected: _cat == c,
                          onTap: () => setState(() => _cat = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: p.tasks.isEmpty
                        ? const Center(
                            child: Text(
                              'No tasks on this page yet.\nType above to create your first one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: C.muted, height: 1.6),
                            ),
                          )
                        : ListView.builder(
                            itemCount: p.tasks.length,
                            itemBuilder: (_, i) {
                              final t = p.tasks[i];
                              return TaskTile(
                                key: ValueKey(t.id),
                                task: t,
                                onToggle: () => app.toggle(t),
                                onDelete: () => app.removeTask(p, t),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.cat,
    required this.selected,
    required this.onTap,
  });
  final Cat cat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hover(
      onTap: onTap,
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cat.color.withValues(alpha: 0.14)
              : Colors.transparent,
          border: Border.all(
            color: selected ? cat.color : (h ? C.muted : C.line),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, color: cat.color),
            const SizedBox(width: 8),
            Text(
              cat.label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? C.white : C.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskTile extends StatefulWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _c.forward(); // smooth entrance
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    await _c.reverse(); // smooth exit, then really remove
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return SizeTransition(
      sizeFactor: _a,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _a,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Hover(
            builder: (h) {
              final edge = h ? const Color(0xFF444444) : C.line;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: h ? C.panel2 : C.panel,
                  border: Border(
                    left: BorderSide(color: t.cat.color, width: 4),
                    top: BorderSide(color: edge),
                    right: BorderSide(color: edge),
                    bottom: BorderSide(color: edge),
                  ),
                ),
                child: Row(
                  children: [
                    Hover(
                      onTap: widget.onToggle,
                      builder: (hh) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: t.done ? C.orange : Colors.transparent,
                          border: Border.all(
                            color: (t.done || hh) ? C.orange : C.muted,
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: t.done ? 1 : 0,
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: 15,
                          color: t.done ? C.muted : C.white,
                          decoration: t.done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: C.muted,
                        ),
                        child: Text(t.title),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      color: t.cat.color.withValues(alpha: 0.13),
                      child: Text(
                        t.cat.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: t.cat.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button at the right end
                    Hover(
                      onTap: _delete,
                      builder: (hh) => AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 32,
                        height: 32,
                        color: hh
                            ? C.orange.withValues(alpha: 0.16)
                            : Colors.transparent,
                        child: Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: hh ? C.orange : C.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── PROFILE ─────────────────────────

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) {
        final gauges = <(String, Color, Cat?)>[
          ('Overall', C.orange, null),
          for (final c in Cat.values) (c.label, c.color, c),
        ];

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: C.panel,
                          border: Border.all(color: C.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              color: C.orange,
                              alignment: Alignment.center,
                              child: Text(
                                app.initial,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.name,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    app.work,
                                    style: const TextStyle(color: C.muted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    app.email,
                                    style: const TextStyle(
                                      color: C.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: app.logout,
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Logout'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: C.white,
                                side: const BorderSide(color: C.line),
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delayMs: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _InfoBox(
                              label: 'Hobbies',
                              value: app.hobbies,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoBox(
                              label: 'Something I know',
                              value: app.skills,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Reveal(
                      delayMs: 140,
                      child: SmallLabel('Task summary'),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delayMs: 160,
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Created',
                              value: app.created,
                              color: C.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Pending',
                              value: app.pending,
                              color: C.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Completed',
                              value: app.completed,
                              color: C.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Reveal(
                      delayMs: 240,
                      child: SmallLabel('Progress by category'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < gauges.length; i++)
                          Reveal(
                            delayMs: 280 + i * 90,
                            child: _GaugeCard(
                              label: gauges[i].$1,
                              color: gauges[i].$2,
                              stats: app.stats(gauges[i].$3),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmallLabel(label),
          const SizedBox(height: 8),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmallLabel(label),
          const SizedBox(height: 10),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              '$v',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(width: 28, height: 3, color: color),
        ],
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.label,
    required this.color,
    required this.stats,
  });
  final String label;
  final Color color;
  final (int, int) stats;

  @override
  Widget build(BuildContext context) {
    final (done, total) = stats;
    final value = total == 0 ? 0.0 : done / total;

    return Container(
      width: 196,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: GaugePainter(value: v, color: color),
                  ),
                  Text(
                    '${(v * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            total == 0 ? 'No tasks' : '$done / $total done',
            style: const TextStyle(color: C.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Draws a 270° curved meter: grey track + coloured progress arc.
class GaugePainter extends CustomPainter {
  GaugePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const start = 0.75 * math.pi; // bottom-left
    const sweep = 1.5 * math.pi; // 270 degrees
    const stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke,
      stroke,
      size.width - stroke * 2,
      size.height - stroke * 2,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = C.line;
    canvas.drawArc(rect, start, sweep, false, track);

    if (value > 0) {
      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = color;
      canvas.drawArc(rect, start, sweep * value, false, fg);
    }
  }

  @override
  bool shouldRepaint(GaugePainter old) =>
      old.value != value || old.color != color;
}
