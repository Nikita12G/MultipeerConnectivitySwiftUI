//
//  ContentView.swift
//  MultipeerConnectivitySwiftUIEx
//
//  Created by Никита Гуляев on 19.08.2024.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @StateObject private var multipeerManager = MultipeerManager()
    @State private var message: String = ""

    var body: some View {
        VStack {
            Text("Multipeer Connectivity Chat")
                .font(.largeTitle)
                .padding()

            Text("Status: \(multipeerManager.connectionStatus)")
                .foregroundColor(multipeerManager.isConnected ? .green : .red)
                .padding()

            List(multipeerManager.receivedMessages, id: \.self) { msg in
                Text(msg)
            }
            .padding()

            HStack {
                TextField("Enter your message", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    multipeerManager.send(message: message)
                    message = ""
                }) {
                    Text("Send")
                        .font(.title)
                        .padding()
                        .background(multipeerManager.isConnected ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!multipeerManager.isConnected)
            }
            .padding()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
