import { useState, useRef } from 'react'
import { API_BASE } from '../api'

export default function EncodeSection() {
  const [text, setText] = useState('')
  const [imgSrc, setImgSrc] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)
  const prevUrl = useRef(null)

  async function handleEncode(e) {
    e.preventDefault()
    setError(null)

    const trimmed = text.trim()
    if (!trimmed) {
      setError('Please enter some text.')
      return
    }

    setLoading(true)
    try {
      const form = new FormData()
      form.append('text', trimmed)

      const res = await fetch(`${API_BASE}/encode`, { method: 'POST', body: form })

      if (!res.ok) {
        const json = await res.json().catch(() => null)
        throw new Error(json?.error || `Server error (${res.status})`)
      }

      const blob = await res.blob()

      if (prevUrl.current) URL.revokeObjectURL(prevUrl.current)
      const url = URL.createObjectURL(blob)
      prevUrl.current = url
      setImgSrc(url)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="card">
      <h2>Encode</h2>
      <form onSubmit={handleEncode}>
        <label htmlFor="encode-text">Text to encode</label>
        <input
          id="encode-text"
          type="text"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Enter text..."
        />
        <button type="submit" disabled={loading}>
          {loading ? 'Encoding...' : 'Generate QR Code'}
        </button>
      </form>
      {loading && (
        <div className="loading-message">
          <span className="spinner" />
          Generating QR code...
        </div>
      )}
      {error && <p className="error">{error}</p>}
      {imgSrc && <img className="qr-image" src={imgSrc} alt="QR Code" />}
    </div>
  )
}
