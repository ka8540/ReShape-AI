/* screens-flow1.jsx — mode, capture, upload, preview, processing, error */
var { useState, useEffect, useRef } = React;

function FlowHeader({ ctx, step, title }) {
  return (
    <div style={{ paddingTop: ctx.insets.top }}>
      <div className="rs-topbar" style={{ paddingBottom: 8 }}>
        <div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div>
        <div style={{ flex: 1 }}>
          <div className="rs-xs" style={{ fontWeight: 600 }}>{title} · Step {step + 1} of {RESHUFFLE_STEPS.length}</div>
        </div>
        <div className="rs-iconbtn" onClick={() => ctx.go('home', { reset: true })}><Icon name="x" size={18} /></div>
      </div>
      <Stepper steps={RESHUFFLE_STEPS} current={step} />
    </div>
  );
}

function Sc_Mode({ ctx }) {
  const card = (active, accent, icon, badge, title, desc, bullets, onClick) => (
    <div className="rs-card" onClick={onClick} style={{ overflow: 'hidden', cursor: 'pointer', opacity: active ? 1 : 1, position: 'relative', boxShadow: active ? 'var(--sh)' : 'var(--sh-sm)', borderColor: active ? 'var(--teal)' : 'var(--border)' }}>
      <div style={{ position: 'relative' }}>
        <RoomScene items={active ? ROOM_LAYOUTS.livingC : ROOM_LAYOUTS.livingA} palette={ctx.theme === 'dark' ? 'dark' : (active ? 'cool' : 'warm')} height={118} />
        <span className={`rs-badge ${active ? 'rs-badge--teal' : 'rs-badge--warm'}`} style={{ position: 'absolute', top: 11, left: 11 }}>{badge}</span>
      </div>
      <div style={{ padding: '14px 16px 16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
          <div style={{ width: 34, height: 34, borderRadius: 11, background: accent.bg, color: accent.fg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name={icon} size={18} /></div>
          <div className="rs-h2" style={{ fontSize: 18 }}>{title}</div>
        </div>
        <p className="rs-sm" style={{ marginTop: 8 }}>{desc}</p>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 11 }}>
          {bullets.map(b => <span key={b} className="rs-badge rs-badge--neutral">{b}</span>)}
        </div>
      </div>
    </div>
  );
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<FlowHeader ctx={ctx} step={0} title="New project" />}>
      <div style={{ padding: '14px 16px 28px' }}>
        <h1 className="rs-h1">What do you want to do?</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Pick how you'd like to improve your space. You can switch later.</p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginTop: 18 }}>
          {card(true, { bg: 'var(--teal-tint)', fg: 'var(--teal-ink)' }, 'move', 'Recommended', 'Reshuffle my room',
            'Rearrange the furniture you already own into a better layout — no shopping needed.',
            ['Uses your stuff', '3–5 layouts', 'Move checklist'],
            () => { ctx.set({ mode: 'reshuffle' }); ctx.go('capture'); })}
          {card(false, { bg: 'var(--warm-tint)', fg: 'var(--warm-ink)' }, 'palette', 'Coming soon', 'Redesign my room',
            'Get new furniture and décor ideas with estimated sizes, budgets and shopping lists.',
            ['New products', 'Measurements', 'Fit-aware'],
            () => { ctx.set({ mode: 'redesign' }); ctx.go('rd_mode'); })}
        </div>
      </div>
    </ScreenShell>
  );
}

function Sc_Capture({ ctx }) {
  const tips = [
    ['clock', 'Move slowly', 'Pan smoothly around the room — no fast sweeps.'],
    ['scan', 'Show every corner', 'Capture all four corners, the floor and the walls.'],
    ['pin', 'Doors & windows', 'Keep doors and windows in frame so AI maps the space.'],
    ['sofa', 'Keep furniture visible', 'Make sure each big piece appears clearly.'],
    ['bulb', 'Good lighting', 'Turn on lights or scan during the day.'],
    ['ruler', 'Optional: a known object', 'Leave a door or A4 sheet in view to help scale.'],
  ];
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<FlowHeader ctx={ctx} step={1} title="Capture" />}
      footer={<BottomBar ctx={ctx}><button className="rs-btn rs-btn--primary" onClick={() => ctx.go('perm')}>I'm ready to scan</button></BottomBar>}>
      <div style={{ padding: '14px 16px 20px' }}>
        <h1 className="rs-h1">Scan your room slowly<br />so AI understands it</h1>
        <div className="rs-card" style={{ overflow: 'hidden', marginTop: 16, position: 'relative' }}>
          <RoomScene items={ROOM_LAYOUTS.bedA} palette={ctx.theme === 'dark' ? 'dark' : 'warm'} height={150} />
          {/* scan path overlay */}
          <svg viewBox="0 0 300 150" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}>
            <path d="M40 110 Q150 60 260 110" fill="none" stroke="var(--teal)" strokeWidth="2.5" strokeDasharray="2 7" strokeLinecap="round" opacity="0.9" />
            <circle cx="40" cy="110" r="5" fill="var(--teal)" />
            <path d="M255 105l8 5-8 5z" fill="var(--teal)" />
          </svg>
          <span className="rs-badge" style={{ position: 'absolute', bottom: 10, left: 10, background: 'rgba(0,0,0,.5)', color: '#fff', backdropFilter: 'blur(4px)' }}><Icon name="play" size={11} fill="solid" color="#fff" /> 30–60s walkthrough</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2, marginTop: 16 }}>
          {tips.map(([ic, t, d], i) => (
            <div key={i} className="rs-row" style={{ padding: '11px 4px' }}>
              <div style={{ width: 38, height: 38, borderRadius: 11, background: 'var(--teal-tint)', color: 'var(--teal-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name={ic} size={18} /></div>
              <div style={{ flex: 1 }}>
                <div className="rs-h3" style={{ fontSize: 14.5 }}>{t}</div>
                <div className="rs-xs" style={{ marginTop: 1 }}>{d}</div>
              </div>
              {i === tips.length - 1 && <span className="rs-badge rs-badge--neutral">Optional</span>}
            </div>
          ))}
        </div>
      </div>
    </ScreenShell>
  );
}

function Sc_Upload({ ctx }) {
  const [phase, setPhase] = useState('choose'); // choose | uploading | error
  const [pct, setPct] = useState(0);
  const timer = useRef(null);

  const startUpload = (fail) => {
    setPhase('uploading'); setPct(0);
    let p = 0;
    timer.current = setInterval(() => {
      p += Math.random() * 14 + 6;
      if (fail && p > 64) { clearInterval(timer.current); setPhase('error'); return; }
      if (p >= 100) { p = 100; clearInterval(timer.current); setTimeout(() => ctx.go('preview'), 450); }
      setPct(Math.min(100, Math.round(p)));
    }, 260);
  };
  useEffect(() => () => clearInterval(timer.current), []);

  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<FlowHeader ctx={ctx} step={2} title="Upload" />}>
      <div style={{ padding: '14px 16px 28px' }}>
        <h1 className="rs-h1">Add a room video</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Record now or pick one from your gallery.</p>

        {phase === 'choose' && (
          <div className="rs-fade">
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 18 }}>
              <button className="rs-card rs-card--pad" style={{ display: 'flex', alignItems: 'center', gap: 14, textAlign: 'left', cursor: 'pointer', border: '1px solid var(--teal)' }} onClick={() => startUpload(false)}>
                <div style={{ width: 48, height: 48, borderRadius: 14, background: 'var(--teal)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--sh-teal)' }}><Icon name="camera" size={23} /></div>
                <div style={{ flex: 1 }}><div className="rs-h3">Record video</div><div className="rs-xs" style={{ marginTop: 2 }}>Guided in-app capture</div></div>
                <Icon name="chevR" size={18} color="var(--ink-3)" />
              </button>
              <button className="rs-card rs-card--pad" style={{ display: 'flex', alignItems: 'center', gap: 14, textAlign: 'left', cursor: 'pointer' }} onClick={() => startUpload(false)}>
                <div style={{ width: 48, height: 48, borderRadius: 14, background: 'var(--surface-3)', color: 'var(--ink-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="gallery" size={23} /></div>
                <div style={{ flex: 1 }}><div className="rs-h3">Upload from gallery</div><div className="rs-xs" style={{ marginTop: 2 }}>Pick an existing clip</div></div>
                <Icon name="chevR" size={18} color="var(--ink-3)" />
              </button>
            </div>
            <div className="rs-card rs-card--pad" style={{ marginTop: 16, background: 'var(--surface-2)', boxShadow: 'none' }}>
              <div className="rs-h3" style={{ fontSize: 13.5 }}>File requirements</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 7, marginTop: 9 }}>
                {[['MP4 or MOV format'], ['30–60 seconds long'], ['Up to 200 MB'], ['Good lighting, steady pan']].map(([t], i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 9 }}><Icon name="check" size={15} color="var(--teal)" sw={2.6} /><span className="rs-sm">{t}</span></div>
                ))}
              </div>
            </div>
            <button className="rs-btn rs-btn--quiet rs-btn--sm" style={{ margin: '14px auto 0', opacity: .55 }} onClick={() => startUpload(true)}><Icon name="alert" size={14} /> Simulate a failed upload</button>
          </div>
        )}

        {phase === 'uploading' && (
          <div className="rs-fade" style={{ marginTop: 22 }}>
            <div className="rs-card rs-card--pad">
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 50, height: 50, borderRadius: 13, overflow: 'hidden', flexShrink: 0 }}><RoomScene items={ROOM_LAYOUTS.bedB} palette={ctx.theme === 'dark' ? 'dark' : 'cool'} height={50} width={50} /></div>
                <div style={{ flex: 1 }}>
                  <div className="rs-h3" style={{ fontSize: 14.5 }}>room_scan.mp4</div>
                  <div className="rs-xs" style={{ marginTop: 2 }}>48s · 84 MB</div>
                </div>
                <span className="rs-num rs-h3" style={{ color: 'var(--teal)', fontSize: 16 }}>{pct}%</span>
              </div>
              <div className="rs-progress" style={{ marginTop: 14 }}><i style={{ width: pct + '%' }} /></div>
              <div className="rs-xs" style={{ marginTop: 8 }}>Uploading securely…</div>
            </div>
            <button className="rs-btn rs-btn--quiet rs-btn--sm" style={{ margin: '14px auto 0' }} onClick={() => { clearInterval(timer.current); setPhase('choose'); }}>Cancel</button>
          </div>
        )}

        {phase === 'error' && (
          <div className="rs-fade" style={{ marginTop: 22 }}>
            <div className="rs-card rs-card--pad" style={{ textAlign: 'center', padding: '28px 22px' }}>
              <div style={{ width: 56, height: 56, borderRadius: 17, background: 'var(--danger-tint)', color: 'var(--danger)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto' }}><Icon name="alert" size={27} /></div>
              <div className="rs-h3" style={{ marginTop: 14 }}>Upload interrupted</div>
              <p className="rs-sm" style={{ marginTop: 5 }}>Your connection dropped at {pct}%. Nothing was lost — just try again.</p>
              <button className="rs-btn rs-btn--primary" style={{ marginTop: 16 }} onClick={() => startUpload(false)}><Icon name="refresh" size={18} /> Retry upload</button>
              <button className="rs-btn rs-btn--quiet" style={{ marginTop: 4 }} onClick={() => setPhase('choose')}>Choose another video</button>
            </div>
          </div>
        )}
      </div>
    </ScreenShell>
  );
}

function Sc_Preview({ ctx }) {
  const [playing, setPlaying] = useState(false);
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<FlowHeader ctx={ctx} step={2} title="Upload" />}
      footer={<BottomBar ctx={ctx}>
        <button className="rs-btn rs-btn--primary" onClick={() => ctx.go('processing')}><Icon name="sparkleSm" size={19} /> Looks good — analyse</button>
        <button className="rs-btn rs-btn--quiet" style={{ marginTop: 4 }} onClick={() => ctx.back()}>Retake video</button>
      </BottomBar>}>
      <div style={{ padding: '14px 16px 24px' }}>
        <h1 className="rs-h1">Confirm your video</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Make sure the whole room is visible before we analyse it.</p>
        <div className="rs-card" style={{ overflow: 'hidden', marginTop: 16, position: 'relative' }}>
          <RoomScene items={ROOM_LAYOUTS.bedA} palette={ctx.theme === 'dark' ? 'dark' : 'warm'} height={210} />
          <div onClick={() => setPlaying(p => !p)} style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            <div style={{ width: 58, height: 58, borderRadius: '50%', background: 'rgba(255,255,255,.92)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--sh)' }}>
              <Icon name={playing ? 'minus' : 'play'} size={24} color="#0F1E29" fill={playing ? 'none' : 'solid'} />
            </div>
          </div>
          {/* scrubber */}
          <div style={{ position: 'absolute', left: 12, right: 12, bottom: 12, display: 'flex', alignItems: 'center', gap: 9 }}>
            <span className="rs-xs" style={{ color: '#fff', fontWeight: 600 }}>0:12</span>
            <div style={{ flex: 1, height: 4, borderRadius: 999, background: 'rgba(255,255,255,.35)' }}><div style={{ width: '26%', height: '100%', borderRadius: 999, background: '#fff' }} /></div>
            <span className="rs-xs" style={{ color: '#fff', fontWeight: 600 }}>0:48</span>
          </div>
        </div>
        <div className="rs-note rs-note--teal" style={{ marginTop: 14 }}>
          <Icon name="check" size={17} sw={2.6} style={{ flexShrink: 0, marginTop: 1 }} />
          <span>All four corners and the window are visible — great scan for layout detection.</span>
        </div>
      </div>
    </ScreenShell>
  );
}

const PROC_STAGES = [
  { t: 'Uploading video', d: 'Securely sending your clip' },
  { t: 'Extracting frames', d: 'Pulling clear stills from the video' },
  { t: 'Detecting furniture', d: 'Finding sofa, bed, desk and more' },
  { t: 'Understanding the layout', d: 'Mapping walls, doors and open space' },
  { t: 'Generating layout options', d: 'Drafting practical reshuffles' },
];
function Sc_Processing({ ctx }) {
  const [stage, setStage] = useState(0);
  const [pct, setPct] = useState(4);
  useEffect(() => {
    const iv = setInterval(() => setPct(p => Math.min(100, p + Math.random() * 6 + 2)), 180);
    return () => clearInterval(iv);
  }, []);
  useEffect(() => {
    setStage(Math.min(PROC_STAGES.length - 1, Math.floor(pct / (100 / PROC_STAGES.length))));
    if (pct >= 100) { const t = setTimeout(() => ctx.go('review'), 600); return () => clearTimeout(t); }
  }, [pct]);
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" noScroll
      header={<div style={{ paddingTop: ctx.insets.top }}><div className="rs-topbar"><div style={{ flex: 1 }} /><div className="rs-iconbtn" onClick={() => ctx.go('error')} style={{ opacity: .5 }}><Icon name="x" size={18} /></div></div></div>}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 24px 30px' }}>
        {/* animated room build */}
        <div style={{ position: 'relative', margin: '0 auto 26px', width: 200, height: 200 }}>
          <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'var(--teal-tint)', animation: 'rsSpin 9s linear infinite' }} />
          <svg viewBox="0 0 200 200" style={{ position: 'absolute', inset: 0 }}>
            <circle cx="100" cy="100" r="86" fill="none" stroke="var(--border)" strokeWidth="6" />
            <circle cx="100" cy="100" r="86" fill="none" stroke="var(--teal)" strokeWidth="6" strokeLinecap="round" strokeDasharray={`${(pct/100)*540} 540`} transform="rotate(-90 100 100)" style={{ transition: 'stroke-dasharray .3s' }} />
          </svg>
          <div style={{ position: 'absolute', inset: 28, borderRadius: 22, overflow: 'hidden', boxShadow: 'var(--sh)' }}>
            <RoomScene items={ROOM_LAYOUTS.livingC.slice(0, Math.max(1, Math.round(stage / 4 * ROOM_LAYOUTS.livingC.length)))} palette={ctx.theme === 'dark' ? 'dark' : 'cool'} height={144} width={144} />
          </div>
          <div style={{ position: 'absolute', bottom: -6, left: '50%', transform: 'translateX(-50%)', background: 'var(--surface)', borderRadius: 999, padding: '5px 13px', boxShadow: 'var(--sh)', fontWeight: 700, color: 'var(--teal)' }} className="rs-num">{Math.round(pct)}%</div>
        </div>
        <h1 className="rs-h1" style={{ textAlign: 'center' }}>Analysing your space</h1>
        <p className="rs-sm" style={{ textAlign: 'center', marginTop: 6 }}>This usually takes under a minute.</p>

        <div className="rs-card" style={{ marginTop: 22, padding: '6px 16px' }}>
          {PROC_STAGES.map((s, i) => {
            const done = i < stage, cur = i === stage;
            return (
              <div key={i} className="rs-row" style={{ padding: '11px 0', opacity: i > stage ? .4 : 1, transition: 'opacity .3s' }}>
                <div style={{ width: 28, height: 28, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, background: done ? 'var(--teal)' : cur ? 'var(--teal-tint)' : 'var(--surface-3)' }}>
                  {done ? <Icon name="check" size={15} color="#fff" sw={3} /> : cur ? <div className="rs-spin" style={{ borderColor: 'rgba(14,158,140,.3)', borderTopColor: 'var(--teal)', width: 15, height: 15 }} /> : <span className="rs-xs" style={{ fontWeight: 700 }}>{i + 1}</span>}
                </div>
                <div style={{ flex: 1 }}>
                  <div className="rs-h3" style={{ fontSize: 14 }}>{s.t}</div>
                  {cur && <div className="rs-xs" style={{ marginTop: 1 }}>{s.d}</div>}
                </div>
              </div>
            );
          })}
        </div>
        <div className="rs-note rs-note--teal" style={{ marginTop: 14 }}><Icon name="info" size={16} style={{ flexShrink: 0, marginTop: 1 }} /><span>Detection isn't perfect — you'll review and correct everything next.</span></div>
      </div>
    </ScreenShell>
  );
}

function Sc_Error({ ctx }) {
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" noScroll
      header={<div style={{ paddingTop: ctx.insets.top }}><div className="rs-topbar"><div className="rs-iconbtn" onClick={ctx.back}><Icon name="back" size={20} /></div><div style={{ flex: 1 }} /></div></div>}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 26px 40px', textAlign: 'center' }}>
        <div style={{ width: 84, height: 84, borderRadius: 26, background: 'var(--warn-tint)', color: 'var(--warn)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto' }}><Icon name="alert" size={40} /></div>
        <h1 className="rs-h1" style={{ marginTop: 20 }}>We couldn't read that video</h1>
        <p className="rs-body" style={{ marginTop: 8 }}>The clip looked too dark or shaky for AI to map the room reliably. A slower, brighter scan works best.</p>
        <div className="rs-card rs-card--pad" style={{ marginTop: 18, textAlign: 'left' }}>
          <div className="rs-h3" style={{ fontSize: 13.5, marginBottom: 9 }}>Quick fixes</div>
          {[['bulb', 'Turn on more lights'], ['clock', 'Pan more slowly'], ['scan', 'Show all four corners']].map(([ic, t], i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 0' }}><Icon name={ic} size={17} color="var(--teal)" /><span className="rs-sm">{t}</span></div>
          ))}
        </div>
        <button className="rs-btn rs-btn--primary" style={{ marginTop: 20 }} onClick={() => ctx.go('upload')}><Icon name="refresh" size={18} /> Try another video</button>
        <button className="rs-btn rs-btn--quiet" style={{ marginTop: 4 }} onClick={() => ctx.go('home', { reset: true })}>Back to home</button>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, { Sc_Mode, Sc_Capture, Sc_Upload, Sc_Preview, Sc_Processing, Sc_Error, FlowHeader });
