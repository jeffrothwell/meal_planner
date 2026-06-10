import React from 'react'
import { createRoot } from 'react-dom/client'

function App() {
  return (
    <div style={{
      position: 'fixed',
      bottom: '1rem',
      right: '1rem',
      background: '#61dafb',
      color: '#000',
      padding: '4px 10px',
      borderRadius: '4px',
      fontSize: '12px',
      fontWeight: 'bold',
      opacity: 0.85,
    }}>
      ⚛️ React connected
    </div>
  )
}

const container = document.getElementById('react-root')
if (container) {
  createRoot(container).render(<App />)
}
