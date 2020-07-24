//**************************************************************************
// Copyright 2020 Google
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// *****************************************************************************/

import SwiftUI

class contentViewDelegate : ObservableObject {
    @Published var toDisconnect: Bool = false
}


struct SwiftUIClient: View {
    
    @ObservedObject var delegate: contentViewDelegate
    @ObservedObject var viewController: IoTBLEView

    @State var tempMQTT: String = "MQTT Terminal"
    @State var tempData: String = "Temp Data"
    @State var connectedSate : Bool = false
    @State var filename : String = "3973-ripples"
    @State var type:String = "Disconnect from Cloud"
    
    
    var body: some View {
        
        ZStack {
            
            Group {
            Rectangle()
                .fill(Color("Background")).frame(maxWidth:.infinity, maxHeight:.infinity).edgesIgnoringSafeArea(.all)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("Background"))
                .frame(width:300,height: 200)
                .shadow(color: Color("LightShadow"), radius: 8, x: -8, y: -8)
                .shadow(color: Color("DarkShadow"), radius: 8, x: 8, y: 8)
                .offset(x: 0, y: -200)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("Background"))
                .frame(width:300,height: 200)
                .shadow(color: Color("LightShadow"), radius: 8, x: -8, y: -8)
                .shadow(color: Color("DarkShadow"), radius: 8, x: 8, y: 8)
                .offset(x: 0, y: 60)
            
            Text(viewController.command)
                .offset(x: 0, y: -200)
                .frame(width:280,height: 180)
                .foregroundColor(Color("textcolor"))
            
            Text(viewController.sensorData)
                .frame(width:280,height: 180)
                .offset(x: 0, y: 60)
                .foregroundColor(Color("textcolor"))
            }
            
            Group{
                Image("IoTCore").resizable().frame(width: 50, height: 50).position(x: 50, y: 25)
                Text("MQTT Client").foregroundColor(Color("textcolor")).font(.headline).position(x: 140, y: 16)
                Text("Gateway Device").foregroundColor(Color("textcolor")).font(.subheadline).position(x: 145, y: 35)
            }
            
            Group {
                if(viewController.command == ""){
                    LottieView(filename:"3517-growing-circle").frame(width: 50, height: 50).position(x: 350, y: 25)
                } else {
                    LottieView(filename:filename).frame(width: 50, height: 50).position(x: 350, y: 25)
                }
                
                Button(action: {
                    // your action here
                    if(self.delegate.toDisconnect == false){
                        self.viewController.command = ""
                        self.delegate.toDisconnect = true
                        self.self.type = "Connect to Cloud"
                        
                    }else{
                        self.delegate.toDisconnect = false
                        self.self.type = "Disconnect Cloud"
                    }
                    
                }) {
                    Text(self.type)
                }.frame(width: 180, height: 25)
                .padding()
                .foregroundColor(.white)
                .background(Color("Button"))
                .cornerRadius(40)
                .padding(.horizontal, 50).position(x: 205, y: 680)
            }
    }
  }
}


struct SwiftUIObservingUIKit_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIClient(delegate: contentViewDelegate(), viewController: IoTBLEView())
    }
}

