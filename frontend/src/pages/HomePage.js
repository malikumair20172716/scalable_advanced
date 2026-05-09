import React, { useState, useEffect, useCallback } from 'react';
import api from '../api';
import PhotoCard from '../components/PhotoCard';
import SkeletonCard from '../components/SkeletonCard';
import { useToast } from '../components/Toast';
import './HomePage.css';

function HomePage() {
  const [photos, setPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [query, setQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const toast = useToast();

  const fetchPhotos = useCallback(async (pageToLoad = page, searchQuery = '') => {
    try {
      setLoading(true);
      const endpoint = searchQuery 
        ? `/photos/search?q=${encodeURIComponent(searchQuery)}`
        : `/photos?page=${pageToLoad}`;
      
      const response = await api.get(endpoint);
      setPhotos(response.data.photos);
    } catch (err) {
      toast.error('Failed to load photos. Please check your connection.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [toast]); // page removed to avoid duplicate fetches

  useEffect(() => {
    if (!isSearching) {
      fetchPhotos(page);
    }
  }, [page, isSearching, fetchPhotos]);

  const handleSearch = async (e) => {
    e.preventDefault();
    const q = query.trim();

    if (q.length === 0) {
      setIsSearching(false);
      setPage(1);
      fetchPhotos(1);
      return;
    }

    if (q.length < 2) {
      toast.info('Search query must be at least 2 characters');
      return;
    }

    setIsSearching(true);
    fetchPhotos(1, q);
  };

  const clearSearch = () => {
    setQuery('');
    setIsSearching(false);
    setPage(1);
    fetchPhotos(1);
  };

  return (
    <div className="home-page page-enter">
      <header className="hero-section">
        <h1>Explore Capturing Moments</h1>
        <p>Discover beautiful stories shared by our creators.</p>
        
        <form onSubmit={handleSearch} className="search-box">
          <div className="search-input-wrapper">
            <span className="search-icon">🔍</span>
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search title, location, or people..."
            />
            {query && (
              <button type="button" className="clear-icon" onClick={clearSearch}>
                ✕
              </button>
            )}
          </div>
          <button type="submit" className="search-button" disabled={loading}>
            Search
          </button>
        </form>
      </header>

      <div className="container">
        {loading && photos.length === 0 ? (
          <div className="photos-grid">
            {[1, 2, 3, 4, 5, 6, 7, 8].map(i => <SkeletonCard key={i} />)}
          </div>
        ) : photos.length > 0 ? (
          <>
            <div className="photos-grid">
              {photos.map((photo) => (
                <PhotoCard key={photo.id} photo={photo} />
              ))}
            </div>
            
            {!isSearching && (
              <div className="pagination">
                <button 
                  onClick={() => setPage(p => Math.max(1, p - 1))} 
                  disabled={page === 1 || loading}
                  className="page-btn"
                >
                  Previous
                </button>
                <span className="page-info">Page <strong>{page}</strong></span>
                <button 
                  onClick={() => setPage(p => p + 1)} 
                  disabled={loading || photos.length < 12}
                  className="page-btn"
                >
                  Next
                </button>
              </div>
            )}
          </>
        ) : !loading && (
          <div className="empty-state">
            <span className="empty-icon">📷</span>
            <h3>No photos found</h3>
            <p>Try a different search or browse the latest uploads.</p>
            {isSearching && (
              <button onClick={clearSearch} className="clear-search-btn">
                Browse All Photos
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default HomePage;
