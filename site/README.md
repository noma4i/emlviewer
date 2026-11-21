# Site deployment

Enable Email Routing for `noma4i.com` and verify `noma4i@gmail.com` as a destination address in Cloudflare. Configure the domain to send email from `feedback@emlviewer.noma4i.com`.

From `site/`, run `npx wrangler deploy`. The Worker serves `public/` at `emlviewer.noma4i.com` and sends feedback through the `FEEDBACK` binding.
