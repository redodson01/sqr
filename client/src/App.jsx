import './App.css'
import EncodeSection from './components/EncodeSection'
import DecodeSection from './components/DecodeSection'

function App() {
  return (
    <div className="container">
      <h1>SQR</h1>
      <EncodeSection />
      <DecodeSection />
    </div>
  )
}

export default App
