import React, { useState } from 'react';
import api from '../api';
import { useToast } from '../components/Toast';
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
  const toast = useToast();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        toast.error('File size too large. Max 5MB.');
        return;
      }
      setPhotoFile(file);
      const reader = new FileReader();
      reader.onload = (e) => setPreview(e.target.result);
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (!formData.title) {
        toast.error('Title is required');
        return;
      }

      if (!photoFile && !formData.image_url) {
        toast.error('Please upload a photo or provide an image URL');
        return;
      }

      const tagsArray = formData.tags
        .split(',')
        .map((t) => t.trim())
        .filter(Boolean);

      const uploadData = new FormData();
      uploadData.append('title', formData.title);
      uploadData.append('caption', formData.caption);
      uploadData.append('location', formData.location);
      
      if (formData.image_url) uploadData.append('image_url', formData.image_url);
      if (photoFile) uploadData.append('photo_file', photoFile);
      
      if (tagsArray.length > 0) {
        tagsArray.forEach((tag, index) => {
          uploadData.append(`tags[${index}]`, tag);
        });
      }

      await api.post('/photos', uploadData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      toast.success('Awesome! Your photo is now live.');
      setFormData({ title: '', caption: '', location: '', image_url: '', tags: '' });
      setPhotoFile(null);
      setPreview(null);
    } catch (err) {
      toast.error(err.response?.data?.message || 'Upload failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="upload-page page-enter">
      <div className="container">
        <div className="upload-container">
          <div className="upload-header">
            <h2>Share Your Masterpiece</h2>
            <p>Upload your high-quality photos and reach our global community.</p>
          </div>

          <form onSubmit={handleSubmit} className="upload-main-form">
            <div className="upload-grid">
              <div className="upload-fields">
                <div className="form-group">
                  <label>Title <span className="required">*</span></label>
                  <input
                    type="text"
                    name="title"
                    placeholder="E.g. Sunset in Bali"
                    value={formData.title}
                    onChange={handleChange}
                    required
                  />
                </div>

                <div className="form-group">
                  <label>Caption</label>
                  <textarea
                    name="caption"
                    placeholder="Tell the story behind this photo..."
                    value={formData.caption}
                    onChange={handleChange}
                    rows="4"
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Location</label>
                    <input
                      type="text"
                      name="location"
                      placeholder="City, Country"
                      value={formData.location}
                      onChange={handleChange}
                    />
                  </div>
                  <div className="form-group">
                    <label>People Tags</label>
                    <input
                      type="text"
                      name="tags"
                      placeholder="Alex, Sarah (comma separated)"
                      value={formData.tags}
                      onChange={handleChange}
                    />
                  </div>
                </div>
              </div>

              <div className="upload-media">
                <div className="media-selector">
                  <div className={`dropzone ${photoFile ? 'has-file' : ''}`}>
                    <input
                      type="file"
                      id="photo-file"
                      accept="image/*"
                      onChange={handleFileChange}
                    />
                    <label htmlFor="photo-file">
                      {preview ? (
                        <div className="preview-wrap">
                          <img src={preview} alt="Preview" />
                          <div className="preview-overlay">Change Photo</div>
                        </div>
                      ) : (
                        <div className="upload-placeholder">
                          <span className="upload-icon">📁</span>
                          <strong>Click to upload</strong>
                          <span>or drag and drop</span>
                          <small>JPG, PNG, WebP (Max 5MB)</small>
                        </div>
                      )}
                    </label>
                  </div>

                  <div className="url-separator">
                    <span>OR</span>
                  </div>

                  <div className="form-group">
                    <label>Image URL</label>
                    <input
                      type="url"
                      name="image_url"
                      placeholder="https://example.com/image.jpg"
                      value={formData.image_url}
                      onChange={handleChange}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="upload-actions">
              <button type="submit" className="upload-submit-btn" disabled={loading}>
                {loading ? 'Publishing...' : 'Publish Photo'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

export default CreatorUploadPage;
