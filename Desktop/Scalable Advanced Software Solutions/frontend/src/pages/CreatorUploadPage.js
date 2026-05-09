import React, { useState } from 'react';
import axios from 'axios';
import './CreatorUploadPage.css';

function CreatorUploadPage() {
  const [formData, setFormData] = useState({
    title: '',
    caption: '',
    location: '',
    image_url: '',
    tags: ''
  });
  const [photoFile, setPhotoFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);
  const [error, setError] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setPhotoFile(file);
      
      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        setPreview(e.target.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const token = localStorage.getItem('token');
      if (!token) {
        setError('Please login first');
        return;
      }

      if (!formData.title) {
        setError('Title is required');
        return;
      }

      if (!photoFile && !formData.image_url) {
        setError('Please upload a photo or provide an image URL');
        return;
      }

      const tagsArray = formData.tags
        .split(',')
        .map((t) => t.trim())
        .filter(Boolean);

      // Use FormData for multipart/form-data
      const uploadData = new FormData();
      uploadData.append('title', formData.title);
      uploadData.append('caption', formData.caption);
      uploadData.append('location', formData.location);
      if (formData.image_url) {
        uploadData.append('image_url', formData.image_url);
      }
      if (photoFile) {
        uploadData.append('photo_file', photoFile);
      }
      if (tagsArray.length > 0) {
        tagsArray.forEach((tag, index) => {
          uploadData.append(`tags[${index}]`, tag);
        });
      }

      await axios.post('/api/photos', uploadData, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'multipart/form-data'
        }
      });

      setMessage('Photo uploaded successfully!');
      setFormData({ title: '', caption: '', location: '', image_url: '', tags: '' });
      setPhotoFile(null);
      setPreview(null);
    } catch (err) {
      setError(err.response?.data?.message || 'Upload failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="upload-page">
      <h2>Upload Photo</h2>
      
      {message && <div className="success-message">{message}</div>}
      {error && <div className="error-message">{error}</div>}

      <form onSubmit={handleSubmit} className="upload-form">
        <input
          type="text"
          name="title"
          placeholder="Photo Title"
          value={formData.title}
          onChange={handleChange}
          required
        />
        <textarea
          name="caption"
          placeholder="Photo Caption"
          value={formData.caption}
          onChange={handleChange}
          rows="4"
        />
        <input
          type="text"
          name="location"
          placeholder="Location"
          value={formData.location}
          onChange={handleChange}
        />
        
        <div className="upload-section">
          <h3>Upload Photo File or Provide URL</h3>
          
          <div className="file-upload">
            <input
              type="file"
              id="photo-file"
              accept="image/*"
              onChange={handleFileChange}
            />
            <label htmlFor="photo-file" className="file-label">
              {photoFile ? `Selected: ${photoFile.name}` : 'Choose photo file (JPG, PNG, GIF, WebP)'}
            </label>
          </div>

          {preview && (
            <div className="preview-container">
              <p>Preview:</p>
              <img src={preview} alt="Preview" className="preview-image" />
              <button type="button" onClick={() => { setPhotoFile(null); setPreview(null); }}>
                Remove file
              </button>
            </div>
          )}

          <p className="or-text">OR</p>

          <input
            type="url"
            name="image_url"
            placeholder="Image URL"
            value={formData.image_url}
            onChange={handleChange}
          />
        </div>

        <input
          type="text"
          name="tags"
          placeholder="People tags (comma separated)"
          value={formData.tags}
          onChange={handleChange}
        />
        <button type="submit" disabled={loading}>
          {loading ? 'Uploading...' : 'Upload Photo'}
        </button>
      </form>
    </div>
  );
}

export default CreatorUploadPage;
