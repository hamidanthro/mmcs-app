import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Note: During local dockerized dev, the UI calls backend via http://localhost:5000
// If you want a dev proxy for /api, uncomment the proxy section.
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173
    // proxy: {
    //   '/api': {
    //     target: 'http://localhost:5000',
    //     changeOrigin: true
    //   }
    // }
  }
})
