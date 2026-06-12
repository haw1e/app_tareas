const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(cors());
app.use(bodyParser.json());

const ADMIN_API_KEY = process.env.ADMIN_API_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in env');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

function requireAdminKey(req, res, next) {
  const key = req.header('x-admin-key');
  if (!ADMIN_API_KEY || !key || key !== ADMIN_API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

app.post('/create-worker', requireAdminKey, async (req, res) => {
  const { email, password, full_name } = req.body;
  try {
    const { data, error } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name, role: 'worker' },
    });
    if (error) throw error;

    await supabase.from('profiles').upsert({
      id: data.user.id,
      email,
      full_name,
      role: 'worker',
    });
    res.json({ user: data.user });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

app.post('/delete-all-tasks', requireAdminKey, async (req, res) => {
  try {
    await supabase.from('tasks').delete().neq('id', '');
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

app.post('/delete-task', requireAdminKey, async (req, res) => {
  const { id } = req.body;
  try {
    await supabase.from('tasks').delete().eq('id', id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

app.post('/delete-folder', requireAdminKey, async (req, res) => {
  const { id } = req.body;
  try {
    await supabase.from('task_folders').delete().eq('folder_id', id);
    await supabase.from('folders').delete().eq('id', id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

app.post('/update-folder', requireAdminKey, async (req, res) => {
  const { id, name } = req.body;
  try {
    await supabase.from('folders').update({ name }).eq('id', id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

app.post('/delete-user', requireAdminKey, async (req, res) => {
  const { id } = req.body;
  try {
    await supabase.from('profiles').delete().eq('id', id);
    try {
      await supabase.auth.admin.deleteUser(id);
    } catch (e) {
      // ignore auth delete error
    }
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

app.post('/update-user-profile', requireAdminKey, async (req, res) => {
  const { id, full_name, role } = req.body;
  try {
    await supabase.from('profiles').update({ full_name, role }).eq('id', id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

app.post('/update-task', requireAdminKey, async (req, res) => {
  const { id, title, description } = req.body;
  try {
    await supabase.from('tasks').update({ title, description }).eq('id', id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message || e });
  }
});

module.exports = app;
