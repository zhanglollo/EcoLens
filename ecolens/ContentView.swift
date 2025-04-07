//
//  ContentView.swift
//  ecolens
//
//  Created by Litong Zhang on 2025-04-07.
//

import SwiftUI

    
struct ContentView: View {
    @State var isLoggedIn = false
    @State var loggingIn = false
    @State var signUp1 = false
    @State var signingUp = false
    
    @State var email: String = ""
    @State var Password: String = ""
    @State var name: String = ""
    @State var postalCode: String = ""
    
    var body: some View {
        NavigationView {
            WelcomeView()
        }
    }
}

extension View{
    
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

struct WelcomeView: View {
    @State var isLoggedIn = false
    @State var loggingIn = false
    @State var signingUp = false
    
    var body: some View {
        VStack(alignment: .center) {
            Text("ecolens")
            Image("logo")
            NavigationLink(destination: MainView(), isActive: $isLoggedIn) {}
            NavigationLink(destination: LoginView(), isActive: $loggingIn) {}
            NavigationLink(destination: SignUpView(), isActive: $signingUp) {}
            VStack {
                Button(action: {
                    isLoggedIn = true
                }) { HStack{Image("icloudicon")
                        Text("Continue With iCloud")}}.background(Color(red: 0.4, green: 0.4, blue: 0.4)).cornerRadius(10)
                Button("Log in") {
                    loggingIn = true
                }.background(Color(red: 0.4, green: 0.4, blue: 0.4)).cornerRadius(10)
                Button("Sign up") {
                    signingUp = true
                }
            }.frame(width: 400.0, height: 200.0).background(Color(red: 0.2, green: 0.2, blue: 0.2)).cornerRadius(15)
        }
    }
}

struct LoginView: View {
    @State var isLoggedIn = false
    @State var email: String = ""
    @State var Password: String = ""
    
    var body: some View {
        NavigationLink(destination: MainView(), isActive: $isLoggedIn) {}
        VStack {
            Text("Welcome back!")
                
            TextField("Email Address*", text: $email)
                .padding(.all)
                
            TextField("Password*", text: $Password)
                .padding(.all)
        }
        Button("Log in") {
            isLoggedIn = true
        }
    }
}

struct SignUpView: View {
    @State var signUp1 = false
    
    @State var email: String = ""
    @State var password: String = ""
    
    var body: some View {
        NavigationLink(destination: DataView(), isActive: $signUp1) {}
        VStack {
            Text("Join over 2 Canadians!")
            Text("Sign up to Ecolens to experience the new era of recycling")
            
            TextField("Email Address", text: $email)
                .padding(.all)
                
            TextField("Password", text: $password)
                .padding(.all)
            
            Text("By continuing, you agree to the EcoLens Platform Terms & Conditions, and Privacy Policy. Your agreement provides implied consent to receive marketing communications from EcoLens, some of which are powered by third-party partners, but you can opt out of marketing communications any time.")
        }
        Button("Continue") {
            signUp1 = true
        }
    }
}

struct DataView: View {
    @State var isLoggedIn = false
    
    @State var name: String = ""
    @State var postalCode: String = ""
    @State var blank: String = ""
    
    var body: some View {
        NavigationLink(destination: MainView(), isActive: $isLoggedIn) {}
        VStack {
            Text("Let's get some more information")
            Text("We use these to provide the best experience possible")
            
            TextField("Name", text: $name)
                .padding(.all)
                
            TextField("Postal code", text: $postalCode)
                .padding(.all)
            
            TextField("# of people in household", text: $blank)
                .padding(.all)
                
            TextField("Recycling goal", text: $blank)
                .padding(.all)
        }
        Button("Finish") {
            isLoggedIn = true
        }
    }
}

struct MainView: View {
    var body: some View {
        
    }
}

#Preview {
    ContentView()
}
