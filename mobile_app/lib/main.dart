import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

enum AppLanguage { en, am }

const String apiBaseUrl =
    String.fromEnvironment("API_BASE_URL", defaultValue: "http://localhost:4000");

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
    "all": "All",
    "failedLoadPosts": "Failed to load posts. Check API connection.",
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
    "all": "ሁሉም",
    "failedLoadPosts": "ፖስቶችን መጫን አልተሳካም።",
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
  String? _error;
  String _selectedCategory = "All";
  int _navIndex = 1;
  AppLanguage _language = AppLanguage.en;

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
        _posts = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
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
      final response = await http.get(Uri.parse("$apiBaseUrl/api/notifications"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load notifications.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _notifications = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
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
      return;
    }
    _showDrawerMessage(_t("profile"), _t("profileSoon"));
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
        return rawTags
            .map((tag) => tag.toString())
            .contains(_selectedCategory);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _visiblePosts.isEmpty
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
                                itemCount: _visiblePosts.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final post = _visiblePosts[index];
                                  final title = post["title"]?.toString() ??
                                      _t("untitled");
                                  final teacher =
                                      post["teacher"]?.toString().trim() ?? "";
                                  final category =
                                      post["category"]?.toString().trim() ?? "";
                                  final artist =
                                      post["artist"]?.toString() ?? "";
                                  final subtitle = [teacher, category, artist]
                                      .where((value) => value.isNotEmpty)
                                      .join(" - ");
                                  return ListTile(
                                    title: Text(title),
                                    subtitle: subtitle.isEmpty
                                        ? null
                                        : Text(subtitle),
                                    onTap: () => _showPost(post),
                                  );
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
        onTap: _handleNavTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_none),
            label: _t("notifications"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            label: _t("new"),
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
        ],
      ),
    );
  }
}
