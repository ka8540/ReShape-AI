/* screens-onboard.jsx — welcome, auth, permission */

function Sc_Welcome({ ctx }) {
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" noScroll
      footer={
        <BottomBar ctx={ctx} transparent>
          <button className="rs-btn rs-btn--primary" onClick={() => ctx.go('auth')}>
            Get started <Icon name="arrowR" size={19} />
          </button>
          <button className="rs-btn rs-btn--quiet" style={{ marginTop: 4 }} onClick={() => ctx.go('auth')}>I already have an account</button>
        </BottomBar>
      }>
      <div style={{ padding: '6px 22px 0', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <div className="rs-rowflex" style={{ gap: 10 }}>
          <Logo size={34} />
          <span className="rs-h3" style={{ fontFamily: 'var(--font-display)' }}>ReSpace<span style={{ color: 'var(--teal)' }}> AI</span></span>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 22 }}>
          <div className="rs-card rs-rise" style={{ overflow: 'hidden', borderRadius: 'var(--r-xl)', boxShadow: 'var(--sh-lg)' }}>
            <RoomScene items={ROOM_LAYOUTS.livingC} palette={ctx.theme === 'dark' ? 'dark' : 'warm'} height={210} />
            <div style={{ position: 'relative', padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8, borderTop: '1px solid var(--border)' }}>
              <span className="rs-badge rs-badge--teal"><Icon name="sparkleSm" size={13} /> AI layout preview</span>
              <span className="rs-xs">From a 30-second video of your room</span>
            </div>
          </div>

          <div className="rs-rise" style={{ animationDelay: '.06s' }}>
            <h1 className="rs-h1" style={{ fontSize: 30, lineHeight: 1.1 }}>See your room<br />rearranged — before<br />you move a thing.</h1>
            <p className="rs-body" style={{ marginTop: 12 }}>Record a quick video. ReSpace finds your furniture and suggests practical new layouts using what you already own.</p>
          </div>

          <div style={{ display: 'flex', gap: 18 }}>
            {[['scan', 'Scan'], ['sparkleSm', 'Reshuffle'], ['list', 'Move plan']].map(([ic, t], i) => (
              <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 7, flex: 1 }}>
                <div style={{ width: 44, height: 44, borderRadius: 14, background: 'var(--teal-tint)', color: 'var(--teal-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name={ic} size={21} /></div>
                <span className="rs-xs" style={{ fontWeight: 600, color: 'var(--ink-2)' }}>{t}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </ScreenShell>
  );
}

function Sc_Auth({ ctx }) {
  const provider = (icon, label, fill) => (
    <button className="rs-btn rs-btn--ghost" style={{ justifyContent: 'flex-start', gap: 12 }} onClick={() => ctx.go('home', { reset: true })}>
      <span style={{ width: 22, display: 'flex', justifyContent: 'center' }}>{icon}</span>
      <span style={{ flex: 1, textAlign: 'center', marginLeft: -22 }}>{label}</span>
    </button>
  );
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<TopBar onBack={ctx.back} />}>
      <div style={{ padding: '4px 22px 30px' }}>
        <Logo size={40} />
        <h1 className="rs-h1" style={{ marginTop: 18 }}>Welcome back</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>Save your room scans, layouts and move plans across devices.</p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 11, marginTop: 26 }}>
          {provider(<svg width="19" height="19" viewBox="0 0 24 24" fill="currentColor"><path d="M16.4 12.9c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8c-1.5 0-2.9.9-3.7 2.3-1.6 2.7-.4 6.8 1.1 9 .7 1.1 1.6 2.3 2.7 2.2 1.1 0 1.5-.7 2.8-.7s1.7.7 2.8.7 1.9-1.1 2.6-2.2c.8-1.2 1.2-2.4 1.2-2.5-.1 0-2.3-.9-2.3-3.5zM14.2 6.3c.6-.7 1-1.7.9-2.7-.9 0-1.9.6-2.5 1.3-.6.6-1 1.6-.9 2.6 1 .1 2-.5 2.5-1.2z"/></svg>, 'Continue with Apple')}
          {provider(<svg width="19" height="19" viewBox="0 0 24 24"><path fill="#4285F4" d="M21.6 12.2c0-.6-.1-1.2-.2-1.8H12v3.5h5.4c-.2 1.3-.9 2.3-2 3v2.5h3.2c1.9-1.7 3-4.3 3-7.2z"/><path fill="#34A853" d="M12 22c2.7 0 4.9-.9 6.6-2.4l-3.2-2.5c-.9.6-2 1-3.4 1-2.6 0-4.8-1.7-5.6-4.1H3.1v2.6C4.8 19.9 8.1 22 12 22z"/><path fill="#FBBC05" d="M6.4 14c-.2-.6-.3-1.3-.3-2s.1-1.4.3-2V7.4H3.1C2.4 8.8 2 10.4 2 12s.4 3.2 1.1 4.6L6.4 14z"/><path fill="#EA4335" d="M12 5.9c1.5 0 2.8.5 3.8 1.5l2.8-2.8C16.9 2.9 14.7 2 12 2 8.1 2 4.8 4.1 3.1 7.4L6.4 10c.8-2.4 3-4.1 5.6-4.1z"/></svg>, 'Continue with Google')}
          {provider(<Icon name="user" size={19} color="var(--ink-2)" />, 'Continue with email')}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '22px 0' }}>
          <div style={{ flex: 1, height: 1, background: 'var(--border)' }} />
          <span className="rs-xs">or</span>
          <div style={{ flex: 1, height: 1, background: 'var(--border)' }} />
        </div>

        <button className="rs-btn rs-btn--soft" onClick={() => ctx.go('home', { reset: true })}>Continue as guest</button>
        <div className="rs-note rs-note--teal" style={{ marginTop: 14 }}>
          <Icon name="info" size={17} style={{ flexShrink: 0, marginTop: 1 }} />
          <span>Guest mode lets you try the full flow. You'll need an account to <b>save</b> projects.</span>
        </div>

        <p className="rs-xs" style={{ textAlign: 'center', marginTop: 24, lineHeight: 1.6 }}>By continuing you agree to our Terms & Privacy Policy. Your room videos stay private and are never used to train models without consent.</p>
      </div>
    </ScreenShell>
  );
}

function Sc_Perm({ ctx }) {
  const row = (icon, title, body) => (
    <div className="rs-row" style={{ alignItems: 'flex-start', padding: '14px 0' }}>
      <div style={{ width: 42, height: 42, borderRadius: 13, background: 'var(--teal-tint)', color: 'var(--teal-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name={icon} size={21} /></div>
      <div style={{ flex: 1 }}>
        <div className="rs-h3" style={{ fontSize: 15.5 }}>{title}</div>
        <div className="rs-sm" style={{ marginTop: 2 }}>{body}</div>
      </div>
    </div>
  );
  return (
    <ScreenShell ctx={ctx} bg="var(--bg)" header={<TopBar onBack={ctx.back} />}
      footer={
        <BottomBar ctx={ctx} transparent>
          <button className="rs-btn rs-btn--primary" onClick={() => ctx.go('upload')}>Allow access</button>
          <button className="rs-btn rs-btn--quiet" style={{ marginTop: 4 }} onClick={() => ctx.go('upload')}>Not now</button>
        </BottomBar>
      }>
      <div style={{ padding: '8px 22px 0' }}>
        <div style={{ width: 64, height: 64, borderRadius: 20, background: 'var(--teal)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--sh-teal)' }}><Icon name="camera" size={30} /></div>
        <h1 className="rs-h1" style={{ marginTop: 18 }}>Camera & photos access</h1>
        <p className="rs-body" style={{ marginTop: 6 }}>ReSpace needs to record or import a short video of your room to understand the space.</p>
        <div className="rs-card rs-card--pad" style={{ marginTop: 22, padding: '4px 16px' }}>
          {row('camera', 'Camera', 'Record a guided walkthrough of your room.')}
          <div className="rs-divider" style={{ margin: 0 }} />
          {row('gallery', 'Photo library', 'Pick an existing room video to analyse.')}
          <div className="rs-divider" style={{ margin: 0 }} />
          {row('lock', 'Stays private', 'Videos are processed securely and can be deleted any time.')}
        </div>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, { Sc_Welcome, Sc_Auth, Sc_Perm });
