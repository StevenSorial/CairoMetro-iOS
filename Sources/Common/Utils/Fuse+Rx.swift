import Fuse
import RxSwift

extension Fuse {
  public func search<T: Fuseable>(_ text: String, in aList: [T], chunkSize: Int = 100) -> Single<[T]> {
    Single.create { observer in
      self.search(text, in: aList, chunkSize: chunkSize) { result in
        var newFilteredList: [T] = []
        result.forEach { item in
          newFilteredList.append(aList[item.index])
        }
        observer(.success(newFilteredList))
      }
      return Disposables.create()
    }
  }
}
