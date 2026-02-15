import { useState } from 'react'
import { API_BASE } from '../api'

export default function DecodeSection() {
  const [decoded, setDecoded] = useState(null)
  const [qrPng, setQrPng] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  async function handleDecode(e) {
    e.preventDefault()
    setError(null)
    setDecoded(null)
    setQrPng(null)

    const file = e.target.elements['qr-file'].files[0]
    if (!file) {
      setError('Please select a QR code image.')
      return
    }

    setLoading(true)
    try {
      const form = new FormData()
      form.append('file', file)

      const res = await fetch(`${API_BASE}/decode`, { method: 'POST', body: form })
      const json = await res.json()

      if (!res.ok) {
        throw new Error(json.error || `Server error (${res.status})`)
      }

      setDecoded(json.text)
      setQrPng(json.qr_png)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="card">
      <h2>Decode</h2>
      <form onSubmit={handleDecode}>
        <label htmlFor="qr-file">Upload a QR code image</label>
        <input id="qr-file" name="qr-file" type="file" accept="image/*" />
        <button type="submit" disabled={loading}>
          {loading ? 'Decoding...' : 'Decode QR Code'}
        </button>
      </form>
      {loading && (
        <div className="loading-message">
          <span className="spinner" />
          Processing image...
        </div>
      )}
      {error && <p className="error">{error}</p>}
      {decoded !== null && (
        <div className="decoded-text">
          <strong>Decoded text:</strong> {decoded}
        </div>
      )}
      {qrPng && <img className="qr-image" src={`data:image/png;base64,${qrPng}`} alt="Clean QR Code" />}
    </div>
  )
}
