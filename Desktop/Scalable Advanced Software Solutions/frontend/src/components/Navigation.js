import React, { useState } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import './Navigation.css';

function Navigation() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const navigate = useNavigate();
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const token = localStorage.getItem('token');

  const closeMenu = () => setIsMenuOpen(false);

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    closeMenu();
    navigate('/');
    window.location.reload();
  };

  return (
    <nav className="navbar">
      <div className="nav-container">
        <NavLink to="/" className="nav-logo" onClick={closeMenu}>
          📷 PhotoShare
        </NavLink>

        <button
          className="nav-toggle"
          onClick={() => setIsMenuOpen(!isMenuOpen)}
          aria-expanded={isMenuOpen}
        >
          <span></span>
          <span></span>
          <span></span>
        </button>

        <ul className={`nav-menu ${isMenuOpen ? 'open' : ''}`}>
          <li className="nav-item">
            <NavLink 
              to="/" 
              className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
              onClick={closeMenu}
            >
              Home
            </NavLink>
          </li>
          
          {user.role === 'creator' && token && (
            <li className="nav-item">
              <NavLink 
                to="/upload" 
                className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
                onClick={closeMenu}
              >
                Upload
              </NavLink>
            </li>
          )}
          
          {token ? (
            <>
              <li className="nav-item nav-user-item">
                <span className="nav-user">
                  {user.username} 
                  <em>{user.role}</em>
                </span>
              </li>
              <li className="nav-item">
                <button onClick={handleLogout} className="nav-button logout">
                  Logout
                </button>
              </li>
            </>
          ) : (
            <li className="nav-item">
              <NavLink 
                to="/auth" 
                className={({ isActive }) => `nav-button ${isActive ? 'active' : ''}`}
                onClick={closeMenu}
              >
                Login
              </NavLink>
            </li>
          )}
        </ul>
      </div>
    </nav>
  );
}

export default Navigation;
