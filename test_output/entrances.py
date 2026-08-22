from enum import Enum

from .regions import Regions
from rule_builder.rules import Has, True_

class EntranceTypeEnum(Enum):
    def __init__(self, value: str, exiting_region: RegionTypeEnum, entering_region: RegionTypeEnum, entrance_group: Number, rule = True_()):
        # self._value_ must be set to the first element to support lookup by value
        self._value_ = value
        self.exiting_screen = exiting_region
        self.entering_screen = entering_region
        self.entrance_group = entrance_group
        self.rule = rule


class Entrances(EntranceTypeEnum):    REGION_TO_REGION_1 = ("Region To Region 1", Regions.REGION, Regions.REGION_1, 0, {"children":[{"args":{"count":1.0,"item_name":"Burrow"},"options":[],"rule":"Has"},{"args":{"count":1.0,"item_name":"Climb"},"options":[],"rule":"Has"}],"options":[],"rule":"And"})
    REGION_1_TO_REGION_2 = ("Region 1 To Region 2", Regions.REGION_1, Regions.REGION_2, 0, {"args":{"distance":0},"options":[],"rule":"CanJumpTiles"})
    REGION_1_TO_REGION_2_BACK = ("Region 1 To Region 2 Backwards", Regions.REGION_2, Regions.REGION_1, 0, {"args":{"distance":0},"options":[],"rule":"CanJumpTiles"})
    REGION_2_TO_REGION = ("Region 2 To Region", Regions.REGION_2, Regions.REGION, 0, {"args":{"distance":0},"options":[],"rule":"CanJumpTiles"})
    REGION_2_TO_REGION_BACK = ("Region 2 To Region Backwards", Regions.REGION, Regions.REGION_2, 0, {"args":{"distance":0},"options":[],"rule":"CanJumpTiles"})
