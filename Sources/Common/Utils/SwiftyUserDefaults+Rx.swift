import RxSwift
import SwiftyUserDefaults

extension DefaultsAdapter {
  func observe<T: DefaultsSerializable>(_ key: DefaultsKey<T>,
                                        options: NSKeyValueObservingOptions = [.old, .new]
  ) -> RxSwift.Observable<DefaultsObserver<T>.Update> where T == T.T {
    return Observable.create { observer in
      let token = self.observe(key, options: options) { update in
        observer.onNext(update)
      }
      return Disposables.create {
        token.dispose()
      }
    }
  }

  func observe<T: DefaultsSerializable>(_ keyPath: KeyPath<KeyStore, DefaultsKey<T>>,
                                        options: NSKeyValueObservingOptions = [.old, .new]
  ) -> RxSwift.Observable<DefaultsObserver<T>.Update> where T == T.T {
    return Observable.create { observer in
      let token = self.observe(keyPath, options: options) { update in
        observer.onNext(update)
      }

      return Disposables.create {
        token.dispose()
      }
    }
  }
}
