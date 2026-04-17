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

export default function DashboardView(props) {
  const {
    apiBaseUrl,
    auth,
    notice,
    busy,
    posts,
    notifications,
    categories,
    subcategories,
    admins,
    managedSubcategories,
    visibleSubcategories,
    filteredPosts,
    search,
    setSearch,
    postForm,
    setPostForm,
    bulkPostsInput,
    setBulkPostsInput,
    categoryDraft,
    setCategoryDraft,
    categoryEditId,
    categoryEditName,
    setCategoryEditName,
    subcategoryDraft,
    setSubcategoryDraft,
    subcategoryEditId,
    subcategoryEditName,
    setSubcategoryEditName,
    notificationMessage,
    setNotificationMessage,
    adminForm,
    setAdminForm,
    editingId,
    formCardRef,
    bulkCardRef,
    formatDate,
    onRefresh,
    onLogout,
    onScrollToPostForm,
    onScrollToBulkCreate,
    onResetPostForm,
    onPostSubmit,
    onBulkPostSubmit,
    onUseBulkExample,
    onNotificationSubmit,
    onNotificationDelete,
    onBeginPostEdit,
    onDeletePost,
    onCategoryCreate,
    onBeginCategoryEdit,
    onSaveCategoryEdit,
    onCancelCategoryEdit,
    onDeleteCategory,
    onSubcategoryCreate,
    onBeginSubcategoryEdit,
    onSaveSubcategoryEdit,
    onCancelSubcategoryEdit,
    onDeleteSubcategory,
    onAdminCreate,
    onDeleteAdmin
  } = props;

  return (
    <div className="shell">
      <main className="app">
        <header className="panel hero">
          <div className="hero-copy">
            <p className="eyebrow">React Admin</p>
            <h1>Curate the posts catalog with guarded admin access.</h1>
            <p>
              Manage posts, create many entries in one request, broadcast
              notifications, shape the taxonomy, and control admin accounts from
              one React dashboard.
            </p>
          </div>

          <div className="hero-actions">
            <div className="session-pill">
              <strong>{auth.admin?.username || "Admin"}</strong>
              <span>{auth.admin?.role || "admin"}</span>
            </div>
            <button type="button" className="button primary" onClick={onScrollToPostForm}>
              New post
            </button>
            <button
              type="button"
              className="button secondary"
              onClick={onScrollToBulkCreate}
            >
              Multi create
            </button>
            <button
              type="button"
              className="button secondary"
              onClick={onRefresh}
              disabled={busy.refresh}
            >
              {busy.refresh ? "Refreshing..." : "Refresh data"}
            </button>
            <a
              className="button ghost"
              href={`${apiBaseUrl}/api/posts/pack`}
              target="_blank"
              rel="noreferrer"
            >
              Export pack
            </a>
            <button type="button" className="button ghost" onClick={onLogout}>
              Log out
            </button>
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
          <code>{apiBaseUrl}</code>
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
              <form ref={formCardRef} className="stack" onSubmit={onPostSubmit}>
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
                    onClick={onResetPostForm}
                  >
                    Clear form
                  </button>
                </div>
              </form>
            </Panel>

            <Panel
              eyebrow="Multi Create"
              title="Create many posts"
              subtitle="Paste a JSON array and create multiple posts in one request."
              actions={
                <button type="button" className="mini-button" onClick={onUseBulkExample}>
                  Load example
                </button>
              }
            >
              <form ref={bulkCardRef} className="stack" onSubmit={onBulkPostSubmit}>
                <p className="helper-copy">
                  Required for each item: <code>title</code>, <code>category</code>,
                  and <code>body</code>. <code>tags</code> can be an array or a comma
                  separated string.
                </p>

                <label className="field">
                  <span>Posts JSON</span>
                  <textarea
                    value={bulkPostsInput}
                    onChange={(event) => setBulkPostsInput(event.target.value)}
                    rows={16}
                    placeholder='[{"title":"Morning Worship","category":"Worship","body":"..."}]'
                  />
                </label>

                <pre className="json-hint">
                  {`[
  {
    "title": "Morning Worship",
    "category": "Worship",
    "body": "Full post body"
  }
]`}
                </pre>

                <div className="button-row">
                  <button type="submit" className="button primary" disabled={busy.bulk}>
                    {busy.bulk ? "Creating..." : "Create many posts"}
                  </button>
                  <button
                    type="button"
                    className="button secondary"
                    onClick={() => setBulkPostsInput("")}
                  >
                    Clear bulk input
                  </button>
                </div>
              </form>
            </Panel>

            <Panel
              eyebrow="Broadcast"
              title="Send a notification"
              subtitle="Push a short reminder or announcement into the app feed."
            >
              <form className="stack" onSubmit={onNotificationSubmit}>
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
                        onClick={() => onNotificationDelete(notification)}
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
                        <span className="pill">
                          {formatDate(post.updatedAt || post.createdAt)}
                        </span>
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
                          onClick={() => onBeginPostEdit(post)}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          className="mini-button danger"
                          onClick={() => onDeletePost(post)}
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
                  <form className="inline-form" onSubmit={onCategoryCreate}>
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
                                    onClick={onSaveCategoryEdit}
                                  >
                                    Save
                                  </button>
                                  <button
                                    type="button"
                                    className="mini-button muted"
                                    onClick={onCancelCategoryEdit}
                                  >
                                    Cancel
                                  </button>
                                </>
                              ) : (
                                <button
                                  type="button"
                                  className="mini-button"
                                  onClick={() => onBeginCategoryEdit(category)}
                                >
                                  Edit
                                </button>
                              )}
                              <button
                                type="button"
                                className="mini-button danger"
                                onClick={() => onDeleteCategory(category)}
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
                  <form className="stack" onSubmit={onSubcategoryCreate}>
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
                                      onSaveSubcategoryEdit(
                                        subcategory?.categoryId?.toString() || ""
                                      )
                                    }
                                  >
                                    Save
                                  </button>
                                  <button
                                    type="button"
                                    className="mini-button muted"
                                    onClick={onCancelSubcategoryEdit}
                                  >
                                    Cancel
                                  </button>
                                </>
                              ) : (
                                <button
                                  type="button"
                                  className="mini-button"
                                  onClick={() => onBeginSubcategoryEdit(subcategory)}
                                >
                                  Edit
                                </button>
                              )}
                              <button
                                type="button"
                                className="mini-button danger"
                                onClick={() => onDeleteSubcategory(subcategory)}
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
              <form className="field-grid" onSubmit={onAdminCreate}>
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
                          {admin.password
                            ? `Password: ${admin.password}`
                            : "Password hidden"}
                        </p>
                      </div>
                      <button
                        type="button"
                        className="mini-button danger"
                        onClick={() => onDeleteAdmin(admin)}
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
