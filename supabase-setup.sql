-- ============================================================
--  Carservice — Configuración de la base de datos en Supabase
--  Pega y ejecuta todo esto en: Supabase → SQL Editor
-- ============================================================

-- 1) Tabla que guarda los pedidos del taller.
--    Se usa una sola fila (id = 'taller-principal') que contiene
--    todos los pedidos como JSON, para mantenerlo simple.
create table if not exists pedidos (
  id           text primary key,
  data         jsonb default '[]'::jsonb,
  inspecciones jsonb default '[]'::jsonb,
  last_backup  text,
  updated_at   timestamptz default now()
);

-- Si la tabla ya existía sin la columna de inspecciones, añádela:
alter table pedidos add column if not exists inspecciones jsonb default '[]'::jsonb;

-- Nota: el bastidor (VIN) de cada coche y la referencia de cada pieza se guardan
-- DENTRO del JSON de 'inspecciones' y 'data', así que no hacen falta columnas
-- nuevas para ellos.

-- 2) Activar la seguridad por filas (obligatorio en Supabase).
alter table pedidos enable row level security;

-- 3) Permitir lectura y escritura con la clave pública "anon".
--    Esto hace que la app funcione sin login. Para un taller
--    (herramienta interna) suele ser suficiente.
--    Si más adelante quieres restringir el acceso con usuarios,
--    se sustituyen estas políticas por otras basadas en auth.

drop policy if exists "lectura publica" on pedidos;
create policy "lectura publica"
  on pedidos for select
  using (true);

drop policy if exists "escritura publica" on pedidos;
create policy "escritura publica"
  on pedidos for insert
  with check (true);

drop policy if exists "actualizacion publica" on pedidos;
create policy "actualizacion publica"
  on pedidos for update
  using (true)
  with check (true);

-- 4) Fila inicial vacía para el taller.
insert into pedidos (id, data)
values ('taller-principal', '[]'::jsonb)
on conflict (id) do nothing;
