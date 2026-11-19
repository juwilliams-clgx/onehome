import Foundation

/// A single listing photo. Mirrors the web prototype's `Photo` model
/// (vision-board-prototype/src/app/models/photo.model.ts) so mock data and
/// interaction rules stay comparable between the web and native surfaces.
struct Photo: Identifiable, Hashable {
    let id: String
    let url: URL
    let room: String
    let caption: String
}
