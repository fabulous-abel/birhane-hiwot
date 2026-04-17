import { startTransition, useDeferredValue, useEffect, useRef, useState } from "react";

const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || "http://localhost:4000").replace(/\/$/, "");

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

const emptyAdminForm = {
  username: "",
  password: ""
};

function formatDate(value) {
  if (!value) {
    return "Just now";
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }

  return parsed.toLocaleString();
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

async function apiFetch(path, options = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      Accept: "application/json",
      ...(options.body ? { "Content-Type": "application/json" } : {}),
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
    throw new Error(message);
  }

  return payload;
}

function Panel({ eyebrow, title, subtitle, actions, children }) {
  return (
    <section className="panel section-panel">
      <div className="section-head">
        <div>
          {eyebrow ? <p className="eyebrow">{eyebrow}</p> : null}
          <h2>{title}</h2>
          {subtitle ? <p className="section-copy">{subtitle}</p> : null}
        </div>
        {actions ? <div className="section-actions">{actions}</div> : null}
      </div>
      {children}
    </section>
  );
}

export default function App() {
  const formCardRef = useRef(null);
  const [posts, setPosts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [subcategories, setSubcategories] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [admins, setAdmins] = useState([]);
  const [postForm, setPostForm] = useState(emptyPostForm);
  const [editingId, setEditingId] = useState("");
  const [categoryDraft, setCategoryDraft] = useState("");
  const [categoryEditId, setCategoryEditId] = useState("");
  const [categoryEditName, setCategoryEditName] = useState("");
  const [subcategoryDraft, setSubcategoryDraft] = useState({
    name: "",
    categoryId: ""
  });
  const [subcategoryEditId, setSubcategoryEditId] = useState("");
  const [subcategoryEditName, setSubcategoryEditName] = useState("");
  const [notificationMessage, setNotificationMessage] = useState("");
  const [adminForm, setAdminForm] = useState(emptyAdminForm);
  const [search, setSearch] = useState("");
  const [notice, setNotice] = useState({ tone: "idle", text: "" });
  const [busy, setBusy] = useState({
    boot: true,
    refresh: false,
    post: false,
    category: false,
    subcategory: false,
    notification: false,
    admin: false
  });

  const deferredSearch = useDeferredValue(search);
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
  const filteredPosts = posts.filter((post) => {
    const haystack = [
      post.title,
      post.teacher,
      post.category,
      post.subCategory,
      post.body
    ]
      .join(" ")
      .toLowerCase();
    return haystack.includes(deferredSearch.trim().toLowerCase());
  });
  const subcategoryStillValid =
    !postForm.subCategory ||
    visibleSubcategories.some(
      (subcategory) => subcategory?.name?.toString() === postForm.subCategory
    );

  useEffect(() => {
    void refreshDashboard({ initial: true });
  }, []);

  useEffect(() => {
    if (!categories.length) {
      return;
    }

    setSubcategoryDraft((current) => {
      if (current.categoryId) {
        return current;
      }

      return {
        ...current,
        categoryId: categories[0]?._id?.toString() || ""
      };
    });
  }, [categories]);

  useEffect(() => {
    if (!postForm.subCategory || subcategoryStillValid) {
      return;
    }

    setPostForm((current) => ({
      ...current,
      subCategory: ""
    }));
  }, [postForm.subCategory, subcategoryStillValid]);

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

  async function loadAdmins() {
    const data = await apiFetch("/api/admins");
    return Array.isArray(data) ? data : [];
  }

  async function refreshDashboard({ initial = false } = {}) {
    setBusy((current) => ({
      ...current,
      boot: initial,
      refresh: !initial
    }));

    const loaders = [
      { label: "posts", setter: setPosts, promise: loadPosts() },
      { label: "categories", setter: setCategories, promise: loadCategories() },
      {
        label: "subcategories",
        setter: setSubcategories,
        promise: loadSubcategories()
      },
      {
        label: "notifications",
        setter: setNotifications,
        promise: loadNotifications()
      },
      { label: "admins", setter: setAdmins, promise: loadAdmins() }
    ];

    const results = await Promise.allSettled(loaders.map((entry) => entry.promise));
    const failures = [];

    results.forEach((result, index) => {
      const entry = loaders[index];
      if (result.status === "fulfilled") {
        entry.setter(result.value);
      } else {
        failures.push(`Failed to load ${entry.label}: ${result.reason?.message || "Unknown error"}`);
      }
    });

    setBusy((current) => ({
      ...current,
      boot: false,
      refresh: false
    }));

    if (failures.length) {
      setNotice({ tone: "warning", text: failures[0] });
      return;
    }

    if (!initial) {
      setNotice({ tone: "success", text: "Dashboard synced." });
    }
  }

  function resetPostForm() {
    setEditingId("");
    setPostForm(emptyPostForm);
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

    formCardRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "start"
    });
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
          body: JSON.stringify(payload)
        });
      } else {
        await apiFetch("/api/posts", {
          method: "POST",
          body: JSON.stringify(payload)
        });
      }

      const [freshPosts, freshNotifications] = await Promise.all([
        loadPosts(),
        loadNotifications()
      ]);

      setPosts(freshPosts);
      setNotifications(freshNotifications);
      resetPostForm();
      setNotice({
        tone: "success",
        text: editingId ? "Post updated." : "Post created."
      });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, post: false }));
    }
  }

  async function handlePostDelete(post) {
    if (!window.confirm(`Delete "${post.title || "this post"}"?`)) {
      return;
    }

    try {
      await apiFetch(`/api/posts/${post._id}`, { method: "DELETE" });
      setPosts(await loadPosts());
      if (editingId === post._id) {
        resetPostForm();
      }
      setNotice({ tone: "success", text: "Post deleted." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleNotificationSubmit(event) {
    event.preventDefault();

    if (!notificationMessage.trim()) {
      setNotice({ tone: "danger", text: "Notification message is required." });
      return;
    }

    setBusy((current) => ({ ...current, notification: true }));

    try {
      await apiFetch("/api/notifications", {
        method: "POST",
        body: JSON.stringify({ message: notificationMessage.trim() })
      });
      setNotificationMessage("");
      setNotifications(await loadNotifications());
      setNotice({ tone: "success", text: "Notification sent." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, notification: false }));
    }
  }

  async function handleNotificationDelete(notification) {
    if (!window.confirm("Delete this broadcast message?")) {
      return;
    }

    try {
      await apiFetch(`/api/notifications/${notification._id}`, {
        method: "DELETE"
      });
      setNotifications(await loadNotifications());
      setNotice({ tone: "success", text: "Broadcast deleted." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleCategoryCreate(event) {
    event.preventDefault();

    if (!categoryDraft.trim()) {
      return;
    }

    setBusy((current) => ({ ...current, category: true }));

    try {
      await apiFetch("/api/categories", {
        method: "POST",
        body: JSON.stringify({ name: categoryDraft.trim() })
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
      setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, category: false }));
    }
  }

  function beginCategoryEdit(category) {
    setCategoryEditId(category?._id?.toString() || "");
    setCategoryEditName(category?.name?.toString() || "");
  }

  async function saveCategoryEdit() {
    if (!categoryEditId || !categoryEditName.trim()) {
      return;
    }

    try {
      await apiFetch(`/api/categories/${categoryEditId}`, {
        method: "PUT",
        body: JSON.stringify({ name: categoryEditName.trim() })
      });
      setCategories(await loadCategories());
      setCategoryEditId("");
      setCategoryEditName("");
      setNotice({ tone: "success", text: "Category updated." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleCategoryDelete(category) {
    if (!window.confirm(`Delete category "${category.name || "Unnamed"}"?`)) {
      return;
    }

    try {
      await apiFetch(`/api/categories/${category._id}`, { method: "DELETE" });
      const [freshCategories, freshSubcategories] = await Promise.all([
        loadCategories(),
        loadSubcategories()
      ]);
      setCategories(freshCategories);
      setSubcategories(freshSubcategories);
      setNotice({ tone: "success", text: "Category deleted." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleSubcategoryCreate(event) {
    event.preventDefault();

    if (!subcategoryDraft.categoryId || !subcategoryDraft.name.trim()) {
      return;
    }

    setBusy((current) => ({ ...current, subcategory: true }));

    try {
      await apiFetch("/api/subcategories", {
        method: "POST",
        body: JSON.stringify({
          name: subcategoryDraft.name.trim(),
          categoryId: subcategoryDraft.categoryId
        })
      });
      setSubcategories(await loadSubcategories());
      setSubcategoryDraft((current) => ({ ...current, name: "" }));
      setNotice({ tone: "success", text: "Subcategory added." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, subcategory: false }));
    }
  }

  function beginSubcategoryEdit(subcategory) {
    setSubcategoryEditId(subcategory?._id?.toString() || "");
    setSubcategoryEditName(subcategory?.name?.toString() || "");
    setSubcategoryDraft((current) => ({
      ...current,
      categoryId: subcategory?.categoryId?.toString() || current.categoryId
    }));
  }

  async function saveSubcategoryEdit(categoryId) {
    if (!subcategoryEditId || !subcategoryEditName.trim() || !categoryId) {
      return;
    }

    try {
      await apiFetch(`/api/subcategories/${subcategoryEditId}`, {
        method: "PUT",
        body: JSON.stringify({
          name: subcategoryEditName.trim(),
          categoryId
        })
      });
      setSubcategories(await loadSubcategories());
      setSubcategoryEditId("");
      setSubcategoryEditName("");
      setNotice({ tone: "success", text: "Subcategory updated." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleSubcategoryDelete(subcategory) {
    if (!window.confirm(`Delete subcategory "${subcategory.name || "Unnamed"}"?`)) {
      return;
    }

    try {
      await apiFetch(`/api/subcategories/${subcategory._id}`, {
        method: "DELETE"
      });
      setSubcategories(await loadSubcategories());
      setNotice({ tone: "success", text: "Subcategory deleted." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    }
  }

  async function handleAdminCreate(event) {
    event.preventDefault();

    if (!adminForm.username.trim() || !adminForm.password.trim()) {
      setNotice({
        tone: "danger",
        text: "Admin username and password are required."
      });
      return;
    }

    setBusy((current) => ({ ...current, admin: true }));

    try {
      await apiFetch("/api/admins", {
        method: "POST",
        body: JSON.stringify({
          username: adminForm.username.trim(),
          password: adminForm.password.trim()
        })
      });
      setAdmins(await loadAdmins());
      setAdminForm(emptyAdminForm);
      setNotice({ tone: "success", text: "Admin account created." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    } finally {
      setBusy((current) => ({ ...current, admin: false }));
    }
  }

  async function handleAdminDelete(admin) {
    if (!window.confirm(`Delete admin account "${admin.username}"?`)) {
      return;
    }

    try {
      await apiFetch(`/api/admins/${encodeURIComponent(admin.username)}`, {
        method: "DELETE"
      });
      setAdmins(await loadAdmins());
      setNotice({ tone: "success", text: "Admin deleted." });
    } catch (error) {
      setNotice({ tone: "danger", text: error.message });
    }
  }

  return (
    <div className="shell">
      <main className="app">
        <header className="panel hero">
          <div className="hero-copy">
            <p className="eyebrow">React Admin</p>
            <h1>Curate the lyrics catalog without the Flutter shell.</h1>
            <p>
              Manage posts, broadcasts, taxonomy, and admin accounts from a React
              dashboard wired directly to the existing Express API.
            </p>
          </div>
          <div className="hero-actions">
            <button type="button" className="button primary" onClick={resetPostForm}>
              New post
            </button>
            <button
              type="button"
              className="button secondary"
              onClick={() => refreshDashboard()}
              disabled={busy.refresh}
            >
              {busy.refresh ? "Refreshing..." : "Refresh data"}
            </button>
            <a
              className="button ghost"
              href={`${API_BASE_URL}/api/posts/pack`}
              target="_blank"
              rel="noreferrer"
            >
              Export pack
            </a>
          </div>
          <div className="hero-stats">
            <div className="stat-pill">
              <span>{posts.length}</span>
              <small>posts</small>
            </div>
            <div className="stat-pill">
              <span>{notifications.length}</span>
              <small>broadcasts</small>
            </div>
            <div className="stat-pill">
              <span>{categories.length}</span>
              <small>categories</small>
            </div>
            <div className="stat-pill">
              <span>{admins.length}</span>
              <small>admins</small>
            </div>
          </div>
        </header>

        <div className="runtime-strip">
          <span className="runtime-label">API</span>
          <code>{API_BASE_URL}</code>
        </div>

        {notice.text ? (
          <div className={`notice notice-${notice.tone}`}>{notice.text}</div>
        ) : null}

        <div className="dashboard-grid">
          <div className="column">
            <Panel
              eyebrow="Posts Control"
              title={editingId ? "Edit post" : "Create post"}
              subtitle="Shape the metadata that the mobile app and JSON pack rely on."
            >
              <form ref={formCardRef} className="stack" onSubmit={handlePostSubmit}>
                <div className="field-grid">
                  <label className="field">
                    <span>Title</span>
                    <input
                      value={postForm.title}
                      onChange={(event) =>
                        setPostForm((current) => ({
                          ...current,
                          title: event.target.value
                        }))
                      }
                      placeholder="Song or post title"
                    />
                  </label>
                  <label className="field">
                    <span>Teacher</span>
                    <input
                      value={postForm.teacher}
                      onChange={(event) =>
                        setPostForm((current) => ({
                          ...current,
                          teacher: event.target.value
                        }))
                      }
                      placeholder="Teacher or author"
                    />
                  </label>
                  <label className="field">
                    <span>Link</span>
                    <input
                      value={postForm.link}
                      onChange={(event) =>
                        setPostForm((current) => ({
                          ...current,
                          link: event.target.value
                        }))
                      }
                      placeholder="https://..."
                    />
                  </label>
                  <label className="field">
                    <span>Language</span>
                    <input
                      value={postForm.language}
                      onChange={(event) =>
                        setPostForm((current) => ({
                          ...current,
                          language: event.target.value
                        }))
                      }
                      placeholder="Amharic, English..."
                    />
                  </label>
                  <label className="field">
                    <span>Category</span>
                    <select
                      value={postForm.category}
                      onChange={(event) =>
                        setPostForm((current) => ({
                          ...current,
                          category: event.target.value,
                          subCategory: ""
                        }))
                      }
                    >
                      <option value="">Select a category</option>
                      {categories.map((category) => (
                        <option key={category._id} value={category.name || ""}>
                          {category.name || "Unnamed"}
                        </option>
                      ))}
                    </select>
                  </label>
                  <label className="field">
                    <span>Subcategory</span>
                    <select
                      value={postForm.subCategory}
                      onChange={(event) =>
                        setPostForm((current) => ({
                          ...current,
                          subCategory: event.target.value
                        }))
                      }
                      disabled={!visibleSubcategories.length}
                    >
                      <option value="">
                        {visibleSubcategories.length
                          ? "Select a subcategory"
                          : "Pick a category first"}
                      </option>
                      {visibleSubcategories.map((subcategory) => (
                        <option key={subcategory._id} value={subcategory.name || ""}>
                          {subcategory.name || "Unnamed"}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>

                <label className="field">
                  <span>Tags</span>
                  <input
                    value={postForm.tags}
                    onChange={(event) =>
                      setPostForm((current) => ({
                        ...current,
                        tags: event.target.value
                      }))
                    }
                    placeholder="comma, separated, tags"
                  />
                </label>

                <label className="field">
                  <span>Post body</span>
                  <textarea
                    value={postForm.body}
                    onChange={(event) =>
                      setPostForm((current) => ({
                        ...current,
                        body: event.target.value
                      }))
                    }
                    rows={12}
                    placeholder="Paste the full post or lyrics text here."
                  />
                </label>

                <div className="button-row">
                  <button type="submit" className="button primary" disabled={busy.post}>
                    {busy.post
                      ? editingId
                        ? "Updating..."
                        : "Creating..."
                      : editingId
                        ? "Update post"
                        : "Create post"}
                  </button>
                  <button
                    type="button"
                    className="button secondary"
                    onClick={resetPostForm}
                  >
                    Clear form
                  </button>
                </div>
              </form>
            </Panel>

            <Panel
              eyebrow="Broadcast"
              title="Send a notification"
              subtitle="Push a short reminder or announcement into the app feed."
            >
              <form className="stack" onSubmit={handleNotificationSubmit}>
                <label className="field">
                  <span>Message</span>
                  <textarea
                    value={notificationMessage}
                    onChange={(event) => setNotificationMessage(event.target.value)}
                    rows={4}
                    placeholder="Share a reminder with everyone."
                  />
                </label>
                <div className="button-row">
                  <button
                    type="submit"
                    className="button primary"
                    disabled={busy.notification}
                  >
                    {busy.notification ? "Sending..." : "Send broadcast"}
                  </button>
                </div>
              </form>
            </Panel>

            <Panel
              eyebrow="History"
              title="Broadcast history"
              subtitle="Newest messages appear first."
            >
              <div className="list-stack">
                {notifications.length ? (
                  notifications.map((notification) => (
                    <article key={notification._id} className="line-card">
                      <div className="line-copy">
                        <strong>{notification.message}</strong>
                        <p>{formatDate(notification.createdAt)}</p>
                      </div>
                      <button
                        type="button"
                        className="mini-button"
                        onClick={() => handleNotificationDelete(notification)}
                      >
                        Delete
                      </button>
                    </article>
                  ))
                ) : (
                  <div className="empty-state">No broadcast messages yet.</div>
                )}
              </div>
            </Panel>
          </div>

          <div className="column">
            <Panel
              eyebrow="Library"
              title="Posts library"
              subtitle="Search, edit, and prune the catalog."
              actions={
                <label className="search-field">
                  <span>Search</span>
                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Find by title, body, or category"
                  />
                </label>
              }
            >
              <div className="list-stack library-stack">
                {busy.boot ? (
                  <div className="empty-state">Loading dashboard...</div>
                ) : filteredPosts.length ? (
                  filteredPosts.map((post) => (
                    <article
                      key={post._id}
                      className={`post-card ${editingId === post._id ? "post-card-active" : ""}`}
                    >
                      <div className="post-card-head">
                        <div>
                          <h3>{post.title || "Untitled"}</h3>
                          <p>
                            {[post.teacher, post.category, post.subCategory]
                              .filter(Boolean)
                              .join(" - ") || "No metadata"}
                          </p>
                        </div>
                        <span className="pill">{formatDate(post.updatedAt || post.createdAt)}</span>
                      </div>
                      <p className="snippet">{post.body || "No body content."}</p>
                      {Array.isArray(post.tags) && post.tags.length ? (
                        <div className="tag-row">
                          {post.tags.map((tag) => (
                            <span key={`${post._id}-${tag}`} className="tag">
                              {tag}
                            </span>
                          ))}
                        </div>
                      ) : null}
                      <div className="button-row compact">
                        <button
                          type="button"
                          className="mini-button"
                          onClick={() => beginPostEdit(post)}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          className="mini-button danger"
                          onClick={() => handlePostDelete(post)}
                        >
                          Delete
                        </button>
                      </div>
                    </article>
                  ))
                ) : (
                  <div className="empty-state">No posts match the current search.</div>
                )}
              </div>
            </Panel>

            <Panel
              eyebrow="Taxonomy"
              title="Categories and subcategories"
              subtitle="Keep the post form aligned with the backend collections."
            >
              <div className="manager-grid">
                <div className="manager-block">
                  <h3>Categories</h3>
                  <form className="inline-form" onSubmit={handleCategoryCreate}>
                    <input
                      value={categoryDraft}
                      onChange={(event) => setCategoryDraft(event.target.value)}
                      placeholder="Add a category"
                    />
                    <button
                      type="submit"
                      className="mini-button"
                      disabled={busy.category}
                    >
                      Add
                    </button>
                  </form>
                  <div className="list-stack">
                    {categories.length ? (
                      categories.map((category) => {
                        const relatedCount = subcategories.filter(
                          (subcategory) =>
                            subcategory?.categoryId?.toString() === category?._id?.toString()
                        ).length;

                        return (
                          <article key={category._id} className="line-card">
                            <div className="line-copy">
                              {categoryEditId === category._id ? (
                                <input
                                  value={categoryEditName}
                                  onChange={(event) =>
                                    setCategoryEditName(event.target.value)
                                  }
                                />
                              ) : (
                                <>
                                  <strong>{category.name || "Unnamed"}</strong>
                                  <p>{relatedCount} linked subcategories</p>
                                </>
                              )}
                            </div>
                            <div className="button-row compact">
                              {categoryEditId === category._id ? (
                                <>
                                  <button
                                    type="button"
                                    className="mini-button"
                                    onClick={saveCategoryEdit}
                                  >
                                    Save
                                  </button>
                                  <button
                                    type="button"
                                    className="mini-button muted"
                                    onClick={() => {
                                      setCategoryEditId("");
                                      setCategoryEditName("");
                                    }}
                                  >
                                    Cancel
                                  </button>
                                </>
                              ) : (
                                <button
                                  type="button"
                                  className="mini-button"
                                  onClick={() => beginCategoryEdit(category)}
                                >
                                  Edit
                                </button>
                              )}
                              <button
                                type="button"
                                className="mini-button danger"
                                onClick={() => handleCategoryDelete(category)}
                              >
                                Delete
                              </button>
                            </div>
                          </article>
                        );
                      })
                    ) : (
                      <div className="empty-state">No categories yet.</div>
                    )}
                  </div>
                </div>

                <div className="manager-block">
                  <h3>Subcategories</h3>
                  <form className="stack" onSubmit={handleSubcategoryCreate}>
                    <label className="field">
                      <span>Parent category</span>
                      <select
                        value={subcategoryDraft.categoryId}
                        onChange={(event) =>
                          setSubcategoryDraft((current) => ({
                            ...current,
                            categoryId: event.target.value
                          }))
                        }
                      >
                        <option value="">Select a category</option>
                        {categories.map((category) => (
                          <option key={category._id} value={category._id}>
                            {category.name || "Unnamed"}
                          </option>
                        ))}
                      </select>
                    </label>
                    <div className="inline-form">
                      <input
                        value={subcategoryDraft.name}
                        onChange={(event) =>
                          setSubcategoryDraft((current) => ({
                            ...current,
                            name: event.target.value
                          }))
                        }
                        placeholder="Add a subcategory"
                      />
                      <button
                        type="submit"
                        className="mini-button"
                        disabled={busy.subcategory}
                      >
                        Add
                      </button>
                    </div>
                  </form>

                  <div className="list-stack">
                    {managedSubcategories.length ? (
                      managedSubcategories.map((subcategory) => {
                        const parentName =
                          categories.find(
                            (category) =>
                              category?._id?.toString() ===
                              subcategory?.categoryId?.toString()
                          )?.name || "Missing category";

                        return (
                          <article key={subcategory._id} className="line-card">
                            <div className="line-copy">
                              {subcategoryEditId === subcategory._id ? (
                                <input
                                  value={subcategoryEditName}
                                  onChange={(event) =>
                                    setSubcategoryEditName(event.target.value)
                                  }
                                />
                              ) : (
                                <>
                                  <strong>{subcategory.name || "Unnamed"}</strong>
                                  <p>{parentName}</p>
                                </>
                              )}
                            </div>
                            <div className="button-row compact">
                              {subcategoryEditId === subcategory._id ? (
                                <>
                                  <button
                                    type="button"
                                    className="mini-button"
                                    onClick={() =>
                                      saveSubcategoryEdit(
                                        subcategory?.categoryId?.toString() || ""
                                      )
                                    }
                                  >
                                    Save
                                  </button>
                                  <button
                                    type="button"
                                    className="mini-button muted"
                                    onClick={() => {
                                      setSubcategoryEditId("");
                                      setSubcategoryEditName("");
                                    }}
                                  >
                                    Cancel
                                  </button>
                                </>
                              ) : (
                                <button
                                  type="button"
                                  className="mini-button"
                                  onClick={() => beginSubcategoryEdit(subcategory)}
                                >
                                  Edit
                                </button>
                              )}
                              <button
                                type="button"
                                className="mini-button danger"
                                onClick={() => handleSubcategoryDelete(subcategory)}
                              >
                                Delete
                              </button>
                            </div>
                          </article>
                        );
                      })
                    ) : (
                      <div className="empty-state">No subcategories yet.</div>
                    )}
                  </div>
                </div>
              </div>
            </Panel>

            <Panel
              eyebrow="Access"
              title="Admin accounts"
              subtitle="Create additional dashboard users and inspect the seeded default account."
            >
              <form className="field-grid" onSubmit={handleAdminCreate}>
                <label className="field">
                  <span>Username</span>
                  <input
                    value={adminForm.username}
                    onChange={(event) =>
                      setAdminForm((current) => ({
                        ...current,
                        username: event.target.value
                      }))
                    }
                    placeholder="new admin"
                  />
                </label>
                <label className="field">
                  <span>Password</span>
                  <input
                    type="password"
                    value={adminForm.password}
                    onChange={(event) =>
                      setAdminForm((current) => ({
                        ...current,
                        password: event.target.value
                      }))
                    }
                    placeholder="secure password"
                  />
                </label>
                <div className="button-row compact">
                  <button type="submit" className="button primary" disabled={busy.admin}>
                    {busy.admin ? "Creating..." : "Create admin"}
                  </button>
                </div>
              </form>

              <div className="list-stack">
                {admins.length ? (
                  admins.map((admin) => (
                    <article key={admin.username} className="line-card">
                      <div className="line-copy">
                        <strong>
                          {admin.username}
                          {admin.isDefault ? " - Default admin" : ""}
                        </strong>
                        <p>
                          Created {formatDate(admin.createdAt)} -{" "}
                          {admin.password ? `Password: ${admin.password}` : "Password hidden"}
                        </p>
                      </div>
                      <button
                        type="button"
                        className="mini-button danger"
                        onClick={() => handleAdminDelete(admin)}
                        disabled={Boolean(admin.isDefault)}
                      >
                        Delete
                      </button>
                    </article>
                  ))
                ) : (
                  <div className="empty-state">No admin accounts yet.</div>
                )}
              </div>
            </Panel>
          </div>
        </div>
      </main>
    </div>
  );
}

