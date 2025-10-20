import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import tailwind from "@astrojs/tailwind";

// https://astro.build/config
export default defineConfig({
  // Updated for GitHub Pages repository `eromosele.edeko2`
  site: 'https://edekoethan.github.io/eromosele.edeko2',
  base: '/eromosele.edeko2/',
  integrations: [mdx(), sitemap(), tailwind()]
});
