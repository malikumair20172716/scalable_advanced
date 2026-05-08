import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Navigation.css';

function Navigation() {
  const navigate = useNavigate();
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const token = localStorage.getItem('token');

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/');
    window.location.reload();
  };

  return (
    <nav className="navbar">
      <div className="nav-container">
        <Link to="/" className="nav-logo">
          📷 PhotoShare
        </Link>
        <ul className="nav-menu">
          <li className="nav-item">
            <Link to="/" className="nav-link">Home</Link>
          </li>
          {user.role === 'creator' && token && (
            <li className="nav-item">
              <Link to="/upload" className="nav-link">Upload</Link>
            </li>
          )}
          {token ? (
            <>
              <li className="nav-item">
                <span className="nav-user">{user.username} ({user.role})</span>
              </li>
              <li className="nav-item">
                <button onClick={handleLogout} className="nav-button logout">
                  Logout
                </button>
              </li>
            </>
          ) : (
            <li className="nav-item">
              <Link to="/auth" className="nav-button">Login/Register</Link>
            </li>
          )}
        </ul>
      </div>
    </nav>
  );
}

export default Navigation;
