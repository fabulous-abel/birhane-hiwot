import { startTransition, useDeferredValue, useEffect, useRef, useState } from "react";
import DashboardView from "./DashboardView.jsx";
import LoginView from "./LoginView.jsx";

const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || "http://localhost:4000"
).replace(/\/$/, "");
const SESSION_STORAGE_KEY = "lyrics-admin-session";

const emptyPostForm = {
  title: "",
  teacher: "",
  link: "",
  category: "",
  subCategory: "",
  language: "",
  tags: "",
  body: ""
};

const emptyCredentials = {
  username: "",
  password: ""
};

const emptySubcategoryDraft = {
  name: "",
  categoryId: ""
};

const bulkPostsExample = JSON.stringify(
  [
    {
      title: "Morning Worship",
      teacher: "Choir",
      category: "Worship",
      subCategory: "Sunday Service",
      language: "English",
      tags: ["worship", "opening"],
      link: "https://example.com/morning-worship",
      body: "Full lyrics or post body goes here."
    },
    {
      title: "Evening Prayer",
      teacher: "Youth Team",
      category: "Prayer",
      subCategory: "Evening",
      language: "Amharic",
      tags: "prayer, devotion",
      body: "Second post body goes here."
    }
  ],
  null,
  2
);

function formatDate(value) {
  if (!value) return "Just now";
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleString();
}

function joinTags(tags) {
  return Array.isArray(tags) ? tags.join(", ") : "";
}

function splitTags(value) {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function isAuthError(error) {
  return error?.status === 401 || error?.status === 403;
}

function readStoredSession() {
  if (typeof window === "undefined") return null;

  try {
    const rawValue = window.localStorage.getItem(SESSION_STORAGE_KEY);
    const parsed = rawValue ? JSON.parse(rawValue) : null;
    return parsed?.token ? parsed : null;
  } catch {
    return null;
  }
}

function writeStoredSession(session) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(session));
}

function clearStoredSession() {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem(SESSION_STORAGE_KEY);
}

function normalizeBulkPosts(rawValue) {
  if (!rawValue.trim()) {
    throw new Error("Paste a JSON array of posts first.");
  }

  let parsed;
  try {
    parsed = JSON.parse(rawValue);
  } catch {
    throw new Error("Bulk create expects valid JSON.");
  }

  const items = Array.isArray(parsed)
    ? parsed
    : Array.isArray(parsed?.posts)
      ? parsed.posts
      : null;

  if (!items?.length) {
    throw new Error("Provide a non-empty JSON array of posts.");
  }

  return items.map((item, index) => {
    if (!item || typeof item !== "object" || Array.isArray(item)) {
      throw new Error(`Post ${index + 1} must be a JSON object.`);
    }

    return {
      title: item.title?.toString() ?? "",
      teacher: item.teacher?.toString() ?? "",
      link: item.link?.toString() ?? "",
      category: item.category?.toString() ?? "",
      subCategory: item.subCategory?.toString() ?? "",
      language: item.language?.toString() ?? "",
      tags: Array.isArray(item.tags)
        ? item.tags.map((tag) => tag?.toString?.() ?? "").filter(Boolean)
        : typeof item.tags === "string"
          ? splitTags(item.tags)
          : [],
      body: item.body?.toString() ?? ""
    };
  });
}

async function apiFetch(path, options = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      Accept: "application/json",
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...(options.authToken
        ? { Authorization: `Bearer ${options.authToken}` }
        : {}),
      ...(options.headers || {})
    },
    ...options
  });

  const contentType = response.headers.get("content-type") || "";
  const payload = contentType.includes("application/json")
    ? await response.json().catch(() => null)
    : await response.text().catch(() => "");

  if (!response.ok) {
    const message =
      (typeof payload === "object" && payload?.error) ||
      (typeof payload === "object" && payload?.message) ||
      (typeof payload === "string" && payload) ||
      `Request failed with status ${response.status}`;
    const error = new Error(message);
    error.status = response.status;
    error.payload = payload;
    throw error;
  }

  return payload;
}

export default function App() {
  const formCardRef = useRef(null);
  const bulkCardRef = useRef(null);

  const [auth, setAuth] = useState({
    status: "restoring",
    token: "",
    admin: null,
    expiresAt: ""
  });
  const [posts, setPosts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [subcategories, setSubcategories] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [admins, setAdmins] = useState([]);
  const [postForm, setPostForm] = useState(emptyPostForm);
  const [bulkPostsInput, setBulkPostsInput] = useState("");
  const [editingId, setEditingId] = useState("");
  const [categoryDraft, setCategoryDraft] = useState("");
  const [categoryEditId, setCategoryEditId] = useState("");
  const [categoryEditName, setCategoryEditName] = useState("");
  const [subcategoryDraft, setSubcategoryDraft] = useState(emptySubcategoryDraft);
  const [subcategoryEditId, setSubcategoryEditId] = useState("");
  const [subcategoryEditName, setSubcategoryEditName] = useState("");
  const [notificationMessage, setNotificationMessage] = useState("");
  const [adminForm, setAdminForm] = useState(emptyCredentials);
  const [loginForm, setLoginForm] = useState(emptyCredentials);
  const [search, setSearch] = useState("");
  const [notice, setNotice] = useState({ tone: "idle", text: "" });
  const [busy, setBusy] = useState({
    auth: false,
    boot: false,
    refresh: false,
    post: false,
    bulk: false,
    category: false,
    subcategory: false,
    notification: false,
    admin: false
  });

  const deferredSearch = useDeferredValue(search);
  const isAuthenticated = auth.status === "authenticated";
  const selectedCategory = categories.find(
    (category) => category?.name?.toString() === postForm.category
  );
  const visibleSubcategories = selectedCategory
    ? subcategories.filter(
        (subcategory) =>
          subcategory?.categoryId?.toString() === selectedCategory?._id?.toString()
      )
    : [];
  const managedSubcategories = subcategoryDraft.categoryId
    ? subcategories.filter(
        (subcategory) =>
          subcategory?.categoryId?.toString() === subcategoryDraft.categoryId
      )
    : subcategories;
  const filteredPosts = posts.filter((post) =>
    [post.title, post.teacher, post.category, post.subCategory, post.body]
      .join(" ")
      .toLowerCase()
      .includes(deferredSearch.trim().toLowerCase())
  );

  useEffect(() => {
    const storedSession = readStoredSession();

    if (!storedSession?.token) {
      setAuth({ status: "guest", token: "", admin: null, expiresAt: "" });
      return;
    }

    async function restoreSession() {
      setBusy((current) => ({ ...current, auth: true }));

      try {
        const currentAdmin = await apiFetch("/api/admins/me", {
          authToken: storedSession.token
        });
        commitSession(storedSession.token, currentAdmin, storedSession.expiresAt || "");
        const synced = await refreshDashboard(storedSession.token, true);
        if (synced) {
          setNotice({
            tone: "success",
            text: `Welcome back, ${currentAdmin.username}.`
          });
        }
      } catch (error) {
        clearStoredSession();
        resetDashboardState();
        setAuth({ status: "guest", token: "", admin: null, expiresAt: "" });
        setNotice({
          tone: "warning",
          text: isAuthError(error)
            ? "Session expired. Please sign in again."
            : error.message
        });
      } finally {
        setBusy((current) => ({ ...current, auth: false }));
      }
    }

    void restoreSession();
  }, []);

  useEffect(() => {
    if (!categories.length || subcategoryDraft.categoryId) return;
    setSubcategoryDraft((current) => ({
      ...current,
      categoryId: categories[0]?._id?.toString() || ""
    }));
  }, [categories, subcategoryDraft.categoryId]);

  useEffect(() => {
    if (
      !postForm.subCategory ||
      visibleSubcategories.some(
        (subcategory) => subcategory?.name?.toString() === postForm.subCategory
      )
    ) {
      return;
    }

    setPostForm((current) => ({ ...current, subCategory: "" }));
  }, [postForm.subCategory, visibleSubcategories]);

  function commitSession(token, admin, expiresAt = "") {
    const session = { status: "authenticated", token, admin, expiresAt };
    setAuth(session);
    writeStoredSession({ token, admin, expiresAt });
  }

  function resetPostForm() {
    setEditingId("");
    setPostForm(emptyPostForm);
  }

  function resetDashboardState() {
    setPosts([]);
    setCategories([]);
    setSubcategories([]);
    setNotifications([]);
    setAdmins([]);
    resetPostForm();
    setBulkPostsInput("");
    setCategoryDraft("");
    setCategoryEditId("");
    setCategoryEditName("");
    setSubcategoryDraft(emptySubcategoryDraft);
    setSubcategoryEditId("");
    setSubcategoryEditName("");
    setNotificationMessage("");
    setAdminForm(emptyCredentials);
    setSearch("");
  }

  function signOut(message = "Signed out.") {
    clearStoredSession();
    resetDashboardState();
    setAuth({ status: "guest", token: "", admin: null, expiresAt: "" });
    setBusy((current) => ({
      ...current,
      auth: false,
      boot: false,
      refresh: false,
      post: false,
      bulk: false,
      category: false,
      subcategory: false,
      notification: false,
      admin: false
    }));
    setNotice(message ? { tone: "warning", text: message } : { tone: "idle", text: "" });
  }

  function handleProtectedError(error) {
    if (isAuthError(error)) {
      signOut("Session expired. Please sign in again.");
      return true;
    }
    return false;
  }

  async function loadPosts() {
    const data = await apiFetch("/api/posts");
    return Array.isArray(data) ? data : [];
  }

  async function loadCategories() {
    const data = await apiFetch("/api/categories");
    return Array.isArray(data) ? data : [];
  }

  async function loadSubcategories() {
    const data = await apiFetch("/api/subcategories");
    return Array.isArray(data) ? data : [];
  }

  async function loadNotifications() {
    const data = await apiFetch("/api/notifications");
    return Array.isArray(data) ? data : [];
  }

  async function loadAdmins(token = auth.token) {
    const data = await apiFetch("/api/admins", { authToken: token });
    return Array.isArray(data) ? data : [];
  }

  async function refreshDashboard(token = auth.token, initial = false) {
    if (!token) return false;

    setBusy((current) => ({ ...current, boot: initial, refresh: !initial }));
    const loaders = [
      { label: "posts", setter: setPosts, promise: loadPosts() },
      { label: "categories", setter: setCategories, promise: loadCategories() },
      { label: "subcategories", setter: setSubcategories, promise: loadSubcategories() },
      { label: "notifications", setter: setNotifications, promise: loadNotifications() },
      { label: "admins", setter: setAdmins, promise: loadAdmins(token) }
    ];
    const results = await Promise.allSettled(loaders.map((entry) => entry.promise));
    let authFailure = null;
    const failures = [];

    results.forEach((result, index) => {
      const entry = loaders[index];
      if (result.status === "fulfilled") {
        entry.setter(result.value);
      } else {
        if (!authFailure && isAuthError(result.reason)) authFailure = result.reason;
        failures.push(`Failed to load ${entry.label}: ${result.reason?.message || "Unknown error"}`);
      }
    });

    setBusy((current) => ({ ...current, boot: false, refresh: false }));

    if (authFailure) {
      handleProtectedError(authFailure);
      return false;
    }

    if (failures.length) {
      setNotice({ tone: "warning", text: failures[0] });
      return false;
    }

    if (!initial) {
      setNotice({ tone: "success", text: "Dashboard synced." });
    }

    return true;
  }

  async function handleLoginSubmit(event) {
    event.preventDefault();
    if (!loginForm.username.trim() || !loginForm.password.trim()) {
      setNotice({ tone: "danger", text: "Username and password are required." });
      return;
    }

    setBusy((current) => ({ ...current, auth: true }));
    try {
      const session = await apiFetch("/api/admins/login", {
        method: "POST",
        body: JSON.stringify({
          username: loginForm.username.trim(),
          password: loginForm.password.trim()
        })
      });
      commitSession(session.token, session.admin, session.expiresAt || "");
      setLoginForm(emptyCredentials);
      const synced = await refreshDashboard(session.token, true);
      if (synced) {
        setNotice({ tone: "success", text: `Welcome back, ${session.admin.username}.` });
      }
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, auth: false }));
    }
  }

  function ensureToken() {
    if (auth.token) return auth.token;
    signOut("Session expired. Please sign in again.");
    return "";
  }

  function beginPostEdit(post) {
    startTransition(() => {
      setEditingId(post?._id?.toString() || "");
      setPostForm({
        title: post?.title || "",
        teacher: post?.teacher || "",
        link: post?.link || "",
        category: post?.category || "",
        subCategory: post?.subCategory || "",
        language: post?.language || "",
        tags: joinTags(post?.tags),
        body: post?.body || ""
      });
    });

    formCardRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  async function handlePostSubmit(event) {
    event.preventDefault();
    if (!postForm.title.trim() || !postForm.body.trim()) {
      setNotice({ tone: "danger", text: "Title and post body are required." });
      return;
    }
    if (!postForm.category.trim()) {
      setNotice({ tone: "danger", text: "Category is required." });
      return;
    }

    const token = ensureToken();
    if (!token) return;

    setBusy((current) => ({ ...current, post: true }));
    try {
      const payload = {
        title: postForm.title.trim(),
        teacher: postForm.teacher.trim(),
        link: postForm.link.trim(),
        category: postForm.category.trim(),
        subCategory: postForm.subCategory.trim(),
        language: postForm.language.trim(),
        tags: splitTags(postForm.tags),
        body: postForm.body.trim()
      };
      if (editingId) {
        await apiFetch(`/api/posts/${editingId}`, {
          method: "PUT",
          body: JSON.stringify(payload),
          authToken: token
        });
        setPosts(await loadPosts());
      } else {
        await apiFetch("/api/posts", {
          method: "POST",
          body: JSON.stringify(payload),
          authToken: token
        });
        const [freshPosts, freshNotifications] = await Promise.all([
          loadPosts(),
          loadNotifications()
        ]);
        setPosts(freshPosts);
        setNotifications(freshNotifications);
      }
      resetPostForm();
      setNotice({ tone: "success", text: editingId ? "Post updated." : "Post created." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, post: false }));
    }
  }

  async function handleBulkPostSubmit(event) {
    event.preventDefault();
    const token = ensureToken();
    if (!token) return;

    setBusy((current) => ({ ...current, bulk: true }));
    try {
      const postsToCreate = normalizeBulkPosts(bulkPostsInput);
      await apiFetch("/api/posts/bulk", {
        method: "POST",
        body: JSON.stringify({ posts: postsToCreate }),
        authToken: token
      });
      const [freshPosts, freshNotifications] = await Promise.all([
        loadPosts(),
        loadNotifications()
      ]);
      setPosts(freshPosts);
      setNotifications(freshNotifications);
      setBulkPostsInput("");
      setNotice({ tone: "success", text: `${postsToCreate.length} posts created.` });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, bulk: false }));
    }
  }

  async function handleDeletePost(post) {
    if (!window.confirm(`Delete "${post.title || "this post"}"?`)) return;
    const token = ensureToken();
    if (!token) return;

    try {
      await apiFetch(`/api/posts/${post._id}`, { method: "DELETE", authToken: token });
      setPosts(await loadPosts());
      if (editingId === post._id) resetPostForm();
      setNotice({ tone: "success", text: "Post deleted." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleNotificationSubmit(event) {
    event.preventDefault();
    if (!notificationMessage.trim()) {
      setNotice({ tone: "danger", text: "Notification message is required." });
      return;
    }
    const token = ensureToken();
    if (!token) return;

    setBusy((current) => ({ ...current, notification: true }));
    try {
      await apiFetch("/api/notifications", {
        method: "POST",
        body: JSON.stringify({ message: notificationMessage.trim() }),
        authToken: token
      });
      setNotificationMessage("");
      setNotifications(await loadNotifications());
      setNotice({ tone: "success", text: "Notification sent." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, notification: false }));
    }
  }

  async function handleDeleteNotification(notification) {
    if (!window.confirm("Delete this broadcast message?")) return;
    const token = ensureToken();
    if (!token) return;
    try {
      await apiFetch(`/api/notifications/${notification._id}`, {
        method: "DELETE",
        authToken: token
      });
      setNotifications(await loadNotifications());
      setNotice({ tone: "success", text: "Broadcast deleted." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleCategoryCreate(event) {
    event.preventDefault();
    if (!categoryDraft.trim()) return;
    const token = ensureToken();
    if (!token) return;

    setBusy((current) => ({ ...current, category: true }));
    try {
      await apiFetch("/api/categories", {
        method: "POST",
        body: JSON.stringify({ name: categoryDraft.trim() }),
        authToken: token
      });
      const [freshCategories, freshSubcategories] = await Promise.all([
        loadCategories(),
        loadSubcategories()
      ]);
      setCategories(freshCategories);
      setSubcategories(freshSubcategories);
      setCategoryDraft("");
      setNotice({ tone: "success", text: "Category added." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, category: false }));
    }
  }

  async function saveCategoryEdit() {
    if (!categoryEditId || !categoryEditName.trim()) return;
    const token = ensureToken();
    if (!token) return;
    try {
      await apiFetch(`/api/categories/${categoryEditId}`, {
        method: "PUT",
        body: JSON.stringify({ name: categoryEditName.trim() }),
        authToken: token
      });
      setCategories(await loadCategories());
      setCategoryEditId("");
      setCategoryEditName("");
      setNotice({ tone: "success", text: "Category updated." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleDeleteCategory(category) {
    if (!window.confirm(`Delete category "${category.name || "Unnamed"}"?`)) return;
    const token = ensureToken();
    if (!token) return;
    try {
      await apiFetch(`/api/categories/${category._id}`, {
        method: "DELETE",
        authToken: token
      });
      const [freshCategories, freshSubcategories] = await Promise.all([
        loadCategories(),
        loadSubcategories()
      ]);
      setCategories(freshCategories);
      setSubcategories(freshSubcategories);
      setNotice({ tone: "success", text: "Category deleted." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleSubcategoryCreate(event) {
    event.preventDefault();
    if (!subcategoryDraft.categoryId || !subcategoryDraft.name.trim()) return;
    const token = ensureToken();
    if (!token) return;

    setBusy((current) => ({ ...current, subcategory: true }));
    try {
      await apiFetch("/api/subcategories", {
        method: "POST",
        body: JSON.stringify({
          name: subcategoryDraft.name.trim(),
          categoryId: subcategoryDraft.categoryId
        }),
        authToken: token
      });
      setSubcategories(await loadSubcategories());
      setSubcategoryDraft((current) => ({ ...current, name: "" }));
      setNotice({ tone: "success", text: "Subcategory added." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, subcategory: false }));
    }
  }

  async function saveSubcategoryEdit(categoryId) {
    if (!subcategoryEditId || !subcategoryEditName.trim() || !categoryId) return;
    const token = ensureToken();
    if (!token) return;
    try {
      await apiFetch(`/api/subcategories/${subcategoryEditId}`, {
        method: "PUT",
        body: JSON.stringify({ name: subcategoryEditName.trim(), categoryId }),
        authToken: token
      });
      setSubcategories(await loadSubcategories());
      setSubcategoryEditId("");
      setSubcategoryEditName("");
      setNotice({ tone: "success", text: "Subcategory updated." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleDeleteSubcategory(subcategory) {
    if (!window.confirm(`Delete subcategory "${subcategory.name || "Unnamed"}"?`)) return;
    const token = ensureToken();
    if (!token) return;
    try {
      await apiFetch(`/api/subcategories/${subcategory._id}`, {
        method: "DELETE",
        authToken: token
      });
      setSubcategories(await loadSubcategories());
      setNotice({ tone: "success", text: "Subcategory deleted." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleAdminCreate(event) {
    event.preventDefault();
    if (!adminForm.username.trim() || !adminForm.password.trim()) {
      setNotice({ tone: "danger", text: "Admin username and password are required." });
      return;
    }
    const token = ensureToken();
    if (!token) return;

    setBusy((current) => ({ ...current, admin: true }));
    try {
      await apiFetch("/api/admins", {
        method: "POST",
        body: JSON.stringify({
          username: adminForm.username.trim(),
          password: adminForm.password.trim()
        }),
        authToken: token
      });
      setAdmins(await loadAdmins(token));
      setAdminForm(emptyCredentials);
      setNotice({ tone: "success", text: "Admin account created." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, admin: false }));
    }
  }

  async function handleDeleteAdmin(admin) {
    if (!window.confirm(`Delete admin account "${admin.username}"?`)) return;
    const token = ensureToken();
    if (!token) return;
    try {
      await apiFetch(`/api/admins/${encodeURIComponent(admin.username)}`, {
        method: "DELETE",
        authToken: token
      });
      setAdmins(await loadAdmins(token));
      setNotice({ tone: "success", text: "Admin deleted." });
    } catch (error) {
      if (!handleProtectedError(error)) setNotice({ tone: "danger", text: error.message });
    }
  }

  if (!isAuthenticated) {
    return (
      <LoginView
        loginForm={loginForm}
        onLoginFormChange={setLoginForm}
        onSubmit={handleLoginSubmit}
        busy={busy.auth || auth.status === "restoring"}
        notice={notice}
      />
    );
  }

  return (
    <DashboardView
      apiBaseUrl={API_BASE_URL}
      auth={auth}
      notice={notice}
      busy={busy}
      posts={posts}
      notifications={notifications}
      categories={categories}
      subcategories={subcategories}
      admins={admins}
      managedSubcategories={managedSubcategories}
      visibleSubcategories={visibleSubcategories}
      filteredPosts={filteredPosts}
      search={search}
      setSearch={setSearch}
      postForm={postForm}
      setPostForm={setPostForm}
      bulkPostsInput={bulkPostsInput}
      setBulkPostsInput={setBulkPostsInput}
      categoryDraft={categoryDraft}
      setCategoryDraft={setCategoryDraft}
      categoryEditId={categoryEditId}
      categoryEditName={categoryEditName}
      setCategoryEditName={setCategoryEditName}
      subcategoryDraft={subcategoryDraft}
      setSubcategoryDraft={setSubcategoryDraft}
      subcategoryEditId={subcategoryEditId}
      subcategoryEditName={subcategoryEditName}
      setSubcategoryEditName={setSubcategoryEditName}
      notificationMessage={notificationMessage}
      setNotificationMessage={setNotificationMessage}
      adminForm={adminForm}
      setAdminForm={setAdminForm}
      editingId={editingId}
      formCardRef={formCardRef}
      bulkCardRef={bulkCardRef}
      formatDate={formatDate}
      onRefresh={() => refreshDashboard()}
      onLogout={() => signOut()}
      onScrollToPostForm={() => {
        resetPostForm();
        formCardRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
      }}
      onScrollToBulkCreate={() =>
        bulkCardRef.current?.scrollIntoView({ behavior: "smooth", block: "start" })
      }
      onResetPostForm={resetPostForm}
      onPostSubmit={handlePostSubmit}
      onBulkPostSubmit={handleBulkPostSubmit}
      onUseBulkExample={() => setBulkPostsInput(bulkPostsExample)}
      onNotificationSubmit={handleNotificationSubmit}
      onNotificationDelete={handleDeleteNotification}
      onBeginPostEdit={beginPostEdit}
      onDeletePost={handleDeletePost}
      onCategoryCreate={handleCategoryCreate}
      onBeginCategoryEdit={(category) => {
        setCategoryEditId(category?._id?.toString() || "");
        setCategoryEditName(category?.name?.toString() || "");
      }}
      onSaveCategoryEdit={saveCategoryEdit}
      onCancelCategoryEdit={() => {
        setCategoryEditId("");
        setCategoryEditName("");
      }}
      onDeleteCategory={handleDeleteCategory}
      onSubcategoryCreate={handleSubcategoryCreate}
      onBeginSubcategoryEdit={(subcategory) => {
        setSubcategoryEditId(subcategory?._id?.toString() || "");
        setSubcategoryEditName(subcategory?.name?.toString() || "");
        setSubcategoryDraft((current) => ({
          ...current,
          categoryId: subcategory?.categoryId?.toString() || current.categoryId
        }));
      }}
      onSaveSubcategoryEdit={saveSubcategoryEdit}
      onCancelSubcategoryEdit={() => {
        setSubcategoryEditId("");
        setSubcategoryEditName("");
      }}
      onDeleteSubcategory={handleDeleteSubcategory}
      onAdminCreate={handleAdminCreate}
      onDeleteAdmin={handleDeleteAdmin}
    />
  );
}
