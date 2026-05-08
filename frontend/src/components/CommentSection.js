import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './CommentSection.css';

function CommentSection({ photoId }) {
  const [comments, setComments] = useState([]);
  const [newComment, setNewComment] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const token = localStorage.getItem('token');

  useEffect(() => {
    let cancelled = false;

    const fetchComments = async () => {
      try {
        const response = await axios.get(`/api/comments/photo/${photoId}`);
        if (!cancelled) {
          setComments(response.data.comments);
        }
      } catch (err) {
        console.error('Failed to load comments');
      }
    };

    fetchComments();

    return () => {
      cancelled = true;
    };
  }, [photoId]);

  const handleAddComment = async (e) => {
    e.preventDefault();
    if (!token) {
      setError('Please login to comment');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await axios.post(
        '/api/comments',
        { photo_id: photoId, content: newComment },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setComments([response.data, ...comments]);
      setNewComment('');
    } catch (err) {
      setError('Failed to add comment');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="comments-section">
      <h3>Comments</h3>

      {token && (
        <form onSubmit={handleAddComment} className="comment-form">
          {error && <p className="error">{error}</p>}
          <textarea
            placeholder="Add a comment..."
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            required
          />
          <button type="submit" disabled={loading}>
            {loading ? 'Posting...' : 'Post Comment'}
          </button>
        </form>
      )}

      <div className="comments-list">
        {comments.length === 0 ? (
          <p>No comments yet</p>
        ) : (
          comments.map((comment) => (
            <div key={comment.id} className="comment">
              <strong>{comment.username}</strong>
              <p>{comment.content}</p>
              <small>{new Date(comment.created_at).toLocaleDateString()}</small>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default CommentSection;
