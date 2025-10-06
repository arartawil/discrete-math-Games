from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Tuple, List, Callable

import numpy as np
import cvxpy as cp

from models import (
    SimulationConfig,
    build_empty_schedule,
    propagate_soc,
    enforce_power_balance,
    check_feasibility,
    compute_costs,
    aggregate_power,
    combine_profiles_with_signals,
)


@dataclass
class AlgorithmResult:
    schedule: Dict[str, np.ndarray]
    price: np.ndarray
    carbon: np.ndarray
    iterations: int
    convergence: List[float]
    costs: np.ndarray
    diagnostics: Dict[str, np.ndarray]


def _solve_prosumer(
    profile: Dict[str, np.ndarray],
    config: SimulationConfig,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    T = config.T
    c = cp.Variable(T)
    d = cp.Variable(T)
    g = cp.Variable(T)
    e = cp.Variable(T)
    s = cp.Variable(T + 1)
    peak = cp.Variable(T)

    constraints = [
        c >= 0,
        d >= 0,
        g >= 0,
        e >= 0,
        peak >= 0,
        c <= config.c_max,
        d <= config.d_max,
        g <= config.g_max,
        e <= config.e_max,
        s[0] == profile["s0"],
        s <= config.s_max,
        s >= config.s_min,
    ]

    for t in range(T):
        constraints.append(
            s[t + 1]
            == s[t]
            + config.eta_c * c[t]
            - d[t] / config.eta_d
        )
        constraints.append(
            profile["L"][t]
            == profile["G"][t]
            + d[t]
            + g[t]
            - c[t]
            - e[t]
        )
        constraints.append(
            peak[t] >= profile["L"][t] - profile["L_hat"]
        )

    objective = cp.sum(
        profile["p"] * (g - e)
        + profile["lambda"] * config.k_g * g
        + config.delta * (c + d)
        + config.alpha * peak
    )

    problem = cp.Problem(cp.Minimize(objective), constraints)
    problem.solve(solver=cp.OSQP, verbose=False, max_iter=100000)
    if problem.status not in (cp.OPTIMAL, cp.OPTIMAL_INACCURATE):
        raise RuntimeError(f"Prosumer optimisation failed: {problem.status}")
    return (
        np.array(c.value).astype(float),
        np.array(d.value).astype(float),
        np.array(g.value).astype(float),
        np.array(e.value).astype(float),
        np.array(s.value).astype(float),
    )


def _stack_schedule(
    c_list: List[np.ndarray],
    d_list: List[np.ndarray],
    g_list: List[np.ndarray],
    e_list: List[np.ndarray],
    s_list: List[np.ndarray],
) -> Dict[str, np.ndarray]:
    schedule = {
        "c": np.vstack(c_list),
        "d": np.vstack(d_list),
        "g": np.vstack(g_list),
        "e": np.vstack(e_list),
        "s": np.vstack(s_list),
    }
    return schedule


def algorithm_a(
    profiles: Dict[str, np.ndarray],
    config: SimulationConfig,
) -> AlgorithmResult:
    N, T = profiles["G"].shape
    schedule = build_empty_schedule(N, T)
    s = schedule["s"]
    s[:, 0] = profiles["s0"]

    for t in range(T):
        net = profiles["L"][:, t] - profiles["G"][:, t]
        soc = s[:, t]

        max_discharge = np.minimum(
            config.d_max,
            config.eta_d * np.maximum(soc - config.s_min, 0.0),
        )
        discharge = np.minimum(np.maximum(net, 0.0), max_discharge)
        schedule["d"][:, t] = discharge
        soc -= discharge / config.eta_d

        residual = net - discharge

        max_charge = np.minimum(
            config.c_max,
            np.maximum(config.s_max - soc, 0.0) / max(config.eta_c, 1e-6),
        )
        charge = np.minimum(np.maximum(-residual, 0.0), max_charge)
        schedule["c"][:, t] = charge
        soc += config.eta_c * charge

        residual = residual + charge
        import_power = np.maximum(residual, 0.0)
        export_power = np.maximum(-residual, 0.0)
        schedule["g"][:, t] = np.minimum(import_power, config.g_max)
        schedule["e"][:, t] = np.minimum(export_power, config.e_max)
        s[:, t + 1] = np.clip(soc, config.s_min, config.s_max)

    enforce_power_balance(schedule, profiles, config)
    check_feasibility(schedule, profiles, config)
    costs, diagnostics = compute_costs(schedule, profiles, config)
    return AlgorithmResult(
        schedule=schedule,
        price=profiles["p"],
        carbon=profiles["lambda"],
        iterations=1,
        convergence=[0.0],
        costs=costs,
        diagnostics=diagnostics,
    )


def _best_response_all(
    profiles: Dict[str, np.ndarray],
    price: np.ndarray,
    carbon: np.ndarray,
    config: SimulationConfig,
) -> Dict[str, np.ndarray]:
    N = profiles["G"].shape[0]
    c_list: List[np.ndarray] = []
    d_list: List[np.ndarray] = []
    g_list: List[np.ndarray] = []
    e_list: List[np.ndarray] = []
    s_list: List[np.ndarray] = []
    for i in range(N):
        profile_i = {
            "G": profiles["G"][i],
            "L": profiles["L"][i],
            "s0": profiles["s0"][i],
            "L_hat": profiles["L_hat"][i],
            "p": price,
            "lambda": carbon,
        }
        c_i, d_i, g_i, e_i, s_i = _solve_prosumer(profile_i, config)
        c_list.append(c_i)
        d_list.append(d_i)
        g_list.append(g_i)
        e_list.append(e_i)
        s_list.append(s_i)
    return _stack_schedule(c_list, d_list, g_list, e_list, s_list)


def _update_signals_from_net(
    base_price: np.ndarray,
    base_carbon: np.ndarray,
    net_import: np.ndarray,
    config: SimulationConfig,
    beta_p: float = 5e-4,
    beta_c: float = 5e-4,
) -> Tuple[np.ndarray, np.ndarray]:
    price = np.clip(
        base_price + beta_p * (net_import - np.mean(net_import)),
        config.p_min,
        config.p_max,
    )
    carbon = np.clip(
        base_carbon + beta_c * (net_import - np.mean(net_import)),
        config.lambda_min,
        config.lambda_max,
    )
    return price, carbon


def algorithm_b(
    profiles: Dict[str, np.ndarray],
    config: SimulationConfig,
    tol: float = 1e-4,
    max_iter: int = 500,
) -> AlgorithmResult:
    base_price = profiles["p"].copy()
    base_carbon = profiles["lambda"].copy()
    result_a = algorithm_a(profiles, config)
    schedule = result_a.schedule
    convergence: List[float] = []

    for k in range(max_iter):
        agg = aggregate_power(schedule, profiles)
        price, carbon = _update_signals_from_net(
            base_price, base_carbon, agg["net_import"], config
        )
        new_schedule = _best_response_all(profiles, price, carbon, config)
        diff = max(
            np.max(np.abs(new_schedule["c"] - schedule["c"])),
            np.max(np.abs(new_schedule["d"] - schedule["d"])),
            np.max(np.abs(new_schedule["g"] - schedule["g"])),
            np.max(np.abs(new_schedule["e"] - schedule["e"])),
        )
        convergence.append(float(diff))
        schedule = new_schedule
        if diff < tol:
            iterations = k + 1
            break
    else:
        iterations = max_iter
        price, carbon = _update_signals_from_net(
            base_price, base_carbon, aggregate_power(schedule, profiles)["net_import"], config
        )

    schedule = _best_response_all(profiles, price, carbon, config)
    propagate_soc(schedule, profiles["s0"], config)
    final_profiles = combine_profiles_with_signals(profiles, price, carbon)
    check_feasibility(schedule, final_profiles, config)
    costs, diagnostics = compute_costs(schedule, final_profiles, config)
    return AlgorithmResult(
        schedule=schedule,
        price=price,
        carbon=carbon,
        iterations=iterations,
        convergence=convergence,
        costs=costs,
        diagnostics=diagnostics,
    )


def algorithm_c(
    profiles: Dict[str, np.ndarray],
    config: SimulationConfig,
    tol: float = 1e-4,
    max_iter: int = 200,
) -> AlgorithmResult:
    price = profiles["p"].copy()
    carbon = profiles["lambda"].copy()
    target_co2 = 0.8 * config.k_g * np.sum(profiles["G"])
    agg_load = np.sum(profiles["L"], axis=0)
    target_peak = 0.95 * np.max(agg_load)
    objective_trace: List[float] = []
    convergence: List[float] = []
    step_p = 0.01
    step_c = 0.01
    prev_price = price.copy()
    prev_carbon = carbon.copy()
    adjustments = 0
    iterations = 0

    while iterations < max_iter:
        schedule = _best_response_all(profiles, price, carbon, config)
        agg = aggregate_power(schedule, combine_profiles_with_signals(profiles, price, carbon))
        total_co2 = config.k_g * np.sum(agg["g"])
        peak_import = np.max(agg["net_import"])
        objective = (total_co2 - target_co2) ** 2 + 0.1 * (peak_import - target_peak) ** 2

        if objective_trace and objective > objective_trace[-1] + 1e-6:
            adjustments += 1
            if adjustments > 25:
                raise AssertionError("Leader objective not monotone")
            price = prev_price.copy()
            carbon = prev_carbon.copy()
            step_p *= 0.5
            step_c *= 0.5
            continue

        adjustments = 0
        objective_trace.append(float(objective))
        if len(objective_trace) > 1:
            gap = abs(objective_trace[-1] - objective_trace[-2])
            convergence.append(gap)
            if gap < tol:
                iterations += 1
                break

        emission_gap = total_co2 - target_co2
        congestion_gap = peak_import - target_peak
        prev_price = price.copy()
        prev_carbon = carbon.copy()
        price = np.clip(
            price - step_p * congestion_gap,
            config.p_min,
            config.p_max,
        )
        carbon = np.clip(
            carbon + step_c * emission_gap,
            config.lambda_min,
            config.lambda_max,
        )
        iterations += 1
    else:
        iterations = max_iter

    schedule = _best_response_all(profiles, price, carbon, config)
    propagate_soc(schedule, profiles["s0"], config)
    check_feasibility(schedule, combine_profiles_with_signals(profiles, price, carbon), config)
    costs, diagnostics = compute_costs(schedule, combine_profiles_with_signals(profiles, price, carbon), config)
    return AlgorithmResult(
        schedule=schedule,
        price=price,
        carbon=carbon,
        iterations=iterations,
        convergence=convergence or [0.0],
        costs=costs,
        diagnostics=diagnostics,
    )


def algorithm_d(
    profiles: Dict[str, np.ndarray],
    config: SimulationConfig,
) -> AlgorithmResult:
    N, T = profiles["G"].shape
    c = cp.Variable((N, T))
    d = cp.Variable((N, T))
    g = cp.Variable((N, T))
    e = cp.Variable((N, T))
    s = cp.Variable((N, T + 1))
    peak = cp.Variable((N, T))

    constraints = [
        c >= 0,
        d >= 0,
        g >= 0,
        e >= 0,
        peak >= 0,
        c <= config.c_max,
        d <= config.d_max,
        g <= config.g_max,
        e <= config.e_max,
        s[:, 0] == profiles["s0"],
        s <= config.s_max,
        s >= config.s_min,
    ]

    for t in range(T):
        constraints.append(
            s[:, t + 1]
            == s[:, t]
            + config.eta_c * c[:, t]
            - d[:, t] / config.eta_d
        )
        constraints.append(
            profiles["L"][:, t]
            == profiles["G"][:, t]
            + d[:, t]
            + g[:, t]
            - c[:, t]
            - e[:, t]
        )
        constraints.append(
            peak[:, t] >= profiles["L"][:, t] - profiles["L_hat"][:, None]
        )

    objective = cp.sum(
        cp.multiply(profiles["p"], g - e)
        + cp.multiply(profiles["lambda"], config.k_g * g)
        + config.delta * (c + d)
        + config.alpha * peak
    )
    problem = cp.Problem(cp.Minimize(objective), constraints)
    problem.solve(solver=cp.OSQP, verbose=False, max_iter=200000)
    if problem.status not in (cp.OPTIMAL, cp.OPTIMAL_INACCURATE):
        raise RuntimeError(f"Centralised optimisation failed: {problem.status}")
    schedule = {
        "c": np.array(c.value).astype(float),
        "d": np.array(d.value).astype(float),
        "g": np.array(g.value).astype(float),
        "e": np.array(e.value).astype(float),
        "s": np.array(s.value).astype(float),
    }
    propagate_soc(schedule, profiles["s0"], config)
    check_feasibility(schedule, profiles, config)
    costs, diagnostics = compute_costs(schedule, profiles, config)
    return AlgorithmResult(
        schedule=schedule,
        price=profiles["p"],
        carbon=profiles["lambda"],
        iterations=1,
        convergence=[0.0],
        costs=costs,
        diagnostics=diagnostics,
    )


def algorithm_e(
    profiles: Dict[str, np.ndarray],
    config: SimulationConfig,
    tol: float = 1e-4,
    max_iter: int = 500,
) -> AlgorithmResult:
    base_price = profiles["p"].copy()
    base_carbon = profiles["lambda"].copy()
    mean_field = np.mean(profiles["L"] - profiles["G"], axis=0)
    convergence: List[float] = []
    price = base_price.copy()
    carbon = base_carbon.copy()

    for k in range(max_iter):
        price, carbon = _update_signals_from_net(
            base_price,
            base_carbon,
            mean_field,
            config,
            beta_p=1e-3,
            beta_c=1e-3,
        )
        schedule = _best_response_all(profiles, price, carbon, config)
        agg = aggregate_power(schedule, combine_profiles_with_signals(profiles, price, carbon))
        new_mean_field = agg["net_import"] / profiles["G"].shape[0]
        diff = float(np.max(np.abs(new_mean_field - mean_field)))
        convergence.append(diff)
        mean_field = 0.5 * mean_field + 0.5 * new_mean_field
        if diff < tol:
            iterations = k + 1
            break
    else:
        iterations = max_iter

    schedule = _best_response_all(profiles, price, carbon, config)
    propagate_soc(schedule, profiles["s0"], config)
    check_feasibility(schedule, combine_profiles_with_signals(profiles, price, carbon), config)
    costs, diagnostics = compute_costs(schedule, combine_profiles_with_signals(profiles, price, carbon), config)
    return AlgorithmResult(
        schedule=schedule,
        price=price,
        carbon=carbon,
        iterations=iterations,
        convergence=convergence,
        costs=costs,
        diagnostics=diagnostics,
    )


ALGO_MAP: Dict[str, Callable[[Dict[str, np.ndarray], SimulationConfig], AlgorithmResult]] = {
    "A": algorithm_a,
    "B": algorithm_b,
    "C": algorithm_c,
    "D": algorithm_d,
    "E": algorithm_e,
}
