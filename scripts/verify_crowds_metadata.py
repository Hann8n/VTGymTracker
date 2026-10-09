#!/usr/bin/env python3
"""Verify Xcode's extracted system-facing contract, not just Swift declarations."""
import json
import sys
from pathlib import Path

app = Path(sys.argv[1])
data = json.loads((app / "Metadata.appintents/extract.actionsdata").read_text())
action = data["actions"]["CurrentCrowdsIntent"]
assert action["isDiscoverable"] is True
assert action["openAppWhenRun"] is False
assert action["parameters"][0]["name"] == "facility"
assert action["outputType"]["array"]["wrapper"]["memberValueType"]["entity"]["wrapper"]["typeName"] == "FacilityCrowdsEntity"
props = {p["identifier"]: p for p in data["entities"]["FacilityCrowdsEntity"]["properties"]}
required = {"facility", "facilityID", "name", "isClimbingFacility", "count", "capacity", "fullnessPercent", "status", "fetchedAt", "checkedAt", "lastSuccessfulFetchAt", "sourceMeasuredAt", "cacheAgeSeconds", "availabilityDetail", "source", "sourceURL", "sourceLimitation"}
assert props.keys() == required
for name in ["count", "fullnessPercent", "fetchedAt", "sourceMeasuredAt", "cacheAgeSeconds", "lastSuccessfulFetchAt"]:
    assert props[name]["isOptional"] is True, name
choices = next(e for e in data["enums"] if e["identifier"] == "TrackedFacility")
assert {c["identifier"] for c in choices["cases"]} == {"allFacilities", "mcComas", "warMemorial", "boulderingWall"}
war = next(c for c in choices["cases"] if c["identifier"] == "warMemorial")
assert "War" in {s["key"] for s in war["displayRepresentation"]["synonyms"]}
assert len(data["autoShortcuts"]) == 1
phrases = (app / "Metadata.appintents/root.ssu.yaml").read_text()
for phrase in ["Check current crowds", "Compare gyms", "Check crowds at", "How busy is"]:
    assert phrase in phrases
print("PASS: one discoverable background action, four choices/aliases, typed array with 17 properties and optional unknowns, four trained phrases")
