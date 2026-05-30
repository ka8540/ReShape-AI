/* screens-home.jsx — home, saved, explore, profile (+ empty state) */

function ProjectCard({ p, ctx, onMenu }) {
  return (
    <div className="rs-card" style={{ display: 'flex', gap: 13, padding: 11, alignItems: 'center', cursor: 'pointer' }}
      onClick={() => { ctx.set({ mode: p.mode }); ctx.go(p.mode === 'redesign' ? 'rd_concepts' : 'results'); }}>
      <div style={{ width: 76, height: 64, borderRadius: 13, overflow: 'hidden', flexShrink: 0, border: '1px solid var(--border)' }}>
        <FloorPlan items={(window.FLOOR_LAYOUTS[p.floor] || []).slice(0, 6)} width={120} height={100} theme={ctx.theme} showDoor={false} showWindow={false} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="rs-h3" style={{ fontSize: 15.5 }}>{p.name}</div>
        <div className="rs-xs" style={{ marginTop: 3 }}>{p.room} · {p.mode === 'redesign' ? 'Redesign' : 'Reshuffle'} · {p.edited}</div>
        <span className={`rs-badge ${p.status === 'Plan saved' ? 'rs-badge--ok' : 'rs-badge--warm'}`} style={{ marginTop: 7 }}>
          <span className="rs-dot" style={{ background: 'currentColor' }} />{p.status}
        </span>
      </div>
      <div className="rs-iconbtn" style={{ width: 34, height: 34, boxShadow: 'none', border: 'none', background: 'transparent' }} onClick={(e) => { e.stopPropagation(); onMenu(p); }}>
        <Icon name="dots" size={20} color="var(--ink-3)" />
      </div>
    </div>
  );
}

function projMenu(ctx, p) {
  return (
    <Sheet open onClose={ctx.closeSheet} title={p.name} pb={ctx.insets.bottom + 18}>
      {[['eye', 'Reopen project', () => { ctx.set({ mode: p.mode }); ctx.go(p.mode === 'redesign' ? 'rd_concepts' : 'results'); }],
        ['pencil', 'Rename', ctx.closeSheet],
        ['share', 'Share plan', ctx.closeSheet],
        ['download', 'Export as PDF', ctx.closeSheet]].map(([ic, t, fn], i) => (
        <button key={i} className="rs-btn rs-btn--quiet" style={{ justifyContent: 'flex-start', gap: 13, padding: '14px 6px' }} onClick={fn}>
          <Icon name={ic} size={20} color="var(--ink-2)" />{t}
        </button>
      ))}
      <div className="rs-divider" style={{ margin: '6px 0' }} />
      <button className="rs-btn rs-btn--quiet" style={{ justifyContent: 'flex-start', gap: 13, padding: '14px 6px', color: 'var(--danger)' }} onClick={ctx.closeSheet}>
        <Icon name="trash" size={20} />Delete project
      </button>
    </Sheet>
  );
}

function Sc_Home({ ctx }) {
  const { project } = ctx;
  const empty = project.empty;
  const greeting = (
    <div className="rs-topbar" style={{ paddingTop: ctx.insets.top + 4 }}>
      <Logo size={36} />
      <div style={{ flex: 1 }}>
        <div className="rs-xs">Good evening</div>
        <div className="rs-h3" style={{ fontSize: 16 }}>Maya</div>
      </div>
      <div className="rs-iconbtn" onClick={() => ctx.go('profile', { reset: true })}><Icon name="user" size={20} /></div>
    </div>
  );
  return (
    <div className="rs-screen rs-fade">
      <div style={{ flexShrink: 0 }}>{greeting}</div>
      <div className="rs-scroll" ref={ctx.scrollRef}>
        <div style={{ padding: '4px 16px 24px' }}>
          {/* hero start card */}
          <div className="rs-card rs-rise" style={{ overflow: 'hidden', borderRadius: 'var(--r-xl)', boxShadow: 'var(--sh)' }}>
            <div style={{ position: 'relative' }}>
              <RoomScene items={ROOM_LAYOUTS.bedB} palette={ctx.theme === 'dark' ? 'dark' : 'cool'} height={150} />
              <div style={{ position: 'absolute', top: 12, left: 12 }}>
                <span className="rs-badge rs-badge--teal" style={{ background: ctx.theme === 'dark' ? 'rgba(43,192,171,.22)' : 'rgba(255,255,255,.9)', color: 'var(--teal-ink)', backdropFilter: 'blur(6px)' }}><Icon name="sparkleSm" size={13} /> Start here</span>
              </div>
            </div>
            <div style={{ padding: '14px 16px 16px' }}>
              <div className="rs-h2" style={{ fontSize: 19 }}>Reshuffle a room</div>
              <p className="rs-sm" style={{ marginTop: 4 }}>Scan it, review what we find, and get practical new layouts using your current furniture.</p>
              <button className="rs-btn rs-btn--primary" style={{ marginTop: 14 }} onClick={ctx.startNewProject}>
                <Icon name="plus" size={19} /> New project
              </button>
            </div>
          </div>

          {/* two quick modes */}
          <div className="rs-grid2" style={{ marginTop: 14 }}>
            <div className="rs-card rs-card--pad" style={{ cursor: 'pointer' }} onClick={() => { ctx.set({ mode: 'reshuffle' }); ctx.go('capture'); }}>
              <div style={{ width: 38, height: 38, borderRadius: 12, background: 'var(--teal-tint)', color: 'var(--teal-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="move" size={19} /></div>
              <div className="rs-h3" style={{ fontSize: 14.5, marginTop: 10 }}>Reshuffle</div>
              <div className="rs-xs" style={{ marginTop: 2 }}>Use what you own</div>
            </div>
            <div className="rs-card rs-card--pad" style={{ cursor: 'pointer' }} onClick={() => { ctx.set({ mode: 'redesign' }); ctx.go('rd_mode'); }}>
              <div style={{ width: 38, height: 38, borderRadius: 12, background: 'var(--warm-tint)', color: 'var(--warm-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="palette" size={19} /></div>
              <div className="rs-h3" style={{ fontSize: 14.5, marginTop: 10 }}>Redesign <span className="rs-badge rs-badge--warm" style={{ fontSize: 9, padding: '2px 6px', verticalAlign: 'middle' }}>SOON</span></div>
              <div className="rs-xs" style={{ marginTop: 2 }}>Shop new pieces</div>
            </div>
          </div>

          {/* recent */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '24px 2px 12px' }}>
            <h2 className="rs-h2" style={{ fontSize: 17 }}>Recent projects</h2>
            <span className="rs-sm" style={{ color: 'var(--teal)', fontWeight: 600, cursor: 'pointer' }} onClick={() => ctx.go('saved', { reset: true })}>See all</span>
          </div>

          {empty ? (
            <div className="rs-card rs-card--pad" style={{ textAlign: 'center', padding: '34px 22px' }}>
              <div style={{ width: 92, margin: '0 auto', opacity: .9 }}>
                <FloorPlan items={[]} width={150} height={110} theme={ctx.theme} />
              </div>
              <div className="rs-h3" style={{ marginTop: 14 }}>No projects yet</div>
              <p className="rs-sm" style={{ marginTop: 4 }}>Scan your first room to see AI layout ideas here.</p>
              <button className="rs-btn rs-btn--soft rs-btn--sm" style={{ margin: '14px auto 0' }} onClick={ctx.startNewProject}>Start a project</button>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
              {project.saved.map(p => <ProjectCard key={p.id} p={p} ctx={ctx} onMenu={(pp) => ctx.openSheet(projMenu(ctx, pp))} />)}
            </div>
          )}

          {/* dev toggle for empty state */}
          <button className="rs-btn rs-btn--quiet rs-btn--sm" style={{ margin: '16px auto 0', opacity: .55 }} onClick={() => ctx.set({ empty: !empty })}>
            <Icon name="refresh" size={14} /> Preview {empty ? 'populated' : 'empty'} state
          </button>
        </div>
      </div>
      {ctx.sheet}
      <TabBar ctx={ctx} />
    </div>
  );
}

function Sc_Saved({ ctx }) {
  const { project } = ctx;
  return (
    <div className="rs-screen rs-fade">
      <div style={{ flexShrink: 0 }}><div className="rs-topbar" style={{ paddingTop: ctx.insets.top + 4 }}><div style={{ flex: 1 }}><h1 className="rs-h1" style={{ fontSize: 25 }}>Saved</h1></div><div className="rs-iconbtn"><Icon name="search" size={20} /></div></div></div>
      <div className="rs-scroll">
        <div className="rs-scroll-x" style={{ marginBottom: 6 }}>
          {['All', 'Reshuffle', 'Redesign', 'Plan saved', 'In review'].map((f, i) => <Chip key={f} label={f} on={i === 0} sm />)}
        </div>
        <div style={{ padding: '4px 16px 24px', display: 'flex', flexDirection: 'column', gap: 11 }}>
          {project.saved.map(p => <ProjectCard key={p.id} p={p} ctx={ctx} onMenu={(pp) => ctx.openSheet(projMenu(ctx, pp))} />)}
          <div className="rs-card" style={{ borderStyle: 'dashed', padding: 18, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 9, color: 'var(--teal)', cursor: 'pointer', boxShadow: 'none' }} onClick={ctx.startNewProject}>
            <Icon name="plus" size={19} /><span style={{ fontWeight: 600 }}>New project</span>
          </div>
        </div>
      </div>
      {ctx.sheet}
      <TabBar ctx={ctx} />
    </div>
  );
}

function Sc_Explore({ ctx }) {
  const styles = [
    { t: 'Minimal bedroom', room: 'bedB', pal: 'cool' }, { t: 'Cosy living room', room: 'livingC', pal: 'cozy' },
    { t: 'Small apartment', room: 'bedA', pal: 'warm' }, { t: 'Work-from-home', room: 'livingB', pal: 'cool' },
    { t: 'Budget refresh', room: 'livingA', pal: 'warm' }, { t: 'Luxury calm', room: 'bedB', pal: 'cozy' },
  ];
  return (
    <div className="rs-screen rs-fade">
      <div style={{ flexShrink: 0 }}><div className="rs-topbar" style={{ paddingTop: ctx.insets.top + 4 }}><div style={{ flex: 1 }}><div className="rs-eyebrow">Inspiration</div><h1 className="rs-h1" style={{ fontSize: 25, marginTop: 2 }}>Explore styles</h1></div></div></div>
      <div className="rs-scroll">
        <p className="rs-sm" style={{ padding: '0 16px 12px' }}>Browse layout directions, then bring one into your own room scan.</p>
        <div className="rs-grid2" style={{ padding: '0 16px 24px' }}>
          {styles.map((s, i) => (
            <div key={i} className="rs-card" style={{ overflow: 'hidden', cursor: 'pointer' }} onClick={ctx.startNewProject}>
              <RoomScene items={ROOM_LAYOUTS[s.room]} palette={ctx.theme === 'dark' ? 'dark' : s.pal} height={104} width={170} rw={9} rd={7} />
              <div style={{ padding: '9px 11px 11px' }}>
                <div className="rs-h3" style={{ fontSize: 13.5 }}>{s.t}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
      <TabBar ctx={ctx} />
    </div>
  );
}

function Sc_Profile({ ctx }) {
  const pref = (icon, label, val, onClick) => (
    <React.Fragment>
      <div className="rs-row" onClick={onClick} style={{ cursor: onClick ? 'pointer' : 'default' }}>
        <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--surface-3)', color: 'var(--ink-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name={icon} size={18} /></div>
        <div style={{ flex: 1 }} className="rs-h3"><span style={{ fontSize: 15 }}>{label}</span></div>
        <span className="rs-sm" style={{ fontWeight: 600 }}>{val}</span>
        {onClick && <Icon name="chevR" size={16} color="var(--ink-3)" />}
      </div>
      <div className="rs-divider" />
    </React.Fragment>
  );
  return (
    <div className="rs-screen rs-fade">
      <div style={{ flexShrink: 0 }}><div className="rs-topbar" style={{ paddingTop: ctx.insets.top + 4 }}><div style={{ flex: 1 }}><h1 className="rs-h1" style={{ fontSize: 25 }}>Profile</h1></div></div></div>
      <div className="rs-scroll">
        <div style={{ padding: '0 16px 24px' }}>
          <div className="rs-card rs-card--pad" style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 56, height: 56, borderRadius: '50%', background: 'var(--teal)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, fontWeight: 700, fontFamily: 'var(--font-display)' }}>M</div>
            <div style={{ flex: 1 }}>
              <div className="rs-h3">Maya Chen</div>
              <div className="rs-xs" style={{ marginTop: 2 }}>maya@email.com · Free plan</div>
            </div>
          </div>
          <button className="rs-btn rs-btn--soft" style={{ marginTop: 12 }}><Icon name="sparkleSm" size={18} /> Upgrade for redesign & PDF export</button>

          <div className="rs-eyebrow" style={{ margin: '24px 4px 8px' }}>Preferences</div>
          <div className="rs-card" style={{ padding: '4px 14px' }}>
            {pref('ruler', 'Measurement units', 'Feet / inches', () => {})}
            {pref('cart', 'Favourite stores', 'IKEA, Target', () => {})}
            {pref('palette', 'Default style', 'Minimal', () => {})}
            <div className="rs-row">
              <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--surface-3)', color: 'var(--ink-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name={ctx.theme === 'dark' ? 'moon' : 'sun'} size={18} /></div>
              <div style={{ flex: 1 }} className="rs-h3"><span style={{ fontSize: 15 }}>Appearance</span></div>
              <span className="rs-sm" style={{ fontWeight: 600 }}>Use the toggle above ↑</span>
            </div>
          </div>

          <div className="rs-eyebrow" style={{ margin: '24px 4px 8px' }}>Privacy</div>
          <div className="rs-card" style={{ padding: '4px 14px' }}>
            {pref('lock', 'Delete room videos', '', () => {})}
            {pref('info', 'Data & training consent', 'Off', () => {})}
          </div>
          <button className="rs-btn rs-btn--quiet" style={{ marginTop: 18, color: 'var(--danger)' }} onClick={() => ctx.go('welcome', { reset: true })}>Log out</button>
        </div>
      </div>
      <TabBar ctx={ctx} />
    </div>
  );
}

Object.assign(window, { Sc_Home, Sc_Saved, Sc_Explore, Sc_Profile, ProjectCard });
