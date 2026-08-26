from enum import Enum

from .regions import Regions
from rule_builder.rules import True_

class EntranceTypeEnum(Enum):
    def __init__(self, value: str, exiting_region: RegionTypeEnum, entering_region: RegionTypeEnum, entrance_group: Number, rule = True_()):
        # self._value_ must be set to the first element to support lookup by value
        self._value_ = value
        self.exiting_screen = exiting_region
        self.entering_screen = entering_region
        self.entrance_group = entrance_group
        self.rule = rule


class Entrances(EntranceTypeEnum):
    REGION_TO_REGION_1 = ("Region To Region 1", Regions.REGION, Regions.REGION_1, 0, {"children":[{"args":{"distance":2.0},"options":[],"rule":"CanJumpTiles"},{"args":{"count":1.0,"item_name":"Burrow"},"options":[],"rule":"Has"}],"options":[],"rule":"And"})
    REGION_TO_REGION_4 = ("Region To Region 4", Regions.REGION, Regions.REGION_4, 0)
    REGION_4_TO_REGION = ("Region 4 To Region", Regions.REGION_4, Regions.REGION, 0)
    REGION_3_TO_REGION = ("Region 3 To Region", Regions.REGION_3, Regions.REGION, 0, {"children":[{"args":{"distance":2.0},"options":[],"rule":"CanJumpTiles"},{"args":{"count":1.0,"item_name":"Burrow"},"options":[],"rule":"Has"}],"options":[],"rule":"And"})
    REGION_3_TO_REGION_BACK = ("Region 3 To Region Backwards", Regions.REGION, Regions.REGION_3, 0, {"children":[{"args":{"distance":2.0},"options":[],"rule":"CanJumpTiles"},{"args":{"count":1.0,"item_name":"Burrow"},"options":[],"rule":"Has"}],"options":[],"rule":"And"})
