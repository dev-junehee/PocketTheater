//
//  DetailViewModel.swift
//  PocketTheater
//
//  Created by junehee on 10/10/24.
//

import Foundation
import RxCocoa
import RxSwift

class DetailViewModel: ViewModelType {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let media: Result
    }
    
    struct Output {
        let dataSource: Observable<[DetailSectionModel]>
    }
    
    func transform(input: Input) -> Output {
        let mediaDetailObservable = Observable.zip(
            getCast(input.media),
            getSimilarMedia(input.media)
        ).map { (castCrew, similar) in
            let (cast, crew) = castCrew
            return MediaDetail(movie: input.media, cast: cast, crew: crew, similar: similar)
        }.share(replay: 1, scope: .whileConnected)
        
        let dataSource = mediaDetailObservable.map { detail in
            [
                DetailSectionModel(header: "", items: [.header(detail)]),
                DetailSectionModel(header: "비슷한 콘텐츠", items: detail.similar.map { .media($0) })
            ]
        }
        
        return Output(dataSource: dataSource)
    }
    
    private func getCast(_ media: Result) -> Observable<([String], [String])> {
        return Observable.create { observer in
            Task {
                do {
                    let type = MediaType(rawValue: media.mediaType ?? "") ?? .unknown
                    let data = try await NetworkManager.shared.fetchCast(mediaType: type, id: media.id)
                    let cast = data.cast.map { $0.name }
                    let crew = data.crew.map { $0.name }
                    observer.onNext((cast, crew))
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    private func getSimilarMedia(_ media: Result) -> Observable<[Result]> {
        return Observable.create { observer in
            Task {
                do {
                    let type = MediaType(rawValue: media.mediaType ?? "") ?? .unknown
                    let media = try await NetworkManager.shared.fetchSimilar(mediaType: type, id: media.id)
                    observer.onNext(media.results)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
