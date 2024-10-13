//
//  SearchMediaSection.swift
//  PocketTheater
//
//  Created by 김윤우 on 10/12/24.
//

import RxDataSources

typealias MediaSection = SectionModel<String, MediaItem>

struct MediaItem {
    let title: String
    let imageUrl: String?
    let id: Int
}