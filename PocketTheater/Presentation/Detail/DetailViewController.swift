//
//  DetailViewController.swift
//  PocketTheater
//
//  Created by junehee on 10/10/24.
//

import UIKit
import RxCocoa
import RxDataSources
import RxGesture
import RxSwift
import SnapKit

struct MediaDetail {
    let movie: Result
    let cast: [String]
    let crew: [String]
    let similar: [Result]
}

enum DetailSection {
    case header
    case similar
}

enum DetailItem {
    case header(MediaDetail)
    case media(Result)  // 여기를 [Result] 배열로 변경
}

struct DetailSectionModel {
    var header: String
    var items: [DetailItem]
}

extension DetailSectionModel: SectionModelType {
    typealias Item = DetailItem
    
    init(original: DetailSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}

final class DetailViewController: BaseViewController {
    
    private let detailView = DetailView()
    private let viewModel = DetailViewModel()
    private let disposeBag = DisposeBag()
    
    var media: Result?
    
    private var dataSource: RxCollectionViewSectionedReloadDataSource<DetailSectionModel>!
    
    override func loadView() {
        view = detailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViewController()
        detailView.similarCollectionView.collectionViewLayout = createCompositionalLayout()
        setDataSource()
        bind()
    }
    
    private func setDataSource() {
        dataSource = RxCollectionViewSectionedReloadDataSource<DetailSectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                switch item {
                case .header(let mediaDetail):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailHeaderCell.identifier, for: indexPath) as? DetailHeaderCell else {
                        return UICollectionViewCell()
                    }
                    cell.updateCell(with: mediaDetail)
                    self?.detailView.updateDetailMainImage(mediaDetail.movie.backdropPath)
                    return cell
                    
                case .media(let media):  // 개별 Result 항목을 받음
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCollectionViewCell.identifier, for: indexPath) as? MediaCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    cell.configure(with: media)  // 개별 항목을 설정
                    return cell
                }
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard kind == UICollectionView.elementKindSectionHeader,
                      let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MediaSectionHeaderView.identifier, for: indexPath) as? MediaSectionHeaderView else {
                    return UICollectionReusableView()
                }
                header.configure(with: dataSource[indexPath.section].header)
                return header
            }
        )
    }
    func bind() {
        guard let media = media else { return }
        
        let input = DetailViewModel.Input(media: media)
        let output = viewModel.transform(input: input)
        
        output.dataSource
            .bind(to: detailView.similarCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    override func setViewController() {
           super.setViewController()
           detailView.similarCollectionView.collectionViewLayout = createCompositionalLayout()
       }
    
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self else { return nil }
            
            if sectionIndex == 0 {
                return self.createHeaderSection()
            } else {
                return self.createSimilarContentSection()
            }
        }
        return layout
    }

    private func createHeaderSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(250))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(250))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    private func createSimilarContentSection() -> NSCollectionLayoutSection {
        // 아이템 크기 설정
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalWidth(1/3))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        // 그룹 크기 설정 (한 줄에 3개의 아이템)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1/3))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item, item])
        
        // 섹션 설정
        let section = NSCollectionLayoutSection(group: group)

        // 헤더 설정
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }

}
