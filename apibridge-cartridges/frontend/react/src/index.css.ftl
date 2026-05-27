*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg: #f8fafc;
  --card: #ffffff;
  --card-border: #e2e8f0;
  --accent: #1e293b;
  --accent-dim: rgba(30, 41, 59, 0.06);
  --text: #1e293b;
  --text-muted: #64748b;
  --input-bg: #ffffff;
  --input-border: #cbd5e1;
  --error: #dc2626;
  --success: #16a34a;
  --font-sans: 'Outfit', sans-serif;
  --font-mono: 'Fira Code', monospace;
  --radius: 10px;
}

html, body, #root {
  min-height: 100vh;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
}

#root { display: flex; flex-direction: column; }

.apib-shell {
  flex: 1;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
}

.apib-topbar {
  position: fixed;
  top: 0; left: 0; right: 0;
  height: 3px;
  background: var(--accent);
  z-index: 100;
}

.apib-card {
  width: 100%;
  max-width: 520px;
  background: var(--card);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 2rem;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06), 0 1px 4px rgba(0, 0, 0, 0.04);
  animation: fadeUp 0.4s ease both;
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}

.apib-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.apib-badge {
  font-family: var(--font-mono);
  font-size: 0.65rem;
  font-weight: 500;
  letter-spacing: 0.08em;
  color: var(--accent);
  background: var(--accent-dim);
  border: 1px solid var(--card-border);
  border-radius: 4px;
  padding: 0.2rem 0.5rem;
}

.apib-title {
  font-size: 1.2rem;
  font-weight: 600;
  color: var(--text);
  letter-spacing: -0.01em;
}

.apib-tabs {
  display: flex;
  gap: 0.375rem;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--card-border);
  overflow-x: auto;
}

.apib-tab {
  font-family: var(--font-mono);
  font-size: 0.72rem;
  padding: 0.35rem 0.75rem;
  border-radius: 6px;
  border: 1px solid var(--card-border);
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: color 0.15s, border-color 0.15s, background 0.15s;
  white-space: nowrap;
  flex-shrink: 0;
}

.apib-tab:hover { color: var(--text); border-color: var(--accent); }

.apib-tab--active {
  background: var(--accent-dim);
  border-color: var(--accent);
  color: var(--accent);
}

.apib-form { display: flex; flex-direction: column; gap: 1rem; }

.apib-field { display: flex; flex-direction: column; gap: 0.375rem; }

.apib-label {
  font-family: var(--font-mono);
  font-size: 0.68rem;
  font-weight: 500;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.apib-required { color: var(--accent); line-height: 1; }

.apib-input {
  width: 100%;
  background: var(--input-bg);
  border: 1px solid var(--input-border);
  border-radius: var(--radius);
  padding: 0.625rem 0.875rem;
  font-family: var(--font-mono);
  font-size: 0.875rem;
  color: var(--text);
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
  -webkit-appearance: none;
}

.apib-input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-dim);
}

.apib-input::placeholder { color: var(--text-muted); opacity: 0.6; }

.apib-checkbox-wrap {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.5rem 0;
}

.apib-checkbox {
  width: 1rem;
  height: 1rem;
  accent-color: var(--accent);
  cursor: pointer;
}

.apib-error {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8rem;
  color: var(--error);
  background: rgba(220, 38, 38, 0.05);
  border: 1px solid rgba(220, 38, 38, 0.2);
  border-radius: var(--radius);
  padding: 0.625rem 0.875rem;
}

.apib-submit {
  margin-top: 0.5rem;
  width: 100%;
  padding: 0.75rem;
  background: var(--accent);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 0.875rem;
  font-weight: 600;
  letter-spacing: 0.03em;
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: opacity 0.15s, transform 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 2.75rem;
}

.apib-submit:hover:not(:disabled) { opacity: 0.85; transform: translateY(-1px); }
.apib-submit:active:not(:disabled) { transform: translateY(0); opacity: 1; }
.apib-submit:disabled { opacity: 0.35; cursor: not-allowed; }

.apib-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #ffffff;
  border-radius: 50%;
  animation: spin 0.65s linear infinite;
  display: inline-block;
}

@keyframes spin { to { transform: rotate(360deg); } }

.apib-response {
  margin-top: 1.25rem;
  border: 1px solid var(--card-border);
  border-radius: var(--radius);
  overflow: hidden;
}

.apib-response-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.875rem;
  background: var(--bg);
  font-family: var(--font-mono);
  font-size: 0.65rem;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  border-bottom: 1px solid var(--card-border);
}

.apib-response-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--success);
  flex-shrink: 0;
}

.apib-response-body {
  padding: 1rem 0.875rem;
  font-family: var(--font-mono);
  font-size: 0.8rem;
  color: var(--success);
  background: rgba(22, 163, 74, 0.03);
  overflow-x: auto;
  line-height: 1.65;
  white-space: pre;
}

/* ── Card variants ──────────────────────────────────────────── */
.apib-card--wide { max-width: 860px; }

/* ── Loading state ──────────────────────────────────────────── */
.apib-loading {
  display: flex;
  justify-content: center;
  padding: 2rem;
}

/* ── Buttons ────────────────────────────────────────────────── */
.apib-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.45rem 0.875rem;
  font-family: var(--font-sans);
  font-size: 0.8rem;
  font-weight: 500;
  border-radius: var(--radius);
  border: 1px solid var(--card-border);
  background: transparent;
  color: var(--text);
  cursor: pointer;
  transition: opacity 0.15s, background 0.15s;
}
.apib-btn:hover { opacity: 0.8; }
.apib-btn--primary {
  background: var(--accent);
  color: #ffffff;
  border-color: var(--accent);
}
.apib-btn--danger {
  background: var(--error);
  color: #ffffff;
  border-color: var(--error);
}
.apib-btn--ghost {
  background: transparent;
  border-color: transparent;
  color: var(--text-muted);
}
.apib-btn--ghost:hover { color: var(--text); background: var(--accent-dim); }

/* ── List page ──────────────────────────────────────────────── */
.apib-list-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
  gap: 1rem;
}
.apib-title--inline { display: inline; margin-left: 0.5rem; }
.apib-list-actions { display: flex; gap: 0.5rem; }

.apib-table-wrap { overflow-x: auto; border-radius: var(--radius); border: 1px solid var(--card-border); }

.apib-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
  font-family: var(--font-mono);
}

.apib-th {
  padding: 0.625rem 0.875rem;
  text-align: left;
  font-size: 0.65rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  background: var(--bg);
  border-bottom: 1px solid var(--card-border);
  white-space: nowrap;
  user-select: none;
}
.apib-th--sortable { cursor: pointer; }
.apib-th--sortable:hover { color: var(--text); }
.apib-th--sorted { color: var(--accent); }
.apib-th--action { width: 3rem; }
.apib-sort-icon { font-size: 0.75rem; }

.apib-tr { transition: background 0.1s; }
.apib-tr:hover { background: var(--accent-dim); }

.apib-td {
  padding: 0.6rem 0.875rem;
  border-bottom: 1px solid var(--card-border);
  color: var(--text);
  vertical-align: middle;
}
.apib-td--empty {
  text-align: center;
  color: var(--text-muted);
  padding: 2rem;
}
.apib-td--action { text-align: right; }

.apib-row-link {
  font-size: 0.75rem;
  color: var(--accent);
  opacity: 0.7;
}
.apib-tr:hover .apib-row-link { opacity: 1; }

.apib-pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 0;
  margin-top: 0.75rem;
  font-size: 0.8rem;
  color: var(--text-muted);
  font-family: var(--font-mono);
}
.apib-pagination-controls { display: flex; align-items: center; gap: 0.75rem; }
.apib-page-btn {
  padding: 0.3rem 0.625rem;
  border-radius: 6px;
  border: 1px solid var(--card-border);
  background: transparent;
  color: var(--text);
  cursor: pointer;
  font-size: 0.8rem;
  transition: background 0.1s;
}
.apib-page-btn:hover:not(:disabled) { background: var(--accent-dim); }
.apib-page-btn:disabled { opacity: 0.35; cursor: not-allowed; }
.apib-page-num { color: var(--text); }

/* ── View page ──────────────────────────────────────────────── */
.apib-view-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}
.apib-view-actions { display: flex; gap: 0.5rem; }

.apib-detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem 1.5rem;
  margin-top: 1rem;
}
@media (max-width: 560px) { .apib-detail-grid { grid-template-columns: 1fr; } }

.apib-detail-field { display: flex; flex-direction: column; gap: 0.25rem; }

.apib-detail-label {
  font-family: var(--font-mono);
  font-size: 0.65rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  color: var(--text-muted);
  text-transform: uppercase;
}

.apib-detail-value {
  font-family: var(--font-sans);
  font-size: 0.9rem;
  color: var(--text);
  word-break: break-word;
}
