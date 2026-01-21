//
//  Deeplink.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 21/01/26.
//

import UIKit
extension SceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
      for context in URLContexts {
        print("url: \(context.url.absoluteURL)")
        print("scheme: \(context.url.scheme)")
        print("host: \(context.url.host)")
        print("path: \(context.url.path)")
        print("components: \(context.url.pathComponents)")
      }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
      guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
        let urlToOpen = userActivity.webpageURL else {
          return
      }

    }
}
