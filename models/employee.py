from dataclasses import dataclass, field
from typing import List
from datetime import date
import calendar

@dataclass
class Allowance:
    name: str
    amount: float

@dataclass
class Deduction:
    name: str
    amount: float

@dataclass
class Employee:
    id: str
    name: str
    position: str
    department: str
    join_date: date
    base_salary: float
    hourly_rate: float
    allowances: List[Allowance] = field(default_factory=list)
    deductions: List[Deduction] = field(default_factory=list)
    overtime_hours: float = 0.0
    bonus: float = 0.0
    unpaid_leave_days: int = 0

    def total_allowances(self) -> float:
        return sum(a.amount for a in self.allowances)

    def total_deductions(self) -> float:
        return sum(d.amount for d in self.deductions)

    def working_days_in_month(self, year: int, month: int) -> int:
        return calendar.monthrange(year, month)[1]
