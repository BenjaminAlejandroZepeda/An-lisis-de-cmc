import React from 'react'

function Footer() {
  return (
    <footer className="bg-dark text-white py-3 mt-auto">
      <div className="container text-center">
        <small>
          &copy; {new Date().getFullYear()} CMC Auditores y Consultores. Todos los derechos reservados.
        </small>
      </div>
    </footer>
  )
}

export default Footer