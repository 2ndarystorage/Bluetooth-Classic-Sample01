import SwiftUI

struct CommunicationView: View {
    @EnvironmentObject var bluetoothManager: BluetoothClassicManager
    @Environment(\.dismiss) private var dismiss
    @State private var inputText: String = ""
    @State private var showingDisconnectAlert = false

    var body: some View {
        VStack(spacing: 0) {
            connectionStatusBar
            Divider()
            messagesScrollView
            Divider()
            inputBar
        }
        .navigationTitle(bluetoothManager.selectedAccessory?.name ?? "通信")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingDisconnectAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("切断")
                    }
                    .foregroundColor(.red)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("クリア") {
                    bluetoothManager.messages.removeAll()
                }
            }
        }
        .alert("切断確認", isPresented: $showingDisconnectAlert) {
            Button("切断", role: .destructive) {
                bluetoothManager.closeSession()
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("アクセサリとの接続を切断しますか？")
        }
        .alert("エラー",
               isPresented: Binding(
                   get: { bluetoothManager.errorMessage != nil },
                   set: { if !$0 { bluetoothManager.errorMessage = nil } }
               )) {
            Button("OK") { bluetoothManager.errorMessage = nil }
        } message: {
            Text(bluetoothManager.errorMessage ?? "")
        }
        .onDisappear {
            if bluetoothManager.isSessionOpen {
                bluetoothManager.closeSession()
            }
        }
    }

    // MARK: - Subviews

    private var connectionStatusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(bluetoothManager.isSessionOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(bluetoothManager.isSessionOpen ? "接続中" : "切断済み")
                .font(.caption)
                .foregroundColor(bluetoothManager.isSessionOpen ? .green : .red)

            if !bluetoothManager.currentProtocol.isEmpty {
                Text("·")
                    .foregroundColor(.secondary)
                Text(bluetoothManager.currentProtocol)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()

            Text("\(bluetoothManager.messages.count) 件")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if bluetoothManager.messages.isEmpty {
                        emptyMessagesView
                    } else {
                        ForEach(bluetoothManager.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: bluetoothManager.messages.count) { _ in
                if let last = bluetoothManager.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyMessagesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text("メッセージはまだありません")
                .foregroundColor(.secondary)
                .font(.callout)
            Text("下の入力欄からメッセージを送信できます")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("メッセージを入力", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(canSend ? Color.blue : Color.gray)
                    .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && bluetoothManager.isSessionOpen
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        bluetoothManager.send(text)
        inputText = ""
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if message.isSent { Spacer(minLength: 60) }

            VStack(alignment: message.isSent ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isSent ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isSent ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !message.isSent { Spacer(minLength: 60) }
        }
    }
}
