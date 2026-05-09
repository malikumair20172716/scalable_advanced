import React from 'react';
import { Link } from 'react-router-dom';
import './PhotoCard.css';

function PhotoCard({ photo }) {
  const ratingNumber = Number(photo?.average_rating);
  const ratingText = Number.isFinite(ratingNumber) ? ratingNumber.toFixed(1) : 'N/A';

  return (
    <Link to={`/photo/${photo.id}`} className="photo-card">
      <div className="photo-image">
        <img 
          src={photo.thumbnail_url || photo.image_url} 
          alt={photo.title} 
          loading="lazy"
        />
        {photo.location && (
          <div className="location-badge">
            📍 {photo.location}
          </div>
        )}
        <div className="overlay">
          <div className="stats">
            <span className="stat-item">💬 {photo.comment_count || 0}</span>
            <span className="stat-item">⭐ {ratingText}</span>
          </div>
        </div>
      </div>
      <div className="photo-info">
        <h3>{photo.title}</h3>
        <div className="photo-meta">
          <span className="creator">by {photo.username}</span>
          {photo.caption && <p className="caption-preview">{photo.caption}</p>}
        </div>
      </div>
    </Link>
  );
}

export default PhotoCard;
