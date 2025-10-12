//
//  InternetConnectivityView.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 12/10/25.
//

import SwiftUI
import Network

struct InternetConnectivityWrapperView: View {
     @StateObject private var monitor = NetworkMonitor()
     var body: some View {
        InternetConnectivityView()
             .environment(\.isNetworkConnected, monitor.isNetworkConnected)
             .environment(\.connectionType, monitor.connectionType)
     }
}

struct InternetConnectivityView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    @Environment(\.connectionType) private var connectionType
    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    Text( (isConnected ?? false) ? "Connected" : "No Internet")
                }
                
                if let connectionType {
                    Section("Type")  {
                        Text(String(describing: connectionType).capitalized)
                    }
                }
            }
            .navigationTitle("Network Connectivity")
        }
        .sheet(isPresented: .constant((isConnected ?? true))) {
            NoINternetConnectionView()
                .presentationDetents([.height(310)])
                .presentationCornerRadius(0)
                .presentationBackgroundInteraction(.disabled)
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    InternetConnectivityWrapperView()
}

struct NoINternetConnectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 80, weight: .semibold))
                .frame(height: 100)
            
            Text("No Internet Connection")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Please check your internet connection and try again.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .lineLimit(2)

            Text("Waiting for Internet...")
                .font(.caption)
                .foregroundColor(Color.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.primary)
                .padding(.top, 10)
                .padding(.horizontal, -20)
        }
        .fontDesign(.rounded)
        .padding([.horizontal, .top], 20)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .frame(height: 310)
    }
}

         

extension EnvironmentValues {
    @Entry var isNetworkConnected: Bool?
    @Entry var connectionType: NWInterface.InterfaceType?
}



class NetworkMonitor: ObservableObject  {
    
    @Published var isNetworkConnected: Bool?
    @Published var connectionType: NWInterface.InterfaceType?
    
    
    private var queue = DispatchQueue(label: "NetworkMonitor")
    private var monitor: NWPathMonitor = .init()
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                
                self.isNetworkConnected = path.status == .satisfied
                let type : [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet, .loopback]
                
                if let type = type.first(where: { path.usesInterfaceType($0) }) {
                    self.connectionType = type
                } else {
                    self.connectionType = nil
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
}


