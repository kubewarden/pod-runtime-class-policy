import XCTest
import class Foundation.Bundle
@testable import Policy

final class ValidateTests: XCTestCase {
    func testAcceptBecauseOperationNotRelevant() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "",
        trustedGroups: "trusted-users")
      let result = validate(rawJSON: PodDeleteRequest, config: config)

      XCTAssert(result.accepted)
      XCTAssertEqual("", result.message)
    }

    func testRejectBecauseUserNotPartOfTrustedGroups() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "",
        trustedGroups: "trusted-users")
      let result = validate(rawJSON: PodRequestWithRuncRuntime, config: config)

      XCTAssert(!result.accepted)
      XCTAssert(!result.message.isEmpty)
    }

    func testRejectBecauseUserNotPartOfTrustedUsers() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "alice,bob",
        trustedGroups: "")
      let result = validate(rawJSON: PodRequestWithRuncRuntime, config: config)

      XCTAssert(!result.accepted)
      XCTAssert(!result.message.isEmpty)
    }

    func testAcceptBecauseUserPartOfTrustedUsers() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "kubernetes-admin,alice,bob",
        trustedGroups: "")
      let result = validate(rawJSON: PodRequestWithRuncRuntime, config: config)

      XCTAssert(result.accepted)
      XCTAssert(result.message.isEmpty)
    }

    func testAcceptBecauseUserPartOfTrustedGroup() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "alice,bob",
        trustedGroups: "system:masters,trusted-users")
      let result = validate(rawJSON: PodRequestWithRuncRuntime, config: config)

      XCTAssert(result.accepted)
      XCTAssert(result.message.isEmpty)
    }

    func testAcceptBecauseSpecifiedRuntimeIsNotReserved() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "alice,bob",
        trustedGroups: "trusted-users")
      let result = validate(rawJSON: PodRequestWithKataRuntime, config: config)

      XCTAssert(result.accepted)
      XCTAssert(result.message.isEmpty)
    }

    func testAcceptBecauseDefaultRuntimeIsNotReserved() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: false,
        trustedUsers: "alice,bob",
        trustedGroups: "trusted-users")
      let result = validate(rawJSON: PodRequestWithoutRuntime, config: config)

      XCTAssert(result.accepted)
      XCTAssert(result.message.isEmpty)
    }

    func testRejectBecauseDefaultRuntimeIsReserved() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "alice,bob",
        trustedGroups: "trusted-users")
      let result = validate(rawJSON: PodRequestWithoutRuntime, config: config)

      XCTAssert(!result.accepted)
      XCTAssert(!result.message.isEmpty)
    }

    func testAcceptBecauseDefaultRuntimeIsReservedButUserIsTrusted() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "kubernetes-admin,alice,bob",
        trustedGroups: "trusted-users")
      let result = validate(rawJSON: PodRequestWithoutRuntime, config: config)

      XCTAssert(result.accepted)
      XCTAssert(result.message.isEmpty)
    }

    func testAcceptBecauseDefaultRuntimeIsReservedButBelongsToTrustedGroup() {
      let config = Config(
        reservedRuntime: "runC",
        defaultRuntimeReserved: true,
        trustedUsers: "alice,bob",
        trustedGroups: "system:masters,trusted-users")
      let result = validate(rawJSON: PodRequestWithoutRuntime, config: config)

      XCTAssert(result.accepted)
      XCTAssert(result.message.isEmpty)
    }

    static var allTests = [
      ("testRejectBecauseUserNotPartOfTrustedUsers", testRejectBecauseUserNotPartOfTrustedUsers),
      ("testRejectBecauseUserNotPartOfTrustedGroups", testRejectBecauseUserNotPartOfTrustedGroups),
      ("testAcceptBecauseOperationNotRelevant", testAcceptBecauseOperationNotRelevant),
      ("testAcceptBecauseUserPartOfTrustedUsers", testAcceptBecauseUserPartOfTrustedUsers),
      ("testAcceptBecauseUserPartOfTrustedGroup", testAcceptBecauseUserPartOfTrustedGroup),
      ("testAcceptBecauseSpecifiedRuntimeIsNotReserved", testAcceptBecauseSpecifiedRuntimeIsNotReserved),
      ("testAcceptBecauseDefaultRuntimeIsNotReserved", testAcceptBecauseDefaultRuntimeIsNotReserved),
      ("testRejectBecauseDefaultRuntimeIsReserved", testRejectBecauseDefaultRuntimeIsReserved),
      ("testAcceptBecauseDefaultRuntimeIsReservedButUserIsTrusted", testAcceptBecauseDefaultRuntimeIsReservedButUserIsTrusted),
      ("testAcceptBecauseDefaultRuntimeIsReservedButBelongsToTrustedGroup", testAcceptBecauseDefaultRuntimeIsReservedButBelongsToTrustedGroup),
    ]
}
