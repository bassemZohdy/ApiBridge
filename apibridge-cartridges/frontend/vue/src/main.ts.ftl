import { createApp } from 'vue';
import App from './App.vue';

// Injected last so brand overrides win over bundled CSS
const customLink = document.createElement('link');
customLink.rel = 'stylesheet';
customLink.href = '/custom.css';
document.head.appendChild(customLink);

createApp(App).mount('#app');
