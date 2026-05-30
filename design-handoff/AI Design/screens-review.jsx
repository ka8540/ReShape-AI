/* screens-review.jsx — detected items review + reshuffle preferences */
const { useState: useStateR } = React;

const ITEM_ICON = { bed:'bed', sofa:'sofa', desk:'desk', tv:'video', shelf:'layers', rug:'grid', lamp:'bulb', plant:'plant', table:'desk', chair:'sofa', window:'scan', door:'pin', wardrobe:'layers' };
const ADDABLE = ['Sofa','Chair','Coffee table','Bed','Desk','TV','TV stand','Bookshelf','Wardrobe','Lamp','Rug','Plant','Dresser','Mirror'];

function Sc_Review({ ctx }) {
  const items = ctx.project.items;
  const furniture = items.filter(i => !i.structural);
  const structure = items.filter(i => i.structural);
  const [renaming, setRenaming] = useStateR(null);
  const [nameVal, setNameVal] = useStateR('');

  const setItem = (id, patch) => ctx.set(p => ({ items: p.items.map(i => i.id === id ? { ...i, ...patch } : i) }));
  const delItem = (id) => ctx.set(p => ({ items: p.items.filter(i => i.id !== id) }));
  const addItem = (name) => { ctx.set(p => ({ items: [...p.items, { id: 'x' + Date.now(), name, type: name.toLowerCase().split(' ')[0], conf: 1, movable: true, added: true }] })); ctx.closeSheet(); };

  const fixedCount = furniture.filter(i => i.fixed).length;

  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<FlowHeader ctx={ctx} step={3} title="Review items" />}
      footer={<BottomBar ctx={ctx}>
        <button className="rs-btn rs-btn--primary" onClick={() => ctx.go('prefs')}>Looks right — continue <Icon name="arrowR" size={18} /></button>
      </BottomBar>}>
      <div style={{ padding: '14px 16px 20px' }}>
        <h1 className="rs-h1">Review detected items</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Fix anything we got wrong, then mark what should stay put. Layouts always respect your <b style={{ color: 'var(--ink)' }}>fixed</b> items.</p>

        <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
          <div className="rs-card rs-card--pad" style={{ flex: 1, padding: '11px 13px', boxShadow: 'none', background: 'var(--surface-2)' }}>
            <div className="rs-h2" style={{ fontSize: 19, color: 'var(--teal)' }}>{furniture.length}</div>
            <div className="rs-xs">items found</div>
          </div>
          <div className="rs-card rs-card--pad" style={{ flex: 1, padding: '11px 13px', boxShadow: 'none', background: 'var(--surface-2)' }}>
            <div className="rs-h2" style={{ fontSize: 19, color: 'var(--warm-ink)' }}>{fixedCount}</div>
            <div className="rs-xs">marked fixed</div>
          </div>
        </div>

        <div className="rs-eyebrow" style={{ margin: '22px 2px 10px' }}>Furniture & objects</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {furniture.map(it => (
            <div key={it.id} className="rs-card rs-card--pad" style={{ padding: '12px 13px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 42, height: 42, borderRadius: 12, background: it.fixed ? 'var(--warm-tint)' : 'var(--teal-tint)', color: it.fixed ? 'var(--warm-ink)' : 'var(--teal-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name={ITEM_ICON[it.type] || 'grid'} size={20} /></div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                    <span className="rs-h3" style={{ fontSize: 15.5 }}>{it.name}</span>
                    {it.added ? <span className="rs-badge rs-badge--teal" style={{ fontSize: 9, padding: '2px 6px' }}>ADDED</span> : null}
                  </div>
                  <div style={{ marginTop: 4 }}>{it.added ? <span className="rs-xs">Added by you</span> : <Confidence value={it.conf} theme={ctx.theme} />}</div>
                </div>
                <div style={{ display: 'flex', gap: 4 }}>
                  <div className="rs-iconbtn" style={{ width: 32, height: 32, boxShadow: 'none', background: 'var(--surface-2)', border: 'none' }} onClick={() => { setRenaming(it.id); setNameVal(it.name); }}><Icon name="pencil" size={15} color="var(--ink-2)" /></div>
                  <div className="rs-iconbtn" style={{ width: 32, height: 32, boxShadow: 'none', background: 'var(--surface-2)', border: 'none' }} onClick={() => delItem(it.id)}><Icon name="trash" size={15} color="var(--ink-2)" /></div>
                </div>
              </div>
              <div className="rs-seg" style={{ marginTop: 11, width: '100%', display: 'flex' }}>
                <button className={!it.fixed ? 'on' : ''} style={{ flex: 1, justifyContent: 'center' }} onClick={() => setItem(it.id, { fixed: false })}><Icon name="move" size={14} /> Movable</button>
                <button className={`seg-fixed ${it.fixed ? 'on' : ''}`} style={{ flex: 1, justifyContent: 'center', color: it.fixed ? 'var(--warm-ink)' : undefined }} onClick={() => setItem(it.id, { fixed: true })}><Icon name="lock" size={14} /> Fixed</button>
              </div>
            </div>
          ))}
        </div>

        <button className="rs-card" style={{ marginTop: 12, borderStyle: 'dashed', padding: 15, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 9, color: 'var(--teal)', boxShadow: 'none', width: '100%', cursor: 'pointer', background: 'transparent' }}
          onClick={() => ctx.openSheet(
            <Sheet open onClose={ctx.closeSheet} title="Add a missing item" pb={ctx.insets.bottom + 18}>
              <p className="rs-sm" style={{ marginBottom: 14 }}>Pick anything the scan missed.</p>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                {ADDABLE.map(a => <button key={a} className="rs-chip" onClick={() => addItem(a)}><Icon name="plus" size={14} /> {a}</button>)}
              </div>
            </Sheet>
          )}>
          <Icon name="plus" size={18} /> Add missing item
        </button>

        <div className="rs-eyebrow" style={{ margin: '24px 2px 10px' }}>Room structure</div>
        <div className="rs-card" style={{ padding: '4px 14px' }}>
          {structure.map((it, i) => (
            <React.Fragment key={it.id}>
              <div className="rs-row" style={{ padding: '12px 2px' }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--surface-3)', color: 'var(--ink-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name={ITEM_ICON[it.type]} size={18} /></div>
                <div style={{ flex: 1 }} className="rs-h3"><span style={{ fontSize: 14.5 }}>{it.name}</span></div>
                <span className="rs-badge rs-badge--neutral"><Icon name="lock" size={12} /> Structure</span>
              </div>
              {i < structure.length - 1 && <div className="rs-divider" style={{ margin: 0 }} />}
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* rename sheet */}
      <Sheet open={!!renaming} onClose={() => setRenaming(null)} title="Rename item" pb={ctx.insets.bottom + 18}>
        <input autoFocus value={nameVal} onChange={e => setNameVal(e.target.value)}
          style={{ width: '100%', boxSizing: 'border-box', padding: '14px 16px', borderRadius: 'var(--r)', border: '1px solid var(--border-2)', background: 'var(--surface-2)', fontSize: 16, fontFamily: 'var(--font-sans)', color: 'var(--ink)', outline: 'none' }} />
        <button className="rs-btn rs-btn--primary" style={{ marginTop: 14 }} onClick={() => { setItem(renaming, { name: nameVal || 'Item' }); setRenaming(null); }}>Save name</button>
      </Sheet>
    </ScreenShell>
  );
}

function Sc_Prefs({ ctx }) {
  const { project } = ctx;
  const toggleGoal = (id) => ctx.set(p => ({ goals: p.goals.includes(id) ? p.goals.filter(g => g !== id) : [...p.goals, id] }));
  const fixed = project.items.filter(i => i.fixed && !i.structural);
  const [gen, setGen] = useStateR(false);

  const generate = () => { setGen(true); setTimeout(() => ctx.go('results'), 1400); };

  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<FlowHeader ctx={ctx} step={4} title="Preferences" />}
      footer={<BottomBar ctx={ctx}>
        <button className="rs-btn rs-btn--primary" disabled={gen || project.goals.length === 0} onClick={generate}>
          {gen ? <React.Fragment><span className="rs-spin" /> Generating layouts…</React.Fragment> : <React.Fragment><Icon name="sparkleSm" size={19} /> Generate {project.goals.length ? '' : ''}layouts</React.Fragment>}
        </button>
      </BottomBar>}>
      <div style={{ padding: '14px 16px 20px' }}>
        <h1 className="rs-h1">What should improve?</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Pick one or more goals. AI balances them against your fixed items.</p>

        <div className="rs-eyebrow" style={{ margin: '20px 2px 11px' }}>Goals · pick any</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>
          {GOALS.map(g => <Chip key={g.id} label={g.label} icon={g.icon} on={project.goals.includes(g.id)} onClick={() => toggleGoal(g.id)} />)}
        </div>

        <div className="rs-eyebrow" style={{ margin: '26px 2px 11px' }}>Style feeling · pick one</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 9 }}>
          {STYLES.map(s => <Chip key={s} label={s} on={project.style === s} onClick={() => ctx.set({ style: s })} />)}
        </div>

        <div className="rs-eyebrow" style={{ margin: '26px 2px 11px' }}>How much moving are you up for?</div>
        <div className="rs-seg" style={{ width: '100%', display: 'flex' }}>
          {[['Easy', 'Light only'], ['Medium', 'Some lifting'], ['Heavy', 'Anything goes']].map(([lv, d]) => (
            <button key={lv} className={project.difficulty === lv ? 'on' : ''} style={{ flex: 1, flexDirection: 'column', gap: 2, padding: '9px 6px', justifyContent: 'center' }} onClick={() => ctx.set({ difficulty: lv })}>
              <span style={{ fontSize: 13 }}>{lv}</span><span style={{ fontSize: 10, opacity: .7, fontWeight: 500 }}>{d}</span>
            </button>
          ))}
        </div>

        <div className="rs-eyebrow" style={{ margin: '26px 2px 11px' }}>Staying put ({fixed.length})</div>
        <div className="rs-card rs-card--pad" style={{ background: 'var(--surface-2)', boxShadow: 'none' }}>
          {fixed.length ? (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 7 }}>
              {fixed.map(i => <span key={i.id} className="rs-badge rs-badge--warm"><Icon name="lock" size={11} /> {i.name}</span>)}
            </div>
          ) : <span className="rs-sm">Nothing locked — AI can move everything.</span>}
          <button className="rs-btn rs-btn--quiet rs-btn--sm" style={{ marginTop: 10, justifyContent: 'flex-start', padding: '4px 0', color: 'var(--teal)' }} onClick={ctx.back}><Icon name="pencil" size={14} /> Edit fixed items</button>
        </div>

        <div className="rs-note rs-note--teal" style={{ marginTop: 18 }}>
          <Icon name="info" size={17} style={{ flexShrink: 0, marginTop: 1 }} />
          <span>These layouts are <b>suggestions</b> based on your video and choices — not exact engineering plans.</span>
        </div>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, { Sc_Review, Sc_Prefs });
