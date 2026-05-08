import React from 'react';
import { useParams } from 'react-router-dom';
import { useState, useEffect } from 'react';
import axios from 'axios';
import CommentSection from '../components/CommentSection';
import RatingSection from '../components/RatingSection';
import './PhotoDetailPage.css';

function PhotoDetailPage() {
  const { id } = useParams();
  const [photo, setPhoto] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    const fetchPhoto = async () => {
      try {
        setLoading(true);
        const response = await axios.get(`/api/photos/${id}`);
        if (!cancelled) {
          setPhoto(response.data);
          setError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setError('Failed to load photo');
        }
        console.error(err);
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    fetchPhoto();

    return () => {
      cancelled = true;
    };
  }, [id]);

  if (loading) return <div className="loading">Loading...</div>;
  if (error) return <div className="error">{error}</div>;
  if (!photo) return <div className="error">Photo not found</div>;

  return (
    <div className="photo-detail-page">
      <div className="photo-container">
        <img src={photo.image_url} alt={photo.title} />
        <div className="photo-info">
          <h1>{photo.title}</h1>
          <p className="creator">by {photo.username}</p>
          <p className="caption">{photo.caption}</p>
          {photo.location && <p className="location">📍 {photo.location}</p>}
          {Array.isArray(photo.tags) && photo.tags.length > 0 && (
            <p className="tags">Tagged: {photo.tags.join(', ')}</p>
          )}
        </div>
      </div>

      <RatingSection photoId={id} currentRating={photo.average_rating} />
      <CommentSection photoId={id} />
    </div>
  );
}

export default PhotoDetailPage;
