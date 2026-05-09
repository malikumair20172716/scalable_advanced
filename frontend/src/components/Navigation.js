import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Navigation.css';

function Navigation() {
  const { user, token, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();           // Updates context — no page reload needed
    navigate('/auth');
  };

  const isActive = (path) => location.pathname === path;

  return (
    <nav className="navbar">
      <div className="nav-container">
        <Link to="/" className="nav-logo">
          <span className="logo-icon">📷</span>
          PhotoShare
        </Link>

        <ul className="nav-menu">
          <li className="nav-item">
            <Link to="/" className={`nav-link ${isActive('/') ? 'active' : ''}`}>
              Home
            </Link>
          </li>

          {user?.role === 'creator' && token && (
            <li className="nav-item">
              <Link to="/upload" className={`nav-link ${isActive('/upload') ? 'active' : ''}`}>
                Upload
              </Link>
            </li>
          )}

          {token ? (
            <>
              <li className="nav-item">
                <span className="nav-user">
                  <span className="user-avatar">{user?.username?.[0]?.toUpperCase()}</span>
                  {user?.username}
                  <span className="role-badge">{user?.role}</span>
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
              <Link to="/auth" className="nav-button">
                Login / Register
              </Link>
            </li>
          )}
        </ul>
      </div>
    </nav>
  );
}

export default Navigation;
