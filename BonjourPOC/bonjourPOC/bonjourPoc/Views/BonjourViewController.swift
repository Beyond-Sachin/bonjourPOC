import UIKit
import Network

class BonjourViewController: UITableViewController {

	@IBOutlet weak var nameField: UITextField!
	@IBOutlet weak var passcodeLabel: UILabel!
    @IBOutlet weak var psCell: UITableViewCell!
    
    var results: [NWBrowser.Result] = [NWBrowser.Result]()
	var name: String = "Default"
	var passcode: String = ""

	var sections: [ServiceFinderSection] = [.publish, .join]

	enum ServiceFinderSection {
		case publish
		case passcode
		case join
	}

	func shouldShowPasscode() -> Bool {
		if sharedListener != nil {
			return true
		}
		return false
	}

	func resultRows() -> Int {
		if results.isEmpty {
			return 1
		} else {
			return min(results.count, 6)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Generate a new passcode.
		passcodeLabel.text = "Service published....."
        passcodeLabel.font = passcodeLabel.font.withSize(16.0)
//        psCell.isHidden = true
        
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "joinServiceCell")
	}

	func publishServiceButton() {
		view.endEditing(true)

		guard let name = nameField.text,
			!name.isEmpty else {
			return
		}

		self.name = name
		if let listener = sharedListener {
			// If your app is already listening, just update the name.
			listener.resetName(name)
		} else {
			// If your app is not yet listening, start a new listener.
			sharedListener = Listener(name: name, passcode: passcode, delegate: self)
		}

		// Show the passcode field once you have started hosting a service.
		sections = [.publish, .passcode, .join]
		tableView.reloadData()
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let currentSection = sections[section]
		switch currentSection {
		case .publish:
			return 2
		case .passcode:
			return 1
		case .join:
			return resultRows()
		}
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let currentSection = sections[section]
		switch currentSection {
		case .publish:
			return "Publish Service"
		case .passcode:
            return ""
//			return "Passcode"
		case .join:
			return "Listen Service"
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let currentSection = sections[indexPath.section]
		if currentSection == .join {
			let cell = tableView.dequeueReusableCell(withIdentifier: "joinServiceCell") ?? UITableViewCell(style: .default, reuseIdentifier: "joinServiceCell")
			if sharedBrowser == nil {
				cell.textLabel?.text = "Search for services"
				cell.textLabel?.textAlignment = .center
				cell.textLabel?.textColor = .systemBlue
			} else if results.isEmpty {
				cell.textLabel?.text = "Searching for services..."
				cell.textLabel?.textAlignment = .left
				cell.textLabel?.textColor = .black
			} else {
				let Endpoint = results[indexPath.row].endpoint
				if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = Endpoint {
					cell.textLabel?.text = name
				} else {
					cell.textLabel?.text = "Unknown Endpoint"
				}
				cell.textLabel?.textAlignment = .left
				cell.textLabel?.textColor = .black
			}
			return cell
		}
		return super.tableView(tableView, cellForRowAt: indexPath)
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let currentSection = sections[indexPath.section]
		switch currentSection {
		case .publish:
			if indexPath.row == 1 {
				publishServiceButton()
			}
		case .join:
			if sharedBrowser == nil {
				sharedBrowser = Browser(delegate: self)
			} else if !results.isEmpty {
				// Handle the user tapping on a discovered game
			}
		default:
			print("Tapped inactive row: \(indexPath)")
		}

		tableView.deselectRow(at: indexPath, animated: true)
	}
}

extension BonjourViewController: BrowserDelegate {
    
	func refreshResults(results: Set<NWBrowser.Result>) {
        
        print("results->",results)
		self.results = [NWBrowser.Result]()
        
		for result in results {
            print("result in results->",results)
			if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = result.endpoint {
				print("name in results->",name)
                if name != self.name {
					self.results.append(result)
				}
			}
		}
		tableView.reloadData()
	}

	// Show an error if service discovery failed.
	func displayBrowseError(_ error: NWError) {
		var message = "Error \(error)"
		if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
			message = "Not allowed to access the network"
		}
		let alert = UIAlertController(title: "Cannot discover other players",
									  message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		self.present(alert, animated: true)
	}
}

extension BonjourViewController: ConnectionDelegate {
	func connectionReady() {
	}

	// When the a service cannot be advertised, show an error
	func displayAdvertiseError(_ error: NWError) {
		var message = "Error \(error)"
		if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
			message = "Not allowed to access the network"
		}
		let alert = UIAlertController(title: "Cannot Publish Service",
									  message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		self.present(alert, animated: true)
	}

	// Ignore connection failures and messages prior to starting a service.
	func connectionFailed() { }
	func receivedMessage(content: Data?, message: NWProtocolFramer.Message) { }
}
