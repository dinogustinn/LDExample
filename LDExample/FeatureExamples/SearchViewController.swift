//
//  SearchViewController.swift
//  LDExample
//
//  Created by Dino Gustin on 05.11.2021..
//

import UIKit
import LSData
import LSCocoa
import Combine
import CoreData

class SearchViewController: UIViewController {
    
    public lazy var searchBar = UISearchBar()
    public lazy var tableView = UITableView()
    
    var cancelBag = Set<AnyCancellable>()
    let repository = LSCoreDataRepository<RepositoryManagedObject>(stack: try! LSCoreDataStack(modelName: "Model"))
    let dataSource = LSAPINetworkDataSource(endpoint: SearchRepositoriesEndpoint())
        .jsonDecodeMap(to: SearchRepositoriesEndpoint.Response.self)
        .outMap(with: SearchRepositoriesOutputMapper())
        .paramMap(with: SearchRepositoriesParamMapper())
    
    let searchTextPublisher = CurrentValueSubject<String, Never>("")
    
    var repositories = [Repository]()

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self

        searchTextPublisher
            .map { text -> AnyPublisher<[Repository], Never> in
                self.dataSource.publisher(parameter: [.query(text)])
                    .catch { _ in Just([]) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { repositories in
                self.repositories = repositories
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
            .store(in: &cancelBag)
    }
    
    override func loadView() {
        super.loadView()
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        
        view.backgroundColor = .white
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTextPublisher.send(searchText)
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else { return UITableViewCell() }
        cell.textLabel?.text = repositories[indexPath.row].name
        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    
}
