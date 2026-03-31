import Foundation
import os

private let wsLogger = Logger(subsystem: "se.bokvia.app", category: "WebSocket")

/// Socket.IO client for Bokvia real-time events.
/// Server uses Socket.IO with two namespaces:
///   - /chat — for real-time chat messages (join rooms, send/receive messages, typing)
///   - /notifications — for push-style notifications (auto-joins user:{userId} room)
///
/// Auth: token via handshake query param or handshake.auth.token
///
/// NOTE: This uses Socket.IO's HTTP long-polling transport via URLSession.
/// For full WebSocket transport, add SocketIO-Client-Swift SPM package.
@MainActor @Observable
class WebSocketClient {
    static let shared = WebSocketClient()

    var isConnected = false
    var onNewMessage: ((String) -> Void)?
    var onBookingUpdate: (() -> Void)?

    // Built by Christos Ferlachidis & Daniel Hedenberg

    private var chatSid: String?
    private var notifSid: String?
    private var pollTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var currentUserId: String?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    private let baseURL = Config.baseURL

    func connect(userId: String) {
        disconnect()
        currentUserId = userId
        reconnectAttempts = 0

        guard let token = KeychainHelper.getAccessToken() else { return }
        wsLogger.info("Connecting Socket.IO for user \(userId)")

        startPolling(token: token)
        startHeartbeat(token: token)
    }

    func disconnect() {
        pollTask?.cancel()
        pollTask = nil
        heartbeatTask?.cancel()
        heartbeatTask = nil
        chatSid = nil
        notifSid = nil
        isConnected = false
        currentUserId = nil
        reconnectAttempts = 0
    }

    /// Call when app returns to foreground to re-establish connection
    func reconnect() {
        guard let userId = currentUserId else { return }
        wsLogger.info("Reconnecting for user \(userId)")
        reconnectAttempts = 0
        connect(userId: userId)
    }

    func joinChatRoom(_ chatId: String) async {
        guard let sid = chatSid, let token = KeychainHelper.getAccessToken() else { return }
        // Send join event via Socket.IO polling
        let payload = "42[\"join\",{\"chatId\":\"\(chatId)\"}]"
        await sendToNamespace("/chat", sid: sid, token: token, payload: payload)
    }

    func sendMessage(chatId: String, content: String, imageUrl: String? = nil) async {
        guard let sid = chatSid, let token = KeychainHelper.getAccessToken() else { return }
        var msgObj = "{\"chatId\":\"\(chatId)\",\"content\":\"\(content.replacingOccurrences(of: "\"", with: "\\\""))\""
        if let img = imageUrl {
            msgObj += ",\"imageUrl\":\"\(img)\""
        }
        msgObj += "}"
        let payload = "42[\"message\",\(msgObj)]"
        await sendToNamespace("/chat", sid: sid, token: token, payload: payload)
    }

    func sendTyping(chatId: String) async {
        guard let sid = chatSid, let token = KeychainHelper.getAccessToken() else { return }
        let payload = "42[\"typing\",{\"chatId\":\"\(chatId)\"}]"
        await sendToNamespace("/chat", sid: sid, token: token, payload: payload)
    }

    // MARK: - Polling & Heartbeat

    private func startPolling(token: String) {
        pollTask = Task {
            await connectNamespace("/chat", token: token)
            await connectNamespace("/notifications", token: token)
            isConnected = true

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Config.pollingInterval))
                guard !Task.isCancelled else { break }

                let chatOk = await pollChat(token: token)
                let notifOk = await pollNotifications(token: token)

                if chatOk && notifOk {
                    reconnectAttempts = 0
                } else {
                    await handlePollFailure()
                    if Task.isCancelled { break }
                }
            }
        }
    }

    private func startHeartbeat(token: String) {
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                guard !Task.isCancelled else { break }
                // Send Socket.IO ping ("2") to both namespaces
                if let sid = chatSid {
                    await sendToNamespace("/chat", sid: sid, token: token, payload: "2")
                }
                if let sid = notifSid {
                    await sendToNamespace("/notifications", sid: sid, token: token, payload: "2")
                }
            }
        }
    }

    private func handlePollFailure() async {
        reconnectAttempts += 1
        if reconnectAttempts >= maxReconnectAttempts {
            wsLogger.error("Max reconnect attempts reached, stopping")
            isConnected = false
            pollTask?.cancel()
            heartbeatTask?.cancel()
            return
        }

        let delay = pow(2.0, Double(reconnectAttempts))
        wsLogger.info("Poll failed, reconnecting in \(delay)s (attempt \(self.reconnectAttempts)/\(self.maxReconnectAttempts))")
        try? await Task.sleep(for: .seconds(delay))

        guard !Task.isCancelled, let token = KeychainHelper.getAccessToken() else { return }
        await connectNamespace("/chat", token: token)
        await connectNamespace("/notifications", token: token)
    }

    // MARK: - Socket.IO HTTP Polling

    private func connectNamespace(_ namespace: String, token: String) async {
        // Socket.IO handshake: GET with EIO=4&transport=polling
        let urlStr = "\(baseURL)/socket.io/?EIO=4&transport=polling&nsp=\(namespace)&token=\(token)"
        guard let url = URL(string: urlStr) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let text = String(data: data, encoding: .utf8) {
                // Parse sid from response like: 0{"sid":"xxxxx","upgrades":["websocket"],...}
                if let sidStart = text.range(of: "\"sid\":\""),
                   let sidEnd = text[sidStart.upperBound...].range(of: "\"") {
                    let sid = String(text[sidStart.upperBound..<sidEnd.lowerBound])
                    if namespace == "/chat" {
                        chatSid = sid
                    } else {
                        notifSid = sid
                    }
                    wsLogger.info("Connected to \(namespace) sid=\(sid)")
                }
            }
        } catch {
            wsLogger.error("Failed to connect \(namespace): \(error.localizedDescription)")
        }
    }

    @discardableResult
    private func pollChat(token: String) async -> Bool {
        guard let sid = chatSid else { return false }
        return await pollNamespace("/chat", sid: sid, token: token) { [weak self] event, data in
            guard let self else { return }
            switch event {
            case "message":
                let chatId = (data as? [String: Any])?["chatId"] as? String ?? ""
                HapticManager.medium()
                self.onNewMessage?(chatId)
            default: break
            }
        }
    }

    @discardableResult
    private func pollNotifications(token: String) async -> Bool {
        guard let sid = notifSid else { return false }
        return await pollNamespace("/notifications", sid: sid, token: token) { [weak self] event, _ in
            guard let self else { return }
            if event == "booking-update" {
                HapticManager.medium()
                self.onBookingUpdate?()
            }
        }
    }

    private func pollNamespace(_ namespace: String, sid: String, token: String, handler: (String, Any?) -> Void) async -> Bool {
        let urlStr = "\(baseURL)/socket.io/?EIO=4&transport=polling&sid=\(sid)&nsp=\(namespace)&token=\(token)"
        guard let url = URL(string: urlStr) else { return false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let http = response as? HTTPURLResponse
            guard http?.statusCode == 200 else {
                wsLogger.warning("Poll \(namespace) HTTP \(http?.statusCode ?? 0)")
                return false
            }

            if let text = String(data: data, encoding: .utf8) {
                parseMessages(text, handler: handler)
            }
            return true
        } catch {
            wsLogger.warning("Poll \(namespace) error: \(error.localizedDescription)")
            return false
        }
    }

    private func sendToNamespace(_ namespace: String, sid: String, token: String, payload: String) async {
        let urlStr = "\(baseURL)/socket.io/?EIO=4&transport=polling&sid=\(sid)&nsp=\(namespace)&token=\(token)"
        guard let url = URL(string: urlStr) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload.data(using: .utf8)

        _ = try? await URLSession.shared.data(for: request)
    }

    private func parseMessages(_ text: String, handler: (String, Any?) -> Void) {
        // Socket.IO message format: 42["eventName",{...}]
        let pattern = /42\["([^"]+)"(?:,(.+?))?\]/
        for match in text.matches(of: pattern) {
            let event = String(match.output.1)
            var data: Any?
            if let jsonStr = match.output.2,
               let jsonData = String(jsonStr).data(using: .utf8) {
                data = try? JSONSerialization.jsonObject(with: jsonData)
            }
            handler(event, data)
        }
    }
}
