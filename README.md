# Carservice — Control de Pedidos de Piezas

Aplicación web para el taller, con dos secciones:

1. **Inspecciones** — el mecánico revisa un coche averiado y anotas lo que
   necesita: matrícula, marca/modelo, fecha de matriculación y las piezas (varias
   por coche, una por línea). Es tu lista antes de llamar a los proveedores.
2. **Pedidos de piezas** — cuando llamas a un proveedor y pides una pieza, pasa a
   ser un pedido real con proveedor, precio, descuento y fecha.

**Cómo se conectan:** en una inspección, cada pieza tiene un botón **"Pedir"**.
Al pulsarlo, se abre la sección Pedidos con la matrícula, la marca y el nombre de
la pieza ya rellenados (solo añades proveedor y precio durante la llamada), y en
la inspección esa pieza queda marcada **"En pedido"**. Cuando el pedido está
hecho, pulsas **"Confirmar"** y la pieza pasa a **"Pedido ✓"**. Las piezas nunca
desaparecen solas: quedan como registro de lo que necesitaba el coche.

Esta versión está preparada para funcionar como **página web real**, con los datos
**compartidos entre todos los dispositivos del taller** a través de una base de
datos gratuita (Supabase).

---

## Cómo funciona el almacenamiento

El archivo `index.html` tiene, al principio del `<script>`, un bloque de
configuración:

```js
const SUPABASE_URL = '';        // p.ej. 'https://xxxxxxxx.supabase.co'
const SUPABASE_ANON_KEY = '';   // la clave "anon public"
```

- **Si dejas esos dos valores vacíos**, la app funciona igualmente, pero guarda
  los datos solo en el navegador de ese dispositivo (no se comparten). Útil para
  probar.
- **Si los rellenas** con los datos de tu proyecto Supabase, todos los
  dispositivos que abran la página comparten los mismos pedidos en tiempo real.

---

## Puesta en marcha (paso a paso)

Puedes pedirle a Claude Code que te acompañe en cada uno de estos pasos.

### 1. Crear el proyecto en Supabase
1. Entra en https://supabase.com y crea una cuenta gratuita.
2. Pulsa **New project**, ponle un nombre (p.ej. `carservice-taller`) y elige una
   contraseña para la base de datos (guárdala).
3. Espera 1–2 minutos a que el proyecto se cree.

### 2. Crear la tabla
1. En el menú lateral, entra en **SQL Editor**.
2. Pega y ejecuta el contenido del archivo `supabase-setup.sql` (incluido en
   esta carpeta).
   Eso crea la tabla `pedidos` y deja preparado el acceso.

### 3. Copiar tus dos valores
1. Ve a **Project Settings → API**.
2. Copia el **Project URL** → pégalo en `SUPABASE_URL`.
3. Copia la clave **anon public** → pégala en `SUPABASE_ANON_KEY`.

### 4. Probar en local
- Abre `index.html` en el navegador (o, mejor, usa un servidor local; Claude Code
  puede levantar uno con `python3 -m http.server`).
- Añade un pedido de prueba. Recarga la página: debe seguir ahí.
- Ábrelo desde otro dispositivo con la misma configuración: debe verse el mismo
  pedido.

### 5. Publicarlo como página web
Opciones gratuitas y sencillas (Claude Code puede guiarte):
- **Netlify** o **Vercel**: arrastras la carpeta y te dan una URL fija.
- **GitHub Pages**: si subes el proyecto a GitHub.

---

## Nota de seguridad

La clave `anon public` de Supabase está pensada para usarse en el navegador — no
es la clave secreta. Aun así, con la configuración de este proyecto (ver
`supabase-setup.sql`), cualquiera con la URL de tu página podría leer y escribir
pedidos. Para un taller esto suele ser aceptable (es una herramienta interna),
pero si quieres restringir el acceso, el siguiente paso sería añadir un login de
Supabase. Coméntaselo a Claude Code si te interesa.

---

## Próximas mejoras posibles

- Login para restringir el acceso.
- Campo de notas por pieza.
- Número de teléfono por proveedor, para que "Reclamar" abra directamente el chat.
