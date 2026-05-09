/**
 * ================================================================
 * MODERN GLASSMORPHISM DASHBOARD - JAVASCRIPT
 * ================================================================
 * GSAP animations: staggered fade-up entrance effects
 * Smooth, buttery animations with power3.out easing
 * ================================================================
 */

// ================================================================
// DOM READY: Initialize animations on page load
// ================================================================

document.addEventListener('DOMContentLoaded', function() {
    initializeDashboard();
});

/**
 * Initialize the dashboard with GSAP animations
 * Called once on page load
 */
function initializeDashboard() {
    console.log('🎬 Initializing dashboard animations...');
    
    // Animate header with fade-in-down
    animateHeader();
    
    // Animate widgets with staggered entrance effect
    animateWidgetsEntrance();
    
    // Setup interactive micro-interactions
    setupWidgetInteractions();
    
    console.log('✅ Dashboard initialized successfully');
}

/**
 * ================================================================
 * HEADER ANIMATION
 * ================================================================
 * Fade in the header with a subtle downward entrance
 */
function animateHeader() {
    const header = document.querySelector('.dashboard-header');
    
    gsap.from(header, {
        duration: 0.8,
        opacity: 0,
        y: -30,
        ease: 'power3.out'
    });
}

/**
 * ================================================================
 * WIDGET ENTRANCE ANIMATIONS
 * ================================================================
 * Staggered fade-up animation for all widgets with:
 * - Initial position: 30px below (y: 30)
 * - Initial opacity: 0 (fully transparent)
 * - Easing: power3.out for smooth deceleration
 * - Stagger: 0.1s delay between each widget
 */
function animateWidgetsEntrance() {
    const widgets = gsap.utils.toArray('.widget');
    
    console.log(`📊 Animating ${widgets.length} widgets...`);
    
    gsap.from(widgets, {
        duration: 0.65,           // Smooth 650ms animation
        y: 30,                    // Start 30px below
        opacity: 0,               // Fade in from transparent
        ease: 'power3.out',       // Smooth deceleration curve
        stagger: {
            amount: 0.3,          // Total stagger time
            from: 'start'         // Start from first widget
        },
        onComplete: function() {
            console.log('✨ Widget entrance animation complete');
        }
    });
}

/**
 * ================================================================
 * WIDGET INTERACTIVE MICRO-INTERACTIONS
 * ================================================================
 * Enhanced hover and click effects for better user feedback
 */
function setupWidgetInteractions() {
    const widgets = document.querySelectorAll('.widget');
    
    widgets.forEach((widget, index) => {
        // Hover enter effect
        widget.addEventListener('mouseenter', function() {
            // Enhanced glow effect on hover
            gsap.to(this, {
                duration: 0.3,
                boxShadow: '0 16px 48px rgba(102, 126, 234, 0.3), inset 0 1px 2px rgba(255, 255, 255, 0.15)',
                ease: 'power2.out'
            });
        });
        
        // Hover leave effect
        widget.addEventListener('mouseleave', function() {
            // Reset to normal state
            gsap.to(this, {
                duration: 0.3,
                boxShadow: 'inset 0 1px 2px rgba(255, 255, 255, 0.1), 0 8px 24px rgba(0, 0, 0, 0.3)',
                ease: 'power2.out'
            });
        });
        
        // Click ripple effect
        widget.addEventListener('click', function(e) {
            createRippleEffect(e, this);
        });
    });
    
    console.log('🎯 Widget interactions set up');
}

/**
 * ================================================================
 * RIPPLE EFFECT ON WIDGET CLICK
 * ================================================================
 * Creates a smooth ripple animation on click for tactile feedback
 */
function createRippleEffect(event, widget) {
    const rect = widget.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height);
    const x = event.clientX - rect.left - size / 2;
    const y = event.clientY - rect.top - size / 2;
    
    // Create ripple element
    const ripple = document.createElement('div');
    ripple.style.width = ripple.style.height = size + 'px';
    ripple.style.left = x + 'px';
    ripple.style.top = y + 'px';
    ripple.style.position = 'absolute';
    ripple.style.borderRadius = '50%';
    ripple.style.background = 'radial-gradient(circle, rgba(255,255,255,0.5) 0%, transparent 70%)';
    ripple.style.pointerEvents = 'none';
    ripple.style.transform = 'scale(0)';
    
    widget.style.position = 'relative';
    widget.appendChild(ripple);
    
    // Animate ripple
    gsap.to(ripple, {
        duration: 0.6,
        scale: 1,
        opacity: 0,
        ease: 'power2.out',
        onComplete: function() {
            ripple.remove();
        }
    });
}

/**
 * ================================================================
 * CHECKBOX ANIMATION HANDLER
 * ================================================================
 * Smooth animation when checking/unchecking tasks
 */
function setupTaskAnimations() {
    const checkboxes = document.querySelectorAll('.task-item input[type="checkbox"]');
    
    checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', function() {
            const label = this.nextElementSibling;
            
            if (this.checked) {
                gsap.to(label, {
                    duration: 0.3,
                    color: 'var(--text-muted)',
                    ease: 'power2.out'
                });
            } else {
                gsap.to(label, {
                    duration: 0.3,
                    color: 'var(--text-primary)',
                    ease: 'power2.out'
                });
            }
        });
    });
}

/**
 * ================================================================
 * SCROLL-TRIGGERED ANIMATIONS (BONUS)
 * ================================================================
 * Animate widgets as they come into view (requires ScrollTrigger plugin)
 */
function setupScrollAnimations() {
    // This would require GSAP's ScrollTrigger plugin
    // Uncomment if you add: https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrollTrigger.min.js
    
    /*
    gsap.registerPlugin(ScrollTrigger);
    
    const widgets = gsap.utils.toArray('.widget');
    
    widgets.forEach((widget, index) => {
        gsap.from(widget, {
            scrollTrigger: {
                trigger: widget,
                start: 'top 80%',
                end: 'top 20%',
                scrub: 1,
                markers: false
            },
            y: 50,
            opacity: 0,
            ease: 'power3.out',
            duration: 0.8
        });
    });
    */
}

/**
 * ================================================================
 * UTILITY: Animate counter values
 * ================================================================
 * Smoothly count from 0 to target number (for stats widgets)
 */
function animateCounter(element, startValue, endValue, duration = 1) {
    gsap.to(element, {
        textContent: endValue,
        duration: duration,
        snap: { textContent: 1 },
        ease: 'power2.out'
    });
}

/**
 * ================================================================
 * UTILITY: Animate list items entrance
 * ================================================================
 * Stagger animation for notification/task list items
 */
function animateListItems(container) {
    const items = gsap.utils.toArray(`${container} li, ${container} .notification-item`);
    
    gsap.from(items, {
        duration: 0.5,
        y: 20,
        opacity: 0,
        ease: 'power3.out',
        stagger: 0.08
    });
}

/**
 * ================================================================
 * UTILITY: Pulse animation for notifications
 * ================================================================
 * Add a subtle pulsing effect to notification dots
 */
function animateNotificationPulse() {
    const dots = gsap.utils.toArray('.notification-dot');
    
    dots.forEach(dot => {
        gsap.to(dot, {
            duration: 1.5,
            scale: 1.5,
            opacity: 0.5,
            repeat: -1,
            yoyo: true,
            ease: 'sine.inOut'
        });
    });
}

/**
 * ================================================================
 * UTILITY: Floating animation for icons
 * ================================================================
 * Continuous gentle floating effect for widget icons
 */
function animateFloatingIcons() {
    const icons = gsap.utils.toArray('.widget-icon');
    
    icons.forEach((icon, index) => {
        // Each icon has a slightly different animation
        const offset = index * 0.2;
        
        gsap.to(icon, {
            duration: 3 + offset,
            y: -10,
            repeat: -1,
            yoyo: true,
            ease: 'sine.inOut'
        });
    });
}

/**
 * ================================================================
 * UTILITY: Shimmer loading animation
 * ================================================================
 * Apply shimmer effect to loading widgets
 */
function addLoadingShimmer(widget) {
    gsap.to(widget, {
        backgroundPosition: '1000px 0',
        duration: 2,
        repeat: -1,
        ease: 'power1.inOut'
    });
}

/**
 * ================================================================
 * WINDOW RESIZE HANDLER
 * ================================================================
 * Handle responsive adjustments
 */
let resizeTimeout;
window.addEventListener('resize', function() {
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(function() {
        console.log('📐 Window resized - checking responsive layout');
    }, 250);
});

/**
 * ================================================================
 * PERFORMANCE: Use requestAnimationFrame for smooth animations
 * ================================================================
 * GSAP handles this automatically, but here's a helper for custom animations
 */
function smoothScroll(target, duration = 1) {
    gsap.to(window, {
        duration: duration,
        scrollTo: { y: target, autoKill: false },
        ease: 'power3.inOut'
    });
}

/**
 * ================================================================
 * DEBUG MODE: Uncomment to see animation timelines
 * ================================================================
 */
// gsap.globalTimeline.pause(); // Uncomment to pause all animations for debugging

console.log('📦 Dashboard.js loaded - GSAP v' + gsap.version);
