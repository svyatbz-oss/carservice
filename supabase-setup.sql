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

-- 3) SOLO usuarios con sesión iniciada pueden leer y escribir.
--    Con estas políticas, cualquiera que tenga solo la URL y la clave
--    pública NO puede ver ni tocar los datos: hace falta iniciar sesión
--    (Supabase Auth) desde la app. Esta es la parte que protege los datos.
--
--    IMPORTANTE: ejecuta este bloque SOLO cuando la versión de la app con
--    login ya esté publicada y hayas creado el usuario del taller
--    (Authentication → Users → Add user). Si lo ejecutas antes, la app
--    dejará de cargar hasta que exista el login.

-- Quitar las políticas públicas antiguas si existían.
drop policy if exists "lectura publica" on pedidos;
drop policy if exists "escritura publica" on pedidos;
drop policy if exists "actualizacion publica" on pedidos;

drop policy if exists "lectura autenticada" on pedidos;
create policy "lectura autenticada"
  on pedidos for select
  to authenticated
  using (true);

drop policy if exists "escritura autenticada" on pedidos;
create policy "escritura autenticada"
  on pedidos for insert
  to authenticated
  with check (true);

drop policy if exists "actualizacion autenticada" on pedidos;
create policy "actualizacion autenticada"
  on pedidos for update
  to authenticated
  using (true)
  with check (true);

-- 4) Fila inicial vacía para el taller.
insert into pedidos (id, data)
values ('taller-principal', '[]'::jsonb)
on conflict (id) do nothing;
