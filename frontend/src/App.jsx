import React, { useEffect, useState } from 'react'

function App() {
  const [status, setStatus] = useState('Checking backend...')

  useEffect(() => {
    fetch('http://localhost:5000/api/health')
      .then((r) => r.json())
      .then((d) => setStatus(`Backend says: ${d.status}`))
      .catch(() => setStatus('Backend unreachable'))
  }, [])

  return (
    <main style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
      <h1>MMCS Frontend</h1>
      <p id="status-line">{status}</p>
    </main>
  )
}

export default App