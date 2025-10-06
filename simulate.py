import argparse
import csv
from pathlib import Path
from typing import Dict, List

from models import (
    SimulationConfig,
    generate_profiles,
    compute_kpis,
    combine_profiles_with_signals,
)
from algorithms import ALGO_MAP, AlgorithmResult
from viz import plot_convergence, plot_pareto, plot_timeseries


def run_algorithm(
    algo_key: str,
    profiles: Dict[str, np.ndarray],
    config: SimulationConfig,
) -> AlgorithmResult:
    algo = ALGO_MAP.get(algo_key)
    if algo is None:
        raise ValueError(f"Unknown algorithm '{algo_key}'")
    return algo(profiles, config)


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="PV prosumer coordination simulator")
    parser.add_argument("--N", type=int, default=200, help="Number of prosumers")
    parser.add_argument("--scenario", type=str, default="mixed", choices=["sunny", "cloudy", "mixed"])
    parser.add_argument("--algos", nargs="*", default=["A", "B", "C", "D", "E"], help="Algorithms to run (A-E)")
    parser.add_argument("--seed", type=int, default=1234)
    parser.add_argument("--save_dir", type=str, default="./runs")
    args = parser.parse_args()

    config = SimulationConfig()
    base_profiles = generate_profiles(args.N, args.scenario, args.seed, config)

    save_dir = Path(args.save_dir)
    ensure_dir(save_dir)

    csv_path = save_dir / f"results_{args.scenario}_{args.N}.csv"
    csv_file = open(csv_path, "w", newline="")
    writer = csv.writer(csv_file)
    writer.writerow([
        "scenario",
        "algorithm",
        "total_co2",
        "par",
        "curtailment_pct",
        "welfare",
        "fairness",
        "avg_cost",
        "iterations",
    ])

    convergence_traces: Dict[str, List[float]] = {}
    metrics_summary: Dict[str, Dict[str, float]] = {}

    print("Scenario:", args.scenario)
    header = f"{'Alg':<5}{'CO2':>12}{'PAR':>10}{'Curt%':>10}{'Welfare':>14}{'Fairness':>12}{'Iter':>8}"
    print(header)
    print("-" * len(header))

    first_algo_result: AlgorithmResult | None = None
    first_algo_profiles: Dict[str, np.ndarray] | None = None

    for algo_key in args.algos:
        algo_key = algo_key.upper()
        result = run_algorithm(algo_key, base_profiles, config)
        final_profiles = combine_profiles_with_signals(base_profiles, result.price, result.carbon)
        metrics = compute_kpis(result.schedule, final_profiles, config)
        metrics_summary[algo_key] = metrics
        convergence_traces[algo_key] = result.convergence
        writer.writerow([
            args.scenario,
            algo_key,
            metrics["total_co2"],
            metrics["par"],
            metrics["curtailment_pct"],
            metrics["welfare"],
            metrics["fairness"],
            metrics["avg_cost"],
            result.iterations,
        ])
        print(
            f"{algo_key:<5}{metrics['total_co2']:>12.2f}{metrics['par']:>10.3f}{metrics['curtailment_pct']:>10.2f}{metrics['welfare']:>14.2f}{metrics['fairness']:>12.3f}{result.iterations:>8}"
        )
        if first_algo_result is None:
            first_algo_result = result
            first_algo_profiles = final_profiles

    csv_file.close()

    if convergence_traces:
        plot_convergence(convergence_traces, save_dir / "convergence.png")
    if metrics_summary:
        plot_pareto(metrics_summary, save_dir / "pareto.png")
    if first_algo_result is not None and first_algo_profiles is not None:
        plot_timeseries(
            first_algo_result.price,
            first_algo_result.carbon,
            first_algo_result.schedule,
            first_algo_profiles,
            save_dir / "timeseries.png",
        )

    print(f"Results saved to {csv_path}")


if __name__ == "__main__":
    main()
