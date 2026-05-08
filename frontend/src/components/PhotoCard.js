import React from 'react';
import { Link } from 'react-router-dom';
import './PhotoCard.css';

function PhotoCard({ photo }) {
  const ratingNumber = Number(photo?.average_rating);
  const ratingText = Number.isFinite(ratingNumber) ? ratingNumber.toFixed(1) : 'N/A';

  return (
    <Link to={`/photo/${photo.id}`} className="photo-card">
      <div className="photo-image">
        <img src={photo.thumbnail_url || photo.image_url} alt={photo.title} />
        <div className="overlay">
          <p className="comment-count">💬 {photo.comment_count || 0}</p>
          <p className="rating">⭐ {ratingText}</p>
        </div>
      </div>
      <div className="photo-info">
        <h3>{photo.title}</h3>
        <p className="creator">by {photo.username}</p>
      </div>
    </Link>
  );
}

export default PhotoCard;
