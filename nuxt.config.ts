import { defineNuxtConfig } from "nuxt3";
import elmPlugin from "vite-plugin-elm";

// https://v3.nuxtjs.org/docs/directory-structure/nuxt.config
export default defineNuxtConfig({
  vite: {
    plugins: [elmPlugin()],
  },
  ssr: true,
  target: "static",
  build: {
    postcss: {
      postcssOptions: {
        plugins: {
          tailwindcss: {},
          autoprefixer: {},
        },
      },
    },
  },
});
