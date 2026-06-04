from datetime import date
from models.employee import Employee, Allowance, Deduction
from core.calculator import SalaryCalculator
from reports.generator import generate_payslip, format_rupiah

def sample_employee() -> Employee:
    return Employee(
        id="EMP001",
        name="Budi Santoso",
        position="Senior Developer",
        department="IT",
        join_date=date(2020, 1, 15),
        base_salary=12_000_000,
        hourly_rate=75_000,
        allowances=[
            Allowance("Transport", 1_000_000),
            Allowance("Makan", 800_000),
            Allowance("Jabatan", 2_000_000),
        ],
        deductions=[
            Deduction("Pinjaman Karyawan", 500_000),
        ],
        overtime_hours=10,
        bonus=1_500_000,
        unpaid_leave_days=1,
    )

if __name__ == "__main__":
    emp = sample_employee()
    calc = SalaryCalculator(year=2026, month=6)
    payslip = calc.calculate(emp)

    path = generate_payslip(payslip)
    print(f"✅ Slip gaji tersimpan: {path}")
    print(f"💰 Take Home Pay: {format_rupiah(payslip.take_home_pay)}")
