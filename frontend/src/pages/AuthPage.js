import React, { useState } from 'react';
import api from '../api';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';
import './AuthPage.css';

function AuthPage() {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    full_name: '',
    role: 'consumer'
  });
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();
  const toast = useToast();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const endpoint = isLogin ? '/auth/login' : '/auth/register';
      const data = isLogin 
        ? { email: formData.email, password: formData.password }
        : formData;

      const response = await api.post(endpoint, data);
      login(response.data.user, response.data.token);
      
      toast.success(isLogin ? 'Welcome back!' : 'Account created successfully!');
      navigate('/');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Authentication failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page page-enter">
      <div className="auth-card">
        <div className="auth-header">
          <div className="auth-logo">📷</div>
          <h2>{isLogin ? 'Welcome Back' : 'Create Account'}</h2>
          <p>{isLogin ? 'Log in to your PhotoShare account' : 'Join our creative community today'}</p>
        </div>

        <form onSubmit={handleSubmit} className="auth-form-content">
          {!isLogin && (
            <div className="form-group">
              <label>Username</label>
              <input
                type="text"
                name="username"
                placeholder="johndoe"
                value={formData.username}
                onChange={handleChange}
                required
              />
            </div>
          )}

          {!isLogin && (
            <div className="form-group">
              <label>Full Name</label>
              <input
                type="text"
                name="full_name"
                placeholder="John Doe"
                value={formData.full_name}
                onChange={handleChange}
              />
            </div>
          )}

          <div className="form-group">
            <label>Email Address</label>
            <input
              type="email"
              name="email"
              placeholder="name@example.com"
              value={formData.email}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-group">
            <label>Password</label>
            <input
              type="password"
              name="password"
              placeholder="••••••••"
              value={formData.password}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-group">
            <label>{isLogin ? 'Login as' : 'Join as'}</label>
            <select name="role" value={formData.role} onChange={handleChange}>
              <option value="consumer">Consumer (Browse & Rate)</option>
              <option value="creator">Creator (Upload Photos)</option>
            </select>
          </div>

          <button type="submit" className="auth-submit-btn" disabled={loading}>
            {loading ? (
              <span className="btn-spinner"></span>
            ) : (
              isLogin ? 'Sign In' : 'Register'
            )}
          </button>
        </form>

        <div className="auth-footer">
          <p>
            {isLogin ? "New to PhotoShare? " : 'Already a member? '}
            <button 
              type="button" 
              onClick={() => setIsLogin(!isLogin)}
              className="auth-toggle-link"
            >
              {isLogin ? 'Sign up now' : 'Sign in'}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}

export default AuthPage;
