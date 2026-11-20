import Foundation

@MainActor
@Observable
final class HeroSearchViewModel {
    var query = ""
    private(set) var state: HeroSearchState = .idle

    private let searchHeroes: SearchHeroesUseCase
    @ObservationIgnored private var activeTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0

    init(searchHeroes: SearchHeroesUseCase) {
        self.searchHeroes = searchHeroes
    }

    var canSubmit: Bool {
        !SearchQueryNormalizer.normalizedQuery(query).isEmpty
    }

    var isLoading: Bool {
        state == .loading
    }

    func submit() {
        let normalizedQuery = SearchQueryNormalizer.normalizedQuery(query)
        guard !normalizedQuery.isEmpty else {
            clear()
            return
        }

        activeTask?.cancel()
        generation &+= 1
        let generation = generation

        state = .loading
        activeTask = Task { [weak self] in
            guard let self else { return }

            do {
                let heroes = try await self.searchHeroes.execute(query: normalizedQuery)
                try Task.checkCancellation()
                guard self.generation == generation else { return }
                self.state = heroes.isEmpty ? .empty : .results(heroes)
                self.activeTask = nil
            } catch is CancellationError {
                guard self.generation == generation else { return }
                if case .loading = self.state {
                    self.state = .idle
                }
                self.activeTask = nil
            } catch let error as HeroRepositoryError {
                guard !Task.isCancelled, self.generation == generation else { return }
                if error == .notFound {
                    self.state = .empty
                } else {
                    self.state = .failure(HeroSearchFailure(error: error))
                }
                self.activeTask = nil
            } catch {
                guard !Task.isCancelled, self.generation == generation else { return }
                self.state = .failure(.unexpected)
                self.activeTask = nil
            }
        }
    }

    func retry() {
        submit()
    }

    /// Clears the field, cancels the active search, and returns to the idle state.
    func clear() {
        query = ""
        cancelActiveSearch()
        state = .idle
    }

    /// Cancels without discarding already-published results. Used when leaving the view.
    func cancelActiveSearch() {
        activeTask?.cancel()
        activeTask = nil
        generation &+= 1

        if state == .loading {
            state = .idle
        }
    }
}
