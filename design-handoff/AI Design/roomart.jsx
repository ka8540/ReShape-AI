/* roomart.jsx — isometric room "renders" + top-down floor plans (pure SVG) */

// ---- isometric projection ----
const ISO_U = 19;          // horizontal half-unit
const ISO_V = 0.56;        // vertical squash
const ISO_H = 15;          // screen px per height-unit
function isoP(gx, gy, gz, o) {
  return [
    o.cx + (gx - gy) * ISO_U,
    o.cy + (gx + gy) * ISO_U * ISO_V - gz * ISO_H,
  ];
}
const pts = (arr) => arr.map(p => p.join(',')).join(' ');

// shade helper
function shade(hex, amt) {
  const n = parseInt(hex.slice(1), 16);
  let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  r = Math.max(0, Math.min(255, r + amt));
  g = Math.max(0, Math.min(255, g + amt));
  b = Math.max(0, Math.min(255, b + amt));
  return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, '0')}`;
}

// one iso box (furniture)
function IsoBox({ x, y, w, d, h, color, o, opacity = 1 }) {
  const P00 = isoP(x, y, 0, o), P10 = isoP(x + w, y, 0, o), P11 = isoP(x + w, y + d, 0, o), P01 = isoP(x, y + d, 0, o);
  const T00 = isoP(x, y, h, o), T10 = isoP(x + w, y, h, o), T11 = isoP(x + w, y + d, h, o), T01 = isoP(x, y + d, h, o);
  const top = shade(color, 22), right = shade(color, -28), left = shade(color, -6);
  return (
    <g opacity={opacity}>
      <polygon points={pts([P01, P11, T11, T01])} fill={left} />
      <polygon points={pts([P10, P11, T11, T10])} fill={right} />
      <polygon points={pts([T00, T10, T11, T01])} fill={top} />
    </g>
  );
}

// flat rug / mat on floor
function IsoRug({ x, y, w, d, color, o, opacity = 0.9 }) {
  const a = isoP(x, y, 0.02, o), b = isoP(x + w, y, 0.02, o), c = isoP(x + w, y + d, 0.02, o), e = isoP(x, y + d, 0.02, o);
  return <polygon points={pts([a, b, c, e])} fill={color} opacity={opacity} />;
}

/* RoomScene — a warm flat-iso room "render".
   `items` = array of {t, x, y, w, d, h} furniture; palette themes it. */
const ROOM_PALETTES = {
  warm:  { floor: '#E9D9C4', floorEdge: '#D8C3A6', wallL: '#EFE7DC', wallR: '#E2D6C6', sky: '#F6F1E9' },
  cool:  { floor: '#DCE6E8', floorEdge: '#C5D4D7', wallL: '#EAF0F1', wallR: '#DBE4E6', sky: '#F0F5F6' },
  cozy:  { floor: '#E7D3C8', floorEdge: '#D4BBAC', wallL: '#F0E4DC', wallR: '#E5D2C7', sky: '#F7EFE9' },
  dark:  { floor: '#2A3A40', floorEdge: '#1E2C31', wallL: '#34474E', wallR: '#28383E', sky: '#1A262B' },
};
const FURN_COLORS = {
  sofa: '#5FA89B', bed: '#6E8FC4', desk: '#C99B6B', wardrobe: '#9A8FB0', table: '#C0A57E',
  tv: '#33414C', shelf: '#B98E63', plant: '#5D9E6A', lamp: '#E6C15A', chair: '#7FB0A6',
  nightstand: '#B98E63', dresser: '#A98A6B', rug: '#D98C6A', tvstand: '#55636E',
};

function RoomScene({ items = [], palette = 'warm', width = 300, height = 188, rw = 9, rd = 7, glow = true }) {
  const pal = ROOM_PALETTES[palette] || ROOM_PALETTES.warm;
  const o = { cx: width / 2, cy: 50 };
  // floor corners
  const F00 = isoP(0, 0, 0, o), F10 = isoP(rw, 0, 0, o), F11 = isoP(rw, rd, 0, o), F01 = isoP(0, rd, 0, o);
  // walls (height 4.4 units)
  const WH = 4.4;
  const Lb0 = isoP(0, 0, 0, o), Lb1 = isoP(0, rd, 0, o), Lt0 = isoP(0, 0, WH, o), Lt1 = isoP(0, rd, WH, o);
  const Rb0 = isoP(0, 0, 0, o), Rb1 = isoP(rw, 0, 0, o), Rt0 = isoP(0, 0, WH, o), Rt1 = isoP(rw, 0, WH, o);
  // sort furniture back-to-front by (x+y)
  const sorted = [...items].sort((a, b) => (a.x + a.y) - (b.x + b.y));
  return (
    <svg viewBox={`0 0 ${width} ${height}`} width="100%" style={{ display: 'block' }}>
      <defs>
        <linearGradient id={`rsky-${palette}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={pal.sky} />
          <stop offset="1" stopColor={shade(pal.sky, palette === 'dark' ? 8 : -8)} />
        </linearGradient>
      </defs>
      <rect x="0" y="0" width={width} height={height} fill={`url(#rsky-${palette})`} />
      {/* back-left wall */}
      <polygon points={pts([Lb0, Lb1, Lt1, Lt0])} fill={pal.wallL} />
      {/* back-right wall */}
      <polygon points={pts([Rb0, Rb1, Rt1, Rt0])} fill={pal.wallR} />
      {/* window on right wall */}
      <polygon points={pts([isoP(2.2,0,1.4,o), isoP(4.6,0,1.4,o), isoP(4.6,0,3.4,o), isoP(2.2,0,3.4,o)])} fill={palette==='dark' ? '#1b3138' : '#CDE3EA'} opacity="0.9" />
      <line x1={isoP(3.4,0,1.4,o)[0]} y1={isoP(3.4,0,1.4,o)[1]} x2={isoP(3.4,0,3.4,o)[0]} y2={isoP(3.4,0,3.4,o)[1]} stroke={pal.wallR} strokeWidth="1.5" />
      {/* floor */}
      <polygon points={pts([F00, F10, F11, F01])} fill={pal.floor} stroke={pal.floorEdge} strokeWidth="1" />
      {/* furniture */}
      {sorted.map((it, i) => it.t === 'rug'
        ? <IsoRug key={i} x={it.x} y={it.y} w={it.w} d={it.d} color={FURN_COLORS.rug} o={o} />
        : <IsoBox key={i} x={it.x} y={it.y} w={it.w} d={it.d} h={it.h} color={FURN_COLORS[it.t] || '#9aa'} o={o} />
      )}
      {glow && <rect x="0" y="0" width={width} height={height} fill="url(#none)" />}
    </svg>
  );
}

/* Preset furniture arrangements (reused as "layout options") */
const ROOM_LAYOUTS = {
  // living room variants
  livingA: [ {t:'rug',x:2,y:2.4,w:4.5,d:3}, {t:'sofa',x:1.4,y:4.6,w:4,d:1.3,h:1.1}, {t:'table',x:3,y:3,w:1.8,d:1.1,h:.5}, {t:'tvstand',x:3.2,y:.3,w:3,d:.8,h:.9}, {t:'plant',x:.4,y:.4,w:.8,d:.8,h:2.2}, {t:'shelf',x:7.6,y:1,w:.7,d:2.4,h:2.6} ],
  livingB: [ {t:'rug',x:3,y:1.8,w:4,d:3.2}, {t:'sofa',x:.4,y:2,w:1.2,d:3.4,h:1.1}, {t:'table',x:2.4,y:3,w:1.6,d:1.1,h:.5}, {t:'tvstand',x:3.4,y:.3,w:3,d:.8,h:.9}, {t:'chair',x:6.4,y:3.4,w:1.1,d:1.1,h:1}, {t:'plant',x:7.4,y:.5,w:.8,d:.8,h:2.2} ],
  livingC: [ {t:'rug',x:2.2,y:3,w:4.6,d:2.6}, {t:'sofa',x:2,y:5,w:4.4,d:1.3,h:1.1}, {t:'chair',x:6.6,y:4,w:1.1,d:1.1,h:1}, {t:'table',x:3.4,y:3.5,w:1.6,d:1,h:.5}, {t:'tvstand',x:2.6,y:.3,w:3.4,d:.8,h:.9}, {t:'plant',x:.5,y:5,w:.8,d:.8,h:2.1}, {t:'shelf',x:.4,y:.6,w:.7,d:2.2,h:2.6} ],
  // bedroom + wfh
  bedA: [ {t:'rug',x:3.4,y:3.4,w:3.6,d:2.6}, {t:'bed',x:3.4,y:3.4,w:3.4,d:2.6,h:.9}, {t:'nightstand',x:2.4,y:3.6,w:.9,d:.9,h:.8}, {t:'desk',x:.5,y:.4,w:2.6,d:1,h:.9}, {t:'chair',x:1.3,y:1.5,w:1,d:1,h:1}, {t:'wardrobe',x:7.2,y:.5,w:.9,d:2.6,h:3.4}, {t:'plant',x:.4,y:5.6,w:.8,d:.8,h:2} ],
  bedB: [ {t:'rug',x:2.6,y:3,w:3.8,d:2.8}, {t:'bed',x:.5,y:3,w:2.6,d:3.4,h:.9}, {t:'desk',x:3,y:.4,w:1,d:2.4,h:.9}, {t:'chair',x:4.2,y:1.4,w:1,d:1,h:1}, {t:'wardrobe',x:7.2,y:.5,w:.9,d:2.4,h:3.4}, {t:'shelf',x:.5,y:.5,w:.7,d:2,h:2.6}, {t:'plant',x:7,y:5.6,w:.8,d:.8,h:2} ],
};

/* ---------- Top-down floor plan ---------- */
/* items: {label, x, y, w, h, type, fixed, moved}  in a 0..gw / 0..gd grid */
function FloorPlan({ items = [], gw = 12, gd = 9, width = 300, height = 224, showDoor = true, showWindow = true, theme = 'light' }) {
  const pad = 16;
  const iw = width - pad * 2, ih = height - pad * 2;
  const sx = iw / gw, sy = ih / gd;
  const wallC = theme === 'dark' ? '#3A4F57' : '#C7D4D8';
  const wallStroke = theme === 'dark' ? '#56707A' : '#9DB0B6';
  const txt = theme === 'dark' ? '#C9D8DA' : '#46585F';
  const grid = theme === 'dark' ? 'rgba(255,255,255,.04)' : 'rgba(15,30,41,.04)';
  const tealC = theme === 'dark' ? '#2BC0AB' : '#0E9E8C';
  const warmC = theme === 'dark' ? '#F0AB54' : '#E0962F';
  const fillFor = (it) => it.fixed ? (theme==='dark'?'rgba(240,171,84,.16)':'#FBEEDB') : (it.moved ? (theme==='dark'?'rgba(43,192,171,.20)':'#DBF1EC') : (theme==='dark'?'rgba(255,255,255,.05)':'#F1F6F7'));
  const strokeFor = (it) => it.fixed ? warmC : (it.moved ? tealC : (theme==='dark'?'#5C7077':'#B6C6CB'));
  return (
    <svg viewBox={`0 0 ${width} ${height}`} width="100%" style={{ display: 'block' }}>
      <rect x="0" y="0" width={width} height={height} fill={theme === 'dark' ? '#16272E' : '#FBFDFD'} />
      {/* grid */}
      {Array.from({ length: gw + 1 }).map((_, i) => <line key={'v'+i} x1={pad+i*sx} y1={pad} x2={pad+i*sx} y2={pad+ih} stroke={grid} strokeWidth="1" />)}
      {Array.from({ length: gd + 1 }).map((_, i) => <line key={'h'+i} x1={pad} y1={pad+i*sy} x2={pad+iw} y2={pad+i*sy} stroke={grid} strokeWidth="1" />)}
      {/* room walls */}
      <rect x={pad} y={pad} width={iw} height={ih} fill="none" stroke={wallStroke} strokeWidth="3.5" rx="3" />
      {/* door (arc) */}
      {showDoor && <g>
        <rect x={pad - 2} y={pad + ih * 0.55} width="4" height={sy * 1.6} fill={theme==='dark'?'#16272E':'#FBFDFD'} />
        <path d={`M ${pad} ${pad + ih*0.55} A ${sy*1.6} ${sy*1.6} 0 0 1 ${pad + sy*1.6} ${pad + ih*0.55 + sy*1.6}`} fill="none" stroke={wallStroke} strokeWidth="1.5" strokeDasharray="3 3" />
        <text x={pad + 6} y={pad + ih*0.55 - 4} fontSize="9" fontFamily="Inter, sans-serif" fill={txt}>door</text>
      </g>}
      {/* window */}
      {showWindow && <rect x={pad + iw*0.4} y={pad - 2} width={sx*2.4} height="4" fill={tealC} rx="2" />}
      {showWindow && <text x={pad + iw*0.4} y={pad - 6} fontSize="9" fontFamily="Inter, sans-serif" fill={txt}>window</text>}
      {/* furniture */}
      {items.map((it, i) => {
        const x = pad + it.x * sx, y = pad + it.y * sy, w = it.w * sx, h = it.h * sy;
        return (
          <g key={i}>
            <rect x={x} y={y} width={w} height={h} rx="3" fill={fillFor(it)} stroke={strokeFor(it)} strokeWidth={it.fixed || it.moved ? 2 : 1.4} strokeDasharray={it.fixed ? '4 3' : 'none'} />
            <text x={x + w/2} y={y + h/2} fontSize={Math.min(11, w/ (it.label.length*0.62))} fontFamily="Inter, sans-serif" fontWeight="600" fill={txt} textAnchor="middle" dominantBaseline="central">{it.label}</text>
          </g>
        );
      })}
    </svg>
  );
}

const FLOOR_LAYOUTS = {
  before:  [ {label:'Bed',x:7.4,y:.4,w:4,h:3.2,fixed:true}, {label:'Desk',x:.4,y:5.6,w:3,h:1.2}, {label:'Sofa',x:.4,y:.4,w:1.4,h:3.4}, {label:'TV',x:5,y:7.4,w:3,h:.7}, {label:'Shelf',x:.4,y:3.6,w:1,h:1.6}, {label:'Rug',x:3.5,y:3,w:3,h:2.6} ],
  moreSpace: [ {label:'Bed',x:7.4,y:.4,w:4,h:3.2,fixed:true}, {label:'Desk',x:.4,y:.4,w:3,h:1.2,moved:true}, {label:'Sofa',x:.4,y:5,w:3.6,h:1.4,moved:true}, {label:'TV',x:5.5,y:8,w:3,h:.6,moved:true}, {label:'Shelf',x:11,y:5,w:.8,h:2.4,moved:true}, {label:'Rug',x:4,y:4,w:3,h:2.4,moved:true} ],
  workFlow: [ {label:'Bed',x:7.4,y:.4,w:4,h:3.2,fixed:true}, {label:'Desk',x:4.2,y:.5,w:2.8,h:1.2,moved:true}, {label:'Sofa',x:.4,y:6,w:3.6,h:1.4,moved:true}, {label:'TV',x:.5,y:.5,w:3,h:.7,moved:true}, {label:'Shelf',x:.4,y:2.2,w:1,h:2.4}, {label:'Rug',x:4,y:4.5,w:3,h:2.2,moved:true} ],
  openWalk: [ {label:'Bed',x:7.4,y:.4,w:4,h:3.2,fixed:true}, {label:'Desk',x:.4,y:.4,w:2.6,h:1.2,moved:true}, {label:'Sofa',x:8,y:5,w:3.6,h:1.4,moved:true}, {label:'TV',x:.5,y:7.6,w:3,h:.7}, {label:'Shelf',x:.4,y:2.4,w:1,h:3.4,moved:true}, {label:'Rug',x:4.5,y:4,w:3,h:2.6,moved:true} ],
};

Object.assign(window, { RoomScene, FloorPlan, ROOM_LAYOUTS, FLOOR_LAYOUTS, IsoBox });
