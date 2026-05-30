/* components.jsx — icon set + shared UI primitives for ReSpace AI */

const ICONS = {
  back: 'M15 5l-7 7 7 7',
  chevR: 'M9 5l7 7-7 7',
  chevD: 'M5 9l7 7 7-7',
  chevUp: 'M5 15l7-7 7 7',
  x: 'M6 6l12 12M18 6L6 18',
  check: 'M5 12.5l4.5 4.5L19 7',
  plus: 'M12 5v14M5 12h14',
  minus: 'M5 12h14',
  camera: 'M3 8.5A1.5 1.5 0 014.5 7H7l1.2-2h7.6L17 7h2.5A1.5 1.5 0 0121 8.5v10A1.5 1.5 0 0119.5 20h-15A1.5 1.5 0 013 18.5zM12 16.5a3.5 3.5 0 100-7 3.5 3.5 0 000 7z',
  upload: 'M12 16V4m0 0L7.5 8.5M12 4l4.5 4.5M4 18v1.5A1.5 1.5 0 005.5 21h13a1.5 1.5 0 001.5-1.5V18',
  gallery: 'M4 5.5A1.5 1.5 0 015.5 4h13A1.5 1.5 0 0120 5.5v13a1.5 1.5 0 01-1.5 1.5h-13A1.5 1.5 0 014 18.5zM4 16l4.5-4 3.5 3 4-4.5L20 14M9 9.5a1.5 1.5 0 100-3 1.5 1.5 0 000 3z',
  video: 'M4 7.5A1.5 1.5 0 015.5 6h8A1.5 1.5 0 0115 7.5v9A1.5 1.5 0 0113.5 18h-8A1.5 1.5 0 014 16.5zM15 10l5-3v10l-5-3',
  play: 'M8 5.5l11 6.5-11 6.5z',
  trash: 'M5 7h14M9 7V5h6v2m-8 0l.8 12.5a1 1 0 001 .9h6.4a1 1 0 001-.9L17 7',
  edit: 'M4 20h4L19 9l-4-4L4 16zM14 6l4 4',
  home: 'M4 11l8-7 8 7M6 9.5V20h12V9.5',
  folder: 'M4 6.5A1.5 1.5 0 015.5 5H10l2 2.5h6.5A1.5 1.5 0 0120 9v8.5a1.5 1.5 0 01-1.5 1.5h-13A1.5 1.5 0 014 17.5z',
  user: 'M12 12a4 4 0 100-8 4 4 0 000 8zM5 20c0-3.5 3.1-5.5 7-5.5s7 2 7 5.5',
  sparkle: 'M12 3l1.8 4.8L19 9.5l-4.6 2.2L12 17l-1.9-5.3L5 9.5l4.7-1.7zM18 14l.8 2 2 .8-2 .9-.8 2-.9-2-2-.9 2-.8z',
  sparkleSm: 'M12 4l2 5.5L19.5 12 14 14l-2 5.5L10 14 4.5 12 10 9.5z',
  move: 'M12 4v16M4 12h16M9 7l3-3 3 3M9 17l3 3 3-3M7 9l-3 3 3 3M17 9l3 3-3 3',
  lock: 'M7 11V8a5 5 0 0110 0v3m-11 0h12a1 1 0 011 1v7a1 1 0 01-1 1H6a1 1 0 01-1-1v-7a1 1 0 011-1z',
  sun: 'M12 7.5a4.5 4.5 0 100 9 4.5 4.5 0 000-9zM12 2v2M12 20v2M4 12H2M22 12h-2M5.6 5.6L4.2 4.2M19.8 19.8l-1.4-1.4M18.4 5.6l1.4-1.4M4.2 19.8l1.4-1.4',
  moon: 'M20 14.5A8 8 0 119.5 4 6.5 6.5 0 0020 14.5z',
  search: 'M11 4a7 7 0 105 12l4 4M16 11a5 5 0 10-10 0 5 5 0 0010 0z',
  share: 'M12 15V4m0 0L8.5 7.5M12 4l3.5 3.5M5 12v6.5A1.5 1.5 0 006.5 20h11a1.5 1.5 0 001.5-1.5V12',
  download: 'M12 4v11m0 0l-4-4m4 4l4-4M5 20h14',
  info: 'M12 11v6m0-9.5h.01M12 21a9 9 0 100-18 9 9 0 000 18z',
  alert: 'M12 9v4m0 3h.01M10.3 4l-7 12A1.5 1.5 0 004.6 18.3h14.8A1.5 1.5 0 0020.7 16l-7-12a1.5 1.5 0 00-3.4 0z',
  refresh: 'M4 12a8 8 0 0114-5.3L20 8M20 4v4h-4M20 12a8 8 0 01-14 5.3L4 16m0 4v-4h4',
  layers: 'M12 4l8 4-8 4-8-4zM4 12l8 4 8-4M4 16l8 4 8-4',
  ruler: 'M5 9l10-5 4 8.5-10 5zM8 7.5l1.2 2.4M11 6l1.6 3.2M14 4.8l1.4 2.8',
  sliders: 'M5 7h7m4 0h3M5 12h3m4 0h7M5 17h11m4 0h0M13 5v4M9 10v4M16 15v4',
  bulb: 'M9 17h6m-5 3h4M8.5 14a5 5 0 117 0c-.8.7-1.2 1.3-1.3 2H9.8c-.1-.7-.5-1.3-1.3-2z',
  grid: 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z',
  swap: 'M7 7h11m0 0l-3.5-3.5M18 7l-3.5 3.5M17 17H6m0 0l3.5-3.5M6 17l3.5 3.5',
  heart: 'M12 20S4 14.5 4 9a4 4 0 017.5-2A4 4 0 0120 9c0 5.5-8 11-8 11z',
  dots: 'M6 12h.01M12 12h.01M18 12h.01',
  mic: 'M12 4a2.5 2.5 0 012.5 2.5v5a2.5 2.5 0 01-5 0v-5A2.5 2.5 0 0112 4zM6 11a6 6 0 0012 0M12 17v3',
  eye: 'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7zM12 15a3 3 0 100-6 3 3 0 000 6z',
  cart: 'M5 6h15l-1.5 8.5a1.5 1.5 0 01-1.5 1.2H9a1.5 1.5 0 01-1.5-1.2L5.5 4H3M9 20a1 1 0 100-2 1 1 0 000 2zm8 0a1 1 0 100-2 1 1 0 000 2z',
  bed: 'M3 18v-7a2 2 0 012-2h14a2 2 0 012 2v7M3 14h18M7 9V7a1 1 0 011-1h3M3 18v2M21 18v2',
  sofa: 'M5 11V9a2 2 0 012-2h10a2 2 0 012 2v2M3 12a2 2 0 012 2v3h14v-3a2 2 0 012-2 2 2 0 00-2-2v0a2 2 0 00-2 2M5 17v2M19 17v2',
  desk: 'M4 8h16M5 8v11M19 8v11M4 12h6M9 8v4',
  plant: 'M12 21v-7m0 0c-3 0-4-2-4-4 2 0 4 1 4 4zm0 0c0-3 2-4 4-4 0 2-1 4-4 4zM9 21h6',
  flag: 'M6 21V4m0 0h11l-2 4 2 4H6',
  star: 'M12 4l2.4 5 5.6.6-4 4 1 5.4L12 16l-5 3 1-5.4-4-4 5.6-.6z',
  clock: 'M12 7v5l3 2M12 21a9 9 0 100-18 9 9 0 000 18z',
  pin: 'M12 21s7-6 7-11a7 7 0 10-14 0c0 5 7 11 7 11zM12 12a2.5 2.5 0 100-5 2.5 2.5 0 000 5z',
  scan: 'M4 8V6a2 2 0 012-2h2M16 4h2a2 2 0 012 2v2M20 16v2a2 2 0 01-2 2h-2M8 20H6a2 2 0 01-2-2v-2M4 12h16',
  palette: 'M12 3a9 9 0 100 18c1 0 1.5-.8 1.5-1.5 0-1 .9-1.5 2-1.5h1.5A3.5 3.5 0 0021 14.5C21 8.5 17 3 12 3zM7.5 12a1 1 0 100-2 1 1 0 000 2zm3-3a1 1 0 100-2 1 1 0 000 2zm5 0a1 1 0 100-2 1 1 0 000 2z',
  wallet: 'M4 7.5A1.5 1.5 0 015.5 6H18a1 1 0 011 1v0H5.5M4 7.5V17a2 2 0 002 2h12a1 1 0 001-1v-3m0-5v5m0-5h-3a2.5 2.5 0 000 5h3',
  list: 'M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01',
  filter: 'M4 5h16l-6 7v6l-4 2v-8z',
  pencil: 'M4 20h4L18 10l-4-4L4 16zM13 7l4 4',
  arrowR: 'M5 12h14m0 0l-6-6m6 6l-6 6',
};

function Icon({ name, size = 22, color = 'currentColor', sw = 2, fill = 'none', style }) {
  const filled = ['play', 'star', 'heart', 'sparkle'].includes(name) && fill === 'solid';
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? color : 'none'}
      stroke={filled ? 'none' : color} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style}>
      <path d={ICONS[name] || ''} />
    </svg>
  );
}

// generic press-scale wrapper
function Tap({ as = 'div', onClick, children, style, className }) {
  const El = as;
  return <El className={className} onClick={onClick} style={{ cursor: onClick ? 'pointer' : undefined, ...style }}>{children}</El>;
}

// step progress (Mode → Capture → Upload → Review → Prefs → Results → Plan)
function Stepper({ steps, current }) {
  return (
    <div className="rs-stepper">
      {steps.map((s, i) => (
        <div key={i} className={`seg ${i < current ? 'done' : ''} ${i === current ? 'cur' : ''}`} />
      ))}
    </div>
  );
}

// chip
function Chip({ label, icon, on, onClick, sm }) {
  return (
    <button className={`rs-chip ${on ? 'rs-chip--on' : ''} ${sm ? 'rs-chip--sm' : ''}`} onClick={onClick}>
      {icon && <Icon name={icon} size={sm ? 14 : 16} sw={2.2} />}
      {label}
    </button>
  );
}

// switch
function Switch({ on, onClick }) {
  return <div className={`rs-switch ${on ? 'on' : ''}`} onClick={onClick}><i /></div>;
}

// confidence bar
function Confidence({ value, theme }) {
  const c = value >= 0.8 ? 'var(--ok)' : value >= 0.55 ? 'var(--warn)' : 'var(--danger)';
  const label = value >= 0.8 ? 'High' : value >= 0.55 ? 'Medium' : 'Low';
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <span style={{ display: 'flex', gap: 2 }}>
        {[0,1,2].map(i => <span key={i} style={{ width: 5, height: 11, borderRadius: 2, background: (value*3 > i) ? c : 'var(--border-2)' }} />)}
      </span>
      <span className="rs-xs" style={{ color: c, fontWeight: 700 }}>{label}</span>
    </span>
  );
}

// difficulty pill
function Difficulty({ level }) {
  const map = { Easy: 'var(--diff-easy)', Medium: 'var(--diff-med)', Heavy: 'var(--diff-hard)' };
  const c = map[level] || 'var(--diff-med)';
  return (
    <span className="rs-badge" style={{ background: 'color-mix(in srgb, ' + c + ' 14%, transparent)', color: c }}>
      <span className="rs-dot" style={{ background: c }} />{level} move
    </span>
  );
}

// bottom sheet
function Sheet({ open, onClose, children, title, pb = 22 }) {
  if (!open) return null;
  return (
    <React.Fragment>
      <div className="rs-sheet-scrim" onClick={onClose} />
      <div className="rs-sheet" style={{ paddingBottom: pb }}>
        <div className="grab" />
        {title && <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <h3 className="rs-h2">{title}</h3>
          <div className="rs-iconbtn" style={{ width: 34, height: 34 }} onClick={onClose}><Icon name="x" size={18} /></div>
        </div>}
        <div style={{ overflowY: 'auto' }}>{children}</div>
      </div>
    </React.Fragment>
  );
}

// top bar with optional back + title + trailing
function TopBar({ title, onBack, trailing, sub, compact }) {
  return (
    <div className="rs-topbar" style={compact ? { paddingBottom: 6 } : {}}>
      {onBack && <div className="rs-iconbtn" onClick={onBack}><Icon name="back" size={20} /></div>}
      <div style={{ flex: 1, minWidth: 0 }}>
        {title && <div className="rs-h3" style={{ lineHeight: 1.2 }}>{title}</div>}
        {sub && <div className="rs-xs" style={{ marginTop: 1 }}>{sub}</div>}
      </div>
      {trailing}
    </div>
  );
}

// little avatar/logo mark
function Logo({ size = 30 }) {
  return (
    <div style={{ width: size, height: size, borderRadius: size * 0.3, background: 'var(--teal)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--sh-teal)', flexShrink: 0 }}>
      <svg width={size*0.6} height={size*0.6} viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 10l8-6 8 6M6 8.5V19h12V8.5" />
        <path d="M10 19v-4h4v4" />
      </svg>
    </div>
  );
}

Object.assign(window, { Icon, Tap, Stepper, Chip, Switch, Confidence, Difficulty, Sheet, TopBar, Logo, ICONS });
