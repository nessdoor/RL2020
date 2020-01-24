from sys import argv
from random import seed, randrange, shuffle
from typing import Collection, Sequence, List


def generate_test_zones(quantity: int) -> List[int]:
    zones = list()
    covered_addresses = set()
    while len(zones) < quantity:
        candidate = randrange(0, 125)

        if {candidate, candidate + 3}.isdisjoint(covered_addresses):
            zones.append(candidate)
            
            for a in range(candidate, candidate + 4):
                covered_addresses.add(a)

    return zones


def generate_test_inputs(zones: Collection[int]) -> List[int]:
    input_set = set()

    input_set.add(0)
    input_set.add(1)
    
    for wz in zones:
        for address in range(wz - 2, wz + 3):
            if 0 <= address <= 127:
                input_set.add(address)

    input_set.add(126)
    input_set.add(127)

    return list(input_set)


def encode_address(zones: Sequence[int], address: int) -> int:
    output = address
    
    for wz in zones:
        if wz <= address < wz + 4:
            return 128 | (zones.index(wz) << 4) | (1 << (address - wz))

    return output


def generate_wz(index: int, base: int) -> str:
    return " 100 ns 0 0 1 " + '{:04X}'.format(index) + " " + '{:02X}'.format(base)


def generate_input(address: int) -> str:
    return " 100 ns 0 0 1 0008 " + '{:02X}'.format(address)


def generate_start() -> str:
    return " 100 ns 0 1 0 0000 00"


def generate_checkpoint(expected: int) -> str:
    return "V " + '{:02X}'.format(expected)


def generate_reset() -> str:
    return " 100 ns 1 0 0 0000 00"


def generate_pause() -> str:
    return " 100 ns 0 0 0 0000 00"


if __name__ == '__main__':
    seed()
    iterations = 1

    if len(argv) > 1:
        iterations = int(argv[1])

    for i in range(0, iterations):
        print("# Iteration: " + str(i))

        wzs = generate_test_zones(8)
        inputs = generate_test_inputs(wzs)
        shuffle(inputs)

        for z in wzs:
            print(generate_wz(wzs.index(z), z))

        print(generate_input(inputs[-1]))
        print(generate_reset())
        print(generate_start())
        print(generate_checkpoint(encode_address(wzs, inputs.pop())))

        for i in inputs:
            print(generate_input(i))
            print(generate_start())
            print(generate_checkpoint(encode_address(wzs, i)))
