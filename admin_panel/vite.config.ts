import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from "path"

// Triggered reload to pick up new dependencies
// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
