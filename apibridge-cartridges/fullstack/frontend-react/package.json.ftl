{
  "name": "${id}-fe",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "build": "vite build",
    "dev": "vite"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "axios": "^1.6.8"<#if (flags.uiPattern!"") == "form-engine">,
    "@rjsf/core": "^5.18.0",
    "@rjsf/utils": "^5.18.0",
    "@rjsf/validator-ajv8": "^5.18.0"</#if>
  },
  "devDependencies": {
    "vite": "^5.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.4.5",
    "@types/react": "^18.3.1",
    "@types/react-dom": "^18.3.0"
  }
}
