import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import { App } from './App';

// Injected last so brand overrides win over bundled CSS
const customLink = document.createElement('link');
customLink.rel = 'stylesheet';
customLink.href = '/custom.css';
document.head.appendChild(customLink);
<#if enableOfflineSupport>

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch((err) => {
      console.warn('SW registration failed:', err);
    });
  });
}
</#if>

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
