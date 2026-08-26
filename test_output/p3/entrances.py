from enum import Enum

from .regions import Regions
from rule_builder.rules import True_
class EntranceGroups(IntFlag):
    NONE = 0
    1 = 1 << 0
    3 = 1 << 1
    2 = 1 << 2
    4 = 1 << 3
    5 = 1 << 4
class Entrances(EntranceTypeEnum):
    REGION_TO_REGION_1 = ("Region To Region 1", Regions.REGION, Regions.REGION_1, 0)
