import "dart:async";
import "dart:convert";

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:share_plus/share_plus.dart";
import "package:shimmer/shimmer.dart";
import "package:url_launcher/url_launcher.dart";

import "admin_dashboard.dart" as admin;

enum AppLanguage { en, am }

const String apiBaseUrl = "https://fabulous-abel-birhane-hiwot.vercel.app";

final ValueNotifier<ThemeMode> _themeModeNotifier =
    ValueNotifier(ThemeMode.light);

// Store admin credentials
bool isAdminLoggedIn = false;

class CarouselSlide {
  final String imageUrl;
  final String description;
  final bool isAsset;

  const CarouselSlide({
    required this.imageUrl,
    required this.description,
    this.isAsset = false,
  });

  factory CarouselSlide.fromJson(Map<String, dynamic> json) {
    final imageUrl = json["imageUrl"]?.toString().trim() ?? "";
    final description = json["description"]?.toString() ?? "";
    final isAsset = imageUrl.startsWith("assets/");
    return CarouselSlide(
      imageUrl: imageUrl,
      description: description,
      isAsset: isAsset,
    );
  }
}

const Map<AppLanguage, Map<String, String>> _strings = {
  AppLanguage.en: {
    "appTitle": "Posts",
    "appName": "ብርሃነ ህይወት",
    "refresh": "Refresh",
    "noPosts": "No posts yet.",
    "untitled": "Untitled",
    "close": "Close",
    "notifications": "Notifications",
    "notification": "Notification",
    "noNotifications": "No notifications yet.",
    "profile": "Profile",
    "profileSoon": "Profile details coming soon.",
    "dailyMessage": "Daily Message",
    "dailyMessageBody": "Keep the words close and the melody closer.",
    "calendars": "Calendars",
    "calendarSoon": "Calendar view coming soon.",
    "categories": "Categories",
    "browsePosts": "Browse posts",
    "contactUs": "Contact Us",
    "contactBody": "Email: support@example.com",
    "about": "About",
    "aboutBody": "Posts app for viewing lyrics shared by the admin.",
    "new": "New",
    "search": "Search",
    "searchHint": "Search posts by title, teacher, or category",
    "categoryFilter": "Category",
    "searchResults": "Search results",
    "noSearchResults": "No matching posts found.",
    "favorites": "Favorites",
    "favoriteEmpty": "No favorites yet.",
    "favoriteAdded": "Added to favorites.",
    "favoriteRemoved": "Removed from favorites.",
    "share": "Share",
    "play": "Play",
    "teacherLink": "Open teacher link",
    "all": "All",
    "failedLoadPosts": "Failed to load posts. Check API connection.",
    "adminLogin": "Admin Login",
    "username": "Username",
    "password": "Password",
    "login": "Login",
    "cancel": "Cancel",
    "loginSuccess": "Login successful!",
    "invalidCredentials": "Invalid username or password.",
    "adminLoginFailed": "Failed to log in to admin.",
    "adminPanel": "Admin Panel",
    "adminPanelMsg": "You are logged in as admin. Access admin features here.",
    "settings": "Settings",
    "settingsSoon": "Settings options coming soon.",
    "brightMode": "Bright",
    "darkMode": "Dark",
    "themeMode": "Theme mode",
  },
  AppLanguage.am: {
    "appTitle": "ፖስቶች",
    "appName": "ብርሃነ ሕይወት",
    "all": "ሁሉም",
    "refresh": "አድስ",
    "noPosts": "ምንም ፖስት የለም።",
    "untitled": "ያልተሰየመ",
    "close": "ዝጋ",
    "notifications": "ማስታወቂያዎች",
    "notification": "ማስታወቂያ",
    "noNotifications": "ምንም ማስታወቂያ የለም።",
    "profile": "ፕሮፋይል",
    "profileSoon": "የፕሮፋይል መረጃ በቅርቡ ይመጣል።",
    "dailyMessage": "የዕለቱ መልዕክት",
    "dailyMessageBody": "ቃሉን ቅርብ ያድርጉ ማለቱንም በጉባኤ ውስጥ ያስቀምጡ።",
    "calendars": "ቀን መቁጠሪያ",
    "calendarSoon": "የቀን መቁጠሪያ በቅርቡ ይመጣል።",
    "categories": "ምድቦች",
    "browsePosts": "ፖስቶችን ያስሱ",
    "contactUs": "አግኙን",
    "contactBody": "ኢሜይል: support@example.com",
    "about": "ስለ መተግበሪያው",
    "aboutBody": "አስተዳዳሪው የሚጋራውን የመዝሙር ፖስቶች ለማየት መተግበሪያ።",
    "new": "አዲስ",
    "search": "ፈልግ",
    "searchHint": "በርዕስ፣ መምህር ወይም ምድብ ይፈልጉ",
    "categoryFilter": "ምድብ",
    "searchResults": "የተፈለጉት ውጤቶች",
    "noSearchResults": "ተመሳሳይ ውጤቶች አልተገኙም።",
    "favorites": "ተወዳጆች",
    "favoriteEmpty": "አሁን ድረስ የተወደዱ አልተገኙም።",
    "favoriteAdded": "ወደ ተወዳጅ ተጨምሯል።",
    "favoriteRemoved": "ከተወዳጅ ዝውውር ተሰርዟል።",
    "share": "አጋራ",
    "play": "ይጫወቱ",
    "teacherLink": "የመምህር አገናኝ ክፈት",
    "failedLoadPosts": "ፖስቶችን መጫን አልተሳካም።",
    "adminLogin": "የአስተዳዳሪ ግባ",
    "username": "የተጠቃሚ ስም",
    "password": "የይለፍ ቃል",
    "login": "ግባ",
    "cancel": "ሰርዝ",
    "loginSuccess": "መግባቱ ተሳክቷል!",
    "invalidCredentials": "የተሳሳተ የተጠቃሚ ስም ወይም የይለፍ ቃል።",
    "adminLoginFailed": "Failed to log in to admin.",
    "adminPanel": "የአስተዳዳሪ ፓነል",
    "adminPanelMsg": "እርስዎ እንደ አስተዳዳሪ በገቡዋል። እዚህ የአስተዳዳሪ ተግባራትን ይድረሳሉ።",
    "settings": "ቅንብሮች",
    "settingsSoon": "ቅንብሮቹ በቅርብ ይመጣሉ።",
    "brightMode": "Bright",
    "darkMode": "Dark",
    "themeMode": "Theme mode",
  }
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PostsMobileApp());
}

const List<CarouselSlide> _defaultCarouselSlides = [
  CarouselSlide(
    imageUrl: "assets/images/carousel_1.png",
    description: "ወደ ብርሃነ ህይወት ሰ/ት/ቤት መዝሙር ጥናት በሰላም መጡ።",
    isAsset: true,
  ),
  CarouselSlide(
    imageUrl: "assets/images/carousel_2.png",
    description: "የተለያዩ መዝሙራቶችን በምድብ ተከፍለው እዚህ ያገኛሉ",
    isAsset: true,
  ),
  CarouselSlide(
    imageUrl: "assets/images/carousel_3.png",
    description: "",
    isAsset: true,
  ),
  CarouselSlide(
    imageUrl: "assets/images/carousel_4.png",
    description: "",
    isAsset: true,
  ),
  CarouselSlide(
    imageUrl: "assets/images/carousel_5.png",
    description: "",
    isAsset: true,
  ),
];
const String _fallbackCarouselDescription = "ብርሃነ ሕይወት";

ThemeData _buildAppTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F3E46),
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}

class PostsMobileApp extends StatelessWidget {
  const PostsMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: "ብርሃነ ህይወት",
          theme: _buildAppTheme(Brightness.light),
          darkTheme: _buildAppTheme(Brightness.dark),
          themeMode: mode,
          home: const PostsHomePage(),
        );
      },
    );
  }
}

class PostsHomePage extends StatefulWidget {
  const PostsHomePage({super.key});

  @override
  State<PostsHomePage> createState() => _PostsHomePageState();
}

class _PostsHomePageState extends State<PostsHomePage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _notifications = [];
  List<CarouselSlide> _carouselSlides = _defaultCarouselSlides;
  bool _loading = false;
  bool _loadingNotifications = false;
  DateTime? _notificationsLastSeenAt;
  bool _adminLoginInProgress = false;
  static const int _recentPostsLimit = 6;
  final PageController _carouselController = PageController(viewportFraction: 0.92);
  Timer? _carouselTimer;
  int _currentCarouselPage = 0;
  bool _carouselSlidesLoading = true;
  String? _error;
  String _selectedCategory = _strings[AppLanguage.am]?["all"] ?? "All";
  String _searchCategory = _strings[AppLanguage.am]?["all"] ?? "All";
  String _searchQuery = "";
  int _navIndex = 1;
  AppLanguage _language = AppLanguage.am;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favoriteIds = {};

  String _t(String key) {
    return _strings[_language]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _notificationsLastSeenAt = DateTime.now();
    _fetchPosts();
    _fetchNotifications();
    _fetchCarouselSlides();
    _startCarouselAutoPlay();
  }

  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final slides = _carouselSlides.isEmpty ? _defaultCarouselSlides : _carouselSlides;
      if (slides.isEmpty) return;
      final nextPage = (_currentCarouselPage + 1) % slides.length;
      _carouselController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/api/posts"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load posts.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      final posts =
          data.map((item) => Map<String, dynamic>.from(item as Map)).toList()
            ..sort((a, b) {
              final categoryA =
                  a["category"]?.toString().toLowerCase().trim() ?? "";
              final categoryB =
                  b["category"]?.toString().toLowerCase().trim() ?? "";
              final categoryComparison = categoryA.compareTo(categoryB);
              if (categoryComparison != 0) {
                return categoryComparison;
              }
              final titleA = a["title"]?.toString().toLowerCase().trim() ?? "";
              final titleB = b["title"]?.toString().toLowerCase().trim() ?? "";
              return titleA.compareTo(titleB);
            });
      setState(() {
        _posts = posts;
      });
    } catch (err) {
      setState(() {
        _error = _t("failedLoadPosts");
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loadingNotifications = true;
    });
    try {
      final response =
          await http.get(Uri.parse("$apiBaseUrl/api/notifications"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load notifications.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _notifications =
            data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } catch (err) {
      setState(() {
        _notifications = [];
      });
    } finally {
      setState(() {
        _loadingNotifications = false;
      });
    }
  }

  int get _unseenNotificationCount {
    final lastSeen = _notificationsLastSeenAt;
    if (lastSeen == null) return 0;
    return _notifications
        .where((notification) {
          final createdAt = _notificationCreatedAt(notification);
          return createdAt != null && createdAt.isAfter(lastSeen);
        })
        .length;
  }

  DateTime? _notificationCreatedAt(Map<String, dynamic> notification) {
    final value = notification["createdAt"]?.toString();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _fetchCarouselSlides() async {
    setState(() { _carouselSlidesLoading = true; });
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/api/carousel"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load carousel slides.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      final slides = data
          .whereType<Map<String, dynamic>>()
          .map(CarouselSlide.fromJson)
          .where((slide) => slide.imageUrl.isNotEmpty)
          .toList();
      setState(() {
        _carouselSlides = slides.isNotEmpty ? slides : _defaultCarouselSlides;
        _carouselSlidesLoading = false;
      });
    } catch (_) {
      setState(() {
        _carouselSlides = _defaultCarouselSlides;
        _carouselSlidesLoading = false;
      });
    }
  }

  Widget _buildCarouselImage(CarouselSlide slide) {
    if (slide.isAsset) {
      return Image.asset(
        slide.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: _buildCarouselImageError,
      );
    }
    return Image.network(
      slide.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.grey.shade300),
        );
      },
      errorBuilder: _buildCarouselImageError,
    );
  }

  Widget _buildCarouselImageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  void _showPost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) {
        final title = post["title"]?.toString() ?? _t("appTitle");
        final teacher = post["teacher"]?.toString().trim() ?? "";
        final category = post["category"]?.toString().trim() ?? "";
        final artist = post["artist"]?.toString().trim() ?? "";
        final meta = [teacher, category, artist]
            .where((value) => value.isNotEmpty)
            .join(" - ");
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      meta,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Text(post["body"]?.toString() ?? ""),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t("close")),
            )
          ],
        );
      },
    );
  }

  void _showDrawerMessage(String title, String body) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t("close")),
            )
          ],
        );
      },
    );
  }

  void _setDarkMode(bool enabled) {
    _themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
    setState(() {});
  }

  void _showThemeSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t("themeMode"),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: _themeModeNotifier,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_t("brightMode")),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: isDark,
                        onChanged: _setDarkMode,
                      ),
                      const SizedBox(width: 8),
                      Text(_t("darkMode")),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdminLoginDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t("adminLogin")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: _t("username"),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _t("password"),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_t("cancel")),
            ),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return ElevatedButton(
                  onPressed: _adminLoginInProgress
                      ? null
                      : () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text.trim();
                          if (username.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(_t("invalidCredentials"))),
                            );
                            return;
                          }
                          setState(() => _adminLoginInProgress = true);
                          setDialogState(() {});
                          final success = await _authenticateAdmin(
                            username: username,
                            password: password,
                          );
                          if (!mounted) return;
                          setState(() => _adminLoginInProgress = false);
                          setDialogState(() {});
                          if (!success) return;
                          isAdminLoggedIn = true;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(_t("loginSuccess"))),
                          );
                          _openAdminPanelScreen();
                        },
                  child: _adminLoginInProgress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_t("login")),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _authenticateAdmin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/api/admins/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      if (response.statusCode == 200) {
        return true;
      }
      final message = _extractErrorMessage(response, _t("invalidCredentials"));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return false;
    } catch (err) {
      final message =
          err is http.ClientException ? err.message : _t("adminLoginFailed");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return false;
    }
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _t("notifications"),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: _t("refresh"),
                      onPressed: _fetchNotifications,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loadingNotifications
                      ? const Center(child: CircularProgressIndicator())
                      : _notifications.isEmpty
                          ? Center(child: Text(_t("noNotifications")))
                          : ListView.separated(
                              itemCount: _notifications.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 20),
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                final message =
                                    notification["message"]?.toString() ?? "";
                                return ListTile(
                                  leading: const Icon(Icons.campaign_outlined),
                                  title: Text(
                                    message.isEmpty
                                        ? _t("notification")
                                        : message,
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSearchSheet() {
    final searchController = TextEditingController(text: _searchQuery);
    String activeCategory = _searchCategory;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final categories = _categories;
              final effectiveCategory = categories.contains(activeCategory)
                  ? activeCategory
                  : (categories.isNotEmpty ? categories.first : _t("all"));
              final trimmedQuery = searchController.text.trim();
              final results =
                  _filterPostsForSearch(effectiveCategory, trimmedQuery);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t("searchResults"),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: _t("searchHint"),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setModalState(() {});
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: categories.contains(effectiveCategory)
                              ? effectiveCategory
                              : null,
                          items: categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            activeCategory = value;
                            setModalState(() {});
                            setState(() {
                              _searchCategory = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: _t("categoryFilter"),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: results.isEmpty
                              ? Center(
                                  child: Text(_t("noSearchResults")),
                                )
                              : ListView.separated(
                                  itemCount: results.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    return _buildPostTile(
                                      results[index],
                                      onFavoriteToggled: () =>
                                          setModalState(() {}),
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
          ),
        );
      },
    ).whenComplete(() => searchController.dispose());
  }

  List<Map<String, dynamic>> get _favoritePosts {
    return _posts
        .where((post) => _favoriteIds.contains(_postId(post)))
        .toList();
  }

  String _postId(Map<String, dynamic> post) {
    return post["_id"]?.toString() ??
        post["id"]?.toString() ??
        post["title"]?.toString() ??
        post["body"]?.toString() ??
        post.hashCode.toString();
  }

  bool _isFavorite(Map<String, dynamic> post) {
    return _favoriteIds.contains(_postId(post));
  }

  void _toggleFavorite(
    Map<String, dynamic> post, {
    VoidCallback? onUpdated,
  }) {
    final id = _postId(post);
    final willFavorite = !_favoriteIds.contains(id);
    setState(() {
      if (willFavorite) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
    });
    onUpdated?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(willFavorite ? "favoriteAdded" : "favoriteRemoved")),
      ),
    );
  }

  Future<void> _sharePost(Map<String, dynamic> post) async {
    final title = post["title"]?.toString() ?? _t("untitled");
    final body = post["body"]?.toString() ?? "";
    final message = "$title\n\n${body.trim()}";
    try {
      await Share.share(message, subject: title);
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t("share")} failed.")),
      );
    }
  }

  Future<void> _launchLink(String rawUrl) async {
    Uri? uri;
    try {
      uri = Uri.parse(rawUrl);
    } catch (_) {
      return;
    }
    if (!uri.hasScheme) {
      uri = Uri.parse("https://$rawUrl");
    }
    if (!await canLaunchUrl(uri)) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _extractPlayLink(Map<String, dynamic> post) {
    return _extractLinkFromPost(post, [
      "playLink",
      "playUrl",
      "audioUrl",
      "youtubeUrl",
      "link",
      "url",
    ]);
  }

  String? _extractTeacherLink(Map<String, dynamic> post) {
    return _extractLinkFromPost(post, ["teacherLink", "teacherUrl"]);
  }

  String? _extractLinkFromPost(
    Map<String, dynamic> post,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = post[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Widget _buildPostTile(
    Map<String, dynamic> post, {
    VoidCallback? onFavoriteToggled,
    int index = 0,
  }) {
    final title = post["title"]?.toString() ?? _t("untitled");
    final teacher = post["teacher"]?.toString().trim() ?? "";
    final category = post["category"]?.toString().trim() ?? "";
    final artist = post["artist"]?.toString().trim() ?? "";
    final playLink = _extractPlayLink(post);
    final teacherLink = _extractTeacherLink(post);
    final metaParts = [
      if (category.isNotEmpty) category,
      if (artist.isNotEmpty) artist,
    ];
    final subtitleWidgets = <Widget>[];
    if (teacher.isNotEmpty) {
      subtitleWidgets.add(
        Row(
          children: [
            Expanded(
              child: Text(
                teacher,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (teacherLink != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.link, size: 18, color: Theme.of(context).colorScheme.primary),
                tooltip: _t("teacherLink"),
                onPressed: () => _launchLink(teacherLink),
              ),
          ],
        ),
      );
    }
    if (metaParts.isNotEmpty) {
      subtitleWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              metaParts.join(" • "),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return _AnimatedPostCard(
      index: index,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showPost(post),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          Theme.of(context).colorScheme.tertiary.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        title.isNotEmpty ? title[0] : "?",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitleWidgets.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ...subtitleWidgets,
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (playLink != null)
                        IconButton(
                          icon: Icon(Icons.play_circle_fill,
                            color: Theme.of(context).colorScheme.primary),
                          tooltip: _t("play"),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _launchLink(playLink),
                        ),
                      IconButton(
                        icon: Icon(
                          _isFavorite(post) ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite(post) ? const Color(0xFFE05E40) : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        tooltip: _t("favorites"),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _toggleFavorite(post, onUpdated: onFavoriteToggled),
                      ),
                      IconButton(
                        icon: Icon(Icons.share_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                        tooltip: _t("share"),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _sharePost(post),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoritesSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final favorites = _favoritePosts;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _t("favorites"),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: _t("refresh"),
                          onPressed: () {
                            _fetchPosts();
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: favorites.isEmpty
                          ? Center(
                              child: Text(_t("favoriteEmpty")),
                            )
                          : ListView.separated(
                              itemCount: favorites.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return _buildPostTile(
                                  favorites[index],
                                  onFavoriteToggled: () => setModalState(() {}),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterPostsForSearch(
    String category,
    String query, {
    List<Map<String, dynamic>>? source,
  }) {
    final normalizedQuery = query.toLowerCase();
    final postsToSearch = source ?? _posts;
    return postsToSearch.where((post) {
      if (!_matchesSearchCategory(post, category)) {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }
      final searchableParts = [
        post["title"]?.toString(),
        post["body"]?.toString(),
        post["teacher"]?.toString(),
        post["category"]?.toString(),
        post["artist"]?.toString(),
      ];
      final searchable = searchableParts
          .where((value) => value != null && value.isNotEmpty)
          .map((value) => value!.toLowerCase())
          .join(" ");
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  bool _matchesSearchCategory(Map<String, dynamic> post, String category) {
    if (category == _t("all")) {
      return true;
    }
    final postCategory = post["category"]?.toString() ?? "";
    return postCategory == category;
  }

  void _handleNavTap(int index) {
    setState(() {
      _navIndex = index;
      if (index == 0) {
        _notificationsLastSeenAt = DateTime.now();
      }
    });
    if (index == 0) {
      _fetchNotifications();
      _showNotificationsSheet();
      return;
    }
    if (index == 1) {
      _showSearchSheet();
      return;
    }
    if (index == 2) {
      _showFavoritesSheet();
      return;
    }
    if (index == 3) {
      _showThemeSettings();
      return;
    }
    _showDrawerMessage(_t("profile"), _t("profileSoon"));
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    if (response.body.isEmpty) {
      return fallback;
    }
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data["error"] ?? data["message"];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return fallback;
  }

  List<String> get _categories {
    final categories = <String>{};
    for (final post in _posts) {
      final category = post["category"]?.toString().trim() ?? "";
      if (category.isNotEmpty) categories.add(category);
    }
    final list = categories.toList()..sort();
    return [_t("all"), ...list];
  }

  List<Map<String, dynamic>> get _visiblePosts {
    if (_selectedCategory == _t("all")) {
      return _posts;
    }
    return _posts
        .where((post) => post["category"]?.toString() == _selectedCategory)
        .toList();
  }

  List<Map<String, dynamic>> get _searchFilteredPosts {
    final base = _visiblePosts;
    if (_searchQuery.isEmpty && _searchCategory == _t("all")) {
      return base;
    }
    return _filterPostsForSearch(
      _searchCategory,
      _searchQuery,
      source: base,
    );
  }

  DateTime? _resolvePostTimestamp(Map<String, dynamic> post) {
    final rawValue = post["createdAt"] ?? post["updatedAt"];
    if (rawValue == null) return null;
    if (rawValue is DateTime) return rawValue;
    if (rawValue is num) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(rawValue.toInt());
      } catch (_) {
        return null;
      }
    }
    if (rawValue is String && rawValue.isNotEmpty) {
      return DateTime.tryParse(rawValue);
    }
    return null;
  }

  List<Map<String, dynamic>> _recentPostsFrom(
      List<Map<String, dynamic>> posts) {
    final sorted = List<Map<String, dynamic>>.from(posts);
    sorted.sort((a, b) {
      final aDate =
          _resolvePostTimestamp(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          _resolvePostTimestamp(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    if (sorted.length <= _recentPostsLimit) {
      return sorted;
    }
    return sorted.sublist(0, _recentPostsLimit);
  }

  Widget _buildCarouselSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
        height: 185,
      ),
    );
  }

  Widget _buildPostSkeletonList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14, width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10, width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarouselWithDots(List<CarouselSlide> slides) {
    return Column(
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            itemCount: slides.length,
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() { _currentCarouselPage = index; });
            },
            itemBuilder: (context, index) {
              final slide = slides[index];
              return AnimatedBuilder(
                animation: _carouselController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_carouselController.position.haveDimensions) {
                    value = (_carouselController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.25)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: Transform.scale(
                      scale: Curves.easeOut.transform(value),
                      child: Opacity(
                        opacity: Curves.easeOut.transform(value),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCarouselImage(slide),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              slide.description.isNotEmpty
                                  ? slide.description
                                  : _fallbackCarouselDescription,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      const Shadow(blurRadius: 8, color: Colors.black54),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final isActive = index == _currentCarouselPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive ? const Color(0xFFE05E40) : Colors.grey.shade400,
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsToShow = _searchFilteredPosts;
    final isShowingDefaultList =
        _searchQuery.isEmpty && _searchCategory == _t("all");
    final displayPosts =
        isShowingDefaultList ? _recentPostsFrom(postsToShow) : postsToShow;
    final slides = _carouselSlides.isEmpty ? _defaultCarouselSlides : _carouselSlides;
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        toolbarHeight: 52,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE05E40), width: 2),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF2F3E46),
                backgroundImage: AssetImage("assets/images/carousel_5.png"),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _t("appName"),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _t("refresh"),
            onPressed: () {
              _fetchPosts();
              _fetchCarouselSlides();
              _fetchNotifications();
            },
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _language = _language == AppLanguage.en
                    ? AppLanguage.am
                    : AppLanguage.en;
                _selectedCategory = _t("all");
                _searchCategory = _t("all");
                _searchQuery = "";
                _searchController.clear();
              });
            },
            child: Text(_language == AppLanguage.en ? "አማ" : "EN"),
          ),
        ],
      ),
      body: Column(
        children: [
          _carouselSlidesLoading
              ? _buildCarouselSkeleton()
              : _buildCarouselWithDots(slides),
          const SizedBox(height: 4),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _t("searchHint"),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() { _searchQuery = value; });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              final isSelected = category == _searchCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(category, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _searchCategory = category;
                                      _selectedCategory = category;
                                      _searchQuery = "";
                                      _searchController.clear();
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? _buildPostSkeletonList()
                : displayPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.article_outlined, size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text(_t("noPosts"),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          itemCount: displayPosts.length,
                          itemBuilder: (context, index) {
                            return _buildPostTile(displayPosts[index], index: index);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: const Color(0xFF2F3E46),
        elevation: 8,
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          selectedItemColor: const Color(0xFFE05E40),
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          showUnselectedLabels: true,
          onTap: _handleNavTap,
          items: [
            BottomNavigationBarItem(
              icon: _buildNotificationNavIcon(),
              label: _t("notifications"),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: _t("search"),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border),
              label: _t("favorites"),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: _t("settings"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationNavIcon() {
    final unseenCount = _unseenNotificationCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none),
        if (unseenCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unseenCount > 99 ? "99+" : unseenCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2F3E46),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage("assets/images/carousel_5.png"),
                  child: Icon(Icons.person, color: Color(0xFF2F3E46)),
                ),
                const SizedBox(height: 12),
                Text(
                  "እንኳን ወደ ብርሃነ ሕይወት መዝሙር ክፍል በሰላም መጡ።",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                Text(
                  _t(""),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: Text(_t("dailyMessage")),
            onTap: () {
              Navigator.pop(context);
              _showDrawerMessage(
                _t("dailyMessage"),
                _t("dailyMessageBody"),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(_t("calendars")),
            onTap: () {
              Navigator.pop(context);
              _showDrawerMessage(_t("calendars"), _t("calendarSoon"));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(_t("contactUs")),
            onTap: () {
              Navigator.pop(context);
              _showDrawerMessage(_t("contactUs"), _t("contactBody"));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_t("about")),
            onTap: () {
              Navigator.pop(context);
              _showDrawerMessage(_t("about"), _t("aboutBody"));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(isAdminLoggedIn
                ? Icons.admin_panel_settings
                : Icons.lock_outline),
            title: Text(isAdminLoggedIn ? _t("adminPanel") : _t("adminLogin")),
            onTap: () {
              Navigator.pop(context);
              if (isAdminLoggedIn) {
                _openAdminPanelScreen();
              } else {
                _showAdminLoginDialog();
              }
            },
          ),
        ],
      ),
    );
  }

  void _openAdminPanelScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const admin.PostsAdminApp(),
      ),
    );
  }
}

class _AnimatedPostCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedPostCard({
    required this.child,
    this.index = 0,
  });

  @override
  State<_AnimatedPostCard> createState() => _AnimatedPostCardState();
}

class _AnimatedPostCardState extends State<_AnimatedPostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    Future.delayed(
      Duration(milliseconds: 80 * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.97),
          onTapUp: (_) => setState(() => _scale = 1.0),
          onTapCancel: () => setState(() => _scale = 1.0),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
