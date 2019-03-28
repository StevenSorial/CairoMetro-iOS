import Alamofire
import RxSwift

extension DataRequest {
  @discardableResult
  public func rxDecodable<T: Decodable>(of type: T.Type = T.self,
                                        queue: DispatchQueue = .main,
                                        decoder: Alamofire.DataDecoder = JSONDecoder()) -> Single<T> {
    Single<T>.create { observer in
      self.responseDecodable(of: type, queue: queue, decoder: decoder) { response in
        switch response.result {
          case .success(let data):
            observer(.success(data))
          case .failure(let error):
            observer(.failure(error))
        }
      }
      return Disposables.create {
        self.cancel()
      }
    }
  }
}
