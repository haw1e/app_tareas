# Admin API for Aplicacion Tareas

This small Express server exposes privileged admin operations using the Supabase service role key. It is meant to be deployed to a secure environment (Heroku, Vercel Serverless, DigitalOcean App Platform, etc.) and NOT included in the mobile app.

Environment variables required:
- `SUPABASE_URL` - your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - your Supabase service role key (keep secret)
- `ADMIN_API_KEY` - a shared secret used by the mobile app (set in the app config)

Install and run locally:

```bash
cd server
npm install
ADMIN_API_KEY=some-secret SUPABASE_URL=https://your.supabase.co SUPABASE_SERVICE_ROLE_KEY=service_role_key node index.js
```

Endpoints (all require header `x-admin-key: <ADMIN_API_KEY>`):
- `POST /create-worker` { email, password, full_name }
- `POST /delete-all-tasks` {}
- `POST /delete-task` { id }
- `POST /delete-folder` { id }
- `POST /update-folder` { id, name }
- `POST /delete-user` { id }
- `POST /update-user-profile` { id, full_name, role }
- `POST /update-task` { id, title, description }

Deploy this to a secure host and set `ADMIN_API_KEY` and Supabase env vars there. Then configure the mobile app to use the deployed URL and API key (see client instructions).
