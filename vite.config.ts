import { defineConfig } from 'vite'
import dotenv from 'dotenv'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
dotenv.config()
export default defineConfig({
  define: {
    'process.env': process.env,
  },
  plugins: [react()],
})
