export default function withBase(url?: string): string {
  // Always return a string (never undefined) to satisfy Image typing.
  if (!url) return "";
  // leave remote urls alone
  if (/^https?:\/\//.test(url)) return url;

  const base = import.meta.env.BASE_URL ?? '/';
  // if url already contains the base, return as-is
  if (base && url.startsWith(base)) return url;

  // if url is root-relative (/file.png), prefix with base (remove trailing slash on base)
  if (url.startsWith('/')) {
    const b = base.endsWith('/') ? base.slice(0, -1) : base;
    return b + url;
  }

  // otherwise, return as-is (relative path or other)
  return url;
}
