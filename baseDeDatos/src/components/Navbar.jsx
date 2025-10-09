import { Link } from 'react-router-dom';
import logo from '../assets/logodb.png'

export default function Navbar() {
  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-dark px-4">
      <div className="container-fluid">
        {/* Logo + Panel Reportes */}
        <div className="d-flex align-items-center">
          <img
            src={logo}
            alt="Logo Panel"
            style={{ width: '32px', height: '32px', marginRight: '8px' }}
          />
          <span className="navbar-brand fw-bold mb-0">Panel Reportes</span>
        </div>

        {/* Botones centrados */}
        <div className="mx-auto">
          <ul className="navbar-nav d-flex flex-row gap-3">
            <li className="nav-item">
              <Link className="nav-link" to="/Boton1">Botón</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/Boton2">Botón</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/Boton3">Botón</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/Boton4">Botón</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/Boton5">Botón</Link>
            </li>
            <li className="nav-item">
              <Link className="nav-link" to="/Boton6">Botón</Link>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  );
}
