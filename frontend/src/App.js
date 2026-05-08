import React from 'react';
import './App.css';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navigation from './components/Navigation';
import HomePage from './pages/HomePage';
import AuthPage from './pages/AuthPage';
import PhotoDetailPage from './pages/PhotoDetailPage';
import CreatorUploadPage from './pages/CreatorUploadPage';

function App() {
  return (
    <Router>
      <Navigation />
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/auth" element={<AuthPage />} />
        <Route path="/photo/:id" element={<PhotoDetailPage />} />
        <Route path="/upload" element={<CreatorUploadPage />} />
      </Routes>
    </Router>
  );
}

export default App;
