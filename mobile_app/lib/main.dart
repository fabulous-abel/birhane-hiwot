import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:share_plus/share_plus.dart";

import "admin_dashboard.dart" as admin;

enum AppLanguage { en, am }

const String apiBaseUrl =
    "https://fabulous-abel-birhane-hiwot.vercel.app/";

// Store admin credentials
bool isAdminLoggedIn = false;

const Map<AppLanguage, Map<String, String>> _strings = {
  AppLanguage.en: {
    "appTitle": "Posts",
    "appName": "Birhane Hiwot",
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
  },
  AppLanguage.am: {
    "appTitle": "ፖስቶች",
    "appName": "ብርሃነ ሕይወት",
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
    "searchResults": "የፈለጉ ውጤቶች",
    "noSearchResults": "ተመሳሳይ ውጤቶች አልተገኙም።",
    "favorites": "ተወዳጆች",
    "favoriteEmpty": "አሁን ድረስ የተወደዱ አልተገኙም።",
    "favoriteAdded": "ወደ ተወዳጅ ተጨምሯል።",
    "favoriteRemoved": "ከተወዳጅ ዝውውር ተሰርዟል።",
    "share": "አጋር",
    "failedLoadPosts": "ፖስቶችን መጫን አልተሳካም።",
    "adminLogin": "የአስተዳዳሪ ግiriş",
    "username": "የተጠቃሚ ስም",
    "password": "የይለፍ ቃል",
    "login": "ግቤት",
    "cancel": "ሰርዝ",
    "loginSuccess": "ግቤቱ ተሳክቷል!",
    "invalidCredentials": "የተሳሳተ የተጠቃሚ ስም ወይም የይለፍ ቃል።",
    "adminLoginFailed": "Failed to log in to admin.",
    "adminPanel": "የአስተዳዳሪ ፓነል",
    "adminPanelMsg": "እርስዎ እንደ አስተዳዳሪ በገቡዋል። እዚህ የአስተዳዳሪ ተግባራትን ይድረሳሉ።",
  }
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PostsMobileApp());
}

class PostsMobileApp extends StatelessWidget {
  const PostsMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Posts",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F3E46)),
        useMaterial3: true,
      ),
      home: const PostsHomePage(),
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
  bool _loading = false;
  bool _loadingNotifications = false;
  bool _adminLoginInProgress = false;
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
    _fetchPosts();
    _fetchNotifications();
  }

  @override
  void dispose() {
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
      setState(() {
        _posts =
            data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
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
      final message =
          _extractErrorMessage(response, _t("invalidCredentials"));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return false;
    } catch (err) {
      final message = err is http.ClientException
          ? err.message
          : _t("adminLoginFailed");
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

  Widget _buildPostTile(
    Map<String, dynamic> post, {
    VoidCallback? onFavoriteToggled,
  }) {
    final title = post["title"]?.toString() ?? _t("untitled");
    final teacher = post["teacher"]?.toString().trim() ?? "";
    final category = post["category"]?.toString().trim() ?? "";
    final artist = post["artist"]?.toString().trim() ?? "";
    final subtitle = [teacher, category, artist]
        .where((value) => value.isNotEmpty)
        .join(" - ");
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        onTap: () => _showPost(post),
        trailing: SizedBox(
          width: 96,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isFavorite(post) ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite(post) ? Colors.red : null,
                ),
                tooltip: _t("favorites"),
                onPressed: () =>
                    _toggleFavorite(post, onUpdated: onFavoriteToggled),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: _t("share"),
                onPressed: () => _sharePost(post),
              ),
            ],
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
                                  onFavoriteToggled: () =>
                                      setModalState(() {}),
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
    if (postCategory == category) {
      return true;
    }
    final rawTags = post["tags"];
    if (rawTags is List) {
      return rawTags.map((tag) => tag.toString()).contains(category);
    }
    return false;
  }

  void _handleNavTap(int index) {
    setState(() {
      _navIndex = index;
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
      final rawTags = post["tags"];
      if (rawTags is List) {
        for (final tag in rawTags) {
          final value = tag.toString().trim();
          if (value.isNotEmpty) categories.add(value);
        }
      }
    }
    final list = categories.toList()..sort();
    return [_t("all"), ...list];
  }

  List<Map<String, dynamic>> get _visiblePosts {
    if (_selectedCategory == _t("all")) {
      return _posts;
    }
    return _posts.where((post) {
      final category = post["category"]?.toString() ?? "";
      if (category == _selectedCategory) {
        return true;
      }
      final rawTags = post["tags"];
      if (rawTags is List) {
        return rawTags.map((tag) => tag.toString()).contains(_selectedCategory);
      }
      return false;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final postsToShow = _searchFilteredPosts;
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        toolbarHeight: 52,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF2F3E46),
              child: Icon(Icons.music_note, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              _t("appName"),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _t("refresh"),
            onPressed: _fetchPosts,
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
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t("search"),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: _t("searchHint"),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categories.contains(_searchCategory)
                          ? _searchCategory
                          : _t("all"),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _searchCategory = value;
                          _selectedCategory = value;
                          _searchQuery = "";
                          _searchController.clear();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: _t("categoryFilter"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : postsToShow.isEmpty
                    ? Center(
                        child: Text(_t("noPosts")),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        child: Column(
                          children: [
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.separated(
                                controller: _scrollController,
                                itemCount: postsToShow.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  return _buildPostTile(postsToShow[index]);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        selectedItemColor: const Color(0xFFE05E40),
        onTap: _handleNavTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_none),
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
            icon: const Icon(Icons.person_outline),
            label: _t("profile"),
          ),
        ],
      ),
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
                  _t("browsePosts"),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(_t("profile")),
            onTap: () {
              Navigator.pop(context);
              _showDrawerMessage(_t("profile"), _t("profileSoon"));
            },
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _t("categories"),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ..._categories.map(
            (category) => ListTile(
              leading: Icon(
                category == _selectedCategory
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(category),
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _searchCategory = category;
                  _searchQuery = "";
                  _searchController.clear();
                });
                Navigator.pop(context);
              },
            ),
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
