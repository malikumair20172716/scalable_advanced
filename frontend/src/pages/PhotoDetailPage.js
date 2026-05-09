import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../api';
import CommentSection from '../components/CommentSection';
import RatingSection from '../components/RatingSection';
import { useToast } from '../components/Toast';
import './PhotoDetailPage.css';

function PhotoDetailPage() {
  const { id } = useParams();
  const [photo, setPhoto] = useState(null);
  const [loading, setLoading] = useState(true);
  const toast = useToast();

  useEffect(() => {
    const fetchPhotoDetails = async () => {
      try {
        setLoading(true);
        const response = await api.get(`/photos/${id}`);
        setPhoto(response.data.photo);
      } catch (err) {
        toast.error('Could not find that photo.');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchPhotoDetails();
  }, [id, toast]);

  if (loading) {
    return (
      <div className="photo-detail-page container loading-state">
        <div className="detail-skeleton">
          <div className="skeleton-media shimmer" />
          <div className="skeleton-content shimmer" />
        </div>
      </div>
    );
  }

  if (!photo) {
    return (
      <div className="photo-detail-page container empty-state">
        <span className="empty-icon">🏜️</span>
        <h3>Photo Not Found</h3>
        <Link to="/" className="back-link">Return to Gallery</Link>
      </div>
    );
  }

  return (
    <div className="photo-detail-page page-enter">
      <div className="container">
        <Link to="/" className="back-nav">← Back to Gallery</Link>
        
        <div className="photo-detail-grid">
          <div className="photo-main-content">
            <div className="photo-frame">
              <img src={photo.image_url} alt={photo.title} />
            </div>
            
            <div className="photo-description-section">
              <h1>{photo.title}</h1>
              <div className="photo-meta-info">
                <span className="meta-item">👤 {photo.username}</span>
                {photo.location && <span className="meta-item">📍 {photo.location}</span>}
                <span className="meta-item">📅 {new Date(photo.created_at).toLocaleDateString()}</span>
              </div>
              
              {photo.caption && (
                <div className="photo-caption">
                  <p>{photo.caption}</p>
                </div>
              )}

              {photo.tags && photo.tags.length > 0 && (
                <div className="photo-tags">
                  {photo.tags.map((tag, index) => (
                    <span key={index} className="tag">#{tag}</span>
                  ))}
                </div>
              )}
            </div>

            <CommentSection photoId={id} />
          </div>

          <aside className="photo-sidebar">
            <div className="sidebar-card rating-card">
              <h3>Community Rating</h3>
              <RatingSection photoId={id} initialRating={photo.average_rating} />
            </div>

            <div className="sidebar-card details-card">
              <h3>Photo Details</h3>
              <ul className="details-list">
                <li><strong>Views</strong> <span>{photo.view_count || 0}</span></li>
                <li><strong>Comments</strong> <span>{photo.comment_count || 0}</span></li>
                <li><strong>Avg. Rating</strong> <span>⭐ {Number(photo.average_rating || 0).toFixed(1)}</span></li>
              </ul>
            </div>
          </aside>
        </div>
      </div>
    </div>
  );
}

export default PhotoDetailPage;
