//
//  LottieView.swift
//  iOS_IoTCore_Client
//
//  Created by Gal Zahavi on 7/16/20.
//  Copyright © 2020 Danilo Campos. All rights reserved.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    let animationView = AnimationView()
    var filename = "LottieLogo2"
    
    func makeUIView(context: UIViewRepresentableContext<LottieView>) ->  UIView {
        let view = UIView()
        
        let animation = Animation.named(filename)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop.self
        animationView.play()
    
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        return view
    }
}
