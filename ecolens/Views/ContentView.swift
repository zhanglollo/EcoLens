import SwiftUI
import UIKit

class DataModel: ObservableObject {
    @Published var image: UIImage?
    @Published var analysisResult = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var name = ""
}

struct ImagePicker: UIViewControllerRepresentable {
    enum SourceType {
        case camera
        case photoLibrary
    }
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    let sourceType: SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType == .camera ? .camera : .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ParsingThing {
    func convert(char: String) -> (String, Color) {
        switch(String(char.prefix(1))) {
        case "1":
            return ("Blue bin", Color.blue)
        case "2":
            return ("Green bin", Color.green)
        case "3":
            return ("Black bin", Color.gray)
        case "4":
            return ("Other", Color.yellow)
        default:
            return ("Error", Color.red)
        }
    }
}

struct ImagePreviewView: View {
    @State private var showAlert = false
    @ObservedObject var dataModel: DataModel
    var thing: ParsingThing
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                Image(uiImage: dataModel.image!)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.95)
                    .cornerRadius(10)
//                    .padding()
            }
            .frame(height: 300)
            
            Button(action: analyzeImage) {
                Text("Analyze Image")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(dataModel.isLoading)
            
            if dataModel.isLoading {
                ProgressView()
            }
            
            if !dataModel.analysisResult.isEmpty {
                VStack {
                    ScrollView {
                        Text(thing.convert(char: dataModel.analysisResult).0)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(thing.convert(char: dataModel.analysisResult).1)
                            .padding()
                            .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                            
//                        Text(dataModel.analysisResult)
//                            .padding()
//                            .background(Color(red: 0.23, green: 0.25, blue: 0.47))
//                            .cornerRadius(10)
                        
                        Text(dataModel.analysisResult.dropFirst(3))
                            .padding()
                            .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                            .cornerRadius(10)
                        Button(action: {
                            showAlert = true
                        }) {
                            HStack {
                                Text(Image(systemName: "exclamationmark.triangle"))
                                Text("Report a Problem")
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                                    .background(Color(red: 0.16, green: 0.17, blue: 0.16))
//                                    .foregroundColor(.white)
//                                    .cornerRadius(8)
                            }.frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.16, green: 0.17, blue: 0.16))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }.alert("Feedback noted", isPresented: $showAlert) {
                            Button("Ok", role: .none) {
                            }
                        } message: {
//                            Text("The operation completed successfully.")
                        }
                    }
                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.3)
                }
            }
        }
        .padding()
    }
    
    private func analyzeImage() {
        guard let image = dataModel.image else {
            dataModel.errorMessage = "Please select an image first"
            dataModel.showError = true
            return
        }
        
        dataModel.isLoading = true
        dataModel.analysisResult = ""
        
        Task {
            do {
                let service = OpenAIVisionService()
                let result = try await service.analyzeImage(
                    image: image,
                    prompt: "Analyze this image and explain how to properly dispose of it according to Canadian recycling guidelines. Identify which bin (black, blue, or green) it should go in and why. If any specific disposing steps are required, take note that we are located in York Region (Ontario, Canada). Do not use formatting (bold, italics, etc.) Before explaining any disposing rules, please state the bin that the item goes into with a single number, 1 for blue, 2 for green, 3 for black. If the item does not belong in any of the bins, instead please state 4. Do not state 4 if the item belongs in the black bin"
                )
                
                await MainActor.run {
                    dataModel.analysisResult = result
                    dataModel.isLoading = false
                }
            } catch {
                await MainActor.run {
                    dataModel.errorMessage = error.localizedDescription
                    dataModel.showError = true
                    dataModel.isLoading = false
                }
            }
        }
    }
}

struct AuthView: View {
    @StateObject var dataModel = DataModel()
    @State private var isLoginView = true
    @State private var email = ""
    @State private var password = ""
    @State private var postalCode = ""
    @State private var householdCount = ""
    @State private var recycleGoal = ""
    @State private var showSignUpSurvey = false
    @State private var showInfoView = false
    
    var body: some View {
        NavigationView {
            if !showSignUpSurvey {
                if isLoginView {
                    loginView
                } else {
                    signUpView
                }
            } else {
                signUpSurveyView
            }
        }
    }
    
    private var loginView: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: PhotoView(), isActive: $showInfoView) {}
            Text("Log in to Ecolens")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.white)
                .padding(.top, 40)
            
            Text("Email Address*")
                .font(.headline)
                .foregroundColor(Color.white)
            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .cornerRadius(8)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            Text("Password*")
                .font(.headline)
                .foregroundColor(Color.white)
            SecureField("Enter your password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .cornerRadius(8)
            
            Button(action: {
                showInfoView = true
            }) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Continue with iCloud")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            Button(action: {
                showInfoView = true
            }) {
                Text("Log in")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.16, green: 0.17, blue: 0.16))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Forgot Password?")
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    isLoginView.toggle()
                }) {
                    Text("Sign up")
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(red: 0.23, green: 0.25, blue: 0.47))
    }
    
    private var signUpView: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: PhotoView(), isActive: $showInfoView) {}
            Text("Join over 2 Canadians")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.white)
                .padding(.top, 40)
            
            Text("Sign up to Ecolens to experience the new era of recycling")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Email Address*")
                .font(.headline)
                .foregroundColor(Color.white)
            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .cornerRadius(8)
            
            Text("Password*")
                .font(.headline)
                .foregroundColor(Color.white)
            SecureField("Enter your password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .cornerRadius(8)
            
            Text("To continue you agree to our Ecolens Customer Terms and Conditions. You may not have any information about your own environment. You can also use your email address or visit our website at www.ecolens.com.")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: {
                showSignUpSurvey = true
            }) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.16, green: 0.17, blue: 0.16))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                Button(action: {
                    isLoginView.toggle()
                }) {
                    Text("Login")
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Forgot Password?")
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(red: 0.23, green: 0.25, blue: 0.47))
    }
    
    private var signUpSurveyView: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: PhotoView(), isActive: $showInfoView) {}
            HStack {
                Button(action: {
                    showSignUpSurvey = false
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                Spacer()
            }
            
            Text("Sign Up Survey")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.white)
            
            Text("Let's get some information")
                .font(.headline)
                .foregroundColor(Color.white)
            Text("We require these to provide the best experience possible")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Name:")
                .font(.headline)
                .foregroundColor(Color.white)
            TextField("Enter your name", text: $dataModel.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Postal Code:")
                .font(.headline)
                .foregroundColor(Color.white)
            TextField("Enter your postal code", text: $postalCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
            
            Text("# of People in Household")
                .font(.headline)
                .foregroundColor(Color.white)
            TextField("Enter number", text: $householdCount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            Text("Recycle Goal:")
                .font(.headline)
                .foregroundColor(Color.white)
            TextField("Enter your recycling goal", text: $recycleGoal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Spacer()
            
            Button(action: {
                showInfoView = true
            }) {
                Text("Finish")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.16, green: 0.17, blue: 0.16))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(red: 0.23, green: 0.25, blue: 0.47))
    }
}

struct PhotoView: View {
    @StateObject private var dataModel = DataModel()
    @State private var showingImagePicker = false
    @State private var imagePickerSourceType: ImagePicker.SourceType?
    @State private var showImageSourceDialog = false
    @State private var showGuide = false
    
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(destination: InfoView(), isActive: $showGuide) {}
                Color(red: 0.34, green: 0.43, blue: 0.71)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Welcome Back!")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                            .cornerRadius(10)
                        
                        if let image = dataModel.image {
                            ImagePreviewView(dataModel: dataModel, thing: ParsingThing())
                        } else {
                            VStack(alignment: .center) {
                                Spacer()
                                    .frame(height: UIScreen.main.bounds.height/3)
                                Text("Take a photo or upload from photo library")
                                    .font(.body)
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.center)
                                    .padding()
//                                    .frame(maxWidth: .infinity)
                                    .frame(width: UIScreen.main.bounds.width/2)
                                    .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                                    .cornerRadius(10)
                            }
                            .position(x: UIScreen.main.bounds.width/2-16)
                        }
                    }
                    .padding()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            showGuide = true
                        }) {
                            Image(systemName: "menucard")
                                .font(.title.weight(.semibold))
                                .frame(width: 60, height: 60)
                                .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                        Spacer().frame(width: UIScreen.main.bounds.width*0.45)
                        Button(action: {
                            showImageSourceDialog = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title.weight(.semibold))
                                .frame(width: 60, height: 60)
                                .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .actionSheet(isPresented: $showImageSourceDialog) {
                ActionSheet(
                    title: Text("Select Image Source"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            imagePickerSourceType = .camera
                            showingImagePicker = true
                        },
                        .default(Text("Choose from Library")) {
                            imagePickerSourceType = .photoLibrary
                            showingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                if let sourceType = imagePickerSourceType {
                    ImagePicker(selectedImage: $dataModel.image, sourceType: sourceType)
                }
            }
            .alert("Error", isPresented: $dataModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(dataModel.errorMessage)
            }
        }
        .navigationBarBackButtonHidden()
    }
}


struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack {
                VStack(alignment: .leading) {
                    Text("Guide")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                        .cornerRadius(10)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("What goes Where?")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("• Throwing away garbage comes in three colours: black, blue, and green bins.")
                        .font(.subheadline)
                        .fontWeight(.regular)
                    Text("• Each bin corresponds to a certain type of garbage which could be thrown away, composted, or recycled.")
                        .font(.subheadline)
                        .fontWeight(.regular)
                    
                }
                .padding()
                .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                .cornerRadius(10)
                .frame(width: UIScreen.main.bounds.width*0.95)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Green bin - Compost")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Acceptable Material: (organic, compostable):")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("• Food scraps\n• Yard Waste\n• Paper products")
                        .font(.subheadline)
                        .fontWeight(.regular)
                    
                    Text("Avoid Composting:")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("• Meat scraps, bones, or animal products (slow to decompose and may attract pests)\n• Dairy, oil, or greasy food (may start to spoil and cause fumes)")
                        .font(.subheadline)
                        .fontWeight(.regular)
                }
                .padding()
                .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                .cornerRadius(10)
                .frame(width: UIScreen.main.bounds.width*0.95)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Black bin - General waste")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text("Acceptable Material: (non-recyclable):                                 ")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("• Non-recyclable plastics\n• Soiled/waxy paper\n• Dirtied materials in general")
                        .font(.subheadline)
                        .fontWeight(.regular)
                    
                    Text("Avoid Throwing: ")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("• Recyclables\n• Organic waste\n• Hazardous waste")
                        .font(.subheadline)
                        .fontWeight(.regular)
                }
                .padding()
                .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                .cornerRadius(10)
                .frame(width: UIScreen.main.bounds.width*0.95)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Blue bin - Recycle")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Acceptable Material: (recyclable):                                ")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("• Paper and cardboard\n• Plastics\n• Metals\n• Glass\nAll items must be clean, flattened, and removed of non-recyclable materials.")
                        .font(.subheadline)
                        .fontWeight(.regular)
                    
                    Text("Avoid Recycling: ")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("• Contaminated items\n• Non-recyclables (garbage or compost)\n• Hazardous waste")
                        .font(.subheadline)
                        .fontWeight(.regular)
                }
                
                /*
                 There are tons of different ways to reuse all kinds of materials, such as clothing that could be donated or reused to create even more clothing! There are lots of DIYs found online as well to reuse, reduce, recycle:

                 https://shopequo.com/blogs/blog/recycling-tips?srsltid=AfmBOop4iGkU0pT1_ManDuvQIUFopssrZVgjyMKw4xf_F2NAtSkOJ9pq
                 */

                .padding()
                .background(Color(red: 0.23, green: 0.25, blue: 0.47))
                .cornerRadius(10)
                .frame(width: UIScreen.main.bounds.width*0.95)
            }
            .padding()
        }
        .background(Color(red: 0.34, green: 0.43, blue: 0.71))
        
//        UINavigationBar.appearance().backIndicatorImage = Image(systemName: "menucard")
//            .font(.title.weight(.semibold))
//            .frame(width: 30, height: 30)
//            .background(Color(red: 0.23, green: 0.25, blue: 0.47))
//            .foregroundColor(.white)
//            .clipShape(Circle())
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            AuthView()
            
//                .previewDisplayName("Auth View")
            PhotoView()
//            InfoView()
//                .previewDisplayName("Recycling Info")
        }
    }
}



