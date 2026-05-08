import React, { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import './RatingSection.css';

function RatingSection({ photoId, currentRating }) {
  const [userRating, setUserRating] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const token = localStorage.getItem('token');

  const average = useMemo(() => {
    if (currentRating === null || currentRating === undefined) return null;
    const n = Number(currentRating);
    return Number.isFinite(n) ? n : null;
  }, [currentRating]);

  useEffect(() => {
    const fetchUserRating = async () => {
      if (!token) return;
      try {
        const response = await axios.get(`/api/ratings/photo/${photoId}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        setUserRating(response.data.rating || 0);
      } catch (err) {
        // Non-blocking: rating is optional UX
      }
    };

    fetchUserRating();
  }, [photoId, token]);

  const handleRate = async (rating) => {
    if (!token) {
      alert('Please login to rate');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      await axios.post(
        '/api/ratings',
        { photo_id: Number(photoId), rating_value: rating },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setUserRating(rating);
    } catch (err) {
      console.error('Failed to submit rating');
      setError(err.response?.data?.message || 'Failed to submit rating');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="rating-section">
      <h3>Rate This Photo</h3>
      {error && <p className="error">{error}</p>}
      <div className="rating-stars">
        {[1, 2, 3, 4, 5].map((star) => (
          <button
            key={star}
            className={`star ${userRating >= star ? 'active' : ''}`}
            onClick={() => handleRate(star)}
            disabled={loading}
          >
            ⭐
          </button>
        ))}
      </div>
      {average !== null && (
        <p className="current-rating">Average Rating: {average.toFixed(1)}/5</p>
      )}
    </div>
  );
}

export default RatingSection;
