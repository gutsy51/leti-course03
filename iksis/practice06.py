from math import log2, ceil


def show(lst):
    for x in lst:
        print(x)
    print()


def count_subnet(node_bit):
    bit = 16 - node_bit
    mask_bin = ('1' * 8) + '.' + ('1' * 8) + '.' + ('1' * bit + (8 - bit) * '0') + '.' + ('0' * 8)
    mask = '.'.join([str(int(x, base=2)) for x in mask_bin.split('.')])
    print(f'node: {node_bit}, subnet: {bit} - {mask} ({mask_bin}) /{bit + 16}')


def main():
    nodes = [
        850, 750, 920, 620, 750, 690, 1800, 1850, 6500, 3400, 7100, 20700
    ]
    nodes10 = [int(x + 0.1*x) for x in nodes]
    nodes_bit = [ceil(log2(x)) for x in nodes10]
    nodes_amount = [2**x for x in nodes_bit]

    show(nodes10)
    show(nodes_amount)
    show(nodes_bit)

    for node_bit in range(9, 16):
        count_subnet(node_bit)


if __name__ == '__main__':
    main()
