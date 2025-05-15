import SwiftUI

struct EventDetailLoader: View {
    let eventId: String
    @StateObject private var viewModel = EventDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Neo-punk background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                            .scaleEffect(1.5)
                        
                        Text("LOADING EVENT DETAILS")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.green)
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)
                        
                        Text("ERROR LOADING EVENT")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.pink)
                        
                        Text(error)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            viewModel.fetchEvent(id: eventId)
                        } label: {
                            Text("RETRY")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.pink)
                                .cornerRadius(5)
                        }
                        .padding(.top, 10)
                        
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("RETURN TO NOTIFICATIONS")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                    }
                } else if let event = viewModel.event {
                    // Show the event detail view
                    EventDetailView(event: event)
                } else {
                    // Fallback view - should rarely be seen since viewModel.error should catch most problems
                    Text("No event data available")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            viewModel.fetchEvent(id: eventId)
        }
        .navigationBarBackButtonHidden(viewModel.event != nil)
    }
} 