from math import exp
from matplotlib import pyplot as plt


def q(k, lamb) -> float:
    b = exp(-3.3*10**(-9)*k - 0.0029)
    frac1 = 0.31 - (3.3*10**(-9)*k + 0.0029)*lamb
    frac2 = 0.31 + (b - 1)*lamb
    return frac1 * b / frac2


def r(k, lamb) -> float:
    return 21*lamb*k


def r_real(k, lamb) -> float:
    return r(k, lamb) * q(k, lamb)


def t(k, lamb) -> float:
    frac1 = (10**(-8)*k + 0.0093)**2 * lamb - 2.1*10**(-8)*k - 0.019
    frac2 = (2.1*10**(-8)*k + 0.019)*lamb - 2
    return frac1/frac2


def lim(k) -> float:
    return 1 / (10**(-8)*k + 0.0093)


def lim_real(k, d, func, target) -> float:
    limit = lim(k)
    in_range = []
    for lamb in range(int(limit*d)-5*d, int(limit*d)+5*d):
        if target[0] <= abs(func(k, lamb/d)) <= target[1]:
            in_range.append(lamb/d)
    if in_range:
        return min(in_range)
    raise RuntimeError('No real limit found.')


def lim_real_diffs(k, d, func) -> float:
    limit = lim(k)
    # Count average diff in last 50 values.
    lambs = [x/d for x in range(int((limit-1))*d, int(limit)*d)]
    print(lambs[-10:])

    diffs = [
        abs(func(k, lambs[i]) - func(k, lambs[i-1]))
        for i in range(len(lambs[-5:]))
    ]
    avg_diff = sum(diffs) / len(diffs)

    # Search.
    previous = func(k, limit-5)
    for lamb in range(int(limit*d)-5*d, int(limit*d)+5*d):
        f = func(k, lamb/d)
        if abs(f - previous) >= avg_diff:
            print(lamb/d)
            return lamb/d
    raise RuntimeError('No huge diff found.')


def draw_plot(ax, x, y, maximum, label, color, width=1.0) -> None:
    ax.plot(x, y, label=label, color=color, linewidth=width)
    ax.axvline(x=maximum, linestyle='--', color=color, label=f'l* = {maximum:.2f}', linewidth=width)
    ax.axhline(y=0, linestyle='-', color='black', linewidth=0.7)
    ax.axvline(x=x[0], linestyle='-', color='black', linewidth=0.7)


def plot(
        step, k_list, y_func, y_label, is_decr,
        lim_method=0, limits=None, lim_target=None
) -> None:
    """Calculate <y_func> and create plot

    :param step: Value calculation step
    :param k_list: Param k values
    :param y_func: Function to calculate
    :param y_label: Y label of plot
    :param is_decr: bool - Is function decreasing or not
    :param lim_method:
        0 - formula,
        1 - look for func(l) near 0,
        2 - use custom limits
    :param limits: Use with lim_method = 3
    :param lim_target: Use with lim_method = 1
    :return: None
    """

    # Line colors
    if lim_target is None:
        lim_target = [-0.1, 0.1]
    colors = ['red', 'green', 'blue']

    # Get lambda values (limits and range)
    lamb_values_expanded = [x/step for x in range(0, 200*step)]
    if lim_method == 0:
        lamb_max_values = [lim(k) for k in k_list]
    elif lim_method == 1:
        lamb_max_values = [lim_real(k, step, y_func, lim_target) for k in k_list]
    elif lim_method == 2:
        lamb_max_values = limits
    else:
        raise AttributeError('Unknown limit search method provided.')

    # Draw graphics.
    fig_full, ax_full = plt.subplots()
    fig_enl, ax_enl = plt.subplots()
    for i, k in enumerate(k_list):
        l_max = lamb_max_values[i]
        x = lamb_values_expanded[:int(l_max*step)+1]
        y = [y_func(k, lamb) for lamb in x if 0 <= y_func(k, lamb)]
        x = x[:len(y)-1] + [l_max]
        y[-1] = y_func(k, l_max) if not is_decr else 0
        # Full graph.
        draw_plot(
            ax_full, x, y, l_max, label=f'k={k}',
            color=colors[k_list.index(k)], width=0.7
        )
        # Enlarged graph.
        draw_plot(
            ax_enl, x[100*step:], y[100*step:], l_max, label=f'k={k}',
            color=colors[k_list.index(k)]
        )
        print('--------------------------------------')
        print(f'Last 5 values of {y_func.__name__}(k={k}):')
        print('x:', *x[-5:])
        print('y:', *y[-5:])

    # Labels and legend.
    ax_full.set_xlabel('Lambda, пак/с')
    ax_full.set_ylabel(y_label)
    ax_full.legend(loc='upper left')
    ax_enl.set_xlabel('Lambda, пак/с')
    ax_enl.set_ylabel(y_label)
    ax_enl.legend(loc='upper left')

    plt.show()


def main():
    step = 10000  # Value calculation step.
    k_list = [46*8, 512*8, 1500*8]  # k in range [46*8, 1500*8].

    plot(
        step, k_list, q, 'Q(lambda)', is_decr=True,
        lim_method=1, lim_target=[-0.1, 0.1]
    )
    plot(
        step, k_list, r, 'Rc(lambda), бит/с', is_decr=False, lim_method=0
    )
    plot(
        step, k_list, r_real, 'Rc{РВ}(lambda), бит/с', is_decr=True, lim_method=2,
        limits=[106.8, 106.4, 105.4]
    )
    plot(
        step, k_list, t, 't(lambda), с', is_decr=False,
        lim_method=1, lim_target=[0.95, 1.05]
    )


if __name__ == '__main__':
    main()
