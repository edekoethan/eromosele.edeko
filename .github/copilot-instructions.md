<!-- GitHub Copilot / AI agent instructions for the Astrofy site -->

This file gives concise, actionable guidance to an AI coding agent working on this Astro + Tailwind template.

1. Project summary
   - Astro site (Astro v4) using Tailwind/DaisyUI. Site source: `src/`. Built static with `pnpm run build` (uses `astro build`).
   - Content uses Astro Content Collections located under `src/content/` (see `src/content/config.ts`). Blog posts are Markdown files with frontmatter fields: `title`, `description`, `pubDate`, `heroImage`, optional `tags`, `badge`, `updatedDate`, etc. Example: `src/content/blog/post1.md`.

2. Important commands (Windows PowerShell)
   - Install deps: `pnpm install`
   - Dev server: `pnpm run dev` (runs `astro dev`)
   - Build static site: `pnpm run build` (runs `astro build`)
   - Preview production build locally: `pnpm run preview` (runs `astro preview`)

3. Routing & content conventions
   - Blog list pagination: `src/pages/blog/[...page].astro` uses `getCollection('blog')` and `paginate(posts, { pageSize: 10 })`. Keep pagination logic when changing listings.
   - Blog post routes: `src/pages/blog/[slug].astro` builds static paths from `getCollection('blog')` and uses `createSlug(entry.data.title, entry.slug)` in `src/lib/createSlug.ts`. If you change slug rules, update that utility and both `[slug].astro` and `[...page].astro` usage.
   - Slug generation is configurable from `src/config.ts` via `GENERATE_SLUG_FROM_TITLE`.

4. Layouts & components
   - Main layout: `src/layouts/BaseLayout.astro`. It imports `Header`, `Footer`, `SideBar`, and optionally includes Astro View Transitions (`TRANSITION_API` flag in `src/config.ts`). Avoid changing `data-theme` on `<html>` without checking `BaseLayout.astro`.
   - Post layout: `src/layouts/PostLayout.astro` (used by individual posts).
   - Reusable UI components are in `src/components/`. Examples: `HorizontalCard.astro` (used by blog list), `HorizontalShopItem.astro` (store items), and `TimeLine.astro` (CV timeline).

5. Styling & design system
   - Tailwind + DaisyUI are used. Theme is set via the `data-theme` attribute in `BaseLayout.astro` (default `lofi`). Tailwind config: `tailwind.config.cjs`.

6. Images & sharp
   - `sharp` is a dependency. Image paths in frontmatter (e.g. `heroImage`) are expected to be under `public/` or remote URLs. If adding server-side image processing, verify `sharp` compatibility when running `pnpm install` on CI.

7. Tests & linting
   - This template does not include test scripts or linters. Do not add heavy infra without approval. Prefer small, local validation: run `pnpm run dev` and visit the pages.

8. Common change patterns and pitfalls
   - When adding a new page, wrap content with `BaseLayout` and set `sideBarActiveItemID` to mark active sidebar link (see `SideBarMenu.astro`).
   - For content collections, keep frontmatter fields consistent with examples in `src/content/blog/*.md`. Missing `pubDate` or `heroImage` may break ordering or layout expectations.
   - Pagination filenames use dynamic route parameters (`[...page].astro`) which the README notes may be incompatible with SSR deploys. Do not convert pagination to SSR without adjusting deploy targets.

9. Integration points & deployment
   - Site `base` and `site` are set in `astro.config.mjs` (important for GitHub Pages). If you change repo name or deploy to a different domain, update `site` and `base` accordingly.
   - RSS and sitemap integrations are enabled (`@astrojs/rss`, `@astrojs/sitemap`) via integrations in `astro.config.mjs`.
   - A GitHub Actions workflow has been added at `.github/workflows/deploy-pages.yml` which builds with `pnpm` and deploys the `dist/` directory to GitHub Pages. This workflow uses `actions/upload-pages-artifact` and `actions/deploy-pages`.
   - Common image/path issue: the site uses `astro.config.mjs` `base` (set to `/eromosele.edeko/`) and `site` (set to the repo Pages URL). If images appear broken after deploy, verify frontmatter `heroImage` paths are absolute to the site root (e.g. `/published_work.png`) or include the base in templates when rendering URLs.

10. Examples to reference in edits
    - Slug util: `src/lib/createSlug.ts`
    - Pagination: `src/pages/blog/[...page].astro`
    - Static paths for posts: `src/pages/blog/[slug].astro`
    - Site config: `src/config.ts` and `astro.config.mjs`
    - Sample content: `src/content/blog/post1.md`

11. What to do when making a PR
    - Keep changes minimal and configuration-aware. If editing frontmatter schema, update `src/content/config.ts` and adjust all sample posts.
    - Run `pnpm run dev` and build locally (`pnpm run build`) to ensure no content collection or routing regressions.

If anything here is unclear or you want extra details (CI commands, deploy steps for GitHub Pages/Vercel, or examples of small tests), tell me which area to expand and I'll update this file.
