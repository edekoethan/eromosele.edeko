This PR configures the site to publish to the GitHub Pages site for repository `eromosele.edeko2`.

Changes included:
- Update `astro.config.mjs`:
  - site: `https://edekoethan.github.io/eromosele.edeko2`
  - base: `/eromosele.edeko2/`
- Add/standardize GitHub Actions Pages workflow:
  - `.github/workflows/deploy-pages.yml` — builds with pnpm, runs image verification, uploads `./dist`, and deploys via `actions/deploy-pages@v1`.
- Ensure all internal image and link URLs respect the base:
  - Added/used `src/lib/withBase.ts` across components/pages and fixed import placement.
  - Wrapped the favicon in `BaseHead.astro` with `withBase('/favicon.svg')`.
- README updated with a note describing the Pages target.
- Verified locally:
  - `pnpm run verify:images` output: "All frontmatter image references resolved."
  - `pnpm.cmd run build` completed and `dist/` was generated.

How to validate after merge:
1. Confirm GitHub Actions runs (Actions tab) — watch the `build` and `deploy` jobs.
2. After successful deploy, confirm the site is available at:
   https://edekoethan.github.io/eromosele.edeko2
3. If you change the repository name or use a custom domain, update `astro.config.mjs` accordingly.

Notes:
- The local build was done with `pnpm.cmd` on Windows to avoid PowerShell script shim issues.
- If you prefer output to `docs/` (instead of deploying `dist/`), I can update the workflow to upload `docs/` instead.
