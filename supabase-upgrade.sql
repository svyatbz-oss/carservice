-- ============================================================
--  Carservice — Actualización de almacenamiento (robusto + copias)
--  Ejecutar en: Supabase → SQL Editor
--
--  QUÉ HACE (y qué NO hace):
--   • CREA tablas nuevas donde cada pedido y cada inspección es una
--     fila propia (así dos dispositivos no se pisan y no se pierde nada).
--   • COPIA los datos actuales del bloque JSON a esas tablas nuevas.
--   • NO toca ni borra el bloque antiguo ('taller-principal'): queda
--     intacto como copia de seguridad hasta que confirmemos que todo va bien.
--   Es seguro ejecutarlo varias veces (usa "if not exists" / "on conflict").
-- ============================================================

-- 1) PEDIDOS — una fila por pedido -----------------------------------------
create table if not exists pedido_items (
  id             text primary key,
  matricula      text,
  marca          text,
  pieza          text,
  proveedor      text,
  precio         numeric,
  descuento      numeric,
  fecha_pedido   text,
  estado         text,
  fecha_recibido text,
  updated_at     timestamptz default now()
);

-- 2) INSPECCIONES — una fila por coche (las piezas van en JSON dentro) ------
create table if not exists inspeccion_items (
  id                  text primary key,
  matricula           text,
  marca               text,
  bastidor            text,
  fecha_matriculacion text,
  creada              text,
  piezas              jsonb default '[]'::jsonb,
  updated_at          timestamptz default now()
);

-- 3) COPIAS DE SEGURIDAD — instantáneas con fecha para "restaurar" ----------
create table if not exists backups (
  id           bigint generated always as identity primary key,
  created_at   timestamptz default now(),
  etiqueta     text,
  pedidos      jsonb,
  inspecciones jsonb
);

-- 4) MIGRAR los datos actuales (del bloque JSON antiguo a las filas nuevas) --
insert into pedido_items (id, matricula, marca, pieza, proveedor, precio, descuento, fecha_pedido, estado, fecha_recibido)
select
  coalesce(nullif(x->>'id',''), 'p_' || replace(gen_random_uuid()::text,'-','')),
  x->>'matricula', x->>'marca', x->>'pieza', x->>'proveedor',
  nullif(x->>'precio','')::numeric,
  coalesce(nullif(x->>'descuento','')::numeric, 0),
  x->>'fechaPedido',
  coalesce(nullif(x->>'estado',''), 'pedido'),
  nullif(x->>'fechaRecibido','')
from pedidos p, jsonb_array_elements(p.data) as x
where p.id = 'taller-principal'
on conflict (id) do nothing;

insert into inspeccion_items (id, matricula, marca, bastidor, fecha_matriculacion, creada, piezas)
select
  coalesce(nullif(x->>'id',''), 'insp_' || replace(gen_random_uuid()::text,'-','')),
  x->>'matricula', x->>'marca', x->>'bastidor', x->>'fechaMatriculacion',
  x->>'creada',
  coalesce(x->'piezas', '[]'::jsonb)
from pedidos p, jsonb_array_elements(p.inspecciones) as x
where p.id = 'taller-principal'
on conflict (id) do nothing;

-- 5) Primera copia de seguridad con los datos actuales ----------------------
insert into backups (etiqueta, pedidos, inspecciones)
select 'copia inicial antes de la actualización', p.data, p.inspecciones
from pedidos p where p.id = 'taller-principal';

-- 6) Seguridad por filas: solo usuarios con sesión pueden acceder -----------
alter table pedido_items      enable row level security;
alter table inspeccion_items  enable row level security;
alter table backups           enable row level security;

drop policy if exists "acceso autenticado" on pedido_items;
create policy "acceso autenticado" on pedido_items      for all to authenticated using (true) with check (true);

drop policy if exists "acceso autenticado" on inspeccion_items;
create policy "acceso autenticado" on inspeccion_items  for all to authenticated using (true) with check (true);

drop policy if exists "acceso autenticado" on backups;
create policy "acceso autenticado" on backups           for all to authenticated using (true) with check (true);

-- ============================================================
--  Comprobación (opcional): cuántas filas se han migrado
--  select (select count(*) from pedido_items) as pedidos,
--         (select count(*) from inspeccion_items) as inspecciones,
--         (select count(*) from backups) as copias;
-- ============================================================
