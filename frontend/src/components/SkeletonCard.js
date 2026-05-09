import React from 'react';
import './SkeletonCard.css';

function SkeletonCard() {
  return (
    <div className="skeleton-card">
      <div className="skeleton-image shimmer" />
      <div className="skeleton-info">
        <div className="skeleton-line skeleton-title shimmer" />
        <div className="skeleton-line skeleton-sub shimmer" />
      </div>
    </div>
  );
}

export default SkeletonCard;
