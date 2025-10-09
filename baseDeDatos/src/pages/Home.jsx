import React from 'react'
import Navbar from '../components/NavBar'
import PanelIntro from '../components/PanelIntro'
import Footer from '../components/Footer'

function Home() {
  return (
    <div className="d-flex flex-column min-vh-100">
        <Navbar />
        <PanelIntro />
        <Footer />
    </div>
  )
}

export default Home