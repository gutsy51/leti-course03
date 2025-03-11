import matplotlib.pyplot as plt
from numpy import linspace


def count_erlang1(intensity, devices_count) -> float:
    """Returns the result of a recursive evaluation of the first Erlang formula"""
    if devices_count <= 0:
        return 1
    frac1 = intensity * count_erlang1(intensity, devices_count - 1)
    frac2 = devices_count + frac1
    return frac1 / frac2


def count_erlang2(intensity, devices_count) -> float:
    """Returns the result of a recursive evaluation of the second Erlang formula"""
    frac1 = count_erlang1(intensity, devices_count)
    frac2 = 1 - (intensity * (1 - frac1)) / devices_count
    return frac1 / frac2


def count_erlang_queue(intensity, devices_count) -> float:
    """Returns the result of a recursive evaluation of the Erlang queue formula"""
    frac1 = intensity * count_erlang1(intensity, devices_count)
    frac2 = devices_count - intensity + frac1
    return frac1 / frac2 * (devices_count / (devices_count - intensity))


def draw_plot(x, y, x_label, y_label) -> None:
    plt.plot(x, y, color='red')
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.grid()
    plt.show()


def main() -> None:
    n = 48
    min_value = 10**(-6)
    max_value = 1 - min_value

    # Graph of the probability of requests being blocked on the intensity of the incoming load
    # Number of devices = 2*n. The first Erlang formula is used
    x = linspace(0, 25000, 100)
    y = [count_erlang1(i, 2 * n) for i in x if count_erlang1(i, 2 * n) < max_value]
    draw_plot(
        x=x[:len(y)], y=y,
        x_label='Входящая интенсивность', y_label='Вероятность блокировки заявок'
    )

    # Graph of the probability of requests being blocked on the number of servicing devices
    # Incoming load intensity = n. The first Erlang formula is used
    x = linspace(0, 2 * n, 100)
    y = [count_erlang1(n, i) for i in x if count_erlang1(n, i) > min_value]
    draw_plot(
        x=x[:len(y)], y=y,
        x_label='Входящая интенсивность', y_label='Вероятность блокировки заявок'
    )

    # Graphs of the probability of waiting for the start of service and the average queue length
    # on the intensity of the incoming load.
    # Number of devices = 2*n. The second Erlang formula is used
    x = linspace(n, 2 * n, 100)
    y = [count_erlang2(i, 2 * n) for i in x]
    draw_plot(
        x=x[:len(y)], y=y,
        x_label='Число обслуживающих устройств', y_label='Вероятность ожидания начала обслуживания'
    )
    x = linspace(n, 2 * n, 100)
    y = [count_erlang_queue(i, 2 * n) for i in x]
    draw_plot(
        x=x[:len(y)], y=y,
        x_label='Входящая интенсивность', y_label='Средняя длина очереди'
    )

    # Graphs of the probability of waiting for the start of service and the average queue length
    # from the number of serving devices.
    # Incoming load intensity = n. The second Erlang formula is used
    x = linspace(n, 2 * n, 100)
    y = [count_erlang2(n, i) for i in x if count_erlang2(n, i) > min_value]
    draw_plot(
        x=x[:len(y)], y=y,
        x_label='Число обслуживающих устройств', y_label='Вероятность ожидания начала обслуживания'
    )
    print('2.3.1', len(y), y[-10:])
    x = linspace(n, 2 * n, 100)
    y = [count_erlang_queue(n, i) for i in x if count_erlang_queue(n, i) > min_value]
    draw_plot(
        x=x[:len(y)], y=y,
        x_label='Число обслуживающих устройств', y_label='Средняя длина очереди'
    )
    print('2.3.2', len(y), y[-10:])


if __name__ == '__main__':
    main()
