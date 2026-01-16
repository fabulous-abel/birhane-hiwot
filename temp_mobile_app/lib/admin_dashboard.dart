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
    "importPdf": "Import PDF",
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
    "categoriesDialogTitle": "Categories",
    "subcategoriesDialogTitle": "Subcategories",
    "addCategory": "Add category",
    "addSubcategory": "Add subcategory",
    "noCategories": "No categories yet.",
    "noSubcategories": "No subcategories yet.",
    "unnamed": "Unnamed",
    "close": "Close",
    "add": "Add",
    "selectCategory": "Select category",
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
  },
  AppLanguage.am: {
    "appTitle": "የጽሑፍ አስተዳዳሪ",
    "importPdf": "PDF አስገባ",
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
    "categoriesDialogTitle": "ምድቦች",
    "subcategoriesDialogTitle": "ንዑስ ምድቦች",
    "addCategory": "ምድብ ጨምር",
    "addSubcategory": "ንዑስ ምድብ ጨምር",
    "noCategories": "ምንም ምድብ የለም።",
    "noSubcategories": "ምንም ንዑስ ምድብ የለም።",
    "unnamed": "ያልተሰየመ",
    "close": "ዝጋ",
    "add": "ጨምር",
    "selectCategory": "ምድብ ምረጥ",
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
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x1418232B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();

  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _notificationController = TextEditingController();
  final ScrollController _pageScrollController = ScrollController();

  List<Lyric> _lyrics = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  bool _loading = false;
  bool _heroVisible = false;
  bool _sendingNotification = false;
  bool _loadingCategories = false;
  bool _loadingSubcategories = false;
  String? _editingId;
  String? _error;
  String? _notificationStatus;
  AppLanguage _language = AppLanguage.en;

  String _t(String key) {
    return _strings[_language]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _fetchCategories();
    _fetchSubcategories();
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
    _categoryController.dispose();
    _subCategoryController.dispose();

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
      setState(() {
        _lyrics = data.map((item) => Lyric.fromJson(item)).toList();
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

  Future<void> _saveLyric() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final category = _categoryController.text.trim();
    final subCategory = _subCategoryController.text.trim();
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
      "subCategory": subCategory,
      "body": body
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
      final response =
          await http.delete(Uri.parse("$adminApiBaseUrl/api/posts/$id"));
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

  Future<void> _fetchCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final response = await http.get(Uri.parse("$adminApiBaseUrl/api/categories"));
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
          : Uri.parse("$adminApiBaseUrl/api/subcategories?categoryId=$categoryId");
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
      final response =
          await http.delete(Uri.parse("$adminApiBaseUrl/api/subcategories/$id"));
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

  String? _selectedCategoryId() {
    final selected = _categoryController.text.trim();
    if (selected.isEmpty) return null;
    final match = _categories.firstWhere(
      (category) => category["name"]?.toString() == selected,
      orElse: () => {},
    );
    return match["_id"]?.toString();
  }

  List<Map<String, dynamic>> get _visibleSubcategories {
    final categoryId = _selectedCategoryId();
    if (categoryId == null) {
      return [];
    }
    return _subcategories
        .where((subcategory) =>
            subcategory["categoryId"]?.toString() == categoryId)
        .toList();
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

  Future<void> _importPdf() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("addCategoryFirst"))),
      );
      return;
    }
    String? selectedCategory = _categories.first["name"]?.toString();
    final category = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_t("selectCategory")),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                value: selectedCategory,
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
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                decoration: InputDecoration(labelText: _t("labelCategory")),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t("cancel")),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedCategory?.trim());
              },
              child: Text(_t("continue")),
            ),
          ],
        );
      },
    );
    if (category == null || category.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("PDF import is only available on the web admin."),
      ),
    );
  }

  void _clearForm() {
    _editingId = null;
    _titleController.clear();
    _teacherController.clear();
    _categoryController.clear();
    _subCategoryController.clear();

    _bodyController.clear();
    setState(() {});
  }

  void _startEdit(Lyric lyric) {
    _editingId = lyric.id;
    _titleController.text = lyric.title;
    _teacherController.text = lyric.teacher;
    _categoryController.text = lyric.category;
    _subCategoryController.text = lyric.subCategory;

    _bodyController.text = lyric.body;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(_t("appTitle")),
        actions: [
          IconButton(
            tooltip: _t("importPdf"),
            onPressed: _importPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
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
              return Column(
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
                  _buildListCard(isEmbedded: true),
                ],
              ),
            );
          },
        ),
      ),
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
            icon: Icons.library_music_outlined,
            label: _t("postsLibrary"),
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
              if (_categories.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_t("addCategoryFirst"))),
                );
                return;
              }
              _fetchSubcategories(
                  categoryId: _categories.first["_id"]?.toString());
              _showSubcategoryManager();
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            label: _t("settings"),
            onTap: () => Navigator.of(context).pop(),
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
                      _subCategoryController.clear();
                      final categoryId = _selectedCategoryId();
                      if (categoryId != null) {
                        _fetchSubcategories(categoryId: categoryId);
                      } else {
                        _fetchSubcategories();
                      }
                      setState(() {});
                    },
              decoration: InputDecoration(
                labelText: _t("labelCategory"),
                helperText:
                    _categories.isEmpty ? _t("addCategoriesDrawer") : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _subCategoryController.text.isEmpty
                  ? null
                  : _subCategoryController.text,
              items: _visibleSubcategories
                  .map((subcategory) => subcategory["name"]?.toString() ?? "")
                  .where((name) => name.isNotEmpty)
                  .map(
                    (name) => DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    ),
                  )
                  .toList(),
              onChanged: _visibleSubcategories.isEmpty
                  ? null
                  : (value) {
                      _subCategoryController.text = value ?? "";
                      setState(() {});
                    },
              decoration: InputDecoration(
                labelText: _t("labelSubcategory"),
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

  Widget _buildLyricTile(Lyric lyric) {
    final subtitle = [lyric.teacher, lyric.category, lyric.subCategory]
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

class Lyric {
  Lyric({
    required this.id,
    required this.title,
    required this.body,
    required this.teacher,
    required this.category,
    required this.subCategory,
  });

  final String id;
  final String title;
  final String body;
  final String teacher;
  final String category;
  final String subCategory;

  factory Lyric.fromJson(Map<String, dynamic> json) {
    return Lyric(
      id: json["_id"]?.toString() ?? json["id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      body: json["body"]?.toString() ?? "",
      teacher: json["teacher"]?.toString() ?? "",
      category: json["category"]?.toString() ?? "",
      subCategory: json["subCategory"]?.toString() ?? "",
    );
  }
}
