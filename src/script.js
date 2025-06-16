// DOM Content Loaded Event
document.addEventListener("DOMContentLoaded", () => {
    // Set last updated timestamp
    updateLastModified()
  
    // Initialize smooth scrolling
    initSmoothScrolling()
  
    // Initialize intersection observer for animations
    initScrollAnimations()
  
    // Add click handlers
    initClickHandlers()
  
    console.log("🚀 AWS Static Website loaded successfully!")
  })
  
  // Update last modified date
  function updateLastModified() {
    const lastUpdatedElement = document.getElementById("last-updated")
    if (lastUpdatedElement) {
      const now = new Date()
      lastUpdatedElement.textContent = now.toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      })
    }
  }
  
  // Smooth scrolling for navigation links
  function initSmoothScrolling() {
    const navLinks = document.querySelectorAll('.nav-links a[href^="#"]')
  
    navLinks.forEach((link) => {
      link.addEventListener("click", function (e) {
        e.preventDefault()
  
        const targetId = this.getAttribute("href")
        const targetSection = document.querySelector(targetId)
  
        if (targetSection) {
          const headerHeight = document.querySelector(".header").offsetHeight
          const targetPosition = targetSection.offsetTop - headerHeight - 20
  
          window.scrollTo({
            top: targetPosition,
            behavior: "smooth",
          })
        }
      })
    })
  }
  
  // Intersection Observer for scroll animations
  function initScrollAnimations() {
    const observerOptions = {
      threshold: 0.1,
      rootMargin: "0px 0px -50px 0px",
    }
  
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.style.opacity = "1"
          entry.target.style.transform = "translateY(0)"
        }
      })
    }, observerOptions)
  
    // Observe feature cards
    const featureCards = document.querySelectorAll(".feature-card")
    featureCards.forEach((card, index) => {
      card.style.opacity = "0"
      card.style.transform = "translateY(30px)"
      card.style.transition = `opacity 0.6s ease ${index * 0.1}s, transform 0.6s ease ${index * 0.1}s`
      observer.observe(card)
    })
  }
  
  // Initialize click handlers
  function initClickHandlers() {
    // CTA Button click handler
    const ctaButton = document.querySelector(".cta-button")
    if (ctaButton) {
      ctaButton.addEventListener("click", showFeatures)
    }
  
    // Feature card click handlers
    const featureCards = document.querySelectorAll(".feature-card")
    featureCards.forEach((card) => {
      card.addEventListener("click", function () {
        this.style.transform = "scale(0.95)"
        setTimeout(() => {
          this.style.transform = ""
        }, 150)
      })
    })
  }
  
  // Show features section
  function showFeatures() {
    const featuresSection = document.getElementById("features")
    if (featuresSection) {
      const headerHeight = document.querySelector(".header").offsetHeight
      const targetPosition = featuresSection.offsetTop - headerHeight - 20
  
      window.scrollTo({
        top: targetPosition,
        behavior: "smooth",
      })
    }
  }
  
  // Utility function to check if element is in viewport
  function isInViewport(element) {
    const rect = element.getBoundingClientRect()
    return (
      rect.top >= 0 &&
      rect.left >= 0 &&
      rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
      rect.right <= (window.innerWidth || document.documentElement.clientWidth)
    )
  }
  
  // Add scroll-to-top functionality
  window.addEventListener("scroll", () => {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop
  
    // Add/remove header shadow based on scroll position
    const header = document.querySelector(".header")
    if (scrollTop > 10) {
      header.style.boxShadow = "0 2px 20px rgba(0,0,0,0.15)"
    } else {
      header.style.boxShadow = "0 2px 10px rgba(0,0,0,0.1)"
    }
  })
  
  // Handle window resize
  window.addEventListener("resize", () => {
    // Recalculate any position-dependent elements if needed
    console.log("Window resized to:", window.innerWidth, "x", window.innerHeight)
  })
  
  // Error handling
  window.addEventListener("error", (e) => {
    console.error("JavaScript error occurred:", e.error)
  })
  
  // Performance monitoring
  window.addEventListener("load", () => {
    const loadTime = performance.now()
    console.log(`🚀 Page loaded in ${Math.round(loadTime)}ms`)
  })
  