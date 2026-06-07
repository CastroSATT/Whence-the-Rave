import SwiftUI

struct EventDetailLoader: View {
    let eventId: String
    @StateObject private var viewModel = EventDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .scaleEffect(1.5)
                    
                    Text("LOADING EVENT DETAILS")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let event = viewModel.event {
                EventDetailView(event: event)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("No event data available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: eventId) {
            viewModel.fetchEvent(id: eventId)
        }
    }
}
