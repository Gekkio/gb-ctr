BANK1 = 0x2000
BANK2 = 0x4000
MODE = 0x6000
write_byte(MODE, 0x01)
for bank in range(0, num_banks):
    write_byte(BANK1, bank)
    if is_multicart:
        write_byte(BANK2, bank >> 4)
        bank_start = 0x4000 if bank & 0x0f else 0x0000
    else:
        write_byte(BANK2, bank >> 5)
        bank_start = 0x4000 if bank & 0x1f else 0x0000
    for addr in range(bank_start, bank_start + 0x4000):
        buf += read_byte(addr)
