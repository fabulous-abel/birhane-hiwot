const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || "http://localhost:4000"
).replace(/\/$/, "");

export default function LoginView({
  loginForm,
  onLoginFormChange,
  onSubmit,
  busy,
  notice
}) {
  return (
    <div className="shell login-shell">
      <main className="app login-app">
        <section className="panel login-panel">
          <div className="login-copy">
            <p className="eyebrow">Admin Access</p>
            <h1>Sign in to manage the posts catalog.</h1>
            <p>
              Use an admin account from the backend to unlock post editing, bulk
              imports, notifications, taxonomy management, and admin settings.
            </p>

            <div className="login-highlights">
              <div className="stat-pill">
                <span>1</span>
                <small>login gate</small>
              </div>
              <div className="stat-pill">
                <span>Bulk</span>
                <small>post creation</small>
              </div>
              <div className="stat-pill">
                <span>Live</span>
                <small>API sync</small>
              </div>
            </div>

            <div className="runtime-strip">
              <span className="runtime-label">API</span>
              <code>{API_BASE_URL}</code>
            </div>
          </div>

          <div className="login-card">
            <form className="stack" onSubmit={onSubmit}>
              <label className="field">
                <span>Username</span>
                <input
                  value={loginForm.username}
                  onChange={(event) =>
                    onLoginFormChange((current) => ({
                      ...current,
                      username: event.target.value
                    }))
                  }
                  placeholder="admin username"
                  autoComplete="username"
                />
              </label>

              <label className="field">
                <span>Password</span>
                <input
                  type="password"
                  value={loginForm.password}
                  onChange={(event) =>
                    onLoginFormChange((current) => ({
                      ...current,
                      password: event.target.value
                    }))
                  }
                  placeholder="admin password"
                  autoComplete="current-password"
                />
              </label>

              {notice.text ? (
                <div className={`notice notice-${notice.tone}`}>{notice.text}</div>
              ) : null}

              <div className="button-row">
                <button type="submit" className="button primary" disabled={busy}>
                  {busy ? "Signing in..." : "Sign in"}
                </button>
              </div>

              <p className="helper-copy">
                The default admin is seeded from the backend environment. Use the
                credentials configured there if this is your first login.
              </p>
            </form>
          </div>
        </section>
      </main>
    </div>
  );
}
