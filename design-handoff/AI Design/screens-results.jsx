/* screens-results.jsx — layout results (grid/swipe/compare), detail, final plan, AI modify */
const { useState: useS, useRef: useR, useEffect: useE } = React;

function ResultMeta({ r }) {
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
      <span className="rs-badge rs-badge--teal"><Icon name="sparkleSm" size={12} /> {r.goal}% goal match</span>
      <Difficulty level={r.diff} />
      <span className="rs-badge rs-badge--neutral"><Icon name="move" size={12} /> {r.moved} moved</span>
    </div>
  );
}

function SaveHeart({ id, ctx, size = 20 }) {
  const saved = (ctx.project.savedIds || []).includes(id);
  return (
    <div className="rs-iconbtn" style={{ width: 38, height: 38 }} onClick={(e) => { e.stopPropagation(); ctx.set(p => ({ savedIds: saved ? (p.savedIds || []).filter(x => x !== id) : [...(p.savedIds || []), id] })); }}>
      <Icon name="heart" size={size} color={saved ? 'var(--danger)' : 'var(--ink-3)'} fill={saved ? 'solid' : 'none'} />
    </div>
  );
}

function Sc_Results({ ctx }) {
  const view = ctx.project.resultsView;
  const setView = (v) => ctx.set({ resultsView: v });
  const open = (r) => { ctx.set({ selected: r.id }); ctx.go('detail'); };
  const [regen, setRegen] = useS(null);
  const doRegen = (id) => { setRegen(id); setTimeout(() => setRegen(null), 1100); };

  const header = (
    <div style={{ paddingTop: ctx.insets.top }}>
      <div className="rs-topbar" style={{ paddingBottom: 8 }}>
        <div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div>
        <div style={{ flex: 1 }}><div className="rs-xs" style={{ fontWeight: 600 }}>Results · Step 6 of {RESHUFFLE_STEPS.length}</div></div>
        <div className="rs-iconbtn" onClick={() => doRegen('all')}><Icon name="refresh" size={18} /></div>
      </div>
      <Stepper steps={RESHUFFLE_STEPS} current={5} />
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', padding: '12px 16px 4px' }}>
        <div>
          <h1 className="rs-h1" style={{ fontSize: 24 }}>{RESULTS.length} layouts for you</h1>
          <p className="rs-sm" style={{ marginTop: 3 }}>Tuned for {ctx.project.goals.length} goal{ctx.project.goals.length !== 1 ? 's' : ''} · {ctx.project.style}</p>
        </div>
      </div>
      {/* view switch */}
      <div style={{ display: 'flex', gap: 6, padding: '10px 16px 12px' }}>
        <div className="rs-seg" style={{ flex: 1, display: 'flex' }}>
          {[['grid', 'Grid', 'grid'], ['swipe', 'Swipe', 'layers'], ['compare', 'Compare', 'swap']].map(([v, l, ic]) => (
            <button key={v} className={view === v ? 'on' : ''} style={{ flex: 1, justifyContent: 'center' }} onClick={() => setView(v)}><Icon name={ic} size={14} /> {l}</button>
          ))}
        </div>
      </div>
    </div>
  );

  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={header} noScroll={view === 'swipe'}>
      {view === 'grid' && <ResultsGrid ctx={ctx} open={open} regen={regen} doRegen={doRegen} />}
      {view === 'swipe' && <ResultsSwipe ctx={ctx} open={open} />}
      {view === 'compare' && <ResultsCompare ctx={ctx} open={open} />}
    </ScreenShell>
  );
}

function ResultsGrid({ ctx, open, regen, doRegen }) {
  return (
    <div style={{ padding: '4px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
      {RESULTS.map((r, i) => (
        <div key={r.id} className="rs-card rs-rise" style={{ overflow: 'hidden', animationDelay: (i * .05) + 's', cursor: 'pointer', position: 'relative' }} onClick={() => open(r)}>
          {(regen === r.id || regen === 'all') && (
            <div style={{ position: 'absolute', inset: 0, zIndex: 5, background: 'color-mix(in srgb, var(--surface) 78%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 8 }}>
              <div className="rs-spin" style={{ width: 26, height: 26, borderColor: 'rgba(14,158,140,.25)', borderTopColor: 'var(--teal)' }} /><span className="rs-sm" style={{ fontWeight: 600 }}>Regenerating…</span>
            </div>
          )}
          <div style={{ position: 'relative' }}>
            <RoomScene items={ROOM_LAYOUTS[r.room]} palette={ctx.theme === 'dark' ? 'dark' : r.palette} height={158} />
            {/* top-down inset */}
            <div style={{ position: 'absolute', bottom: 10, right: 10, width: 78, height: 64, borderRadius: 10, overflow: 'hidden', border: '2px solid var(--surface)', boxShadow: 'var(--sh)' }}>
              <FloorPlan items={FLOOR_LAYOUTS[r.floor]} width={120} height={98} theme={ctx.theme} showDoor={false} showWindow={false} />
            </div>
            <span className="rs-badge" style={{ position: 'absolute', top: 11, left: 11, background: 'rgba(0,0,0,.5)', color: '#fff', backdropFilter: 'blur(4px)' }}>Option {i + 1}</span>
            <div style={{ position: 'absolute', top: 8, right: 8 }}><SaveHeart id={r.id} ctx={ctx} /></div>
          </div>
          <div style={{ padding: '13px 15px 15px' }}>
            <div className="rs-h2" style={{ fontSize: 18 }}>{r.title}</div>
            <p className="rs-sm" style={{ marginTop: 5 }}>{r.reason}</p>
            <div style={{ marginTop: 11 }}><ResultMeta r={r} /></div>
            <div style={{ display: 'flex', gap: 8, marginTop: 13 }}>
              <button className="rs-btn rs-btn--soft rs-btn--sm" style={{ flex: 1 }} onClick={(e) => { e.stopPropagation(); open(r); }}>View plan</button>
              <button className="rs-btn rs-btn--ghost rs-btn--sm" onClick={(e) => { e.stopPropagation(); doRegen(r.id); }}><Icon name="refresh" size={15} /></button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function ResultsSwipe({ ctx, open }) {
  const [idx, setIdx] = useS(0);
  const scroller = useR(null);
  const onScroll = () => { if (scroller.current) setIdx(Math.round(scroller.current.scrollLeft / scroller.current.clientWidth)); };
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      <div ref={scroller} onScroll={onScroll} style={{ flex: 1, display: 'flex', overflowX: 'auto', scrollSnapType: 'x mandatory', scrollbarWidth: 'none' }}>
        {RESULTS.map((r, i) => (
          <div key={r.id} style={{ minWidth: '100%', scrollSnapAlign: 'center', padding: '4px 16px', boxSizing: 'border-box', overflowY: 'auto' }}>
            <div className="rs-card" style={{ overflow: 'hidden' }}>
              <div style={{ position: 'relative' }}>
                <RoomScene items={ROOM_LAYOUTS[r.room]} palette={ctx.theme === 'dark' ? 'dark' : r.palette} height={216} />
                <span className="rs-badge" style={{ position: 'absolute', top: 11, left: 11, background: 'rgba(0,0,0,.5)', color: '#fff', backdropFilter: 'blur(4px)' }}>Option {i + 1} of {RESULTS.length}</span>
                <div style={{ position: 'absolute', top: 8, right: 8 }}><SaveHeart id={r.id} ctx={ctx} /></div>
              </div>
              <div style={{ padding: '15px 16px 17px' }}>
                <div className="rs-h2" style={{ fontSize: 20 }}>{r.title}</div>
                <p className="rs-sm" style={{ marginTop: 6 }}>{r.reason}</p>
                <div style={{ marginTop: 12 }}><ResultMeta r={r} /></div>
                <div className="rs-card" style={{ marginTop: 14, overflow: 'hidden', boxShadow: 'none', background: 'var(--surface-2)' }}>
                  <FloorPlan items={FLOOR_LAYOUTS[r.floor]} width={320} height={190} theme={ctx.theme} />
                  <div style={{ display: 'flex', gap: 14, padding: '9px 13px 11px', flexWrap: 'wrap' }}>
                    {[['var(--teal)', 'Moved'], ['var(--warm)', 'Fixed'], ['var(--ink-3)', 'Unchanged']].map(([c, l]) => (
                      <span key={l} style={{ display: 'flex', alignItems: 'center', gap: 6 }} className="rs-xs"><span style={{ width: 12, height: 8, borderRadius: 2, border: `2px solid ${c}` }} />{l}</span>
                    ))}
                  </div>
                </div>
                <button className="rs-btn rs-btn--primary" style={{ marginTop: 15 }} onClick={() => open(r)}>Open full plan <Icon name="arrowR" size={18} /></button>
              </div>
            </div>
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 7, padding: '10px 0 14px', flexShrink: 0 }}>
        {RESULTS.map((_, i) => <div key={i} style={{ width: i === idx ? 22 : 7, height: 7, borderRadius: 999, background: i === idx ? 'var(--teal)' : 'var(--border-2)', transition: 'all .2s' }} />)}
      </div>
    </div>
  );
}

function ResultsCompare({ ctx, open }) {
  const sel = ctx.project.compareSel;
  const setSel = (i, id) => ctx.set(p => { const s = [...p.compareSel]; s[i] = id; return { compareSel: s }; });
  const a = RESULTS.find(r => r.id === sel[0]), b = RESULTS.find(r => r.id === sel[1]);
  const Picker = ({ slot }) => (
    <div className="rs-scroll-x" style={{ padding: '0 0 4px' }}>
      {RESULTS.map(r => <Chip key={r.id} label={r.title} on={sel[slot] === r.id} onClick={() => setSel(slot, r.id)} sm />)}
    </div>
  );
  const col = (r) => (
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="rs-card" style={{ overflow: 'hidden' }}>
        <RoomScene items={ROOM_LAYOUTS[r.room]} palette={ctx.theme === 'dark' ? 'dark' : r.palette} height={92} width={150} />
        <div style={{ padding: '8px 9px 10px' }}>
          <div className="rs-h3" style={{ fontSize: 13.5, lineHeight: 1.15 }}>{r.title}</div>
        </div>
      </div>
    </div>
  );
  const rowMetric = (label, va, vb, hi) => (
    <div style={{ display: 'flex', alignItems: 'center', padding: '11px 0', borderBottom: '1px solid var(--border)' }}>
      <span className="rs-sm" style={{ width: 92, flexShrink: 0, color: 'var(--ink-2)', fontWeight: 600 }}>{label}</span>
      <span className="rs-sm" style={{ flex: 1, textAlign: 'center', fontWeight: 700, color: hi === 0 ? 'var(--teal)' : 'var(--ink)' }}>{va}</span>
      <span className="rs-sm" style={{ flex: 1, textAlign: 'center', fontWeight: 700, color: hi === 1 ? 'var(--teal)' : 'var(--ink)' }}>{vb}</span>
    </div>
  );
  return (
    <div style={{ padding: '4px 16px 24px' }}>
      <p className="rs-sm">Compare any two layouts side by side.</p>
      <div className="rs-eyebrow" style={{ margin: '14px 0 8px' }}>Layout A</div>
      <Picker slot={0} />
      <div className="rs-eyebrow" style={{ margin: '12px 0 8px' }}>Layout B</div>
      <Picker slot={1} />
      <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>{col(a)}{col(b)}</div>
      <div className="rs-card rs-card--pad" style={{ marginTop: 12 }}>
        {rowMetric('Goal match', a.goal + '%', b.goal + '%', a.goal >= b.goal ? 0 : 1)}
        {rowMetric('Difficulty', a.diff, b.diff, ['Easy','Medium','Heavy'].indexOf(a.diff) <= ['Easy','Medium','Heavy'].indexOf(b.diff) ? 0 : 1)}
        {rowMetric('Items moved', a.moved, b.moved, a.moved <= b.moved ? 0 : 1)}
        <div style={{ display: 'flex', gap: 10, paddingTop: 13 }}>
          <button className="rs-btn rs-btn--ghost rs-btn--sm" style={{ flex: 1 }} onClick={() => open(a)}>Open A</button>
          <button className="rs-btn rs-btn--primary rs-btn--sm" style={{ flex: 1 }} onClick={() => open(b)}>Open B</button>
        </div>
      </div>
    </div>
  );
}

/* ---------------- detail ---------------- */
const QUICK_MODS = ['Make it more spacious', 'Keep the sofa where it is', 'Move the desk near the window', 'Make it more modern', 'Use only existing furniture'];

function Sc_Detail({ ctx }) {
  const r = RESULTS.find(x => x.id === ctx.project.selected) || RESULTS[0];
  const [tab, setTab] = useS('render');
  const [modNote, setModNote] = useS(ctx.project.modNote || null);
  const [tuning, setTuning] = useS(false);
  const [modText, setModText] = useS('');
  const moved = FLOOR_LAYOUTS[r.floor].filter(i => i.moved);
  const fixed = ctx.project.items.filter(i => i.fixed && !i.structural);

  const applyMod = (txt) => {
    ctx.closeSheet(); setTuning(true);
    setTimeout(() => { setTuning(false); setModNote(txt); ctx.set({ modNote: txt }); }, 1500);
  };
  const openModify = () => ctx.openSheet(
    <Sheet open onClose={ctx.closeSheet} title="Ask AI to modify" pb={ctx.insets.bottom + 14}>
      <p className="rs-sm" style={{ marginBottom: 12 }}>Describe a change in your own words, or tap a quick action.</p>
      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        <input value={modText} onChange={e => setModText(e.target.value)} placeholder="e.g. add a reading corner…"
          style={{ flex: 1, padding: '13px 15px', borderRadius: 'var(--r)', border: '1px solid var(--border-2)', background: 'var(--surface-2)', fontSize: 15, fontFamily: 'var(--font-sans)', color: 'var(--ink)', outline: 'none' }} />
        <button className="rs-iconbtn" style={{ background: 'var(--teal)', color: '#fff', border: 'none', width: 46, height: 46 }} onClick={() => modText.trim() && applyMod(modText.trim())}><Icon name="arrowR" size={20} /></button>
      </div>
      <div className="rs-eyebrow" style={{ margin: '18px 0 10px' }}>Quick actions</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {QUICK_MODS.map(q => <button key={q} className="rs-card" style={{ textAlign: 'left', padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', boxShadow: 'none', background: 'var(--surface-2)' }} onClick={() => applyMod(q)}><Icon name="sparkleSm" size={17} color="var(--teal)" /><span className="rs-sm" style={{ color: 'var(--ink)', fontWeight: 500 }}>{q}</span></button>)}
      </div>
    </Sheet>
  );

  return (
    <ScreenShell ctx={ctx} bg="var(--bg)"
      header={<div style={{ paddingTop: ctx.insets.top }}><div className="rs-topbar" style={{ paddingBottom: 6 }}>
        <div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div>
        <div style={{ flex: 1 }}><div className="rs-h3" style={{ fontSize: 15.5 }}>{r.title}</div></div>
        <SaveHeart id={r.id} ctx={ctx} />
        <div className="rs-iconbtn"><Icon name="share" size={18} /></div>
      </div></div>}
      footer={<BottomBar ctx={ctx}>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="rs-btn rs-btn--ghost" style={{ flex: 1 }} onClick={openModify}><Icon name="sparkleSm" size={18} /> Modify</button>
          <button className="rs-btn rs-btn--primary" style={{ flex: 1.4 }} onClick={() => ctx.go('final')}><Icon name="check" size={18} sw={2.6} /> Save this plan</button>
        </div>
      </BottomBar>}>
      <div style={{ padding: '4px 16px 22px' }}>
        {/* image / topdown tabs */}
        <div className="rs-card" style={{ overflow: 'hidden', position: 'relative' }}>
          {tuning && <div style={{ position: 'absolute', inset: 0, zIndex: 5, background: 'color-mix(in srgb, var(--surface) 80%, transparent)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 9 }}><div className="rs-spin" style={{ width: 28, height: 28, borderColor: 'rgba(14,158,140,.25)', borderTopColor: 'var(--teal)' }} /><span className="rs-sm" style={{ fontWeight: 600 }}>Adjusting layout…</span></div>}
          {tab === 'render'
            ? <RoomScene items={ROOM_LAYOUTS[r.room]} palette={ctx.theme === 'dark' ? 'dark' : r.palette} height={210} />
            : <FloorPlan items={FLOOR_LAYOUTS[r.floor]} width={330} height={210} theme={ctx.theme} />}
          <div style={{ position: 'absolute', top: 10, left: 10, display: 'flex', gap: 6 }}>
            <div className="rs-seg" style={{ background: 'rgba(0,0,0,.4)', backdropFilter: 'blur(6px)' }}>
              <button className={tab === 'render' ? 'on' : ''} style={{ color: tab === 'render' ? undefined : '#fff' }} onClick={() => setTab('render')}>Render</button>
              <button className={tab === 'plan' ? 'on' : ''} style={{ color: tab === 'plan' ? undefined : '#fff' }} onClick={() => setTab('plan')}>Top-down</button>
            </div>
          </div>
        </div>

        {modNote && <div className="rs-note rs-note--teal" style={{ marginTop: 12 }}><Icon name="sparkleSm" size={16} style={{ flexShrink: 0, marginTop: 1 }} /><span><b>Adjusted:</b> “{modNote}”. Updated render and steps below.</span></div>}

        <div style={{ marginTop: 14 }}><ResultMeta r={r} /></div>
        <h1 className="rs-h1" style={{ fontSize: 22, marginTop: 14 }}>{r.title}</h1>

        <div className="rs-eyebrow" style={{ margin: '18px 2px 9px' }}>Why this works</div>
        <p className="rs-body">{r.reason}</p>

        <div className="rs-eyebrow" style={{ margin: '20px 2px 9px' }}>What changed</div>
        <div className="rs-card rs-card--pad">
          {r.changed.map((c, i) => <div key={i} style={{ display: 'flex', gap: 10, padding: '6px 0', alignItems: 'flex-start' }}><Icon name="move" size={16} color="var(--teal)" style={{ flexShrink: 0, marginTop: 2 }} /><span className="rs-sm" style={{ color: 'var(--ink)' }}>{c}</span></div>)}
        </div>

        <div className="rs-grid2" style={{ marginTop: 14, alignItems: 'start' }}>
          <div className="rs-card rs-card--pad">
            <div className="rs-h3" style={{ fontSize: 13.5, color: 'var(--ok)', display: 'flex', alignItems: 'center', gap: 6 }}><Icon name="check" size={15} sw={2.6} /> Pros</div>
            <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>{r.pros.map((p, i) => <span key={i} className="rs-sm" style={{ color: 'var(--ink)' }}>· {p}</span>)}</div>
          </div>
          <div className="rs-card rs-card--pad">
            <div className="rs-h3" style={{ fontSize: 13.5, color: 'var(--warm-ink)', display: 'flex', alignItems: 'center', gap: 6 }}><Icon name="info" size={15} /> Trade-offs</div>
            <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>{r.cons.map((p, i) => <span key={i} className="rs-sm" style={{ color: 'var(--ink)' }}>· {p}</span>)}</div>
          </div>
        </div>

        <div className="rs-eyebrow" style={{ margin: '20px 2px 9px' }}>Respected as fixed</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 7 }}>
          {fixed.map(i => <span key={i.id} className="rs-badge rs-badge--warm"><Icon name="lock" size={11} /> {i.name}</span>)}
        </div>
      </div>
    </ScreenShell>
  );
}

/* ---------------- final plan ---------------- */
function Sc_Final({ ctx }) {
  const r = RESULTS.find(x => x.id === ctx.project.selected) || RESULTS[0];
  const [ba, setBa] = useS('after');
  const [done, setDone] = useS([]);
  const toggle = (i) => setDone(d => d.includes(i) ? d.filter(x => x !== i) : [...d, i]);
  const pctDone = Math.round(done.length / r.steps.length * 100);

  return (
    <ScreenShell ctx={ctx} bg="var(--bg)"
      header={<div style={{ paddingTop: ctx.insets.top }}><div className="rs-topbar" style={{ paddingBottom: 6 }}>
        <div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div>
        <div style={{ flex: 1 }}><div className="rs-xs" style={{ fontWeight: 600 }}>Final plan · Step 7 of {RESHUFFLE_STEPS.length}</div></div>
      </div><Stepper steps={RESHUFFLE_STEPS} current={6} /></div>}
      footer={<BottomBar ctx={ctx}>
        <div style={{ display: 'flex', gap: 9 }}>
          <button className="rs-btn rs-btn--ghost" style={{ flex: 1 }}><Icon name="share" size={18} /></button>
          <button className="rs-btn rs-btn--ghost" style={{ flex: 1 }}><Icon name="download" size={18} /></button>
          <button className="rs-btn rs-btn--primary" style={{ flex: 2.4 }} onClick={() => ctx.go('home', { reset: true })}><Icon name="check" size={18} sw={2.6} /> Done</button>
        </div>
      </BottomBar>}>
      <div style={{ padding: '12px 16px 22px' }}>
        <div className="rs-rowflex" style={{ gap: 8 }}>
          <span className="rs-badge rs-badge--ok"><Icon name="check" size={12} sw={3} /> Plan saved</span>
          <span className="rs-sm">{r.title}</span>
        </div>
        <h1 className="rs-h1" style={{ marginTop: 10 }}>Your move plan</h1>

        {/* before / after */}
        <div className="rs-card" style={{ overflow: 'hidden', marginTop: 14 }}>
          {ba === 'after'
            ? <RoomScene items={ROOM_LAYOUTS[r.room]} palette={ctx.theme === 'dark' ? 'dark' : r.palette} height={196} />
            : <RoomScene items={ROOM_LAYOUTS.livingA} palette={ctx.theme === 'dark' ? 'dark' : 'warm'} height={196} />}
          <div style={{ display: 'flex', padding: 7, gap: 6, borderTop: '1px solid var(--border)' }}>
            <button className={`rs-btn rs-btn--sm ${ba === 'before' ? 'rs-btn--soft' : 'rs-btn--quiet'}`} style={{ flex: 1 }} onClick={() => setBa('before')}>Before</button>
            <button className={`rs-btn rs-btn--sm ${ba === 'after' ? 'rs-btn--soft' : 'rs-btn--quiet'}`} style={{ flex: 1 }} onClick={() => setBa('after')}>After</button>
          </div>
        </div>

        <div className="rs-card" style={{ overflow: 'hidden', marginTop: 12, background: 'var(--surface-2)', boxShadow: 'none' }}>
          <FloorPlan items={FLOOR_LAYOUTS[r.floor]} width={330} height={196} theme={ctx.theme} />
        </div>

        {/* checklist */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '22px 2px 4px' }}>
          <h2 className="rs-h2" style={{ fontSize: 18 }}>Move checklist</h2>
          <span className="rs-sm rs-num" style={{ fontWeight: 700, color: 'var(--teal)' }}>{done.length}/{r.steps.length}</span>
        </div>
        <div className="rs-progress" style={{ margin: '6px 2px 14px' }}><i style={{ width: pctDone + '%' }} /></div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
          {r.steps.map((s, i) => {
            const ok = done.includes(i);
            return (
              <div key={i} className="rs-card" style={{ padding: '13px 14px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer', opacity: ok ? .62 : 1 }} onClick={() => toggle(i)}>
                <div style={{ width: 26, height: 26, borderRadius: 8, flexShrink: 0, border: ok ? 'none' : '2px solid var(--border-2)', background: ok ? 'var(--teal)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{ok && <Icon name="check" size={15} color="#fff" sw={3} />}</div>
                <span className="rs-sm" style={{ color: 'var(--ink)', textDecoration: ok ? 'line-through' : 'none', flex: 1 }}><b style={{ color: 'var(--ink-3)' }}>{i + 1}.</b> {s}</span>
              </div>
            );
          })}
        </div>

        <div className="rs-note rs-note--warn" style={{ marginTop: 16 }}>
          <Icon name="alert" size={17} style={{ flexShrink: 0, marginTop: 1 }} />
          <span>Lift heavy items with help and check clearances for doors and outlets as you go.</span>
        </div>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, { Sc_Results, Sc_Detail, Sc_Final });
