import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

const String adminApiBaseUrl = String.fromEnvironment("API_BASE_URL",
    defaultValue: "https://fabulous-abel-birhane-hiwot.vercel.app");

const Color _brandInk = Color(0xFF18232B);
const Color _brandOcean = Color(0xFF1F4A6E);
const Color _brandSand = Color(0xFFF5EFE6);
const Color _brandClay = Color(0xFFE8D7C2);
const Color _brandCoral = Color(0xFFE05E40);
const Color _brandMint = Color(0xFF9FD4C7);

enum AppLanguage { en, am }

const Map<AppLanguage, Map<String, String>> _strings = {
  AppLanguage.en: {
    "appTitle": "Posts Admin",
    "dashboard": "Dashboard",
    "postsLibrary": "Posts Library",
    "postsControl": "Posts Control",
    "categories": "Categories",
    "settings": "Settings",
    "offlineFirstAdmin": "Offline-first admin",
    "heroTitle": "Admin dashboard",
    "heroSubtitle":
        "Curate posts, sync packs, and keep the offline catalog fresh.",
    "newPost": "New post",
    "refresh": "Refresh",
    "statPosts": "Posts",
    "createPost": "Create post",
    "editPost": "Edit post",
    "formHint": "Add rich metadata so the mobile app can filter packs offline.",
    "labelTitle": "Title",
    "labelTeacher": "Teacher",
    "labelLink": "Link",
    "labelCategory": "Category",
    "labelSubcategory": "Subcategory (optional)",
    "labelArtist": "Artist",
    "labelPost": "Post",
    "errorTitleBody": "Title and post body are required.",
    "errorCategory": "Category is required.",
    "create": "Create",
    "update": "Update",
    "clear": "Clear",
    "total": "total",
    "postsLibraryTitle": "Posts library",
    "postsLibraryHint":
        "Tap a post to edit. Use delete to remove from the catalog.",
    "noPosts": "No posts yet.",
    "broadcastTitle": "Broadcast notification",
    "broadcastHint": "Share a quick idea or reminder with everyone in the app.",
    "notificationMessage": "Notification message",
    "notificationSent": "Notification sent.",
    "notificationFailed": "Failed to send notification.",
    "notificationRequired": "Notification message is required.",
    "send": "Send",
    "sending": "Sending...",
    "broadcastListTitle": "Broadcast history",
    "broadcastListHint": "No broadcast messages yet.",
    "deleteBroadcast": "Delete broadcast",
    "broadcastDeletePrompt": "Delete this broadcast message?",
    "broadcastDeleted": "Broadcast deleted.",
    "broadcastDeleteFailed": "Failed to delete broadcast.",
    "categoriesDialogTitle": "Categories",
    "subcategoriesDialogTitle": "Subcategories",
    "addCategory": "Add category",
    "addSubcategory": "Add subcategory",
    "noCategories": "No categories yet.",
    "noSubcategories": "No subcategories yet.",
    "unnamed": "Unnamed",
    "close": "Close",
    "add": "Add",
    "cancel": "Cancel",
    "continue": "Continue",
    "addCategoriesDrawer": "Add categories from the drawer.",
    "failedAddCategory": "Failed to add category.",
    "failedDeleteCategory": "Failed to delete category.",
    "failedUpdateCategory": "Failed to update category.",
    "failedAddSubcategory": "Failed to add subcategory.",
    "failedDeleteSubcategory": "Failed to delete subcategory.",
    "failedUpdateSubcategory": "Failed to update subcategory.",
    "addCategoryFirst": "Add a category first.",
    "failedLoadPosts": "Failed to load posts. Check API connection.",
    "failedSavePost": "Failed to save post.",
    "failedDeletePost": "Failed to delete post.",
    "addAdmin": "Add admin",
    "createAdmin": "Create admin",
    "adminUsername": "Admin username",
    "adminPassword": "Admin password",
    "adminCreated": "Admin account created.",
    "adminCreationFailed": "Failed to create admin.",
    "adminListTitle": "Admin accounts",
    "adminListHint": "No admin accounts yet.",
    "adminListFailed": "Failed to load admin list.",
    "adminPasswordHidden": "Password hidden.",
    "defaultAdminLabel": "Default admin",
    "deleteAdmin": "Delete admin",
    "deleteAdminPrompt": "Delete admin account",
    "adminDeleted": "Admin deleted.",
    "adminDeleteFailed": "Failed to delete admin.",
    "adminCreatedLabel": "Created"
  },
  AppLanguage.am: {
    "appTitle": "የጽሑፍ አስተዳዳሪ",
    "dashboard": "ዳሽቦርድ",
    "postsLibrary": "የፖስቶች ቤተ-መዝገብ",
    "postsControl": "የፖስቶች አስተዳደር",
    "categories": "ምድቦች",
    "settings": "ቅንብሮች",
    "offlineFirstAdmin": "ኦፍላይን-ቀዳሚ አስተዳዳሪ",
    "heroTitle": "የአስተዳዳሪ ዳሽቦርድ",
    "heroSubtitle": "ፖስቶችን አስተዳድር፣ ፓክ ውጣ፣ ኦፍላይን ዝርዝርን ያዘጋጁ።",
    "newPost": "አዲስ ፖስት",
    "refresh": "አድስ",
    "statPosts": "ፖስቶች",
    "createPost": "ፖስት ፍጠር",
    "editPost": "ፖስት አስተካክል",
    "formHint": "ሞባይል መተግበሪያው ኦፍላይን እንዲያጣራ መረጃ ያክሉ።",
    "labelTitle": "ርዕስ",
    "labelTeacher": "አስተማሪ",
    "labelLink": "Link",
    "labelCategory": "ምድብ",
    "labelSubcategory": "ንዑስ ምድብ (አማራጭ)",
    "labelArtist": "አርቲስት",
    "labelPost": "ፖስት",
    "errorTitleBody": "ርዕስና ፖስት አስፈላጊ ናቸው።",
    "errorCategory": "ምድብ አስፈላጊ ነው።",
    "create": "ፍጠር",
    "update": "አዘምን",
    "clear": "አጥፋ",
    "total": "ጠቅላላ",
    "postsLibraryTitle": "የፖስቶች ቤተ-መዝገብ",
    "postsLibraryHint": "ፖስትን ለማስተካከል ይጫኑ። ለመሰረዝ ዲሊት ይጠቀሙ።",
    "noPosts": "ምንም ፖስት የለም።",
    "broadcastTitle": "ማስታወቂያ ላክ",
    "broadcastHint": "ለሁሉም አንድ ማስታወሻ ወይም ሀሳብ ያጋሩ።",
    "notificationMessage": "የማስታወቂያ መልዕክት",
    "notificationSent": "ማስታወቂያ ተላክ።",
    "notificationFailed": "ማስታወቂያ ላክ አልተሳካም።",
    "notificationRequired": "የማስታወቂያ መልዕክት ያስፈልጋል።",
    "send": "ላክ",
    "sending": "በመላክ ላይ...",
    "broadcastListTitle": "?????? ????",
    "broadcastListHint": "???? ??????? ???? ?????",
    "deleteBroadcast": "?????? ??????",
    "broadcastDeletePrompt": "?????? ?????? ???? ??????",
    "broadcastDeleted": "?????? ????",
    "broadcastDeleteFailed": "?????? ???? ???????",
    "categoriesDialogTitle": "ምድቦች",
    "subcategoriesDialogTitle": "ንዑስ ምድቦች",
    "addCategory": "ምድብ ጨምር",
    "addSubcategory": "ንዑስ ምድብ ጨምር",
    "noCategories": "ምንም ምድብ የለም።",
    "noSubcategories": "ምንም ንዑስ ምድብ የለም።",
    "unnamed": "ያልተሰየመ",
    "close": "ዝጋ",
    "add": "ጨምር",
    "cancel": "ሰርዝ",
    "continue": "ቀጥል",
    "addCategoriesDrawer": "ምድቦችን ከመሳቢያው ይጨምሩ።",
    "failedAddCategory": "ምድብ መጨመር አልተሳካም።",
    "failedDeleteCategory": "ምድብ መሰረዝ አልተሳካም።",
    "failedUpdateCategory": "ምድብ መቀየር አልተሳካም።",
    "failedAddSubcategory": "ንዑስ ምድብ መጨመር አልተሳካም።",
    "failedDeleteSubcategory": "ንዑስ ምድብ መሰረዝ አልተሳካም።",
    "failedUpdateSubcategory": "ንዑስ ምድብ መቀየር አልተሳካም።",
    "addCategoryFirst": "እባክዎ መጀመሪያ ምድብ ያክሉ።",
    "failedLoadPosts": "ፖስቶችን መጫን አልተሳካም።",
    "failedSavePost": "ፖስት መቀመጥ አልተሳካም።",
    "failedDeletePost": "ፖስት መሰረዝ አልተሳካም።",
    "addAdmin": "Add admin",
    "createAdmin": "Create admin",
    "adminUsername": "Admin username",
    "adminPassword": "Admin password",
    "adminCreated": "Admin account created.",
    "adminCreationFailed": "Failed to create admin.",
    "adminListTitle": "የአስተዳዳሪ መለያዎች",
    "adminListHint": "አሁን ምንም የአስተዳዳሪ መለያ የለም።",
    "adminListFailed": "የአስተዳዳሪ ዝርዝር መጫን አልተቻለም።",
    "adminPasswordHidden": "Password hidden.",
    "defaultAdminLabel": "Default admin",
    "deleteAdmin": "Delete admin",
    "deleteAdminPrompt": "Delete admin account",
    "adminDeleted": "Admin deleted.",
    "adminDeleteFailed": "Failed to delete admin.",
    "adminCreatedLabel": "Created"
  }
};

void main() {
  runApp(const PostsAdminApp());
}

class PostsAdminApp extends StatelessWidget {
  const PostsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Posts Admin",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandOcean,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: _brandSand,
        useMaterial3: true,
        fontFamily: "Georgia",
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(fontSize: 14),
        ).apply(bodyColor: _brandInk, displayColor: _brandInk),
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandSand,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: _brandInk,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: _brandInk),
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 4,
          shadowColor: Color(0x1418232B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandClay),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandClay),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandOcean, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandCoral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandInk,
            side: const BorderSide(color: _brandOcean),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _notificationController = TextEditingController();
  final ScrollController _pageScrollController = ScrollController();

  List<Lyric> _lyrics = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  bool _loading = false;
  bool _heroVisible = false;
  bool _sendingNotification = false;
  List<Map<String, dynamic>> _broadcastMessages = [];
  bool _loadingBroadcastMessages = false;
  String? _broadcastError;
  bool _loadingCategories = false;
  bool _loadingSubcategories = false;
  bool _addingAdmin = false;
  String? _editingId;
  String? _error;
  String? _notificationStatus;
  AppLanguage _language = AppLanguage.en;
  List<AdminAccount> _adminAccounts = [];
  bool _loadingAdminList = false;
  String? _adminListError;
  bool _sidebarCollapsed = false;

  String _t(String key) {
    return _strings[_language]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _fetchCategories();
    _fetchSubcategories();
    _fetchBroadcastMessages();
    _fetchAdminList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _heroVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _teacherController.dispose();
    _linkController.dispose();
    _categoryController.dispose();

    _bodyController.dispose();
    _notificationController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse("$adminApiBaseUrl/api/posts"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load posts.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      final lyrics = data.map((item) => Lyric.fromJson(item)).toList()
        ..sort((a, b) {
          final categoryComparison = a.category.toLowerCase().compareTo(
                b.category.toLowerCase(),
              );
          if (categoryComparison != 0) {
            return categoryComparison;
          }
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      setState(() {
        _lyrics = lyrics;
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

  Future<void> _fetchAdminList() async {
    setState(() {
      _loadingAdminList = true;
      _adminListError = null;
    });
    List<AdminAccount> accounts = [];
    String? error;
    try {
      final response = await http.get(Uri.parse("$adminApiBaseUrl/api/admins"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load admin list.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      accounts = data
          .whereType<Map<String, dynamic>>()
          .map((item) => AdminAccount.fromJson(item))
          .where((account) => account.username.isNotEmpty)
          .toList();
    } catch (_) {
      error = _t("adminListFailed");
    }
    if (!mounted) return;
    setState(() {
      _adminAccounts = accounts;
      _adminListError = error;
      _loadingAdminList = false;
    });
  }

  Future<void> _saveLyric() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final category = _categoryController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() {
        _error = _t("errorTitleBody");
      });
      return;
    }
    if (category.isEmpty) {
      setState(() {
        _error = _t("errorCategory");
      });
      return;
    }

    final payload = {
      "title": title,
      "teacher": _teacherController.text.trim(),
      "category": category,
      "body": body,
      "link": _linkController.text.trim(),
    };

    try {
      final uri = _editingId == null
          ? Uri.parse("$adminApiBaseUrl/api/posts")
          : Uri.parse("$adminApiBaseUrl/api/posts/$_editingId");
      final response = _editingId == null
          ? await http.post(uri,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload))
          : await http.put(uri,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload));

      if (response.statusCode >= 400) {
        throw Exception("Failed to save post.");
      }

      _clearForm();
      await _loadLyrics();
    } catch (err) {
      setState(() {
        _error = _t("failedSavePost");
      });
    }
  }

  Future<void> _deleteLyric(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$adminApiBaseUrl/api/posts")
            .replace(queryParameters: {"id": id}),
      );
      if (response.statusCode >= 400) {
        throw Exception("Failed to delete post.");
      }
      await _loadLyrics();
    } catch (err) {
      setState(() {
        _error = _t("failedDeletePost");
      });
    }
  }

  Future<void> _confirmDeleteAdmin(AdminAccount admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t("deleteAdmin")),
        content: Text("${_t("deleteAdminPrompt")} ${admin.username}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t("cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t("deleteAdmin")),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteAdmin(admin.username);
    }
  }

  Future<void> _deleteAdmin(String username) async {
    try {
      final uri = Uri.parse(
        "$adminApiBaseUrl/api/admins/${Uri.encodeComponent(username)}",
      );
      final response = await http.delete(uri);
      if (response.statusCode >= 400) {
        throw Exception("Failed to delete admin.");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("adminDeleted"))),
      );
      await _fetchAdminList();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("adminDeleteFailed"))),
      );
    }
  }

  String? _formatAdminCreatedAt(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return parsed
        .toLocal()
        .toIso8601String()
        .replaceFirst("T", " ")
        .split(".")
        .first;
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final response =
          await http.get(Uri.parse("$adminApiBaseUrl/api/categories"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load categories.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _categories =
            data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } catch (err) {
      setState(() {
        _categories = [];
      });
    } finally {
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  Future<void> _fetchSubcategories({String? categoryId}) async {
    setState(() {
      _loadingSubcategories = true;
    });
    try {
      final uri = categoryId == null || categoryId.isEmpty
          ? Uri.parse("$adminApiBaseUrl/api/subcategories")
          : Uri.parse(
              "$adminApiBaseUrl/api/subcategories?categoryId=$categoryId");
      final response = await http.get(uri);
      if (response.statusCode >= 400) {
        throw Exception("Failed to load subcategories.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _subcategories =
            data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } catch (err) {
      setState(() {
        _subcategories = [];
      });
    } finally {
      setState(() {
        _loadingSubcategories = false;
      });
    }
  }

  Future<void> _addSubcategory({
    required String name,
    required String categoryId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$adminApiBaseUrl/api/subcategories"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "categoryId": categoryId}),
      );
      if (response.statusCode >= 400) {
        throw Exception("Failed to add subcategory.");
      }
      await _fetchSubcategories(categoryId: categoryId);
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("failedAddSubcategory"))),
      );
    }
  }

  Future<void> _updateSubcategory({
    required String id,
    required String name,
    required String categoryId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$adminApiBaseUrl/api/subcategories/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "categoryId": categoryId}),
      );
      if (response.statusCode >= 400) {
        throw Exception("Failed to update subcategory.");
      }
      await _fetchSubcategories(categoryId: categoryId);
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("failedUpdateSubcategory"))),
      );
    }
  }

  Future<void> _deleteSubcategory({
    required String id,
    required String categoryId,
  }) async {
    try {
      final response = await http
          .delete(Uri.parse("$adminApiBaseUrl/api/subcategories/$id"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to delete subcategory.");
      }
      await _fetchSubcategories(categoryId: categoryId);
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("failedDeleteSubcategory"))),
      );
    }
  }

  Future<void> _addCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse("$adminApiBaseUrl/api/categories"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name}),
      );
      if (response.statusCode >= 400) {
        throw Exception("Failed to add category.");
      }
      await _fetchCategories();
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("failedAddCategory"))),
      );
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      final response =
          await http.delete(Uri.parse("$adminApiBaseUrl/api/categories/$id"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to delete category.");
      }
      await _fetchCategories();
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("failedDeleteCategory"))),
      );
    }
  }

  Future<void> _updateCategory(String id, String name) async {
    try {
      final response = await http.put(
        Uri.parse("$adminApiBaseUrl/api/categories/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name}),
      );
      if (response.statusCode >= 400) {
        throw Exception("Failed to update category.");
      }
      await _fetchCategories();
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("failedUpdateCategory"))),
      );
    }
  }

  Future<void> _sendNotification() async {
    final message = _notificationController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _notificationStatus = _t("notificationRequired");
      });
      return;
    }
    setState(() {
      _sendingNotification = true;
      _notificationStatus = null;
    });
    try {
      final response = await http.post(
        Uri.parse("$adminApiBaseUrl/api/notifications"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );
      if (response.statusCode >= 400) {
        throw Exception("Failed to send notification.");
      }
      _notificationController.clear();
      setState(() {
        _notificationStatus = _t("notificationSent");
      });
      await _fetchBroadcastMessages();
    } catch (err) {
      setState(() {
        _notificationStatus = _t("notificationFailed");
      });
    } finally {
      setState(() {
        _sendingNotification = false;
      });
    }
  }

  Future<void> _fetchBroadcastMessages() async {
    setState(() {
      _loadingBroadcastMessages = true;
      _broadcastError = null;
    });
    try {
      final response =
          await http.get(Uri.parse("$adminApiBaseUrl/api/notifications"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to load broadcast messages.");
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _broadcastMessages = data
            .whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _broadcastError = null;
      });
    } catch (err) {
      setState(() {
        _broadcastMessages = [];
        _broadcastError = _t("broadcastListHint");
      });
    } finally {
      setState(() {
        _loadingBroadcastMessages = false;
      });
    }
  }

  Future<void> _confirmDeleteBroadcast(Map<String, dynamic> broadcast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t("deleteBroadcast")),
        content: Text(_t("broadcastDeletePrompt")),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t("cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t("deleteBroadcast")),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final id = broadcast["_id"]?.toString();
      if (id != null && id.isNotEmpty) {
        await _deleteBroadcast(id);
      }
    }
  }

  Future<void> _deleteBroadcast(String id) async {
    try {
      final response = await http
          .delete(Uri.parse("$adminApiBaseUrl/api/notifications/$id"));
      if (response.statusCode >= 400) {
        throw Exception("Failed to delete broadcast.");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("broadcastDeleted"))),
      );
      await _fetchBroadcastMessages();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("broadcastDeleteFailed"))),
      );
    }
  }

  Future<void> _showCategoryManager() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_t("categoriesDialogTitle")),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: _t("addCategory"),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _loadingCategories
                      ? const Center(child: CircularProgressIndicator())
                      : _categories.isEmpty
                          ? Center(child: Text(_t("noCategories")))
                          : ListView.separated(
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final name = category["name"]?.toString() ?? "";
                                return ListTile(
                                  title:
                                      Text(name.isEmpty ? _t("unnamed") : name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () async {
                                          final controller =
                                              TextEditingController(text: name);
                                          final updated =
                                              await showDialog<String>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(_t("addCategory")),
                                                content: TextField(
                                                  controller: controller,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        _t("labelCategory"),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Text(_t("cancel")),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context,
                                                          controller.text);
                                                    },
                                                    child: Text(_t("update")),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          controller.dispose();
                                          final id =
                                              category["_id"]?.toString() ?? "";
                                          if (id.isEmpty ||
                                              updated == null ||
                                              updated.trim().isEmpty) {
                                            return;
                                          }
                                          await _updateCategory(
                                            id,
                                            updated.trim(),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          final id =
                                              category["_id"]?.toString() ?? "";
                                          if (id.isEmpty) return;
                                          _deleteCategory(id);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t("close")),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                _addCategory(name);
                controller.clear();
              },
              child: Text(_t("add")),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showSubcategoryManager() async {
    final nameController = TextEditingController();
    String? selectedCategoryId =
        _categories.isNotEmpty ? _categories.first["_id"]?.toString() : null;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_t("subcategoriesDialogTitle")),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: _categories
                      .map((category) {
                        final id = category["_id"]?.toString() ?? "";
                        final name = category["name"]?.toString() ?? "";
                        if (id.isEmpty || name.isEmpty) {
                          return null;
                        }
                        return DropdownMenuItem(
                          value: id,
                          child: Text(name),
                        );
                      })
                      .whereType<DropdownMenuItem<String>>()
                      .toList(),
                  onChanged: (value) {
                    selectedCategoryId = value;
                    if (value != null) {
                      _fetchSubcategories(categoryId: value);
                    }
                  },
                  decoration: InputDecoration(labelText: _t("labelCategory")),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: _t("addSubcategory")),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _loadingSubcategories
                      ? const Center(child: CircularProgressIndicator())
                      : _subcategories.isEmpty
                          ? Center(child: Text(_t("noSubcategories")))
                          : ListView.separated(
                              itemCount: _subcategories.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final subcategory = _subcategories[index];
                                final name =
                                    subcategory["name"]?.toString() ?? "";
                                return ListTile(
                                  title: Text(
                                    name.isEmpty ? _t("unnamed") : name,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () async {
                                          final controller =
                                              TextEditingController(text: name);
                                          final updated =
                                              await showDialog<String>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title:
                                                    Text(_t("addSubcategory")),
                                                content: TextField(
                                                  controller: controller,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        _t("labelSubcategory"),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: Text(_t("cancel")),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        controller.text,
                                                      );
                                                    },
                                                    child: Text(_t("update")),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          controller.dispose();
                                          final id =
                                              subcategory["_id"]?.toString() ??
                                                  "";
                                          final categoryId =
                                              subcategory["categoryId"]
                                                      ?.toString() ??
                                                  "";
                                          if (id.isEmpty ||
                                              categoryId.isEmpty ||
                                              updated == null ||
                                              updated.trim().isEmpty) {
                                            return;
                                          }
                                          await _updateSubcategory(
                                            id: id,
                                            name: updated.trim(),
                                            categoryId: categoryId,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          final id =
                                              subcategory["_id"]?.toString() ??
                                                  "";
                                          final categoryId =
                                              subcategory["categoryId"]
                                                      ?.toString() ??
                                                  "";
                                          if (id.isEmpty ||
                                              categoryId.isEmpty) {
                                            return;
                                          }
                                          _deleteSubcategory(
                                            id: id,
                                            categoryId: categoryId,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t("close")),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (selectedCategoryId == null ||
                    selectedCategoryId!.isEmpty ||
                    name.isEmpty) {
                  return;
                }
                _addSubcategory(
                  name: name,
                  categoryId: selectedCategoryId!,
                );
                nameController.clear();
              },
              child: Text(_t("add")),
            ),
          ],
        );
      },
    );
    nameController.dispose();
  }

  Future<bool> _createAdminAccount({
    required String username,
    required String password,
  }) async {
    setState(() {
      _addingAdmin = true;
    });
    try {
      final response = await http.post(
        Uri.parse("$adminApiBaseUrl/api/admins"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      if (response.statusCode >= 400) {
        final message = _parseErrorMessage(response, _t("adminCreationFailed"));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("adminCreated"))),
      );
      return true;
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("adminCreationFailed"))),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _addingAdmin = false;
        });
      }
    }
  }

  void _showAddAdminDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t("addAdmin")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: _t("adminUsername")),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: _t("adminPassword")),
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
                  onPressed: _addingAdmin
                      ? null
                      : () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text.trim();
                          if (username.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(_t("adminCreationFailed"))),
                            );
                            return;
                          }
                          setDialogState(() {});
                          final success = await _createAdminAccount(
                            username: username,
                            password: password,
                          );
                          if (!mounted) return;
                          setDialogState(() {});
                          if (!success) return;
                          await _fetchAdminList();
                          Navigator.pop(dialogContext);
                        },
                  child: _addingAdmin
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_t("createAdmin")),
                );
              },
            ),
          ],
        );
      },
    ).whenComplete(() {
      usernameController.dispose();
      passwordController.dispose();
    });
  }

  void _clearForm() {
    _editingId = null;
    _titleController.clear();
    _teacherController.clear();
    _linkController.clear();
    _categoryController.clear();

    _bodyController.clear();
    setState(() {});
  }

  void _startEdit(Lyric lyric) {
    _editingId = lyric.id;
    _titleController.text = lyric.title;
    _teacherController.text = lyric.teacher;
    _linkController.text = lyric.link;
    _categoryController.text = lyric.category;

    _bodyController.text = lyric.body;
    setState(() {});
  }

  void _openSubcategoryManagerFromNav() {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("addCategoryFirst"))),
      );
      return;
    }
    _fetchSubcategories(categoryId: _categories.first["_id"]?.toString());
    _showSubcategoryManager();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 1100;
    return Scaffold(
      drawer: isWideScreen ? null : _buildDrawer(),
      appBar: AppBar(
        title: Text(_t("appTitle")),
        actions: [
          if (isWideScreen)
            IconButton(
              tooltip: _sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar",
              icon: Icon(
                _sidebarCollapsed
                    ? Icons.keyboard_double_arrow_right
                    : Icons.keyboard_double_arrow_left,
              ),
              onPressed: () {
                setState(() {
                  _sidebarCollapsed = !_sidebarCollapsed;
                });
              },
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _language = _language == AppLanguage.en
                    ? AppLanguage.am
                    : AppLanguage.en;
              });
            },
            child: Text(
              _language == AppLanguage.en ? "አማ" : "EN",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7F1E6), Color(0xFFE7F2F1)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            if (isWide) {
              return Row(
                children: [
                  _buildSidebarPanel(),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                          child: _buildHeroSection(isWide: true),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildFormCard(),
                                      const SizedBox(height: 16),
                                      _buildBroadcastCard(),
                                      const SizedBox(height: 16),
                                      _buildBroadcastHistoryCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(child: _buildListCard(isEmbedded: false)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              controller: _pageScrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildHeroSection(isWide: false),
                  const SizedBox(height: 16),
                  _buildFormCard(),
                  const SizedBox(height: 16),
                  _buildBroadcastCard(),
                  const SizedBox(height: 16),
                  _buildBroadcastHistoryCard(),
                  const SizedBox(height: 16),
                  _buildAdminAccountsCard(),
                  const SizedBox(height: 16),
                  _buildListCard(isEmbedded: true),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebarPanel() {
    final width = _sidebarCollapsed ? 82.0 : 250.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: width,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_brandOcean, _brandInk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _brandInk.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            _sidebarCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 0 : 18),
            child: Row(
              mainAxisAlignment: _sidebarCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!_sidebarCollapsed)
                  Expanded(
                    child: Text(
                      _t("postsControl"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                IconButton(
                  tooltip:
                      _sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar",
                  onPressed: () {
                    setState(() {
                      _sidebarCollapsed = !_sidebarCollapsed;
                    });
                  },
                  icon: Icon(
                    _sidebarCollapsed
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSidebarNavItem(
            icon: Icons.dashboard_outlined,
            label: _t("dashboard"),
            onTap: () {},
          ),
          _buildSidebarNavItem(
            icon: Icons.category_outlined,
            label: _t("categories"),
            onTap: _showCategoryManager,
          ),
          _buildSidebarNavItem(
            icon: Icons.account_tree_outlined,
            label: _t("subcategoriesDialogTitle"),
            onTap: _openSubcategoryManagerFromNav,
          ),
          _buildSidebarNavItem(
            icon: Icons.person_add_alt_1_outlined,
            label: _t("addAdmin"),
            onTap: _showAddAdminDialog,
          ),
          _buildSidebarNavItem(
            icon: Icons.settings_outlined,
            label: _t("settings"),
            onTap: () {},
          ),
          const Spacer(),
          if (!_sidebarCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _t("offlineFirstAdmin"),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.78),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarCollapsed ? 0 : 14,
            vertical: 11,
          ),
          child: Row(
            mainAxisAlignment:
                _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.92), size: 21),
              if (!_sidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 8 : 12, vertical: 4),
      child: _sidebarCollapsed ? Tooltip(message: label, child: item) : item,
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_brandOcean, _brandInk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                _t("postsControl"),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard_outlined,
            label: _t("dashboard"),
            onTap: () => Navigator.of(context).pop(),
          ),
          _buildDrawerItem(
            icon: Icons.category_outlined,
            label: _t("categories"),
            onTap: () {
              Navigator.of(context).pop();
              _showCategoryManager();
            },
          ),
          _buildDrawerItem(
            icon: Icons.account_tree_outlined,
            label: _t("subcategoriesDialogTitle"),
            onTap: () {
              Navigator.of(context).pop();
              _openSubcategoryManagerFromNav();
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            label: _t("settings"),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: Text(_t("addAdmin")),
            onTap: () {
              Navigator.of(context).pop();
              _showAddAdminDialog();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _t("offlineFirstAdmin"),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _brandInk.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _brandOcean),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _buildHeroSection({required bool isWide}) {
    return AnimatedOpacity(
      opacity: _heroVisible ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 700),
        offset: _heroVisible ? Offset.zero : const Offset(0, 0.06),
        child: Container(
          padding: EdgeInsets.all(isWide ? 28 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _brandOcean.withOpacity(0.95),
                _brandInk.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _brandInk.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _brandMint.withOpacity(0.2),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _brandCoral.withOpacity(0.25),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t("heroTitle"),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t("heroSubtitle"),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.add),
                        label: Text(_t("newPost")),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loadLyrics,
                        icon: const Icon(Icons.refresh),
                        label: Text(_t("refresh")),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildHeroStat(
                        label: _t("statPosts"),
                        value: _lyrics.length.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStat({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingId == null ? _t("createPost") : _t("editPost"),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              _t("formHint"),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _brandInk.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: _t("labelTitle")),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teacherController,
              decoration: InputDecoration(labelText: _t("labelTeacher")),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(labelText: _t("labelLink")),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryController.text.isEmpty
                  ? null
                  : _categoryController.text,
              items: _categories
                  .map((category) => category["name"]?.toString() ?? "")
                  .where((name) => name.isNotEmpty)
                  .map(
                    (name) => DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    ),
                  )
                  .toList(),
              onChanged: _categories.isEmpty
                  ? null
                  : (value) {
                      _categoryController.text = value ?? "";
                      setState(() {});
                    },
              decoration: InputDecoration(
                labelText: _t("labelCategory"),
                helperText:
                    _categories.isEmpty ? _t("addCategoriesDrawer") : null,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: _t("labelPost"),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: _brandCoral),
                      ),
                    ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveLyric,
                  child: Text(
                    _editingId == null ? _t("create") : _t("update"),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: Text(_t("clear")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard({required bool isEmbedded}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _t("postsLibraryTitle"),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _brandSand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_lyrics.length} ${_t("total")}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _t("postsLibraryHint"),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _brandInk.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            if (isEmbedded)
              _buildList(isEmbedded: true)
            else
              Expanded(
                child: _buildList(isEmbedded: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t("broadcastTitle"),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              _t("broadcastHint"),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _brandInk.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notificationController,
              decoration: InputDecoration(
                labelText: _t("notificationMessage"),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            if (_notificationStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _notificationStatus!,
                  style: TextStyle(
                    color: _notificationStatus == _t("notificationSent")
                        ? _brandOcean
                        : _brandCoral,
                  ),
                ),
              ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _sendingNotification ? null : _sendNotification,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    _sendingNotification ? _t("sending") : _t("send"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _t("broadcastListTitle"),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: _t("refresh"),
                  onPressed: _fetchBroadcastMessages,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingBroadcastMessages)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_broadcastError != null)
              Text(
                _broadcastError!,
                style: TextStyle(color: _brandCoral),
              )
            else if (_broadcastMessages.isEmpty)
              Text(
                _t("broadcastListHint"),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Column(
                children: _broadcastMessages.asMap().entries.map(
                  (entry) {
                    final broadcast = entry.value;
                    final createdAt = _formatAdminCreatedAt(
                        broadcast["createdAt"]?.toString());
                    final isLast = entry.key == _broadcastMessages.length - 1;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            broadcast["message"]?.toString() ?? "",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: createdAt == null ? null : Text(createdAt),
                          trailing: IconButton(
                            tooltip: _t("deleteBroadcast"),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDeleteBroadcast(broadcast),
                          ),
                        ),
                        if (!isLast) const Divider(height: 0),
                      ],
                    );
                  },
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAccountsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _t("adminListTitle"),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: _t("refresh"),
                  onPressed: _fetchAdminList,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingAdminList)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_adminListError != null)
              Text(
                _adminListError!,
                style: TextStyle(color: _brandCoral),
              )
            else if (_adminAccounts.isEmpty)
              Text(
                _t("adminListHint"),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Column(
                children: _adminAccounts.asMap().entries.map(
                  (entry) {
                    final admin = entry.value;
                    final isLast = entry.key == _adminAccounts.length - 1;
                    final passwordText = admin.passwordHint?.isNotEmpty == true
                        ? "${_t("adminPassword")}: ${admin.passwordHint}"
                        : _t("adminPasswordHidden");
                    final createdAt = _formatAdminCreatedAt(admin.createdAt);
                    return Column(
                      children: [
                        ListTile(
                          title: Row(
                            children: [
                              Text(admin.username),
                              if (admin.isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Chip(
                                    label: Text(_t("defaultAdminLabel")),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(passwordText),
                              if (createdAt != null)
                                Text("${_t("adminCreatedLabel")}: $createdAt"),
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: _t("deleteAdmin"),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: admin.isDefault
                                ? null
                                : () => _confirmDeleteAdmin(admin),
                          ),
                        ),
                        if (!isLast) const Divider(height: 0),
                      ],
                    );
                  },
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList({required bool isEmbedded}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_lyrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _t("noPosts"),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: _brandInk.withOpacity(0.6)),
          ),
        ),
      );
    }

    if (isEmbedded) {
      return Column(
        children: _lyrics
            .map(
              (lyric) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLyricTile(lyric),
              ),
            )
            .toList(),
      );
    }

    return ListView.separated(
      itemCount: _lyrics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lyric = _lyrics[index];
        return _buildLyricTile(lyric);
      },
    );
  }

  String _parseErrorMessage(http.Response response, String fallback) {
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

  Widget _buildLyricTile(Lyric lyric) {
    final subtitle = [lyric.teacher, lyric.category]
        .where((value) => value.isNotEmpty)
        .join(" - ");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandClay),
      ),
      child: ListTile(
        title: Text(lyric.title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        onTap: () => _startEdit(lyric),
        trailing: IconButton(
          tooltip: "Delete",
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteLyric(lyric.id),
        ),
      ),
    );
  }
}

class AdminAccount {
  final String username;
  final String? createdAt;
  final bool isDefault;
  final String? passwordHint;

  AdminAccount({
    required this.username,
    this.createdAt,
    this.isDefault = false,
    this.passwordHint,
  });

  factory AdminAccount.fromJson(Map<String, dynamic> data) {
    final username = data["username"]?.toString().trim() ?? "";
    return AdminAccount(
      username: username,
      createdAt: data["createdAt"]?.toString(),
      isDefault: data["isDefault"] == true,
      passwordHint: data["password"]?.toString(),
    );
  }
}

class Lyric {
  Lyric({
    required this.id,
    required this.title,
    required this.body,
    required this.teacher,
    required this.category,
    required this.link,
  });

  final String id;
  final String title;
  final String body;
  final String teacher;
  final String category;
  final String link;

  factory Lyric.fromJson(Map<String, dynamic> json) {
    return Lyric(
      id: json["_id"]?.toString() ?? json["id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      body: json["body"]?.toString() ?? "",
      teacher: json["teacher"]?.toString() ?? "",
      category: json["category"]?.toString() ?? "",
      link: json["link"]?.toString() ?? "",
    );
  }
}
