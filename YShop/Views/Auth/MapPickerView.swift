import SwiftUI
import MapKit
import CoreLocation

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var didUpdateLocation: (CLLocationCoordinate2D) -> Void = { _ in }
    var didFailWithError: (String) -> Void = { _ in }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("✅ [MAP] Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            didUpdateLocation(location.coordinate)
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [MAP] Location error: \(error.localizedDescription)")
        didFailWithError(error.localizedDescription)
    }
}

struct MapPickerView: View {
    @Binding var isPresented: Bool
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var originalCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String = ""
    @State private var isLoadingAddress = false
    @State private var locationManager = CLLocationManager()
    @State private var locationDelegate: LocationManagerDelegate?
    @State private var hasUserSelected = false
    @State private var showPermissionAlert = false
    @State private var lastHapticTime: Date = Date()
    @State private var lastGeocodeTime: Date = Date()
    @State private var isLocationInitialized = false
    let onConfirm: (Double, Double, String) -> Void
    
    var body: some View {
        ZStack {
            // Map (show always once initialized, with loading overlay during location detection)
            if let coordinate = selectedCoordinate {
                Map(position: $position) {
                    Annotation("", coordinate: coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.blue))
                            
                            Triangle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 8)
                                .offset(y: -4)
                        }
                    }
                }
                .mapStyle(.standard)
                .ignoresSafeArea()
                .onMapCameraChange { _ in
                    // Update location when user drags map
                    if hasUserSelected && isLocationInitialized {
                        selectedCoordinate = position.region?.center
                        if let coord = selectedCoordinate {
                            // Haptic feedback on dragging (throttled)
                            let now = Date()
                            if now.timeIntervalSince(lastHapticTime) > 0.2 {
                                HapticManager.shared.selection()
                                lastHapticTime = now
                                reverseGeocode(coordinate: coord)
                            }
                        }
                    }
                }
                
                // Loading overlay during initial location detection
                if !isLocationInitialized {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Detecting your location...")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(.label))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.95))
                }
            } else {
                // Initial loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Getting your location...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(.label))
                    Text("Make sure location permission is enabled")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            
            // UI Overlay
            VStack(spacing: 0) {
                // Top bar with close button
                HStack {
                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        cleanup()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                    
                    Spacer()
                }
                .padding(16)
                
                Spacer()
                
                // Bottom panel with address and buttons
                VStack(spacing: 12) {
                    // Address display
                    if isLoadingAddress {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.75)
                            Text("Detecting location...")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(12)
                    } else if !selectedAddress.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Location")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(Color(.secondaryLabel))
                                .textCase(.uppercase)
                            Text(selectedAddress)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                                .foregroundColor(Color(.label))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    
                    // Buttons row
                    HStack(spacing: 12) {
                        // Return to my location button
                        Button(action: {
                            HapticManager.shared.impact(style: .medium)
                            if let original = originalCoordinate {
                                position = .region(
                                    MKCoordinateRegion(
                                        center: original,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    )
                                )
                                selectedCoordinate = original
                                reverseGeocode(coordinate: original)
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                        
                        // Confirm button
                        PrimaryButton(
                            title: "Confirm",
                            isLoading: false
                        ) {
                            if let coord = selectedCoordinate {
                                print("✅ [MAP] Confirming location: \(coord.latitude), \(coord.longitude), \(selectedAddress)")
                                HapticManager.shared.notification(type: .success)
                                onConfirm(
                                    coord.latitude,
                                    coord.longitude,
                                    selectedAddress
                                )
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    cleanup()
                                    isPresented = false
                                }
                            } else {
                                print("❌ [MAP] Cannot confirm - no coordinate selected")
                            }
                        }
                        .disabled(selectedCoordinate == nil || selectedAddress.isEmpty)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
                )
                .padding(16)
            }
        }
        .alert("Location Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings", action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            Button("Cancel", role: .cancel) {
                isPresented = false
            }
        } message: {
            Text("YSHOP needs location permission to set your delivery address. Please enable 'While Using' location access in Settings.")
        }
        .onAppear {
            print("🗺️ [MAP] MapPickerView appeared - requesting user location")
            setupLocationManager()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupLocationManager() {
        // Create delegate
        let delegate = LocationManagerDelegate()
        self.locationDelegate = delegate
        
        // Setup delegate callbacks
        delegate.didUpdateLocation = { coordinate in
            DispatchQueue.main.async {
                // Only process the first location lock
                guard !self.isLocationInitialized else {
                    return
                }
                
                self.selectedCoordinate = coordinate
                self.originalCoordinate = coordinate
                self.isLocationInitialized = true
                self.position = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
                HapticManager.shared.selection()
                self.reverseGeocode(coordinate: coordinate)
                // Stop further updates after we have the initial location
                self.locationManager.stopUpdatingLocation()
            }
        }
        
        delegate.didFailWithError = { error in
            DispatchQueue.main.async {
                print("❌ [MAP] Location request failed: \(error)")
            }
        }
        
        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Check permission status
        let status = locationManager.authorizationStatus
        print("📍 [MAP] Location authorization status: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ [MAP] Permission already granted, starting location update")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ [MAP] Permission denied or restricted")
            showPermissionAlert = true
        case .notDetermined:
            print("⚠️ [MAP] Permission not determined, requesting...")
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func cleanup() {
        print("🧹 [MAP] Cleaning up location manager")
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        locationDelegate = nil
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        // Throttle geocoding requests to max once per 500ms
        let now = Date()
        if now.timeIntervalSince(lastGeocodeTime) < 0.5 {
            return
        }
        
        isLoadingAddress = true
        hasUserSelected = true
        lastGeocodeTime = now
        
        print("🔍 [MAP] Reverse geocoding: \(coordinate.latitude), \(coordinate.longitude)")
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoadingAddress = false
                
                if let error = error {
                    print("❌ [MAP] Geocoding error: \(error.localizedDescription)")
                    selectedAddress = "Location: \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let name = placemark.name {
                        addressComponents.append(name)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let country = placemark.country {
                        addressComponents.append(country)
                    }
                    
                    selectedAddress = addressComponents.joined(separator: ", ")
                    print("✅ [MAP] Address found: \(selectedAddress)")
                } else {
                    selectedAddress = "Location: \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
                    print("⚠️ [MAP] No placemark found, using coordinates")
                }
            }
        }
    }
}

// Helper shape for pin pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    @Previewable @State var isPresented = true
    
    return MapPickerView(
        isPresented: $isPresented,
        onConfirm: { lat, lng, address in
            print("Selected: \(lat), \(lng), \(address)")
        }
    )
}
