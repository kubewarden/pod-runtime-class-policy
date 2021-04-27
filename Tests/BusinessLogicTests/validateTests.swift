import XCTest
import class Foundation.Bundle

import kubewardenSdk
import Foundation

@testable import BusinessLogic

final class ValidateTests: XCTestCase {

  func testAcceptBecauseDefaultRuntimeIsNotReserved() {
    let reservedRuntimes: Set<String> = ["runC"]
    let settings = Settings(
      reservedRuntimes: reservedRuntimes,
      defaultRuntimeReserved: false,
      fallbackRuntime: nil)
    let validation_payload = make_validate_payload(
      request: PodRequestWithoutRuntime,
      settings: settings)

    let response_payload = validate(payload: validation_payload)

    let response : ValidationResponse = try! JSONDecoder().decode(
      ValidationResponse.self, from: Data(response_payload.utf8))

    XCTAssert(response.accepted)
    XCTAssertNil(response.message)
  }

  func testRejectBecauseDefaultRuntimeIsReserved() {
    let reservedRuntimes: Set<String> = ["runC"]
    let settings = Settings(
      reservedRuntimes: reservedRuntimes,
      defaultRuntimeReserved: true,
      fallbackRuntime: nil)
    let validation_payload = make_validate_payload(
      request: PodRequestWithoutRuntime,
      settings: settings)

    let response_payload = validate(payload: validation_payload)

    let response : ValidationResponse = try! JSONDecoder().decode(
      ValidationResponse.self, from: Data(response_payload.utf8))

    XCTAssert(!response.accepted)
    XCTAssertEqual("Usage of the default runtime is reserved", response.message)
  }

  func testAcceptBecauseSpecifiedRuntimeIsNotReserved() {
    let reservedRuntimes: Set<String> = ["runC"]
    let settings = Settings(
      reservedRuntimes: reservedRuntimes,
      defaultRuntimeReserved: true,
      fallbackRuntime: nil)
    let validation_payload = make_validate_payload(
      request: PodRequestWithKataRuntime,
      settings: settings)

    let response_payload = validate(payload: validation_payload)

    let response : ValidationResponse = try! JSONDecoder().decode(
      ValidationResponse.self, from: Data(response_payload.utf8))

    XCTAssert(response.accepted)
    XCTAssertNil(response.message)
  }

  func testRejectBecauseRuntimeIsReserved() {
    let reservedRuntimes: Set<String> = ["kata"]
    let settings = Settings(
      reservedRuntimes: reservedRuntimes,
      defaultRuntimeReserved: true,
      fallbackRuntime: nil)
    let validation_payload = make_validate_payload(
      request: PodRequestWithKataRuntime,
      settings: settings)

    let response_payload = validate(payload: validation_payload)

    let response : ValidationResponse = try! JSONDecoder().decode(
      ValidationResponse.self, from: Data(response_payload.utf8))

    XCTAssert(!response.accepted)
    XCTAssertEqual("runtime 'kata' is reserved", response.message)
  }

  func testChangeRuntimeBecauseOriginalOneIsReserved() {
    let reservedRuntimes: Set<String> = ["runC"]
    let settings = Settings(
      reservedRuntimes: reservedRuntimes,
      defaultRuntimeReserved: true,
      fallbackRuntime: "kata")
    let validation_payload = make_validate_payload(
      request: PodRequestWithRuncRuntime,
      settings: settings)

    let response_payload = validate(payload: validation_payload)

    let response : ValidationResponse = try! JSONDecoder().decode(
      ValidationResponse.self, from: Data(response_payload.utf8))

    XCTAssert(response.accepted)
    XCTAssertNil(response.message)
    XCTAssertNotNil(response.mutatedObject)

    if let mutatedObject = response.mutatedObject,
      let newRuntime = mutatedObject[keyPath: "spec.runtimeClassName"] {
      XCTAssertEqual("kata", newRuntime)
    } else {
      XCTFail("Could not get new runtime from mutated object")
    }
  }

  func testChangeRuntimeBecauseDefaultOneIsReserved() {
    let reservedRuntimes: Set<String> = ["runC"]
    let settings = Settings(
      reservedRuntimes: reservedRuntimes,
      defaultRuntimeReserved: true,
      fallbackRuntime: "kata")
    let validation_payload = make_validate_payload(
      request: PodRequestWithoutRuntime,
      settings: settings)

    let response_payload = validate(payload: validation_payload)

    let response : ValidationResponse = try! JSONDecoder().decode(
      ValidationResponse.self, from: Data(response_payload.utf8))

    XCTAssert(response.accepted)
    XCTAssertNil(response.message)
    XCTAssertNotNil(response.mutatedObject)

    if let mutatedObject = response.mutatedObject,
      let newRuntime = mutatedObject[keyPath: "spec.runtimeClassName"] {
      XCTAssertEqual("kata", newRuntime)
    } else {
      XCTFail("Could not get new runtime from mutated object")
    }
  }


  static var allTests = [
    ("testAcceptBecauseDefaultRuntimeIsNotReserved", testAcceptBecauseDefaultRuntimeIsNotReserved),
    ("testRejectBecauseDefaultRuntimeIsReserved", testRejectBecauseDefaultRuntimeIsReserved),
    ("testAcceptBecauseSpecifiedRuntimeIsNotReserved", testAcceptBecauseDefaultRuntimeIsNotReserved),
    ("testRejectBecauseRuntimeIsReserved", testRejectBecauseRuntimeIsReserved),
    ("testChangeRuntimeBecauseOriginalOneIsReserved", testChangeRuntimeBecauseOriginalOneIsReserved),
    ("testChangeRuntimeBecauseDefaultOneIsReserved", testChangeRuntimeBecauseDefaultOneIsReserved),
  ]
}
