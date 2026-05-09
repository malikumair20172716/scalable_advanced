import React, { useState, useEffect } from 'react';
import api from '../api';
import { useAuth } from '../context/AuthContext';
import { useToast } from './Toast';
import './RatingSection.css';

function RatingSection({ photoId, initialRating }) {
  const [rating, setRating] = useState(0);
  const [hover, setHover] = useState(0);
  const [average, setAverage] = useState(Number(initialRating) || 0);
  const [loading, setLoading] = useState(false);
  const { isAuthenticated } = useAuth();
  const toast = useToast();

  useEffect(() => {
    // Fetch user's own rating if authenticated
    if (isAuthenticated) {
      api.get(`/photos/${photoId}/ratings/me`)
        .then(res => {
          if (res.data.rating) setRating(res.data.rating.score);
        })
        .catch(() => {}); // Silently ignore if no rating found
    }
  }, [photoId, isAuthenticated]);

  const handleRating = async (score) => {
    if (!isAuthenticated) {
      toast.info('Please log in to rate this photo.');
      return;
    }

    setLoading(true);
    try {
      const res = await api.post(`/photos/${photoId}/ratings`, { score });
      setRating(score);
      setAverage(res.data.average_rating);
      toast.success('Rating submitted! Thanks.');
    } catch (err) {
      toast.error('Failed to submit rating.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="rating-section">
      <div className="rating-stars">
        {[1, 2, 3, 4, 5].map((star) => (
          <button
            key={star}
            type="button"
            className={`star-btn ${star <= (hover || rating) ? 'active' : ''} ${loading ? 'loading' : ''}`}
            onClick={() => handleRating(star)}
            onMouseEnter={() => setHover(star)}
            onMouseLeave={() => setHover(0)}
            disabled={loading}
          >
            ★
          </button>
        ))}
      </div>
      
      <div className="rating-display">
        <span className="avg-score">{Number(average).toFixed(1)}</span>
        <span className="avg-label">Average Score</span>
      </div>
      
      {isAuthenticated && (
        <p className="user-rating-status">
          {rating > 0 ? `Your rating: ${rating} stars` : 'Tap a star to rate'}
        </p>
      )}
    </div>
  );
}

export default RatingSection;
