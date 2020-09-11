import Network

var sharedBrowser: Browser?

protocol BrowserDelegate: class {
	func refreshResults(results: Set<NWBrowser.Result>)
	func displayBrowseError(_ error: NWError)
}

class Browser {

	weak var delegate: BrowserDelegate?
	var browser: NWBrowser?

	// Create a browsing object with a delegate.
	init(delegate: BrowserDelegate) {
		self.delegate = delegate
		startBrowsing()
	}

	// Start browsing for services.
	func startBrowsing() {
		let parameters = NWParameters()
		parameters.includePeerToPeer = true
		let browser = NWBrowser(for: .bonjour(type: "_bonjourPoc._tcp", domain: nil), using: parameters)
		self.browser = browser

		browser.stateUpdateHandler = { newState in
			switch newState {
			case .failed(let error):
				// Restart the browser if it loses its connection
				if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
					print("Browser failed with \(error), restarting")
					browser.cancel()
					self.startBrowsing()
				} else {
					print("Browser failed with \(error), stopping")
					self.delegate?.displayBrowseError(error)
					browser.cancel()
				}
			case .ready:
				// Post initial results.
                print("Browsing services \(browser.browseResults)")
				self.delegate?.refreshResults(results: browser.browseResults)
			case .cancelled:
				sharedBrowser = nil
				self.delegate?.refreshResults(results: Set())
			default:
				break
			}
		}

		// When the list of discovered endpoints changes, refresh the delegate.
		browser.browseResultsChangedHandler = { results, changes in
			self.delegate?.refreshResults(results: results)
		}

		// Start browsing and ask for updates on the main queue.
		browser.start(queue: .main)
	}
}
