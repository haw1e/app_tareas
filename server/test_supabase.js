const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://tranonwmjqfnhxluwngt.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyYW5vbndtanFmbmh4bHV3bmd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyMTQzNDUsImV4cCI6MjA5Njc5MDM0NX0.ucmQYOOkp5-ZoNkCZwNhLi3RvZogNMBDteI0kyMPTRA';
const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  const res1 = await supabase.from('task_folders').delete().neq('task_id', '00000000-0000-0000-0000-000000000000');
  console.log('task_folders:', res1.error);
  const res2 = await supabase.from('tasks').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  console.log('tasks:', res2.error);
}

test();
