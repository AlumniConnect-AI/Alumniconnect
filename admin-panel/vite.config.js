import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Standalone Admin Panel Vite Configuration
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5180,
    open: false
  }
})
