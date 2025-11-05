<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <title>Heatmap Acciones - Mapa de Calor</title>
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <style>
    body { font-family: Inter, Arial, sans-serif; padding: 18px; background:#f6f8fb; }
    h1 { margin-bottom: 8px; }
    #grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; max-width:900px; }
    .box {
      padding: 18px; border-radius:12px; text-align:center;
      box-shadow: 0 4px 10px rgba(0,0,0,0.06);
      min-height:86px; display:flex; flex-direction:column; justify-content:center;
      color: #fff; font-weight:700; font-size:18px;
    }
    .ticker { font-size:16px; opacity:0.95; }
    .pct { font-size:14px; margin-top:6px; opacity:0.95; }
    #footer { margin-top:16px; color:#444; font-size:13px; }
    .small { font-size:12px; opacity:0.8; }
  </style>
</head>
<body>
  <h1>Mapa de calor — 16 acciones</h1>
  <div id="grid"></div>
  <div id="footer">
    Datos via Google Sheets (GOOGLEFINANCE). Última actualización: <span id="last">—</span>
    <div class="small">Pega la URL CSV de tu hoja publicada en la variable SHEET_CSV_URL dentro de este archivo si estás corriendo localmente.</div>
  </div>

  <script>
    // ----- PEGÁ ACÁ la URL CSV que obtuviste al "Publicar en la web" desde Google Sheets:
    const SHEET_CSV_URL = "https://docs.google.com/spreadsheets/d/e/YOUR_SHEET_ID/pub?output=csv";
    // --------------------------------------------------------------

    const tickersOrder = ["NVDA","AAPL","MSFT","META","AVGO","GOOGL","BRK-B","JPM",
                          "TSLA","AMZN","XOM","PEP","LLY","TSM","PG","JNJ"];

    function colorForPct(pct) {
      // Le damos intensidad según magnitud; saturamos a +/-8% para colores
      const cap = 8;
      const v = Math.max(-cap, Math.min(cap, pct));
      // Mapear -cap..0..cap a rojo->white->verde
      if (v >= 0) {
        const intensity = Math.round((v / cap) * 255);
        // verde creciente
        const g = 120 + Math.round((135 * (v / cap)));
        const r = 20;
        return `rgb(${r}, ${Math.max(60, g)}, 25)`;
      } else {
        const intensity = Math.round((Math.abs(v) / cap) * 255);
        const r = 200;
        const g = Math.max(30, 200 - Math.round((170 * (Math.abs(v) / cap))));
        return `rgb(${r}, ${g}, 40)`;
      }
    }

    async function fetchCSV(url) {
      const res = await fetch(url);
      if (!res.ok) throw new Error("No se pudo obtener CSV: " + res.status);
      const txt = await res.text();
      return txt;
    }

    function parseCSVtoGrid(csvText) {
      // Espera tabla simple: nombres en la primera fila (B2:E2) y porcentajes en la fila siguiente (B3:E3) etc.
      // Convertimos a matriz
      const rows = csvText.trim().split(/\r?\n/).map(r => r.split(','));
      // Filtramos strings vacíos
      // Buscamos los 4x4 de tickers y 4x4 de porcentajes. Asumimos que la hoja tiene:
      // fila1: encabezado(s) opcionales
      // Para simplicidad, buscamos todos los tickers conocidos y sus pct en la siguiente fila.
      const flat = rows.flat();
      // Hacemos un map ticker->pct buscando el ticker en la matriz y tomando la celda justo abajo
      const map = {};
      for (let r = 0; r < rows.length; r++) {
        for (let c = 0; c < rows[r].length; c++) {
          const val = rows[r][c].trim().replace(/(^"|"$)/g,'');
          if (tickersOrder.includes(val)) {
            const below = (rows[r+1] && rows[r+1][c]) ? rows[r+1][c].trim().replace(/(^"|"$)/g,'') : "";
            // googlefinance puede traer valores como 1.23 o -0.34
            let pct = parseFloat(below);
            if (isNaN(pct)) {
              // intentar con % simbólico: "1.23%"
              const m = below.match(/(-?[\d\.,]+)%/);
              if (m) pct = parseFloat(m[1].replace(',', '.'));
            }
            map[val] = isNaN(pct) ? null : pct;
          }
        }
      }
      return map;
    }

    function buildGrid(dataMap) {
      const grid = document.getElementById('grid');
      grid.innerHTML = '';
      for (let ticker of tickersOrder) {
        const pct = dataMap[ticker];
        const box = document.createElement('div');
        box.className = 'box';
        const pctDisplay = (pct === null || pct === undefined) ? '—' : (pct > 0 ? "+" + pct.toFixed(2) + "%" : pct.toFixed(2) + "%");
        box.innerHTML = `<div class="ticker">${ticker}</div><div class="pct">${pctDisplay}</div>`;
        if (pct === null || pct === undefined) {
          box.style.background = '#7f8c8d';
          box.style.color = '#fff';
        } else {
          box.style.background = colorForPct(pct);
          box.style.color = '#fff';
        }
        grid.appendChild(box);
      }
    }

    async function refresh() {
      try {
        const csv = await fetchCSV(SHEET_CSV_URL);
        const map = parseCSVtoGrid(csv);
        buildGrid(map);
        document.getElementById('last').textContent = new Date().toLocaleString();
      } catch (e) {
        console.error(e);
        document.getElementById('last').textContent = 'Error al actualizar';
      }
    }

    // Primera carga y luego cada 60 seg
    refresh();
    setInterval(refresh, 60 * 1000);
  </script>
</body>
</html>
