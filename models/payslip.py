from dataclasses import dataclass
from models.employee import Employee

@dataclass
class Payslip:
    employee: Employee
    period: str
    base_salary: float
    total_allowances: float
    overtime_pay: float
    bonus: float
    bruto: float
    bpjs_tk: float
    bpjs_kes: float
    pph21: float
    other_deductions: float
    total_deductions: float
    take_home_pay: float
