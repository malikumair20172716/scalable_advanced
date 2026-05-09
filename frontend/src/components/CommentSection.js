import React, { useState, useEffect, useCallback } from 'react';
import api from '../api';
import { useAuth } from '../context/AuthContext';
import { useToast } from './Toast';
import './CommentSection.css';

function CommentSection({ photoId }) {
  const [comments, setComments] = useState([]);
  const [newComment, setNewComment] = useState('');
  const [loading, setLoading] = useState(false);
  const { isAuthenticated, user } = useAuth();
  const toast = useToast();

  const fetchComments = useCallback(async () => {
    try {
      const response = await api.get(`/photos/${photoId}/comments`);
      setComments(response.data.comments || []);
    } catch (err) {
      console.error('Failed to fetch comments', err);
    }
  }, [photoId]);

  useEffect(() => {
    fetchComments();
  }, [fetchComments]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    setLoading(true);
    try {
      await api.post(`/photos/${photoId}/comments`, { content: newComment });
      setNewComment('');
      toast.success('Comment posted!');
      fetchComments();
    } catch (err) {
      toast.error('Failed to post comment.');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (commentId) => {
    if (!window.confirm('Delete this comment?')) return;
    
    try {
      await api.delete(`/photos/${photoId}/comments/${commentId}`);
      toast.success('Comment deleted');
      fetchComments();
    } catch (err) {
      toast.error('Failed to delete comment.');
    }
  };

  return (
    <div className="comment-section">
      <h3>Comments ({comments.length})</h3>

      {isAuthenticated ? (
        <form onSubmit={handleSubmit} className="comment-form">
          <textarea
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            placeholder="Write a comment..."
            required
          />
          <button type="submit" disabled={loading || !newComment.trim()}>
            {loading ? 'Posting...' : 'Post Comment'}
          </button>
        </form>
      ) : (
        <p className="login-prompt">
          <a href="/auth">Log in</a> to leave a comment.
        </p>
      )}

      <div className="comments-list">
        {comments.length > 0 ? (
          comments.map((comment) => (
            <div key={comment.id} className="comment-item">
              <div className="comment-header">
                <div className="comment-user">
                  <div className="mini-avatar">
                    {comment.username?.[0]?.toUpperCase()}
                  </div>
                  <strong>{comment.username}</strong>
                </div>
                <div className="comment-actions">
                  <span className="comment-date">
                    {new Date(comment.created_at).toLocaleDateString()}
                  </span>
                  {user?.id === comment.user_id && (
                    <button 
                      className="delete-comment-btn" 
                      onClick={() => handleDelete(comment.id)}
                      title="Delete comment"
                    >
                      🗑️
                    </button>
                  )}
                </div>
              </div>
              <div className="comment-content">
                <p>{comment.content}</p>
              </div>
            </div>
          ))
        ) : (
          <p className="no-comments">No comments yet. Be the first!</p>
        )}
      </div>
    </div>
  );
}

export default CommentSection;
