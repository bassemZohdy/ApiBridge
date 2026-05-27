export const environment = {
  production: false,
  // Override at build time or at runtime via window.__APIBRIDGE_BASE_URL
  apiBaseUrl: (typeof (window as Window & { __APIBRIDGE_BASE_URL?: string }).__APIBRIDGE_BASE_URL === 'string'
    ? (window as Window & { __APIBRIDGE_BASE_URL?: string }).__APIBRIDGE_BASE_URL
    : '') as string
};
