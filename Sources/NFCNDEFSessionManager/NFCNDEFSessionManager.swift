//
//  NFCNDEFSessionManager.swift
//  NFCNDEFSessionManager
//
//  Created by Omar Barrera Peña on 10/06/22.
//

import Foundation
import CoreNFC

/**
 Allows you to configure a `NFCNDEFReaderSession`
 */
public class NFCNDEFSessionManager: NSObject {
    
    public var delegate: NFCNDEFSessionManagerDelegate?
    fileprivate var messages: [String: String] = [:]
    fileprivate var session: NFCNDEFReaderSession?
    fileprivate var ndefMessage: NFCNDEFMessage?
    fileprivate var successfulNFC = false
    fileprivate var nfcAction: NFCScanAction!
    fileprivate var dataToWrite: Codable!
    fileprivate var scannedPayload: [String] = []
    
    /**
     Configures `NFCNDEFReaderSession` to try to write to a NFC tag the given data
     
     - Parameters:
        - data: `String` array to be sent to a NFC tag
        - alertMessage: Custom message you want to show when the `NFCNDEFReaderSession` begins
     
     - Precondition: `alertMessage` has an empty `String` value by default
     
     - Invariant: Each element in the data array will create a different `NFCNDEFPayload`, so, the number of records in the  `NFCNDEFMessage` will be the same number of elements in the data array
     
     - Throws: Error when trying to create a `NFCNDEFMessage`
     */
    public func write(data: [String], alertMessage: String = "") throws {
        nfcAction = .write
        ndefMessage = try configureNDEFMessage(data: data)
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = alertMessage
        session?.begin()
    }
    
    /**
     Configures `NFCNDEFReaderSession` to try to write to a NFC tag the given data
     
     - Parameters:
        - data: Array of `Codable` structs that contains the data to be sent to a NFC tag
        - alertMessage: Custom message you want to show when the `NFCNDEFReaderSession` begins
     
     - Precondition: `alertMessage` has an empty `String` value by default
     
     - Invariant: Each element in the data array will create a different `NFCNDEFPayload`, so, the number of records in the  `NFCNDEFMessage` will be the same number of elements in the data array
     
     - Throws: Error when trying to create a `NFCNDEFMessage`
     */
    public func write<T: Codable>(data: [T], alertMessage: String = "") throws {
        nfcAction = .write
        ndefMessage = try configureNDEFMessage(data: data)
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = alertMessage
        session?.begin()
    }
    
    /**
     Configures `NFCNDEFReaderSession` to only read a NFC tag
     
     - Parameters:
        - alertMessage: Custom message you want to show when the `NFCNDEFReaderSession` begins
     
     - Precondition: `alertMessage` has an empty `String` value by default
     */
    public func read(alertMessage: String = "") {
        nfcAction = .read
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = alertMessage
        session?.begin()
    }
    
    /**
     Allows you to configure custom messages for different scenarios in the `NFCNDEFReaderSession`
     
     - Parameters:
        - noSupportedTag: Message to show when you try to write to a non supported tag
        - readOnlyTag: Message to show when you try to write to a tag that is configured as real-only
        - noTagAvailable: Message to show when the `NFCNDEFReaderSession` doesn´t detect any tag
        - multipleTags: Message to show when you try to write to a tag but multiple tags are detected at the same time
        - writeSuccess: Message to show when you successfully write to a tag
        - readSuccess: Message to show when you successfully read a tag
        - readNoPayload: Message to show when the `NFCNDEFReaderSession` is unable to detect any `NFCNDEFPayload` in a `NFCNDEFMessage`
        - connectError: Message to show if an error occurred when trying to connect to a tag
        - unknownError: Message to show when there occurs an unknown error during the `NFCNDEFReaderSession`
     
     - Precondition: All parameters have `nil` value by default
     */
    public func setCustomMessages(noSupportedTag: String? = nil, readOnlyTag: String? = nil, noTagAvailable: String? = nil, multipleTags: String? = nil, writeSuccess: String? = nil, readSuccess: String? = nil, readNoPayload: String? = nil, connectError: String? = nil, unknownError: String? = nil) {
        if let noSupportedTag = noSupportedTag {
            messages["notSupported"] = noSupportedTag
        }
        if let readOnlyTag = readOnlyTag {
            messages["readOnly"] = readOnlyTag
        }
        if let noTagAvailable = noTagAvailable {
            messages["noTag"] = noTagAvailable
        }
        if let multipleTags = multipleTags {
            messages["multipleTags"] = multipleTags
        }
        if let writeSuccess = writeSuccess {
            messages["writeSuccess"] = writeSuccess
        }
        if let readSuccess = readSuccess {
            messages["readSuccess"] = readSuccess
        }
        if let readNoPayload = readNoPayload {
            messages["readNoPayload"] = readNoPayload
        }
        if let connectError = connectError {
            messages["connectError"] = connectError
        }
        if let unknownError = unknownError {
            messages["unknownError"] = unknownError
        }
    }
    
    /**
     Creates a `NFCNDEFMessage` from given data
     
     - Parameters:
        - data: Array of `String` values to be sent to a NFC tag
        - locale: `Locale` value to set the language code of the payload
     
     - Precondition: The locale value by default is the current locale value of the device
     
     - Returns: A `NFCNDEFMessage` containing the payloads from all the data to be sent to a NFC tag
     
     - Throws: Error if the payload couldn't be created
     */
    private func configureNDEFMessage(data: [String], locale: Locale = Locale.current) throws -> NFCNDEFMessage {
        var records: [NFCNDEFPayload] = []
        for value in data {
            guard let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: value, locale: locale) else { throw "No valid payload" }
            records.append(payload)
        }
        return NFCNDEFMessage(records: records)
    }
    
    /**
     Creates a `NFCNDEFMessage` from given data
     
     - Parameters:
        - data: Array of `Codable` structs that contains the data to be sent to a NFC tag
        - locale: `Locale` value to set the language code of the payload
     
     - Precondition: The locale value by default is the current locale value of the device
     
     - Returns: A `NFCNDEFMessage` containing the payloads from all the data to be sent to a NFC tag
     
     - Throws: Error if the given data is on an incorrect format or the payload couldn't be created
     */
    private func configureNDEFMessage<T: Codable>(data: [T], locale: Locale = Locale.current) throws -> NFCNDEFMessage {
        var records: [NFCNDEFPayload] = []
        for json in data {
            let payloadData = try JSONEncoder().encode(json)
            guard let payloadJSON = String(data: payloadData, encoding: .utf8) else { throw "No payload data" }
            guard let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: payloadJSON, locale: locale) else { throw "No valid payload" }
            records.append(payload)
        }
        return NFCNDEFMessage(records: records)
    }
    
    /**
     Process a `NFCNDEFMessage` received from a NFC tag to extract the payload for each record
     
     - Parameters:
        - message: `NFCNDEFMessage`  from a NFC tag
     */
    private func processNDEFMessage(_ message: NFCNDEFMessage) {
        for record in message.records {
            let (payload, _) = record.wellKnownTypeTextPayload()
            if let payload = payload {
                scannedPayload.append(payload)
            }
        }
        if scannedPayload.isEmpty {
            session?.alertMessage = messages["readNoPayload"] ?? messages["readSuccess"] ?? "Tag scanned successfully"
        } else {
            session?.alertMessage = messages["readSuccess"] ?? "Tag scanned successfully"
        }
        session?.invalidate()
    }
    
    enum NFCScanAction {
        case read
        case write
    }
}

extension NFCNDEFSessionManager: NFCNDEFReaderSessionDelegate {
    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Add any task the app should do when the NFC scan begins
        delegate?.onNFCSessionStart()
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Add any task the app should do when the NFC scan finish
        switch nfcAction {
            case .read:
                delegate?.onReadResult(successfulNFC, payloads: scannedPayload)
                if successfulNFC {
                    // We change this value to prepare the app for a new scan
                    successfulNFC = false
                    scannedPayload.removeAll()
                }
            case .write:
                delegate?.onWriteResult(successfulNFC)
                if successfulNFC {
                    // We change this value to prepare the app for a new scan
                    successfulNFC = false
                }
            default:
                break
        }
        delegate?.onNFCSessionFinish()
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            processNDEFMessage(message)
        }
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        // Here we check the number of nearby tags and prevent the app to continue if more than one tag is next to the device
        guard tags.count == 1 else {
            session.invalidate(errorMessage: messages["multipleTags"] ?? "Cannot write to more than one tag")
            return
        }
        guard let currentTag = tags.first else {
            session.invalidate(errorMessage: messages["noTag"] ?? "No available tag")
            return
        }
        session.connect(to: currentTag) { [self] error in
            if let error = error {
                session.invalidate(errorMessage: messages["connectError"] ?? error.localizedDescription)
            } else {
                switch nfcAction {
                    case .read:
                        // Here we try to read the existing data in the current tag
                        currentTag.readNDEF { [self] message, error in
                            if let message = message {
                                successfulNFC = true
                                processNDEFMessage(message)
                            } else if let error = error {
                                session.invalidate(errorMessage: error.localizedDescription)
                            }
                        }
                    case .write:
                        // Here we try to write to the tag and finish the NFC connection when done
                        currentTag.queryNDEFStatus { [self] status, capacity, error in
                            print("tag capacity: \(capacity)")
                            if let error = error {
                                session.invalidate(errorMessage: error.localizedDescription)
                            } else {
                                switch status {
                                    case .notSupported:
                                        session.invalidate(errorMessage: messages["notSupported"] ?? "This tag is not supported")
                                    case .readWrite:
                                        guard let message = ndefMessage else {
                                            session.invalidate(errorMessage: "No message to be sent")
                                            return
                                        }
                                        currentTag.writeNDEF(message) { [self] error in
                                            if let error = error {
                                                session.invalidate(errorMessage: error.localizedDescription)
                                            } else {
                                                successfulNFC = true
                                                session.alertMessage = messages["writeSuccess"] ?? "Tag updated"
                                                session.invalidate()
                                            }
                                        }
                                    case .readOnly:
                                        session.invalidate(errorMessage: messages["readOnly"] ?? "This tag is only readable")
                                    @unknown default:
                                        session.invalidate(errorMessage: messages["unknownError"] ?? "Unknown error")
                                }
                            }
                        }
                    default:
                        break
                }
            }
        }
    }
}

/**
 Protocol to implement all the possible results of a `NFCNDEFReaderSession`
 */
public protocol NFCNDEFSessionManagerDelegate {
    /**
     Indicates when a `NFCNDEFReaderSession` begins
     */
    func onNFCSessionStart()
    
    /**
     Indicates when a `NFCNDEFReaderSession` finishes
     */
    func onNFCSessionFinish()
    
    /**
     Tells if the NFC tag was written correctly
     
     - Parameters:
        - success: `Bool` to indicate if the writing process was executed correctly
     */
    func onWriteResult(_ success: Bool)
    
    /**
     Provides the payload of all the records in a `NFCNDEFMessage` scanned from a NFC tag
     
     - Parameters:
        - success: `Bool` to indicate if the reading process was executed correctly
        - payloads: Array of `String`, each value is an individual payload of a `NFCNDEFMessage`
     */
    func onReadResult(_ success: Bool, payloads: [String]?)
}

extension String: LocalizedError {
    public var errorDescription: String? {
        return self
    }
}
