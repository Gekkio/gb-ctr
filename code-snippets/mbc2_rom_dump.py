for bank in range(0, num_banks):
    write_byte(0x2100, bank)
    bank_start = 0x4000 if bank > 0 else 0x0000
    for addr in range(bank_start, bank_start + 0x4000):
        buf += read_byte(addr)
