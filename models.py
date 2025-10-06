import math
from dataclasses import dataclass
from typing import Dict, Tuple, Any

import numpy as np


@dataclass
class SimulationConfig:
    T: int = 24
    eta_c: float = 0.95
    eta_d: float = 0.95
    s_min: float = 0.0
    s_max: float = 6.0
    c_max: float = 2.5
    d_max: float = 2.5
    g_max: float = 6.0
    e_max: float = 4.0
    p_min: float = 0.05
    p_max: float = 0.4
    lambda_min: float = 0.05
    lambda_max: float = 0.9
    k_g: float = 0.45
    alpha: float = 0.1
    delta: float = 0.02


SCENARIO_PRESETS = {
    "sunny": {
        "pv_scale": 4.0,
        "load_base": 1.8,
        "load_amp": 0.9,
    },
    "cloudy": {
        "pv_scale": 2.0,
        "load_base": 2.0,
        "load_amp": 0.7,
    },
    "mixed": {
        "pv_scale": 3.0,
        "load_base": 1.9,
        "load_amp": 0.8,
    },
}


def get_rng(seed: int) -> np.random.Generator:
    return np.random.default_rng(seed)


def generate_profiles(N: int, scenario: str, seed: int, config: SimulationConfig) -> Dict[str, np.ndarray]:
    if scenario not in SCENARIO_PRESETS:
        raise ValueError(f"Unknown scenario '{scenario}'")
    preset = SCENARIO_PRESETS[scenario]
    rng = get_rng(seed)
    T = config.T
    t = np.arange(T)
    daylight = np.sin(np.pi * t / T)
    daylight = np.maximum(daylight, 0.0)
    pv_base = preset["pv_scale"] * daylight
    pv_noise = rng.normal(scale=0.2, size=(N, T))
    G = np.clip(pv_base + pv_noise, 0.0, None)

    load_profile = (
        preset["load_base"]
        + preset["load_amp"] * np.sin(2 * np.pi * (t - 6) / T)
    )
    load_noise = rng.normal(scale=0.3, size=(N, T))
    L = np.clip(load_profile + load_noise, 0.2, None)

    # household specific variations
    scale = rng.uniform(0.8, 1.2, size=(N, 1))
    G *= scale
    L *= scale

    s0 = np.full(N, 0.5 * config.s_max)

    price_base = 0.18 + 0.05 * np.sin(2 * np.pi * (t - 4) / T)
    carbon_base = 0.25 + 0.1 * np.cos(2 * np.pi * (t - 2) / T)
    p = np.clip(price_base, config.p_min, config.p_max)
    lam = np.clip(carbon_base, config.lambda_min, config.lambda_max)

    L_hat = np.percentile(L, 90, axis=1)

    return {
        "G": G,
        "L": L,
        "s0": s0,
        "p": p,
        "lambda": lam,
        "L_hat": L_hat,
    }


def build_empty_schedule(N: int, T: int) -> Dict[str, np.ndarray]:
    shape = (N, T)
    return {
        "c": np.zeros(shape),
        "d": np.zeros(shape),
        "g": np.zeros(shape),
        "e": np.zeros(shape),
        "s": np.zeros((N, T + 1)),
    }


def clip_controls(schedule: Dict[str, np.ndarray], config: SimulationConfig) -> None:
    np.clip(schedule["c"], 0.0, config.c_max, out=schedule["c"])
    np.clip(schedule["d"], 0.0, config.d_max, out=schedule["d"])
    np.clip(schedule["g"], 0.0, config.g_max, out=schedule["g"])
    np.clip(schedule["e"], 0.0, config.e_max, out=schedule["e"])


def propagate_soc(schedule: Dict[str, np.ndarray], s0: np.ndarray, config: SimulationConfig) -> None:
    s = schedule["s"]
    s[:, 0] = np.clip(s0, config.s_min, config.s_max)
    for t in range(config.T):
        s[:, t + 1] = (
            s[:, t]
            + config.eta_c * schedule["c"][:, t]
            - schedule["d"][:, t] / config.eta_d
        )
    np.clip(s, config.s_min, config.s_max, out=s)


def enforce_power_balance(schedule: Dict[str, np.ndarray], profiles: Dict[str, np.ndarray], config: SimulationConfig) -> None:
    G = profiles["G"]
    L = profiles["L"]
    s = schedule["s"]
    for t in range(config.T):
        balance = L[:, t] - (
            G[:, t]
            + schedule["d"][:, t]
            + schedule["g"][:, t]
            - schedule["c"][:, t]
            - schedule["e"][:, t]
        )
        schedule["g"][:, t] += np.maximum(balance, 0.0)
        schedule["e"][:, t] += np.maximum(-balance, 0.0)
        schedule["g"][:, t] = np.minimum(schedule["g"][:, t], config.g_max)
        schedule["e"][:, t] = np.minimum(schedule["e"][:, t], config.e_max)
    propagate_soc(schedule, profiles["s0"], config)


def check_feasibility(schedule: Dict[str, np.ndarray], profiles: Dict[str, np.ndarray], config: SimulationConfig) -> None:
    s = schedule["s"]
    if np.any(s < config.s_min - 1e-5) or np.any(s > config.s_max + 1e-5):
        raise AssertionError("SoC bounds violated")
    if np.any(schedule["c"] < -1e-6) or np.any(schedule["c"] > config.c_max + 1e-6):
        raise AssertionError("Charge bounds violated")
    if np.any(schedule["d"] < -1e-6) or np.any(schedule["d"] > config.d_max + 1e-6):
        raise AssertionError("Discharge bounds violated")
    if np.any(schedule["g"] < -1e-6) or np.any(schedule["g"] > config.g_max + 1e-6):
        raise AssertionError("Import bounds violated")
    if np.any(schedule["e"] < -1e-6) or np.any(schedule["e"] > config.e_max + 1e-6):
        raise AssertionError("Export bounds violated")

    G = profiles["G"]
    L = profiles["L"]
    for t in range(config.T):
        residual = L[:, t] - (
            G[:, t]
            + schedule["d"][:, t]
            + schedule["g"][:, t]
            - schedule["c"][:, t]
            - schedule["e"][:, t]
        )
        if np.linalg.norm(residual, np.inf) > 1e-3:
            raise AssertionError("Power balance violated")


def compute_peak_penalty(L: np.ndarray, L_hat: np.ndarray) -> np.ndarray:
    excess = L - L_hat[:, None]
    return np.maximum(excess, 0.0)


def compute_costs(schedule: Dict[str, np.ndarray], profiles: Dict[str, np.ndarray], config: SimulationConfig) -> Tuple[np.ndarray, Dict[str, Any]]:
    p = profiles["p"]
    lam = profiles["lambda"]
    L = profiles["L"]
    L_hat = profiles["L_hat"]
    c = schedule["c"]
    d = schedule["d"]
    g = schedule["g"]
    e = schedule["e"]

    peak_penalty = compute_peak_penalty(L, L_hat)
    energy_term = np.sum(p * (g - e), axis=1)
    carbon_term = np.sum(lam * config.k_g * g, axis=1)
    cycling_term = config.delta * np.sum(c + d, axis=1)
    peak_term = config.alpha * np.sum(peak_penalty, axis=1)
    costs = energy_term + carbon_term + cycling_term + peak_term

    diagnostics = {
        "energy": energy_term,
        "carbon": carbon_term,
        "cycling": cycling_term,
        "peak": peak_term,
    }
    return costs, diagnostics


def aggregate_power(schedule: Dict[str, np.ndarray], profiles: Dict[str, np.ndarray]) -> Dict[str, np.ndarray]:
    agg = {k: np.sum(v, axis=0) for k, v in schedule.items() if k != "s"}
    agg["net_import"] = agg["g"] - agg["e"]
    agg["load"] = np.sum(profiles["L"], axis=0)
    agg["pv"] = np.sum(profiles["G"], axis=0)
    return agg


def compute_kpis(schedule: Dict[str, np.ndarray], profiles: Dict[str, np.ndarray], config: SimulationConfig) -> Dict[str, float]:
    costs, _ = compute_costs(schedule, profiles, config)
    agg = aggregate_power(schedule, profiles)
    total_co2 = config.k_g * np.sum(agg["g"])
    avg_load = np.mean(agg["load"])
    peak_load = np.max(agg["load"])
    par = peak_load / max(avg_load, 1e-6)

    produced = np.sum(profiles["G"], axis=1)
    utilised = produced - np.sum(np.maximum(0.0, profiles["G"] - (schedule["e"] + schedule["c"] + profiles["L"] - schedule["g"] + schedule["d"])), axis=1)
    curtailment = np.clip(produced - utilised, 0.0, None)
    curtailment_rate = np.sum(curtailment) / max(np.sum(produced), 1e-6)

    welfare = -float(np.sum(costs))
    fairness = (np.sum(costs) ** 2) / (len(costs) * np.sum(costs ** 2) + 1e-9)

    return {
        "total_co2": float(total_co2),
        "par": float(par),
        "curtailment_pct": float(100 * curtailment_rate),
        "welfare": welfare,
        "fairness": float(fairness),
        "avg_cost": float(np.mean(costs)),
    }


def combine_profiles_with_signals(
    base_profiles: Dict[str, np.ndarray],
    price: np.ndarray,
    carbon: np.ndarray,
) -> Dict[str, np.ndarray]:
    profiles = dict(base_profiles)
    profiles["p"] = price
    profiles["lambda"] = carbon
    return profiles
