//
//  SceneDelegate.swift
//  OpenTone
//
//  Created by Student on 12/11/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        // Apply the user's stored theme preference (dark / light / system)
        ThemeManager.shared.applyStoredTheme()

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Show a temporary launch screen or loading indicator while we check auth
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        window.rootViewController = storyboard.instantiateInitialViewController()
        window.makeKeyAndVisible()

        // Listen for the UserDataModel to finish loading the session
        NotificationCenter.default.addObserver(self, selector: #selector(handleSessionLoaded), name: NSNotification.Name("UserDataModelLoaded"), object: nil)
        
        // If it's already loaded (rare but possible), trigger immediately
        if UserDataModel.shared.isLoaded {
            handleSessionLoaded()
        }
    }

    @objc private func handleSessionLoaded() {
        guard let window = self.window else { return }

        let destination = OnboardingDestinationResolver.destination(for: SessionManager.shared.currentUser)
        switch destination {
        case .login:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let initialVC = storyboard.instantiateInitialViewController() {
                window.rootViewController = initialVC
            }

        case .userInfo:
            setOnboardingRoot(window: window, identifier: "UserInfoScreen")

        case .confidence:
            setOnboardingRoot(window: window, identifier: "ConfidenceScreen")

        case .interestsIntro:
            setOnboardingRoot(window: window, identifier: "InterestsIntro")

        case .commitment:
            setOnboardingRoot(window: window, identifier: "CommitmentScreen")

        case .dashboard:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
            tabBarVC.modalPresentationStyle = .fullScreen
            window.rootViewController = tabBarVC
        }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }

    private func setOnboardingRoot(window: UIWindow, identifier: String) {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let onboardingVC = storyboard.instantiateViewController(withIdentifier: identifier)
        let nav = UINavigationController(rootViewController: onboardingVC)
        nav.modalPresentationStyle = .fullScreen
        window.rootViewController = nav
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Refresh saved session caches from Supabase when returning to foreground
        JamSessionDataModel.shared.refreshSavedSession()
        RoleplaySessionDataModel.shared.refreshSavedSession()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Auto-save any active JAM session so the user can continue from the Dashboard
        if JamSessionDataModel.shared.hasActiveSession() {
            JamSessionDataModel.shared.saveSessionForLater()
        }
        // Auto-save any active roleplay session
        if RoleplaySessionDataModel.shared.getActiveSession() != nil {
            RoleplaySessionDataModel.shared.saveSessionForLater()
        }
    }


}

