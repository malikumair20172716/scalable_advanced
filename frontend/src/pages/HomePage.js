import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import PhotoCard from '../components/PhotoCard';
import './HomePage.css';

function HomePage() {
  const [photos, setPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);
  const [query, setQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);

  const fetchPhotos = useCallback(async (pageToLoad = page) => {
    try {
      setLoading(true);
      const response = await axios.get(`/api/photos?page=${pageToLoad}`);
      setPhotos(response.data.photos);
      setError(null);
    } catch (err) {
      setError('Failed to load photos');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    if (isSearching) return;
    fetchPhotos(page);
  }, [page, isSearching, fetchPhotos]);

  const handleSearch = async (e) => {
    e.preventDefault();
    const q = query.trim();

    setError(null);

    if (q.length === 0) {
      setIsSearching(false);
      setPage(1);
      fetchPhotos(1);
      return;
    }

    if (q.length < 2) {
      setError('Search query must be at least 2 characters');
      return;
    }

    try {
      setLoading(true);
      setIsSearching(true);
      const response = await axios.get(`/api/photos/search?q=${encodeURIComponent(q)}`);
      setPhotos(response.data.photos);
      setError(null);
    } catch (err) {
      setError('Failed to search photos');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="home-page">
      <h1>Photo Gallery</h1>
      <form onSubmit={handleSearch} className="search-form">
        <input
          type="text"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            if (error) setError(null);
          }}
          placeholder="Search by title, caption, or location"
        />
        <button type="submit" disabled={loading}>Search</button>
        {isSearching && (
          <button
            type="button"
            onClick={() => {
              setQuery('');
              setIsSearching(false);
              setPage(1);
              fetchPhotos(1);
            }}
            disabled={loading}
          >
            Clear
          </button>
        )}
      </form>

      {error && <div className="error">{error}</div>}
      {loading && <div className="loading">Loading photos...</div>}

      <div className="photos-grid">
        {photos.map((photo) => (
          <PhotoCard key={photo.id} photo={photo} />
        ))}
      </div>
      <div className="pagination">
        <button onClick={() => setPage(Math.max(1, page - 1))} disabled={page === 1}>
          Previous
        </button>
        <span>Page {page}</span>
        <button onClick={() => setPage(page + 1)} disabled={isSearching}>Next</button>
      </div>
    </div>
  );
}

export default HomePage;
