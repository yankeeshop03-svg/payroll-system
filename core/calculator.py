from models.employee import Employee
from core.tax import calculate_pph21
from models.payslip import Payslip
from config import (
    BPJS_TK_JHT_EMPLOYEE, BPJS_TK_JP_EMPLOYEE,
    BPJS_KES_EMPLOYEE, OVERTIME_MULTIPLIER_WEEKDAY,
    OVERTIME_MAX_HOURS,
)

class SalaryCalculator:
    def __init__(self, year: int, month: int):
        self.year = year
        self.month = month

    def calculate(self, emp: Employee) -> Payslip:
        total_days = emp.working_days_in_month(self.year, self.month)
        daily_salary = emp.base_salary / total_days
        effective_salary = emp.base_salary - (daily_salary * emp.unpaid_leave_days)

        hours = min(emp.overtime_hours, OVERTIME_MAX_HOURS)
        overtime_pay = hours * emp.hourly_rate * OVERTIME_MULTIPLIER_WEEKDAY

        bruto = (
            effective_salary
            + emp.total_allowances()
            + overtime_pay
            + emp.bonus
        )

        bpjs_tk = min(emp.base_salary, 9_299_999) * (BPJS_TK_JHT_EMPLOYEE + BPJS_TK_JP_EMPLOYEE)
        bpjs_kes = min(emp.base_salary, 12_000_000) * BPJS_KES_EMPLOYEE

        annual = bruto * 12
        pph21_yearly = calculate_pph21(annual)
        pph21_monthly = pph21_yearly / 12

        other_deductions = emp.total_deductions()
        total_deductions = bpjs_tk + bpjs_kes + pph21_monthly + other_deductions
        take_home = bruto - total_deductions

        return Payslip(
            employee=emp,
            period=f"{self.year}-{self.month:02d}",
            base_salary=effective_salary,
            total_allowances=emp.total_allowances(),
            overtime_pay=overtime_pay,
            bonus=emp.bonus,
            bruto=bruto,
            bpjs_tk=bpjs_tk,
            bpjs_kes=bpjs_kes,
            pph21=pph21_monthly,
            other_deductions=other_deductions,
            total_deductions=total_deductions,
            take_home_pay=take_home,
        )
