/* screens-redesign.jsx — the future "Redesign" path (measurements + products) */
const { useState: useRd } = React;

function RdHeader({ ctx, step, title }) {
  return (
    <div style={{ paddingTop: ctx.insets.top }}>
      <div className="rs-topbar" style={{ paddingBottom: 8 }}>
        <div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div>
        <div style={{ flex: 1 }}><div className="rs-xs" style={{ fontWeight: 600 }}><span className="rs-badge rs-badge--warm" style={{ fontSize: 9, padding: '1px 6px', marginRight: 6 }}>BETA</span>{title} · Step {step + 1} of {REDESIGN_STEPS.length}</div></div>
        <div className="rs-iconbtn" onClick={() => ctx.go('home', { reset: true })}><Icon name="x" size={18} /></div>
      </div>
      <div className="rs-stepper">{REDESIGN_STEPS.map((s, i) => <div key={i} className={`seg ${i < step ? 'done' : ''} ${i === step ? 'cur' : ''}`} style={i <= step ? { background: i < step ? 'var(--warm)' : undefined } : {}} />)}</div>
    </div>
  );
}

function Sc_RdMode({ ctx }) {
  const rooms = [['Bedroom', 'bed'], ['Living room', 'sofa'], ['Studio', 'home'], ['Home office', 'desk'], ['Dining', 'grid'], ['Kitchen', 'layers']];
  const improves = ['Full redesign', 'Add furniture', 'Improve décor', 'Better lighting', 'Premium look', 'Budget-friendly', 'Small-space'];
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<RdHeader ctx={ctx} step={0} title="Redesign" />}
      footer={<BottomBar ctx={ctx}><button className="rs-btn rs-btn--primary" style={{ background: 'var(--warm)', boxShadow: 'none' }} onClick={() => ctx.go('rd_capture')}>Continue <Icon name="arrowR" size={18} /></button></BottomBar>}>
      <div style={{ padding: '14px 16px 24px' }}>
        <h1 className="rs-h1">What are we redesigning?</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Redesign suggests new furniture sized to your room — so it needs a few measurements.</p>
        <div className="rs-eyebrow" style={{ margin: '20px 2px 11px' }}>Room type</div>
        <div className="rs-grid2">
          {rooms.map(([r, ic]) => (
            <button key={r} className="rs-card rs-card--pad" style={{ display: 'flex', alignItems: 'center', gap: 11, cursor: 'pointer', borderColor: ctx.project.roomType === r ? 'var(--warm)' : 'var(--border)' }} onClick={() => ctx.set({ roomType: r })}>
              <div style={{ width: 36, height: 36, borderRadius: 11, background: ctx.project.roomType === r ? 'var(--warm-tint)' : 'var(--surface-3)', color: ctx.project.roomType === r ? 'var(--warm-ink)' : 'var(--ink-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name={ic} size={18} /></div>
              <span className="rs-h3" style={{ fontSize: 14 }}>{r}</span>
            </button>
          ))}
        </div>
        <div className="rs-eyebrow" style={{ margin: '24px 2px 11px' }}>What should AI improve?</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>
          {improves.map((im, i) => <Chip key={im} label={im} on={i === 0} />)}
        </div>
      </div>
    </ScreenShell>
  );
}

function Sc_RdCapture({ ctx }) {
  const tips = [['scan', 'All walls & corners', 'Redesign needs full geometry — capture every wall.'], ['ruler', 'Show ceiling height', 'Tilt up at a corner so AI can estimate height.'], ['pin', 'Windows, doors & outlets', 'These limit where new furniture can go.'], ['clock', 'Scan slowly from each corner', 'Steady, even motion improves measurement.']];
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<RdHeader ctx={ctx} step={1} title="Capture" />}
      footer={<BottomBar ctx={ctx}><button className="rs-btn rs-btn--primary" style={{ background: 'var(--warm)', boxShadow: 'none' }} onClick={() => ctx.go('rd_measure')}>I'm ready to scan</button></BottomBar>}>
      <div style={{ padding: '14px 16px 24px' }}>
        <div className="rs-note rs-note--warn" style={{ marginBottom: 16 }}><Icon name="info" size={17} style={{ flexShrink: 0, marginTop: 1 }} /><span>Redesign capture is <b>stricter</b> than reshuffle — measurements depend on a careful scan.</span></div>
        <h1 className="rs-h1">Scan for measurements</h1>
        <div className="rs-card" style={{ overflow: 'hidden', marginTop: 16 }}><RoomScene items={ROOM_LAYOUTS.livingB} palette={ctx.theme === 'dark' ? 'dark' : 'warm'} height={150} /></div>
        <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 2 }}>
          {tips.map(([ic, t, d], i) => (
            <div key={i} className="rs-row" style={{ padding: '11px 4px' }}>
              <div style={{ width: 38, height: 38, borderRadius: 11, background: 'var(--warm-tint)', color: 'var(--warm-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name={ic} size={18} /></div>
              <div style={{ flex: 1 }}><div className="rs-h3" style={{ fontSize: 14.5 }}>{t}</div><div className="rs-xs" style={{ marginTop: 1 }}>{d}</div></div>
            </div>
          ))}
        </div>
      </div>
    </ScreenShell>
  );
}

function MeasureRow({ label, val, unit, onChange }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--border)' }}>
      <span className="rs-h3" style={{ fontSize: 14.5, flex: 1 }}>{label}</span>
      <span className="rs-badge rs-badge--warm" style={{ marginRight: 10 }}>est.</span>
      <div className="rs-seg" style={{ background: 'var(--surface-2)' }}>
        <button onClick={() => onChange(Math.max(1, +(val - 0.5).toFixed(1)))} style={{ padding: '6px 10px' }}><Icon name="minus" size={14} /></button>
        <span className="rs-num" style={{ minWidth: 58, textAlign: 'center', fontWeight: 700, alignSelf: 'center', fontSize: 14 }}>{val} {unit}</span>
        <button onClick={() => onChange(+(val + 0.5).toFixed(1))} style={{ padding: '6px 10px' }}><Icon name="plus" size={14} /></button>
      </div>
    </div>
  );
}

function Sc_RdMeasure({ ctx }) {
  const m = ctx.project.measures;
  const setM = (k, v) => ctx.set(p => ({ measures: { ...p.measures, [k]: v } }));
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<RdHeader ctx={ctx} step={2} title="Measure" />}
      footer={<BottomBar ctx={ctx}><button className="rs-btn rs-btn--primary" style={{ background: 'var(--warm)', boxShadow: 'none' }} onClick={() => ctx.go('rd_prefs')}>Confirm measurements <Icon name="arrowR" size={18} /></button></BottomBar>}>
      <div style={{ padding: '14px 16px 24px' }}>
        <h1 className="rs-h1">Review the measurements</h1>
        <div className="rs-note rs-note--warn" style={{ marginTop: 12 }}><Icon name="ruler" size={17} style={{ flexShrink: 0, marginTop: 1 }} /><span>Measurements are <b>estimated</b> from your video. Correct any value before generating redesigns.</span></div>
        <div className="rs-card" style={{ overflow: 'hidden', marginTop: 16, background: 'var(--surface-2)', boxShadow: 'none' }}>
          <FloorPlan items={[{ label: m.width + 'ft', x: 0.2, y: 0.2, w: 11.6, h: 0.01 }].length ? FLOOR_LAYOUTS.before.slice(0, 3) : []} width={330} height={150} theme={ctx.theme} />
        </div>
        <div className="rs-card rs-card--pad" style={{ marginTop: 14 }}>
          <MeasureRow label="Room width" val={m.width} unit="ft" onChange={v => setM('width', v)} />
          <MeasureRow label="Room length" val={m.length} unit="ft" onChange={v => setM('length', v)} />
          <MeasureRow label="Wall height" val={m.height} unit="ft" onChange={v => setM('height', v)} />
          <MeasureRow label="Window width" val={m.window} unit="ft" onChange={v => setM('window', v)} />
          <div style={{ display: 'flex', alignItems: 'center', padding: '12px 0 2px' }}>
            <span className="rs-h3" style={{ fontSize: 14.5, flex: 1 }}>Door width</span>
            <span className="rs-badge rs-badge--warm" style={{ marginRight: 10 }}>est.</span>
            <span className="rs-num" style={{ fontWeight: 700, fontSize: 14 }}>{m.door} ft</span>
          </div>
        </div>
        <button className="rs-card" style={{ marginTop: 14, padding: 15, display: 'flex', alignItems: 'center', gap: 12, width: '100%', cursor: 'pointer', textAlign: 'left' }} onClick={() => ctx.go('rd_calibrate')}>
          <div style={{ width: 40, height: 40, borderRadius: 12, background: 'var(--teal-tint)', color: 'var(--teal-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="ruler" size={19} /></div>
          <div style={{ flex: 1 }}><div className="rs-h3" style={{ fontSize: 14.5 }}>Calibrate for accuracy {ctx.project.calibrated && <span className="rs-badge rs-badge--ok" style={{ marginLeft: 4 }}>done</span>}</div><div className="rs-xs" style={{ marginTop: 2 }}>Enter one known size to sharpen estimates</div></div>
          <Icon name="chevR" size={18} color="var(--ink-3)" />
        </button>
      </div>
    </ScreenShell>
  );
}

function Sc_RdCalibrate({ ctx }) {
  const objs = [['Door width', '36 in'], ['A4 paper', '11.7 in'], ['Credit card', '3.4 in'], ['Bed (Queen)', '60 in'], ['Manual entry', '—']];
  const [sel, setSel] = useRd(0);
  const [val, setVal] = useRd('36');
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<RdHeader ctx={ctx} step={2} title="Calibrate" />}
      footer={<BottomBar ctx={ctx}><button className="rs-btn rs-btn--primary" style={{ background: 'var(--warm)', boxShadow: 'none' }} onClick={() => { ctx.set({ calibrated: true }); ctx.back(); }}><Icon name="refresh" size={18} /> Recalculate estimates</button></BottomBar>}>
      <div style={{ padding: '14px 16px 24px' }}>
        <h1 className="rs-h1">Calibrate with a known size</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Tell us one real measurement and AI re-scales the whole room around it.</p>
        <div className="rs-eyebrow" style={{ margin: '20px 2px 11px' }}>Pick a reference</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
          {objs.map(([o, d], i) => (
            <button key={o} className="rs-card" style={{ padding: '13px 15px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer', borderColor: sel === i ? 'var(--teal)' : 'var(--border)' }} onClick={() => setSel(i)}>
              <div style={{ width: 22, height: 22, borderRadius: '50%', border: sel === i ? 'none' : '2px solid var(--border-2)', background: sel === i ? 'var(--teal)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{sel === i && <Icon name="check" size={13} color="#fff" sw={3} />}</div>
              <span className="rs-h3" style={{ fontSize: 14.5, flex: 1 }}>{o}</span>
              <span className="rs-sm" style={{ fontWeight: 600 }}>{d}</span>
            </button>
          ))}
        </div>
        <div className="rs-eyebrow" style={{ margin: '20px 2px 9px' }}>Measured value</div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <input value={val} onChange={e => setVal(e.target.value)} style={{ flex: 1, padding: '14px 16px', borderRadius: 'var(--r)', border: '1px solid var(--border-2)', background: 'var(--surface-2)', fontSize: 16, fontFamily: 'var(--font-sans)', color: 'var(--ink)', outline: 'none' }} />
          <span className="rs-h3" style={{ fontSize: 15 }}>inches</span>
        </div>
      </div>
    </ScreenShell>
  );
}

function Sc_RdPrefs({ ctx }) {
  const { project } = ctx;
  const budgets = ['Under $250', '$250–$500', '$500–$1,000', '$1,000–$2,500', 'Custom'];
  const styles = ['Modern', 'Minimal', 'Cozy', 'Scandinavian', 'Luxury', 'Industrial', 'Boho', 'Gaming', 'WFH'];
  const colors = ['Neutral', 'Warm', 'Dark', 'Light', 'Earth tones'];
  const stores = ['Amazon', 'IKEA', 'Walmart', 'Wayfair', 'Target', 'Home Depot'];
  const items = ['Sofa', 'Desk', 'Bed', 'Storage', 'Bookshelf', 'TV unit', 'Rug', 'Lighting', 'Plants', 'Wall art'];
  const [gen, setGen] = useRd(false);
  const tog = (key, v) => ctx.set(p => ({ [key]: p[key].includes(v) ? p[key].filter(x => x !== v) : [...p[key], v] }));
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<RdHeader ctx={ctx} step={3} title="Style" />}
      footer={<BottomBar ctx={ctx}><button className="rs-btn rs-btn--primary" style={{ background: 'var(--warm)', boxShadow: 'none' }} disabled={gen} onClick={() => { setGen(true); setTimeout(() => ctx.go('rd_concepts'), 1400); }}>{gen ? <React.Fragment><span className="rs-spin" /> Designing…</React.Fragment> : <React.Fragment><Icon name="sparkleSm" size={19} /> Generate concepts</React.Fragment>}</button></BottomBar>}>
      <div style={{ padding: '14px 16px 24px' }}>
        <h1 className="rs-h1">Your taste & budget</h1>
        <div className="rs-eyebrow" style={{ margin: '18px 2px 11px' }}>Budget</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>{budgets.map(b => <Chip key={b} label={b} on={project.budget === b} onClick={() => ctx.set({ budget: b })} />)}</div>
        <div className="rs-eyebrow" style={{ margin: '22px 2px 11px' }}>Style</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>{styles.map(s => <Chip key={s} label={s} on={project.rdStyle === s} onClick={() => ctx.set({ rdStyle: s })} />)}</div>
        <div className="rs-eyebrow" style={{ margin: '22px 2px 11px' }}>Colour mood</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>{colors.map(c => <Chip key={c} label={c} on={project.color === c} onClick={() => ctx.set({ color: c })} />)}</div>
        <div className="rs-eyebrow" style={{ margin: '22px 2px 11px' }}>Shop from</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>{stores.map(s => <Chip key={s} label={s} on={project.stores.includes(s)} onClick={() => tog('stores', s)} />)}</div>
        <div className="rs-eyebrow" style={{ margin: '22px 2px 11px' }}>Must-have pieces</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>{items.map(s => <Chip key={s} label={s} on={project.mustHave.includes(s)} onClick={() => tog('mustHave', s)} sm />)}</div>
      </div>
    </ScreenShell>
  );
}

function Sc_RdConcepts({ ctx }) {
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<RdHeader ctx={ctx} step={4} title="Concepts" />}>
      <div style={{ padding: '14px 16px 24px' }}>
        <h1 className="rs-h1">{REDESIGN_CONCEPTS.length} redesign concepts</h1>
        <p className="rs-sm" style={{ marginTop: 4 }}>Each fits your {ctx.project.measures.width}×{ctx.project.measures.length} ft room and {ctx.project.budget} budget.</p>
        <div className="rs-note rs-note--warn" style={{ marginTop: 12 }}><Icon name="info" size={16} style={{ flexShrink: 0, marginTop: 1 }} /><span>Product sizes are matched to <b>estimated</b> measurements. Confirm fit before buying.</span></div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginTop: 16 }}>
          {REDESIGN_CONCEPTS.map((c, i) => (
            <div key={c.id} className="rs-card rs-rise" style={{ overflow: 'hidden', cursor: 'pointer', animationDelay: i * .05 + 's' }} onClick={() => { ctx.set({ rdSelected: c.id }); ctx.go('rd_detail'); }}>
              <div style={{ position: 'relative' }}>
                <RoomScene items={ROOM_LAYOUTS[c.room]} palette={ctx.theme === 'dark' ? 'dark' : c.palette} height={160} />
                <span className="rs-badge" style={{ position: 'absolute', top: 11, left: 11, background: 'rgba(0,0,0,.5)', color: '#fff', backdropFilter: 'blur(4px)' }}>{c.style}</span>
                <span className="rs-badge rs-badge--ok" style={{ position: 'absolute', top: 11, right: 11 }}><Icon name="check" size={11} sw={3} /> {Math.round(c.fit * 100)}% fit</span>
              </div>
              <div style={{ padding: '13px 15px 15px' }}>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                  <div className="rs-h2" style={{ fontSize: 18 }}>{c.title}</div>
                  <div className="rs-h3 rs-num" style={{ color: 'var(--warm-ink)' }}>${c.cost}</div>
                </div>
                <p className="rs-sm" style={{ marginTop: 5 }}>{c.note}</p>
                <div style={{ display: 'flex', gap: 6, marginTop: 11 }}>
                  <span className="rs-badge rs-badge--warm"><Icon name="cart" size={12} /> {c.items} new items</span>
                  <span className="rs-badge rs-badge--neutral"><Icon name="ruler" size={12} /> Sized to fit</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </ScreenShell>
  );
}

function Sc_RdDetail({ ctx }) {
  const c = REDESIGN_CONCEPTS.find(x => x.id === ctx.project.rdSelected) || REDESIGN_CONCEPTS[0];
  const [tab, setTab] = useRd('render');
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)"
      header={<div style={{ paddingTop: ctx.insets.top }}><div className="rs-topbar" style={{ paddingBottom: 6 }}><div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div><div style={{ flex: 1 }}><div className="rs-h3" style={{ fontSize: 15.5 }}>{c.title}</div></div><div className="rs-iconbtn"><Icon name="heart" size={18} /></div></div></div>}
      footer={<BottomBar ctx={ctx}><div style={{ display: 'flex', gap: 10 }}><button className="rs-btn rs-btn--ghost" style={{ flex: 1 }} onClick={() => ctx.go('rd_products')}><Icon name="cart" size={18} /> Products</button><button className="rs-btn rs-btn--primary" style={{ flex: 1.4, background: 'var(--warm)', boxShadow: 'none' }} onClick={() => ctx.go('rd_final')}><Icon name="check" size={18} sw={2.6} /> Save plan</button></div></BottomBar>}>
      <div style={{ padding: '4px 16px 22px' }}>
        <div className="rs-card" style={{ overflow: 'hidden', position: 'relative' }}>
          {tab === 'render' ? <RoomScene items={ROOM_LAYOUTS[c.room]} palette={ctx.theme === 'dark' ? 'dark' : c.palette} height={210} /> : <FloorPlan items={FLOOR_LAYOUTS[c.floor]} width={330} height={210} theme={ctx.theme} />}
          <div className="rs-seg" style={{ position: 'absolute', top: 10, left: 10, background: 'rgba(0,0,0,.4)', backdropFilter: 'blur(6px)' }}>
            <button className={tab === 'render' ? 'on' : ''} style={{ color: tab === 'render' ? undefined : '#fff' }} onClick={() => setTab('render')}>Render</button>
            <button className={tab === 'plan' ? 'on' : ''} style={{ color: tab === 'plan' ? undefined : '#fff' }} onClick={() => setTab('plan')}>Top-down</button>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: 14 }}>
          <h1 className="rs-h1" style={{ fontSize: 22 }}>{c.title}</h1>
          <div className="rs-h2 rs-num" style={{ color: 'var(--warm-ink)' }}>${c.cost}</div>
        </div>
        <div style={{ display: 'flex', gap: 6, marginTop: 10 }}>
          <span className="rs-badge rs-badge--ok"><Icon name="check" size={11} sw={3} /> {Math.round(c.fit * 100)}% fits your room</span>
          <span className="rs-badge rs-badge--warm">{c.style}</span>
        </div>
        <p className="rs-body" style={{ marginTop: 14 }}>{c.note}</p>
        <div className="rs-eyebrow" style={{ margin: '20px 2px 9px' }}>Recommended products</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
          {PRODUCTS.slice(0, 3).map((p, i) => <ProductRow key={i} p={p} ctx={ctx} />)}
        </div>
        <button className="rs-btn rs-btn--ghost" style={{ marginTop: 12 }} onClick={() => ctx.go('rd_products')}>See all products & swap <Icon name="chevR" size={16} /></button>
      </div>
    </ScreenShell>
  );
}

function ProductRow({ p, ctx, onSwap }) {
  const fitColor = p.fit === 'Fits' ? 'rs-badge--ok' : 'rs-badge--warn';
  return (
    <div className="rs-card" style={{ display: 'flex', gap: 12, padding: 11, alignItems: 'center' }}>
      <div style={{ width: 54, height: 54, borderRadius: 12, background: 'var(--surface-3)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, color: 'var(--ink-3)' }}><Icon name="cart" size={22} /></div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="rs-h3" style={{ fontSize: 14.5 }}>{p.name}</div>
        <div className="rs-xs" style={{ marginTop: 2 }}>{p.store} · {p.dim}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 6 }}>
          <span className="rs-num rs-h3" style={{ fontSize: 14, color: 'var(--warm-ink)' }}>${p.price}</span>
          <span className={`rs-badge ${fitColor}`}>{p.fit === 'Fits' ? <Icon name="check" size={11} sw={3} /> : <Icon name="alert" size={11} />} {p.fit}</span>
        </div>
      </div>
      {onSwap && <button className="rs-iconbtn" style={{ width: 36, height: 36 }} onClick={onSwap}><Icon name="swap" size={17} color="var(--ink-2)" /></button>}
    </div>
  );
}

function Sc_RdProducts({ ctx }) {
  const total = PRODUCTS.reduce((s, p) => s + p.price, 0);
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)"
      header={<div style={{ paddingTop: ctx.insets.top }}><div className="rs-topbar" style={{ paddingBottom: 8 }}><div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div><div style={{ flex: 1 }}><div className="rs-h3" style={{ fontSize: 15.5 }}>Products</div></div><div className="rs-iconbtn"><Icon name="filter" size={18} /></div></div></div>}
      footer={<BottomBar ctx={ctx}><div style={{ display: 'flex', alignItems: 'center', gap: 12 }}><div style={{ flex: 1 }}><div className="rs-xs">Estimated total</div><div className="rs-h2 rs-num" style={{ color: 'var(--warm-ink)' }}>${total}</div></div><button className="rs-btn rs-btn--primary" style={{ flex: 1.6, background: 'var(--warm)', boxShadow: 'none' }} onClick={() => ctx.go('rd_final')}>Save shopping list</button></div></BottomBar>}>
      <div style={{ padding: '8px 16px 22px' }}>
        <div className="rs-scroll-x" style={{ padding: '0 0 6px' }}>{['All', 'IKEA', 'Target', 'Amazon', 'Wayfair'].map((s, i) => <Chip key={s} label={s} on={i === 0} sm />)}</div>
        <div className="rs-note rs-note--warn" style={{ margin: '10px 0 14px' }}><Icon name="info" size={16} style={{ flexShrink: 0, marginTop: 1 }} /><span>Items without dimensions are marked <b>Unknown</b> — fit can't be guaranteed.</span></div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {PRODUCTS.map((p, i) => <ProductRow key={i} p={p} ctx={ctx} onSwap={() => {}} />)}
        </div>
      </div>
    </ScreenShell>
  );
}

function Sc_RdFinal({ ctx }) {
  const c = REDESIGN_CONCEPTS.find(x => x.id === ctx.project.rdSelected) || REDESIGN_CONCEPTS[0];
  const total = PRODUCTS.reduce((s, p) => s + p.price, 0);
  const [done, setDone] = useRd([]);
  const steps = ['Clear the room and measure the wall', 'Place the sofa on the long wall', 'Set the coffee table centred on the rug', 'Position the floor lamp by the window', 'Hang wall art at eye level'];
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<RdHeader ctx={ctx} step={5} title="Final plan" />}
      footer={<BottomBar ctx={ctx}><div style={{ display: 'flex', gap: 9 }}><button className="rs-btn rs-btn--ghost" style={{ flex: 1 }}><Icon name="share" size={18} /></button><button className="rs-btn rs-btn--ghost" style={{ flex: 1 }}><Icon name="download" size={18} /></button><button className="rs-btn rs-btn--primary" style={{ flex: 2.4, background: 'var(--warm)', boxShadow: 'none' }} onClick={() => ctx.go('home', { reset: true })}><Icon name="check" size={18} sw={2.6} /> Done</button></div></BottomBar>}>
      <div style={{ padding: '12px 16px 22px' }}>
        <span className="rs-badge rs-badge--ok"><Icon name="check" size={12} sw={3} /> Redesign saved</span>
        <h1 className="rs-h1" style={{ marginTop: 10 }}>{c.title}</h1>
        <div className="rs-card" style={{ overflow: 'hidden', marginTop: 14 }}><RoomScene items={ROOM_LAYOUTS[c.room]} palette={ctx.theme === 'dark' ? 'dark' : c.palette} height={196} /></div>
        <div className="rs-card rs-card--pad" style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ flex: 1 }}><div className="rs-xs">Shopping list · {PRODUCTS.length} items</div><div className="rs-h2 rs-num" style={{ color: 'var(--warm-ink)' }}>${total}</div></div>
          <button className="rs-btn rs-btn--soft rs-btn--sm" onClick={() => ctx.go('rd_products')}>View list</button>
        </div>
        <div className="rs-eyebrow" style={{ margin: '22px 2px 10px' }}>Setup checklist</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
          {steps.map((s, i) => {
            const ok = done.includes(i);
            return (
              <div key={i} className="rs-card" style={{ padding: '13px 14px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer', opacity: ok ? .62 : 1 }} onClick={() => setDone(d => d.includes(i) ? d.filter(x => x !== i) : [...d, i])}>
                <div style={{ width: 26, height: 26, borderRadius: 8, flexShrink: 0, border: ok ? 'none' : '2px solid var(--border-2)', background: ok ? 'var(--warm)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{ok && <Icon name="check" size={15} color="#fff" sw={3} />}</div>
                <span className="rs-sm" style={{ color: 'var(--ink)', textDecoration: ok ? 'line-through' : 'none', flex: 1 }}><b style={{ color: 'var(--ink-3)' }}>{i + 1}.</b> {s}</span>
              </div>
            );
          })}
        </div>
        <div className="rs-note rs-note--warn" style={{ marginTop: 16 }}><Icon name="ruler" size={17} style={{ flexShrink: 0, marginTop: 1 }} /><span>Based on <b>estimated</b> measurements ({c.fit * 100 | 0}% fit confidence). Measure before ordering large pieces.</span></div>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, { Sc_RdMode, Sc_RdCapture, Sc_RdMeasure, Sc_RdCalibrate, Sc_RdPrefs, Sc_RdConcepts, Sc_RdDetail, Sc_RdProducts, Sc_RdFinal });
