//
//  HomeSelectionView.swift
//  SonAR-ECS
//
//  Created by Gabriella Angelina Widjaja on 17/08/26.
//

import SwiftUI

struct HomeSelectionView: View {
    @Binding var appState: AppState

    private let sonGradient = LinearGradient(
        colors: [Color("sonGrad1"), Color("sonGrad2"), Color("sonGrad3")],
        startPoint: .leading,
        endPoint: .trailing
    )

    private let arGradient = LinearGradient(
        colors: [Color("arGrad1"), Color("arGrad2"), Color("arGrad3")],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        NavigationStack {
            ZStack {
                // Latar Belakang Krem
                Color("bgMain").ignoresSafeArea()

                // Awan Latar
                VStack {
                    HStack {
                        Image("cloudTop")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120)
                            .padding(.top, 40)
                            .padding(.leading, -20)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Image("cloudBottom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140)
                            .padding(.trailing, -30)
                    }
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    // 🤖 Maskot Robot di Atas Kartu
                    Image("mascotRobot")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .offset(y: 28)
                        .zIndex(1)

                    // Kartu Putih Mode Selection
                    VStack(spacing: 20) {
                        // Judul SonAR Kompak (42pt)
                        HStack(spacing: 2) {
                            Text("Son")
                                .foregroundStyle(sonGradient)
                            Text("AR")
                                .foregroundStyle(arGradient)
                        }
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .padding(.top, 28)

                        Text("Learn how a robot sees with\nultrasonic wave")
                            .font(.system(size: 15, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.black.opacity(0.75))
                            .padding(.horizontal, 24)

                        // ✅ Tombol 1: Guided Tour
                        NavigationLink {
                            SensorIntroView(isGuided: true, appState: $appState)
                        } label: {
                            HStack(spacing: 12) {
                                Image("quickTour")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                Text("Guided tour")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color("buttonCyan"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .stroke(Color("buttonCyan"), lineWidth: 2)
                                    .background(Capsule().fill(.white))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        // ✅ Tombol 2: Free Exploration
                        NavigationLink {
                            SensorIntroView(isGuided: false, appState: $appState)
                        } label: {
                            HStack(spacing: 12) {
                                Image("freeExplore")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                Text("Free Exploration")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color("buttonModeText"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .stroke(Color("buttonModeText"), lineWidth: 2)
                                    .background(Capsule().fill(.white))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
                    )
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview("Home Screen") {
    HomeSelectionView(appState: .constant(.home))
}