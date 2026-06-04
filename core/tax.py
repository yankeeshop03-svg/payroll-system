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
