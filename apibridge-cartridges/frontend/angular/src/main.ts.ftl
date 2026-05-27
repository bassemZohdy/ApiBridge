import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

// Injected last so brand overrides win over bundled CSS
const customLink = document.createElement('link');
customLink.rel = 'stylesheet';
customLink.href = '/custom.css';
document.head.appendChild(customLink);

platformBrowserDynamic().bootstrapModule(AppModule).catch(err => console.error(err));
