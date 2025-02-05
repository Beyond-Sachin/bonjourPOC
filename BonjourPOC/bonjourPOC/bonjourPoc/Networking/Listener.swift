import Network

var sharedListener: Listener?

class Listener {

	weak var delegate: ConnectionDelegate?
	var listener: NWListener?
	var name: String
	let passcode: String

	init(name: String, passcode: String, delegate: ConnectionDelegate) {
		self.delegate = delegate
		self.name = name
		self.passcode = passcode
		startListening()
	}

	// Start listening and advertising.
	func startListening() {
		do {
			// Create the listener object.
			let listener = try NWListener(using: NWParameters(passcode: passcode))
			self.listener = listener

			// Set the service to advertise.
			listener.service = NWListener.Service(name: self.name, type: "_bonjourPoc._tcp")

			listener.stateUpdateHandler = { newState in
				switch newState {
				case .ready:
					print("Listener ready on \(String(describing: listener.port!))")
				case .failed(let error):
					// If the listener fails, re-start.
					if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
						print("Listener failed with \(error), restarting")
						listener.cancel()
						self.startListening()
					} else {
						print("Listener failed with \(error), stopping")
						self.delegate?.displayAdvertiseError(error)
						listener.cancel()
					}
				case .cancelled:
					sharedListener = nil
				default:
					break
				}
			}

			listener.newConnectionHandler = { newConnection in
				if let delegate = self.delegate {
					if sharedConnection == nil {
						// Accept a new connection.
						sharedConnection = Connection(connection: newConnection, delegate: delegate)
					} else {
						newConnection.cancel()
					}
				}
			}

			// Start listening, and request updates on the main queue.
			listener.start(queue: .main)
		} catch {
			print("Failed to create listener")
			abort()
		}
	}

	// If the user changes their name, update the advertised name.
	func resetName(_ name: String) {
		self.name = name
		if let listener = listener {
			// Reset the service to advertise.
			listener.service = NWListener.Service(name: self.name, type: "_bonjourPoc._tcp")
		}
	}
}
