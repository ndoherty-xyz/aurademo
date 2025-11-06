//
//  SendHaptic.swift
//  AuraDemo
//
//  Created by nick on 11/4/25.
//

import UIKit

func SendSuccessHaptic() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}

func SendWarningHaptic() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
}

func SendErrorHaptic() {
    UINotificationFeedbackGenerator().notificationOccurred(.error)
}

func SendLightImpactHaptic() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

func SendMediumImpactHaptic() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}

func SendHeavyImpactHaptic() {
    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
}

func SendSoftImpactHaptic() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
}

func SendRigidImpactHaptic() {
    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
}
