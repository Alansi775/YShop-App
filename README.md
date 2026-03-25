# YShop - Advanced E-Commerce Platform with AI & Autonomous Drone Delivery

A next-generation e-commerce ecosystem combining native iOS development (SwiftUI), Flutter, AI-powered product verification, and autonomous drone delivery via Pixhawk technology.

![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Flutter-blue?style=flat-square)
![Version](https://img.shields.io/badge/Version-2.0-blue?style=flat-square)

---

## Overview

YShop is a comprehensive e-commerce platform designed for the modern digital marketplace. The platform features dual mobile applications (iOS with SwiftUI and Flutter), intelligent AI-based product compliance, real-time store browsing with smart polling, and innovative autonomous drone delivery systems.

Current development focus is on native iOS implementation with SwiftUI, featuring real-time store data synchronization and seamless multi-vendor integration.

---

## Core Features

### Customer Features
- Multi-platform access via iOS (SwiftUI) and Flutter applications
- Smart store discovery with dynamic category browsing (Food, Pharmacy, Clothes, Markets)
- Real-time store status updates via intelligent polling mechanism
- Responsive user interface with adaptive dark and light mode support
- Secure authentication using JWT tokens with Keychain encryption
- AI-assisted search and recommendations

### Store Owner Features
- Comprehensive store management dashboard with creation and editing capabilities
- Product catalog management with image uploads and descriptions
- Real-time inventory tracking and stock management
- Order processing and fulfillment tracking
- Performance analytics and sales metrics

### Intelligence & Automation
- CNN-based product verification for automatic compliance checking
- Intelligent content moderation to maintain platform standards
- AI chatbot assistance for customer support
- Computer vision integration for image analysis

### Autonomous Delivery
- Pixhawk-controlled autonomous drones for last-mile delivery
- Real-time GPS tracking and order status updates
- Intelligent route optimization and scheduling
- Safety protocols including obstacle avoidance and emergency systems

---

## Architecture

### Frontend - iOS (SwiftUI)

```
YShop-App/
├── Views/
│   ├── Auth/ (Login and signup flows)
│   ├── Home/ (Hero carousel and category browsing)
│   └── CategoryStoresView.swift (Real-time store grid with polling)
├── Services/
│   ├── StoreService.swift (API integration for store data)
│   ├── StoreUpdateService.swift (Smart polling implementation)
│   ├── AuthService.swift (User authentication)
│   └── AIService.swift (ChatGPT integration)
├── Models/
│   ├── Store.swift (Store data model with mutable status)
│   ├── User.swift (User authentication model)
│   └── Product.swift (Product catalog model)
└── Core/ (Utilities, theme, and networking)
```

Technology Stack: SwiftUI, Combine framework, URLSession, Keychain Security

### Frontend - Flutter

Full feature parity with iOS implementation using Material Design 3 and state management with Provider/Riverpod patterns.

### Backend Architecture

```
Node.js + Express
├── Routes/
│   ├── /api/v1/auth/* (User authentication endpoints)
│   ├── /api/v1/stores/* (Store management endpoints)
│   ├── /api/v1/products/* (Product catalog endpoints)
│   └── /api/v1/stores/updates-since/:timestamp (Real-time update polling)
├── Controllers/ (Business logic implementation)
├── Models/ (MySQL data models)
└── Middleware/ (Authentication, validation, error handling)
```

Infrastructure: MySQL database, Firebase integration, AWS S3 for media storage, Gmail API for email services, OpenAI API for AI features

---

## Screenshots and Demonstrations

Complete design documentation and screenshots available in the project design system:
[YShop Design & Implementation - Notion](https://slender-forsythia-e75.notion.site/YShop-E-Commerce-APP-172883fb9e358081adb7d402501eac5f)

The Notion workspace includes:
- iOS interface mockups and final implementations
- Flutter application screenshots
- Component library (liquid glass, navigation, cards)
- User flow documentation
- Accessibility guidelines

---

## Drone Delivery System

YShop implements a proprietary autonomous delivery network utilizing Pixhawk flight controllers and advanced autonomous navigation algorithms.

### System Capabilities
- Autonomous GPS-guided delivery to customer locations
- Real-time order tracking and status updates
- Weather-aware flight planning and execution
- Collision avoidance and obstacle detection systems
- Scheduled delivery windows with traffic optimization

### References
Drone Delivery System Overview: https://www.youtube.com/watch?v=G9KZVz2MjMk

OpenCV Computer Vision Integration: https://www.youtube.com/watch?v=9puBDk01-_s

---

## Technology Requirements

### iOS Development

- iOS 14.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later
- SwiftUI framework
- URLSession for HTTP networking
- Keychain Services for secure storage

### Backend Requirements

- Node.js 16 or later
- MySQL 8.0 or later
- Firebase account for authentication
- AWS S3 credentials for media storage
- OpenAI API key for AI features

---

## Setup and Installation

### iOS Development Setup

```bash
git clone https://github.com/yourusername/YShop-App.git
cd YShop-App

# Open Xcode project
open YShop.xcodeproj

# Update backend URL in YShop/Core/Network/APIClient.swift
# Configure for your local development environment
```

### Backend Development Setup

```bash
cd YshopProjectFlutter/backend

npm install

# Create .env file with configuration
cp .env.example .env

# Configure MySQL credentials and API keys in .env
npm run dev

# Server starts on http://localhost:3000
```

---

## Development Status

### Completed (v2.0)
- Authentication system with JWT tokens and Keychain storage
- Home screen with hero carousel featuring 4 rotating products
- Category filtering with dynamic store discovery
- Store listing grid with responsive layout
- Real-time store updates via smart polling mechanism
- Fully adaptive UI with dark and light mode support
- Database seeding with 7+ demonstration stores
- Public API endpoints for store data retrieval

### In Development
- Product detail views and advanced filtering
- Shopping cart implementation and management
- Checkout flow with payment gateway integration
- User profile management and preferences
- Order history and delivery tracking interface

### Planned Features
- Complete add-to-cart functionality
- Payment processing (Visa, Apple Pay, OneCash)
- Advanced product search and recommendations
- Store owner dashboard and analytics
- Product compliance verification UI
- Drone delivery integration and real-time tracking
- Multi-language localization (Arabic, English)

---

## Security Implementation

- JWT-based authentication with secure token management
- Keychain integration for encrypted credential storage
- HTTPS/TLS encryption for all API communications
- Role-based access control (Customer, Store Owner, Administrator)
- Automated content moderation via AI systems
- Input validation and SQL injection prevention

---

## Real-Time Update Architecture

YShop implements an efficient smart polling system for store data updates without requiring WebSocket connections. This architecture supports over 1 million concurrent users with minimal server overhead.

### Update Flow

```
Client Poll Request (30-second interval)
    ↓
GET /stores/updates-since/:timestamp?type=Food
    ↓
Server Query: WHERE updated_at > timestamp
    ↓
Response: {id, name, status, updated_at}
    ↓
Client applies updates to local store objects
```

This lightweight approach eliminates the need for persistent connections while maintaining near real-time data consistency across the platform.

---

## Contributing

Contributions are welcome through the standard GitHub workflow:

1. Fork the repository
2. Create a feature branch (git checkout -b feature/improvement)
3. Commit changes (git commit -m 'Add improvement')
4. Push to branch (git push origin feature/improvement)
5. Open a Pull Request

Ensure code follows Swift style guidelines and includes appropriate error handling and testing.

---

## Support and Documentation

Technical documentation: [YShop Project Documentation](https://slender-forsythia-e75.notion.site/YShop-E-Commerce-APP-172883fb9e358081adb7d402501eac5f)

---

## Project Vision

YShop represents a comprehensive approach to modern e-commerce by integrating three core technologies:

1. Native Mobile Development - Optimized user experience across iOS and Flutter
2. Artificial Intelligence - Automated compliance, content verification, and personalization
3. Autonomous Systems - Same-day delivery via intelligent drone networks

This combination creates a platform that is faster, more intelligent, and more accessible than traditional e-commerce solutions.

---

Made by the YShop Development Team
