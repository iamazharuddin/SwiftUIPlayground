//
//  Clean+Architecture.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 04/12/25.
//

import Foundation

/*
 MVC -

 Controler => Model [Oberver, CallBack, Delegate, Notification ]
 Controller => View [ Delegates, Closures, Target Action ]
 
 Controller changes Model
 Conrtroller updates => View
 
 MVVM -
 Model => ViewModel [ Notificaiton, CallBack, Observers]
 ViewModel => exposes Observable properties
 View => Binds View to the ViewModel properties [Closure, Combine, RxSwift]
 View reacts to the changes of viewmodel properties
 
 ViewModel does not hold reference to the view => it just exposes observable properties to view and view observes the changes and properties
 
 */
