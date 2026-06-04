#!/bin/bash
set -e

echo "🚀 Membuat project payroll-system..."

# Buat folder
mkdir -p models core reports data output

# ===== config.py =====
cat > config.py << 'EOF'
BPJS_TK_JHT_EMPLOYEE = 0.02
BPJS_TK_JP_EMPLOYEE = 0.01
BPJS_KES_EMPLOYEE = 0.01
OVERTIME_MULTIPLIER_WEEKDAY = 1.5
OVERTIME_MAX_HOURS = 40

PPh_21_LAYERS = [
    (60_000_000, 0.05),
    (250_000_000, 0.15),
    (500_000_000, 0.25),
    (500_000_000, 0.30),
    (float('inf'), 0.35),
]

PTKP_DEFAULT = 54_000_000
EOF

# ===== models/__init__.py =====
cat > models/__init__.py << 'EOF'
EOF

# ===== models/employee.py =====
cat > models/employee.py << 'EOF'
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
EOF

# ===== models/payslip.py =====
cat > models/payslip.py << 'EOF'
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
EOF

# ===== core/__init__.py =====
cat > core/__init__.py << 'EOF'
EOF

# ===== core/tax.py =====
cat > core/tax.py << 'EOF'
from config import PPh_21_LAYERS, PTKP_DEFAULT

def calculate_pph21(annual_income: float, ptkp: float = PTKP_DEFAULT) -> float:
    pkp = max(0, annual_income - ptkp)
    if pkp == 0:
        return 0.0

    tax = 0.0
    prev = 0.0
    for limit, rate in PPh_21_LAYERS:
        if pkp > prev:
            taxable = min(pkp, limit) - prev
            tax += taxable * rate
            prev = limit
        else:
            break
    return tax
EOF

# ===== core/calculator.py =====
cat > core/calculator.py << 'EOF'
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
EOF

# ===== reports/__init__.py =====
cat > reports/__init__.py << 'EOF'
EOF

# ===== reports/generator.py =====
cat > reports/generator.py << 'EOF'
import os
from models.payslip import Payslip

def format_rupiah(amount: float) -> str:
    return f"Rp {amount:,.0f}".replace(",", ".")

def generate_payslip(payslip: Payslip, output_dir: str = "output") -> str:
    os.makedirs(output_dir, exist_ok=True)
    filename = f"{output_dir}/slip_{payslip.employee.id}_{payslip.period}.txt"
    e = payslip.employee

    lines = [
        "=" * 50,
        f"{'SLIP GAJI':^50}",
        f"Periode: {payslip.period}",
        "=" * 50,
        f"ID Karyawan : {e.id}",
        f"Nama        : {e.name}",
        f"Jabatan     : {e.position}",
        f"Departemen  : {e.department}",
        "-" * 50,
        "PENDAPATAN:",
        f"  Gaji Pokok              {format_rupiah(payslip.base_salary):>20}",
        f"  Tunjangan               {format_rupiah(payslip.total_allowances):>20}",
        f"  Lembur                  {format_rupiah(payslip.overtime_pay):>20}",
        f"  Bonus                   {format_rupiah(payslip.bonus):>20}",
        f"  {'GAJI BRUTO':<28}{format_rupiah(payslip.bruto):>20}",
        "-" * 50,
        "POTONGAN:",
        f"  BPJS TK                 {format_rupiah(payslip.bpjs_tk):>20}",
        f"  BPJS Kesehatan          {format_rupiah(payslip.bpjs_kes):>20}",
        f"  PPh 21                  {format_rupiah(payslip.pph21):>20}",
        f"  Potongan Lain           {format_rupiah(payslip.other_deductions):>20}",
        f"  {'TOTAL POTONGAN':<28}{format_rupiah(payslip.total_deductions):>20}",
        "=" * 50,
        f"  {'TAKE HOME PAY':<28}{format_rupiah(payslip.take_home_pay):>20}",
        "=" * 50,
    ]

    with open(filename, "w") as f:
        f.write("\n".join(lines))
    return filename
EOF

# ===== main.py =====
cat > main.py << 'EOF'
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
EOF

# ===== .gitignore =====
cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
venv/
env/
.vscode/
.idea/
output/
*.txt
EOF

# ===== README.md =====
cat > README.md << 'EOF'
# 💰 Payroll System

Sistem penghitungan gaji bulanan karyawan berbasis Python.

## Fitur
- Hitung gaji pokok, tunjangan, lembur, bonus
- Potongan BPJS TK, BPJS Kesehatan, PPh 21
- Generate slip gaji otomatis

## Cara Pakai
```bash
python main.py
