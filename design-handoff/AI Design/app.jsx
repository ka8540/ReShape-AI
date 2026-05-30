/* app.jsx — ReSpace AI: store, router, shell, tab bar, seed data */

var { useState, useEffect, useRef, useCallback, forwardRef, useImperativeHandle } = React;

/* ---------------- seed data ---------------- */
const SEED_ITEMS = [
  { id: 'bed',   name: 'Bed',          type: 'bed',    conf: 0.94, movable: false },
  { id: 'desk',  name: 'Desk',         type: 'desk',   conf: 0.88, movable: true  },
  { id: 'sofa',  name: 'Sofa',         type: 'sofa',   conf: 0.83, movable: true  },
  { id: 'tv',    name: 'TV',           type: 'tv',     conf: 0.78, movable: true  },
  { id: 'shelf', name: 'Bookshelf',    type: 'shelf',  conf: 0.71, movable: true  },
  { id: 'rug',   name: 'Rug',          type: 'rug',    conf: 0.64, movable: true  },
  { id: 'lamp',  name: 'Floor lamp',   type: 'lamp',   conf: 0.57, movable: true  },
  { id: 'plant', name: 'Plant',        type: 'plant',  conf: 0.46, movable: true  },
  { id: 'window',name: 'Window',       type: 'window', conf: 0.90, movable: false, structural: true },
  { id: 'door',  name: 'Door',         type: 'door',   conf: 0.92, movable: false, structural: true },
];

const GOALS = [
  { id: 'space',   label: 'More open space',   icon: 'move' },
  { id: 'walk',    label: 'Better walking path',icon: 'arrowR' },
  { id: 'tv',      label: 'Better TV setup',    icon: 'video' },
  { id: 'work',    label: 'Better work / study',icon: 'desk' },
  { id: 'light',   label: 'Better lighting',    icon: 'bulb' },
  { id: 'storage', label: 'More storage',       icon: 'layers' },
  { id: 'aesthetic',label:'Better aesthetic',   icon: 'sparkleSm' },
];
const STYLES = ['Minimal','Cozy','Modern','Functional','Luxury','Student apartment','Small-space'];

const RESULTS = [
  { id:0, title:'The Open Studio', goal:92, diff:'Easy', moved:4, room:'bedB', floor:'moreSpace', palette:'cool',
    reason:'Frees the centre of the room and opens a clear path from the door to the window.',
    pros:['Largest open floor area','Clear walking path','Desk gets daylight'], cons:['Sofa faces away from window'],
    changed:['Desk moved to the window wall','Sofa shifted against the left wall','Rug re-centred under the seating'],
    steps:['Slide the desk to the window wall','Rotate desk to face the window','Move sofa flush to the left wall','Shift the rug under the seating area','Keep the bed where it is (fixed)'] },
  { id:1, title:'Focused Work Corner', goal:88, diff:'Medium', moved:5, room:'bedA', floor:'workFlow', palette:'warm',
    reason:'Builds a dedicated study zone by the daylight while keeping the bed undisturbed.',
    pros:['Dedicated work zone','Great task lighting','TV visible from bed'], cons:['Slightly tighter walkway','Bookshelf splits the wall'],
    changed:['Desk paired with the window','TV mounted opposite the bed','Sofa tucked into the reading nook'],
    steps:['Move the desk beside the window','Place the chair facing the desk','Mount / set TV opposite the bed','Move sofa to the bottom-left corner','Add the floor lamp beside the desk'] },
  { id:2, title:'Cosy Lounge', goal:84, diff:'Easy', moved:3, room:'bedB', floor:'openWalk', palette:'cozy',
    reason:'Groups the soft seating into a warm conversation cluster near the shelf and plant.',
    pros:['Inviting lounge feel','Minimal heavy lifting','Storage stays reachable'], cons:['Desk is away from daylight'],
    changed:['Sofa & rug grouped to the right','Bookshelf anchors the corner','Desk kept near the door'],
    steps:['Group sofa and rug on the right side','Stand the bookshelf in the right corner','Leave the desk by the door','Tidy cables behind the shelf'] },
  { id:3, title:'Balanced Flow', goal:80, diff:'Medium', moved:4, room:'bedA', floor:'workFlow', palette:'cool',
    reason:'A middle-ground layout that improves flow without committing fully to work or lounge.',
    pros:['Even use of the room','Flexible for guests','Good light spread'], cons:['No single hero zone'],
    changed:['Desk near window','Sofa centred to the wall','Shelf relocated for balance'],
    steps:['Centre the sofa on the long wall','Move the desk toward the window','Balance the shelf opposite the sofa','Re-lay the rug between zones'] },
];

const REDESIGN_CONCEPTS = [
  { id:0, title:'Warm Scandi', cost:842, fit:0.91, room:'bedB', floor:'moreSpace', palette:'warm', style:'Scandinavian',
    note:'Light oak, soft wool and a compact sofa that fits your 11.5 ft wall.', items:4 },
  { id:1, title:'Modern Calm', cost:1190, fit:0.84, room:'livingA', floor:'workFlow', palette:'cool', style:'Modern',
    note:'Low-profile media unit and a slim desk to protect the walkway.', items:5 },
  { id:2, title:'Budget Refresh', cost:468, fit:0.88, room:'bedA', floor:'openWalk', palette:'cozy', style:'Minimal',
    note:'A few swaps under $500 — rug, lamp and a fold-away desk.', items:3 },
];
const PRODUCTS = [
  { name:'Compact 2-seat sofa', store:'IKEA',    price:399, dim:'72 × 33 in', fit:'Fits' },
  { name:'Oak coffee table',    store:'Wayfair', price:89,  dim:'40 × 22 in', fit:'Fits' },
  { name:'Wool area rug 6×9',   store:'Target',  price:129, dim:'72 × 108 in',fit:'Fits' },
  { name:'Arc floor lamp',      store:'Amazon',  price:64,  dim:'—',          fit:'Unknown' },
];

const SAVED_PROJECTS = [
  { id:'p1', name:'My bedroom', room:'Bedroom', mode:'reshuffle', edited:'2 days ago', status:'Plan saved', floor:'moreSpace' },
  { id:'p2', name:'Living room refresh', room:'Living room', mode:'redesign', edited:'5 days ago', status:'In review', floor:'workFlow' },
];

const RESHUFFLE_STEPS = ['Mode','Capture','Upload','Review','Prefs','Results','Plan'];
const REDESIGN_STEPS  = ['Room','Capture','Measure','Style','Concepts','Plan'];

/* ---------------- layout helpers ---------------- */
function ScreenShell({ ctx, header, footer, children, bg, noScroll, scrollRef }) {
  const { insets } = ctx;
  return (
    <div className="rs-screen rs-fade" style={bg ? { background: bg } : undefined}>
      {header && <div style={{ paddingTop: insets.top, flexShrink: 0 }}>{header}</div>}
      {noScroll
        ? <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column', paddingTop: header ? 0 : insets.top }}>{children}</div>
        : <div className="rs-scroll" ref={scrollRef} style={{ paddingTop: header ? 0 : insets.top }}>{children}</div>}
      {footer}
    </div>
  );
}

function BottomBar({ ctx, children, transparent }) {
  return (
    <div style={{
      flexShrink: 0, padding: `13px 16px ${13 + ctx.insets.bottom}px`,
      background: transparent ? 'transparent' : 'var(--surface)',
      borderTop: transparent ? 'none' : '1px solid var(--border)',
      boxShadow: transparent ? 'none' : '0 -6px 22px -10px rgba(15,30,41,.14)',
    }}>{children}</div>
  );
}

/* ---------------- bottom tabs ---------------- */
function TabBar({ ctx }) {
  const tabs = [
    { id: 'home', label: 'Home', icon: 'home' },
    { id: 'saved', label: 'Saved', icon: 'folder' },
    { id: 'new', label: 'New', icon: 'plus', fab: true },
    { id: 'explore', label: 'Explore', icon: 'sparkleSm' },
    { id: 'profile', label: 'Profile', icon: 'user' },
  ];
  return (
    <div className="rs-tabs" style={{ paddingBottom: 6 + ctx.insets.bottom }}>
      {tabs.map(t => {
        const on = ctx.route === t.id || (t.id === 'new' && false);
        if (t.fab) return (
          <button key={t.id} className="rs-tab" onClick={() => ctx.startNewProject()}>
            <div className="fab"><Icon name="plus" size={26} sw={2.6} /></div>
          </button>
        );
        return (
          <button key={t.id} className={`rs-tab ${on ? 'on' : ''}`} onClick={() => ctx.go(t.id, { reset: true })}>
            <Icon name={t.icon} size={23} sw={on ? 2.4 : 2} />
            {t.label}
          </button>
        );
      })}
    </div>
  );
}

/* ---------------- the app ---------------- */
const RespaceApp = forwardRef(function RespaceApp({ theme, platform }, ref) {
  const insets = platform === 'ios' ? { top: 54, bottom: 24 } : { top: 10, bottom: 10 };
  const [stack, setStack] = useState(['welcome']);
  const route = stack[stack.length - 1];
  const [sheet, setSheet] = useState(null);
  const scrollRef = useRef(null);

  const [project, setProject] = useState({
    mode: null, roomType: 'Bedroom', improve: 'space',
    items: SEED_ITEMS.map(i => ({ ...i, fixed: i.id === 'bed' || i.structural })),
    goals: ['space'], style: 'Minimal', difficulty: 'Easy',
    resultsView: 'grid', selected: 0, compareSel: [0, 1],
    measures: { width: 11.5, length: 14, height: 8, window: 4, door: 3 }, calibrated: false,
    budget: '$250–$500', rdStyle: 'Scandinavian', color: 'Warm', stores: ['IKEA','Target'], mustHave: ['Sofa','Rug'],
    rdSelected: 0,
    saved: SAVED_PROJECTS, empty: false,
  });
  const set = useCallback((patch) => setProject(p => ({ ...p, ...(typeof patch === 'function' ? patch(p) : patch) })), []);

  const go = useCallback((id, opts = {}) => {
    setSheet(null);
    setStack(s => opts.reset ? [id] : (s[s.length - 1] === id ? s : [...s, id]));
    if (scrollRef.current) scrollRef.current.scrollTop = 0;
  }, []);
  const back = useCallback(() => setStack(s => s.length > 1 ? s.slice(0, -1) : s), []);
  const startNewProject = useCallback(() => { setProject(p => ({ ...p, mode: null })); go('mode'); }, [go]);

  useImperativeHandle(ref, () => ({ goTo: (id) => go(id, { reset: id === 'welcome' || id === 'home' }) }), [go]);

  useEffect(() => { if (scrollRef.current) scrollRef.current.scrollTop = 0; }, [route]);

  const ctx = { route, go, back, project, set, theme, platform, insets,
    sheet, openSheet: setSheet, closeSheet: () => setSheet(null), startNewProject, scrollRef };

  const SCREENS = {
    welcome: window.Sc_Welcome, auth: window.Sc_Auth, perm: window.Sc_Perm,
    home: window.Sc_Home, saved: window.Sc_Saved, explore: window.Sc_Explore, profile: window.Sc_Profile,
    mode: window.Sc_Mode, capture: window.Sc_Capture, upload: window.Sc_Upload, preview: window.Sc_Preview,
    processing: window.Sc_Processing, error: window.Sc_Error,
    review: window.Sc_Review, prefs: window.Sc_Prefs,
    results: window.Sc_Results, compare: window.Sc_Compare, detail: window.Sc_Detail, final: window.Sc_Final,
    rd_mode: window.Sc_RdMode, rd_capture: window.Sc_RdCapture, rd_measure: window.Sc_RdMeasure,
    rd_calibrate: window.Sc_RdCalibrate, rd_prefs: window.Sc_RdPrefs, rd_concepts: window.Sc_RdConcepts,
    rd_detail: window.Sc_RdDetail, rd_products: window.Sc_RdProducts, rd_final: window.Sc_RdFinal,
  };
  const Screen = SCREENS[route] || (() => <div style={{ padding: 40 }}>Missing: {route}</div>);

  return (
    <div className={`rs-root ${theme === 'dark' ? 'dark' : ''}`} style={{ position: 'relative', width: '100%', height: '100%', overflow: 'hidden' }}>
      <Screen ctx={ctx} />
    </div>
  );
});

window.RespaceApp = RespaceApp;
window.ScreenShell = ScreenShell;
window.BottomBar = BottomBar;
window.TabBar = TabBar;
window.SEED_ITEMS = SEED_ITEMS; window.GOALS = GOALS; window.STYLES = STYLES;
window.RESULTS = RESULTS; window.REDESIGN_CONCEPTS = REDESIGN_CONCEPTS; window.PRODUCTS = PRODUCTS;
window.RESHUFFLE_STEPS = RESHUFFLE_STEPS; window.REDESIGN_STEPS = REDESIGN_STEPS;
