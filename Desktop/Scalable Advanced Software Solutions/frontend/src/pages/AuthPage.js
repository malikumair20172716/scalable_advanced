import React, { useState } from 'react';
import './AuthPage.css';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

function AuthPage() {
  const [isLogin, setIsLogin] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    full_name: '',
    role: 'consumer'
  });
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const endpoint = isLogin ? '/api/auth/login' : '/api/auth/register';
      const data = isLogin 
        ? { email: formData.email, password: formData.password }
        : formData;

      const response = await axios.post(endpoint, data);
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('user', JSON.stringify(response.data.user));
      setShowSuccess(true);
      setTimeout(() => navigate('/'), 650);
    } catch (err) {
      setError(err.response?.data?.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };


  return (
    <div className="auth-page">
      {showSuccess && <div className="auth-success">✓ Success! Redirecting...</div>}
      <div className="auth-card">
        <div className="auth-left">
          <h2>{isLogin ? 'Welcome Back' : 'Create Account'}</h2>
          {error && <div className="error-message">{error}</div>}

          <form onSubmit={handleSubmit}>
            {!isLogin && (
              <>
                <div className="form-group">
                  <input
                    type="text"
                    name="username"
                    placeholder="Username"
                    value={formData.username}
                    onChange={handleChange}
                    required
                  />
                </div>
                <div className="form-group">
                  <input
                    type="text"
                    name="full_name"
                    placeholder="Full Name"
                    value={formData.full_name}
                    onChange={handleChange}
                  />
                </div>
              </>
            )}

            <div className="form-group">
              <label>Account Type</label>
              <select 
                name="role" 
                value={formData.role} 
                onChange={handleChange}
                className="account-type-select"
              >
                <option value="consumer">Consumer</option>
                <option value="creator">Creator</option>
              </select>
            </div>

            <div className="form-group">
              <input
                type="email"
                name="email"
                placeholder="Email"
                value={formData.email}
                onChange={handleChange}
                required
              />
              {!isLogin && (
                <div className="field-hint">Enter a valid email address</div>
              )}
            </div>

            <div className="form-group">
              <div className="password-row">
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  placeholder="Password"
                  value={formData.password}
                  onChange={handleChange}
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label="Toggle password visibility"
                >
                  {showPassword ? '👁️' : '👁️‍🗨️'}
                </button>
              </div>
              {!isLogin && (
                <div className="field-hint">At least 8 characters recommended</div>
              )}
            </div>

            <button type="submit" disabled={loading} className="auth-submit">
              {loading ? 'Loading...' : (isLogin ? 'Login' : 'Register')}
            </button>
          </form>

          <p className="auth-toggle">
            {isLogin ? "Don't have an account? " : 'Already have an account? '}
            <button
              type="button"
              onClick={() => {
                setIsLogin(!isLogin);
                setError(null);
              }}
              className="toggle-link"
            >
              {isLogin ? 'Register' : 'Login'}
            </button>
          </p>
        </div>

        <div className="auth-right">
          <img 
            src="https://images.unsplash.com/photo-1611532736579-6b16e2b50449?w=600&h=600&fit=crop" 
            alt="PhotoShare community" 
            className="auth-illustration" 
            onError={(e) => {
              e.target.src = 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=600&h=600&fit=crop';
            }}
          />
          <div className="auth-promo">
            <h3>Share Your Moments</h3>
            <p>Connect, discover, and inspire with our vibrant community of creators</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default AuthPage;
