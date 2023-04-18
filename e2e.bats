#!/usr/bin/env bats

@test "reject because runtime is reserved" {
  run kwctl run policy.wasm -r test_data/PodRequestWithRuncRuntime.json --settings-json '{"reservedRuntimes": ["runC"]}'

  # this prints the output when one the checks below fails
  echo "output = ${output}"

  # request rejected
  [ "$status" -eq 0 ]
  [ $(expr "$output" : '.*allowed.*false*') -ne 0 ]
  [ $(expr "$output" : ".*'runC' is reserved.*") -ne 0 ]

}

@test "accept because runtime is not reserved" {
  run kwctl run policy.wasm -r test_data/PodRequestWithRuncRuntime.json --settings-json '{"reservedRuntimes": ["gVisor"]}'
  # this prints the output when one the checks below fails
  echo "output = ${output}"

  # request accepted
  [ "$status" -eq 0 ]
  [ $(expr "$output" : '.*allowed.*true') -ne 0 ]
}

@test "modify incoming request" {
  run kwctl run policy.wasm -r test_data/PodRequestWithRuncRuntime.json --settings-json '{"reservedRuntimes": ["runC"], "fallbackRuntime": "kata"}'
  # this prints the output when one the checks below fails
  echo "output = ${output}"

  # request accepted
  [ "$status" -eq 0 ]
  [ $(expr "$output" : '.*allowed.*true') -ne 0 ]
  [ $(expr "$output" : '.*patch":"W3sib3AiOiJyZXBsYWNlIiwicGF0aCI6Ii9zcGVjL3J1bnRpbWVDbGFzc05hbWUiLCJ2YWx1ZSI6ImthdGEifV0=') -ne 0 ]
}
