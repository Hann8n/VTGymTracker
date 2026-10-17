#!/usr/bin/env python3
"""Verify Xcode's extracted system-facing contract, not just Swift declarations.

Usage: verify_crowds_metadata.py APP [SSU_YAML]
Archives compile SSU assets; pass the same build's intermediate root.ssu.yaml.
"""
import plistlib
import json
import sys
from pathlib import Path

app = Path(sys.argv[1])
with (app / "Info.plist").open("rb") as source:
    info = plistlib.load(source)
assert info["CFBundleDisplayName"] == "Gym Tracker"
assert info["CFBundleName"] == "Gym Tracker"
assert any(alias["INAlternativeAppName"] == "VT Gym Tracker" for alias in info["INAlternativeAppNames"])
assert any(alias["INAlternativeAppName"] == "VT Gyms" for alias in info["INAlternativeAppNames"])
data = json.loads((app / "Metadata.appintents/extract.actionsdata").read_text())
action = data["actions"]["CurrentCrowdsIntent"]
assert action["isDiscoverable"] is True
assert action["openAppWhenRun"] is False
assert action["supportedModes"] == 1  # IntentModes.background, no foreground mode
assert action["parameters"][0]["name"] == "facility"
assert action["parameters"][0]["typeSpecificMetadata"][1]["string"]["wrapper"] == "bothGyms"
assert action["outputType"]["array"]["wrapper"]["memberValueType"]["entity"]["wrapper"]["typeName"] == "FacilityCrowdsEntity"
props = {p["identifier"]: p for p in data["entities"]["FacilityCrowdsEntity"]["properties"]}
required = {"facility", "facilityID", "name", "isClimbingFacility", "count", "capacity", "fullnessPercent", "status", "fetchedAt", "checkedAt", "lastSuccessfulFetchAt", "sourceMeasuredAt", "cacheAgeSeconds", "availabilityDetail", "source", "sourceURL", "sourceLimitation"}
assert props.keys() == required
for name in ["count", "fullnessPercent", "fetchedAt", "sourceMeasuredAt", "cacheAgeSeconds", "lastSuccessfulFetchAt"]:
    assert props[name]["isOptional"] is True, name
choices = next(e for e in data["enums"] if e["identifier"] == "TrackedFacility")
assert {c["identifier"] for c in choices["cases"]} == {"allFacilities", "bothGyms", "mcComas", "warMemorial", "boulderingWall"}
war = next(c for c in choices["cases"] if c["identifier"] == "warMemorial")
assert "War" in {s["key"] for s in war["displayRepresentation"]["synonyms"]}
def contains_type(value, expected):
    if isinstance(value, dict):
        return value.get("typeName") == expected or any(contains_type(v, expected) for v in value.values())
    if isinstance(value, list):
        return any(contains_type(v, expected) for v in value)
    return False

for identifier, output, parameters in [
    ("FindUpcomingEventsIntent", "EventSearchResultEntity", {"from", "before", "limit"}),
    ("GetEventDetailsIntent", "CampusEventEntity", {"event"}),
]:
    event_action = data["actions"][identifier]
    assert event_action["isDiscoverable"] is True
    assert event_action["openAppWhenRun"] is False
    assert event_action["supportedModes"] == 1
    assert {p["name"] for p in event_action["parameters"]} == parameters
    assert contains_type(event_action["outputType"], output), identifier

event_props = {p["identifier"]: p for p in data["entities"]["CampusEventEntity"]["properties"]}
assert event_props.keys() == {"eventID", "title", "startDate", "endDate", "timeZoneIdentifier", "sourceTimeZoneText", "location", "organizer", "priceText", "eventURL", "status", "fetchedAt", "checkedAt", "cacheAgeSeconds", "availabilityDetail", "sourceFeedURL"}
for name in ["title", "startDate", "endDate", "sourceTimeZoneText", "location", "organizer", "priceText", "eventURL", "fetchedAt", "cacheAgeSeconds"]:
    assert event_props[name]["isOptional"] is True, name
search_props = {p["identifier"]: p for p in data["entities"]["EventSearchResultEntity"]["properties"]}
assert search_props.keys() == {"events", "returnedCount", "matchingCount", "from", "before", "limit", "status", "fetchedAt", "checkedAt", "cacheAgeSeconds", "rejectedRecordCount", "availabilityDetail", "sourceFeedURL", "sourceLimitation"}
assert search_props["matchingCount"]["isOptional"] is True
assert contains_type(search_props["events"], "CampusEventEntity")
recommend = data["actions"]["RecommendGymIntent"]
assert recommend["openAppWhenRun"] is False and recommend["supportedModes"] == 1
assert recommend["isDiscoverable"] is True
assert contains_type(recommend["outputType"], "FacilityCrowdsEntity")
assert len(data["autoShortcuts"]) == 4
phrase_path = Path(sys.argv[2]) if len(sys.argv) > 2 else app / "Metadata.appintents/root.ssu.yaml"
phrases = phrase_path.read_text()
assert sum("'{${+prefix} }" in line and "standardAppShortcutNegatives" not in line for line in phrases.splitlines()) == 29
for phrase in ["Check current crowds", "Compare gyms", "Check crowds at", "How busy is", "Check the ${TrackedFacility} crowds", "Check ${TrackedFacility} crowds", "What are the crowds at", "How crowded is", "What is the occupancy at", "What are the crowds like at", "Check which gym I should go to", "Which gym is less crowded at", "Find a quieter gym", "Find upcoming events", "Find recreation events", "Get event details", "Get details for"]:
    assert phrase in phrases
print("PASS: four discoverable background actions; crowds with five choices/aliases and 17 properties; events with 16 factual properties and a 14-property search result; optional unknowns; 29 trained phrases; Gym Tracker name and VT Gyms Siri alias")
