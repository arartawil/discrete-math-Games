from pathlib import Path
from typing import Dict, List

import numpy as np
import matplotlib.pyplot as plt

from models import aggregate_power


def plot_convergence(traces: Dict[str, List[float]], save_path: Path) -> None:
    plt.figure(figsize=(8, 4))
    for label, trace in traces.items():
        if not trace:
            continue
        plt.semilogy(range(1, len(trace) + 1), trace, marker="o", label=label)
    plt.xlabel("Iteration")
    plt.ylabel("Infinity norm gap")
    plt.grid(True, which="both", linestyle="--", alpha=0.4)
    plt.legend()
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()


def plot_pareto(metrics: Dict[str, Dict[str, float]], save_path: Path) -> None:
    plt.figure(figsize=(6, 4))
    for label, vals in metrics.items():
        plt.scatter(vals["total_co2"], vals["welfare"], label=label)
        plt.annotate(label, (vals["total_co2"], vals["welfare"]))
    plt.xlabel("Total CO2")
    plt.ylabel("Social welfare")
    plt.grid(True, linestyle="--", alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()


def plot_timeseries(
    price: np.ndarray,
    carbon: np.ndarray,
    schedule: Dict[str, np.ndarray],
    profiles: Dict[str, np.ndarray],
    save_path: Path,
) -> None:
    agg = aggregate_power(schedule, profiles)
    t = np.arange(len(price))
    fig, axes = plt.subplots(3, 1, figsize=(8, 8), sharex=True)
    axes[0].plot(t, price, marker="o")
    axes[0].set_ylabel("Price")
    axes[1].plot(t, carbon, marker="s", color="tab:green")
    axes[1].set_ylabel("Carbon signal")
    axes[2].plot(t, agg["load"], label="Aggregate load")
    axes[2].plot(t, agg["net_import"], label="Net import")
    axes[2].legend()
    axes[2].set_ylabel("Power")
    axes[2].set_xlabel("Time slot")
    for ax in axes:
        ax.grid(True, linestyle="--", alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()
