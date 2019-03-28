//
//  AdBannerVC.swift
//  CairoMetro
//
//  Created by Steven on 3/16/20.
//  Copyright © 2020 Steven. All rights reserved.
//

import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import WebKit

class AdBannerVC<HostedType: UIViewController>: UIViewController, GADBannerViewDelegate {
  let hostedVC: HostedType
  private weak var containerView: UIView!
  private weak var bannerView: GADBannerView!
  private var containerBottomConstraint: NSLayoutConstraint!
  private var reloadTimer: Timer?
  private var adDidLoad = false

  init(hostedVC: HostedType) {
    self.hostedVC = hostedVC
    super.init(nibName: nil, bundle: nil)
    title = hostedVC.title
    tabBarItem = hostedVC.tabBarItem
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    super.loadView()
    adDidLoad = false
    let bannerView = GADBannerView()
    let containerView = UIView()
    bannerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(containerView)
    view.addSubview(bannerView)

    containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    NSLayoutConstraint.activate([
      containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      containerView.topAnchor.constraint(equalTo: view.topAnchor),
      containerBottomConstraint,
      bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ])
    self.bannerView = bannerView
    self.containerView = containerView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !adDidLoad { requestThenLoad() }
  }

  func setupUI() {
    view.backgroundColor = ColorCompat.systemBackground
    addChildVC(hostedVC, into: containerView)
    setupBanner()
    title = hostedVC.title
    tabBarItem = hostedVC.tabBarItem
  }

  func setupBanner() {
    bannerView.delegate = self
    #if DEBUG
    bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" // test id
    #else
    bannerView.adUnitID = "ca-app-pub-5826989261781617/1346744259" // actual id
    #endif
    bannerView.rootViewController = self
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { [weak self] _ in
      self?.requestThenLoad(viewSize: size)
    }
  }

  func requestThenLoad(viewSize: CGSize? = nil) {
    if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
      ATTrackingManager.safeRequestTrackingAuthorization { [weak self] status in
        guard status != .notDetermined else { return }
        self?.loadAd(viewSize: viewSize)
      }
    } else {
      loadAd(viewSize: viewSize)
    }
  }

  func loadAd(viewSize: CGSize? = nil) {
    reloadTimer?.invalidate()
    adDidLoad = false
    showFull()
    guard view.window != nil else { return }
    let request = GADRequest()
    if #available(iOS 13.0, *) {
      request.scene = view.window!.windowScene
    }
    bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(view.frame.size.width)
    bannerView.load(request)
  }

  func reloadAd(after time: TimeInterval) {
    reloadTimer?.invalidate()
    reloadTimer = Timer(timeInterval: time, repeats: false) { [weak self] _ in
      self?.requestThenLoad()
    }
    reloadTimer!.tolerance = 0.5
    RunLoop.current.add(reloadTimer!, forMode: .common)
  }

  func showFull() {
    guard let view = view, let containerView = containerView, let bannerView = bannerView else {
      Logger.error("views where nil. should not happen")
      return
    }
    bannerView.alpha = 0
    containerBottomConstraint?.isActive = false
    containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    containerBottomConstraint!.isActive = true
  }

  func showWithAd() {
    guard let bannerView = bannerView, let containerView = containerView else {
      fatalError("views where nil. should not happen")
    }
    bannerView.alpha = 1
    containerBottomConstraint?.isActive = false
    containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: bannerView.topAnchor)
    containerBottomConstraint!.isActive = true
  }

  func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
    print("didFailToReceiveAdWithError: \(error)")
    adDidLoad = false
    showFull()
    reloadAd(after: 8)
  }

  func adViewDidReceiveAd(_ bannerView: GADBannerView) {
    print("adViewDidReceiveAd called")
    adDidLoad = true
    showWithAd()
  }
}

@available(iOS 14, *)
extension ATTrackingManager {
  static func safeRequestTrackingAuthorization(
    completionHandler completion: @escaping (ATTrackingManager.AuthorizationStatus) -> Void
  ) {
    requestTrackingAuthorization { status in DispatchQueue.main.async { completion(status) } }
  }
}
