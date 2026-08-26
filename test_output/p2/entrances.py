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


class Entrances(EntranceTypeEnum):
    REGION_TO_REGION_1 = ("Region To Region 1", Regions.REGION, Regions.REGION_1, 0, {"args":{"54":"tr"},"options":[],"rule":"4545"})
