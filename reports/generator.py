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
