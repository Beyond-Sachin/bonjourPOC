import Foundation
import Network

var sharedConnection: Connection?

protocol ConnectionDelegate: class {
	func connectionReady()
	func connectionFailed()
	func receivedMessage(content: Data?, message: NWProtocolFramer.Message)
	func displayAdvertiseError(_ error: NWError)
}

class Connection {

	weak var delegate: ConnectionDelegate?
	var connection: NWConnection?
	let initiatedConnection: Bool

	init(endpoint: NWEndpoint, interface: NWInterface?, passcode: String, delegate: ConnectionDelegate) {
		self.delegate = delegate
		self.initiatedConnection = true

		let connection = NWConnection(to: endpoint, using: NWParameters(passcode: passcode))
		self.connection = connection

		startConnection()
	}

	init(connection: NWConnection, delegate: ConnectionDelegate) {
		self.delegate = delegate
		self.connection = connection
		self.initiatedConnection = false

		startConnection()
	}

	// Handle the user exiting the service.
	func cancel() {
		if let connection = self.connection {
			connection.cancel()
			self.connection = nil
		}
	}

	// Handle starting the connection for both inbound and outbound connections.
	func startConnection() {
    
		guard let connection = connection else {
			return
		}

		connection.stateUpdateHandler = { newState in
			switch newState {
			case .ready:
				print("\(connection) established")

				// Notify your delegate that the connection is ready.
				if let delegate = self.delegate {
					delegate.connectionReady()
				}
			case .failed(let error):
				print("\(connection) failed with \(error)")

				// Cancel the connection upon a failure.
				connection.cancel()

				// Notify your delegate that the connection failed.
				if let delegate = self.delegate {
					delegate.connectionFailed()
				}
			default:
				break
			}
		}

		// Start the connection establishment.
		connection.start(queue: .main)
	}
}
