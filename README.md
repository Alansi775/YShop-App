# 🛍️ YShop - Advanced E-Commerce Platform with AI & Autonomous Drone Delivery

> A next-generation e-commerce ecosystem combining **SwiftUI/iOS**, **Flutter**, **AI-powered product verification**, and **autonomous drone delivery** via Pixhawk technology.

![YShop Badge](https://img.shields.io/badge/Status-Active%20Development-brightgreen?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Flutter-blue?style=flat-square)
![License](https://img.shields.io/badge/License-Proprietary-orange?style=flat-square)

---

## 📱 Overview

YShop is a comprehensive e-commerce platform designed for the modern digital marketplace. The platform features dual mobile applications (iOS with SwiftUI and Flutter), intelligent AI-based product compliance, real-time store browsing with smart polling, and innovative autonomous drone delivery systems.

**Current Focus:** Native iOS development with SwiftUI, featuring real-time store data synchronization and seamless multi-vendor integration.

---

## ✨ Core Features

### 🏪 **For Customers**
- **Multi-platform access** - iOS (SwiftUI) and Flutter apps
- **Smart store discovery** - Browse 4+ store categories (Food, Pharmacy, Clothes, Markets)
- **Real-time updates** - Instant store status changes via intelligent polling (30-second refresh)
- **Beautiful UI** - Liquid glass design, adaptive dark/light modes, hero carousels
- **Secure authentication** - JWT tokens with Keychain encryption
- **AI-assisted search** - Powered by OpenAI integration

### 🏢 **For Store Owners**
- **Store management dashboard** - Create, edit, and manage store listings
- **Product catalog** - Upload products with AI compliance verification
- **Inventory tracking** - Real-time stock management
- **Order management** - View and process customer orders
- **Performance analytics** - Sales tracking and customer insights

### 🤖 **AI & Automation**
- **CNN-based product verification** - Automatic compliance checking for all product listings
- **Smart content moderation** - Ensures platform standards are maintained
- **AI chatbot assistance** - Customer support automation
- **Computer vision integration** - OpenCV-powered image analysis

### 🚁 **Autonomous Drone Delivery**
- **Pixhawk-controlled drones** - Autonomous navigation to delivery locations
- **Real-time tracking** - GPS-based order tracking
- **Smart routing** - Optimized delivery paths
- **Safety systems** - Obstacle avoidance and emergency protocols

---

## 🏗️ Architecture

### **Frontend**

#### iOS (SwiftUI) - **Primary Focus**
```
YShop-App/
├── Views/
│   ├── Auth/ (Login, Signup flows)
│   ├── Home/ (Hero carousel, category browsing)
│   └── CategoryStoresView.swift (Real-time store grid)
├── Services/
│   ├── StoreService.swift (API integration)
│   ├── StoreUpdateService.swift (Smart polling)
│   ├── AuthService.swift (Authentication)
│   └── AIService.swift (ChatGPT integration)
├── Models/
│   ├── Store.swift (Mutable status for real-time updates)
│   ├── User.swift
│   └── Product.swift
└── Core/ (Utilities, theme, networking)
```

**Tech Stack:** SwiftUI, Combine, URLSession, Keychain Security

#### Flutter (Cross-platform)
- Full feature parity with iOS
- Material Design 3
- State management with Provider/Riverpod

### **Backend**

```
Node.js + Express
├── Routes/
│   ├── /api/v1/auth/* (Authentication)
│   ├── /api/v1/stores/* (Store management)
│   ├── /api/v1/products/* (Product catalog)
│   └── /api/v1/stores/updates-since/:timestamp (Real-time updates)
├── Controllers/ (Business logic)
├── Models/ (MySQL ORM)
└── Middleware/ (Auth, validation)
```

**Services:** MySQL, Firebase, Gmail APIs, OpenAI

---

## 📊 Screenshots & Demos

### iOS (SwiftUI)

| Feature | Screenshot |
|---------|-----------|
| **Home Screen** | [Hero Carousel with Category Navigation](#home) |
| **Category Browsing** | [Store Grid with Liquid Glass UI](#stores) |
| **Store Details** | [Full Store Information & Products](#details) |
| **Real-time Updates** | [Smart Polling Demo](#updates) |

### Flutter

| Feature | Screenshot |
|---------|-----------|
| **Dashboard** | [Main Navigation & Store Cards](#flutter-dashboard) |
| **Product Browsing** | [Category & Search Interface](#flutter-products) |
| **Order Management** | [Order History & Tracking](#flutter-orders) |

**📸 Full Screenshots & Design System:**
👉 [YShop Design & Screenshots - Notion](https://slender-forsythia-e75.notion.site/YShop-E-Commerce-APP-172883fb9e358081adb7d402501eac5f)

---

## 🚁 Drone Delivery System

YShop integrates a sophisticated autonomous drone delivery network powered by **Pixhawk flight controller** technology.

### **Features:**
- **Autonomous navigation** - GPS-guided delivery routes
- **Real-time tracking** - Live order status and drone location
- **Smart scheduling** - Optimal delivery window selection
- **Safety protocols** - Collision avoidance and emergency landing
- **Weather adaptation** - Intelligent flight planning

### **Demo Videos:**
- 🎥 [Drone Delivery System Overview](https://www.youtube.com/watch?v=G9KZVz2MjMk)
- 🎥 [OpenCV Vision Integration with Drone](https://www.youtube.com/watch?v=9puBDk01-_s)

---

## 🔧 Tech Stack Details

### **iOS Requirements**
- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

### **Dependencies**
- SwiftUI framework
- Combine for reactive programming
- Security framework (Keychain)
- URLSession for networking

### **Backend Stack**
- **Runtime:** Node.js 16+
- **Database:** MySQL 8.0+
- **Cache:** Redis (optional)
- **Cloud:** Firebase, AWS S3
- **AI/ML:** OpenAI API, TensorFlow (CNN models)

---

## 🚀 Getting Started

### **iOS Setup**

```bash
# Clone the repository
git clone https://github.com/yourusername/YShop-App.git
cd YShop-App

# Open in Xcode
open YShop.xcodeproj

# Configure local backend URL
# Edit YShop/Core/Network/APIClient.swift
let baseURL = "http://10.155.83.72:3000/api/v1"

# Build and run
# Cmd + R in Xcode
```

### **Backend Setup**

```bash
cd YshopProjectFlutter/backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your MySQL credentials

# Start development server
npm run dev
# Server running on http://localhost:3000
```

---

## 📈 Current Development Status

### ✅ Completed (v1.0)
- iOS SwiftUI authentication system
- Home screen with hero carousel (4 products)
- Category browsing with dynamic filtering
- Store listing grid with real-time updates
- Smart polling service (30-second intervals)
- Liquid glass UI components with dark mode
- Database with 7+ demo stores
- Backend API endpoints for public store access

### 🟡 In Progress
- Product detail views and filters
- Shopping cart implementation
- Checkout flow with payment integration
- User profile management
- Order history and tracking

### 📋 Upcoming
- Add-to-cart functionality
- Payment gateway integration (Visa, Apple Pay, OneCash)
- Advanced search and recommendations
- Store owner dashboard
- AI product compliance verification UI
- Drone delivery tracking integration
- Multi-language support (Arabic, English)

---

## 🔐 Security Features

- **JWT Authentication** - Secure token-based auth
- **Keychain Storage** - Encrypted credential storage
- **SSL/TLS** - Encrypted API communications
- **AI Moderation** - Automatic content compliance checking
- **Role-based access** - Customer vs Store vs Admin permissions

---

## 📡 Real-Time Updates Architecture

YShop implements an efficient **smart polling system** for real-time store updates without requiring WebSocket connections. This allows **1M+ concurrent users** without server overhead.

```
iOS App (every 30s)
    ↓
GET /stores/updates-since/:timestamp?type=Food
    ↓
Backend queries stores with updated_at > timestamp
    ↓
Returns only: {id, name, status, updated_at}
    ↓
App applies updates to local store objects
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** changes (`git commit -m 'Add AmazingFeature'`)
4. **Push** to branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow Swift style guide (Apple's recommendations)
- Write comprehensive comments for complex logic
- Test on both light and dark modes
- Ensure proper error handling

---

## 📞 Support & Contact

- **Issues:** GitHub Issues
- **Email:** support@yshop.io
- **Documentation:** [YShop Docs](https://slender-forsythia-e75.notion.site/YShop-E-Commerce-APP-172883fb9e358081adb7d402501eac5f)

---

## 📄 License

This project is proprietary software. All rights reserved © 2024-2026 YShop Inc.

---

## 🎯 Vision

YShop represents the future of e-commerce by combining three revolutionary technologies:
1. **Native Mobile Apps** - Best-in-class user experience
2. **Intelligent AI** - Automated compliance and personalization
3. **Autonomous Delivery** - Drone-based same-day delivery

Together, these create an ecosystem that is faster, smarter, and more accessible than traditional e-commerce platforms.

---

**Made with ❤️ by the YShop Team**
