import React from 'react';
import './App.css';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { ToastProvider } from './components/Toast';
import ProtectedRoute from './components/ProtectedRoute';
import Navigation from './components/Navigation';
import HomePage from './pages/HomePage';
import AuthPage from './pages/AuthPage';
import PhotoDetailPage from './pages/PhotoDetailPage';
import CreatorUploadPage from './pages/CreatorUploadPage';

function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <Router>
          <Navigation />
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/auth" element={<AuthPage />} />
            <Route path="/photo/:id" element={<PhotoDetailPage />} />
            <Route
              path="/upload"
              element={
                <ProtectedRoute role="creator">
                  <CreatorUploadPage />
                </ProtectedRoute>
              }
            />
          </Routes>
        </Router>
      </ToastProvider>
    </AuthProvider>
  );
}

export default App;
